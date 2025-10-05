import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

/// A small service responsible for uploading and tracking profile photos in Firebase.
struct ProfilePhotoService {
    private static let pendingKeyPrefix = "PendingProfileUpload_"
    private static var authListener: AuthStateDidChangeListenerHandle?

    private static func pendingKey(for username: String) -> String { return pendingKeyPrefix + username }

    /// Queue a profile photo for later upload (when Firebase Auth is available).
    static func queuePending(_ image: UIImage, for username: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let defaults = UserDefaults.standard
        defaults.set(data, forKey: pendingKey(for: username))
        defaults.synchronize()
    }

    /// Attempt to upload any pending photo for the given username. If not signed in, no-op.
    static func tryUploadPendingIfAny(for username: String, completion: ((Result<URL, Error>) -> Void)? = nil) {
        let defaults = UserDefaults.standard
        let key = pendingKey(for: username)
        guard let data = defaults.data(forKey: key) else { return }
        guard let _ = Auth.auth().currentUser?.uid else { return }
        guard let image = UIImage(data: data) else { return }
        uploadProfilePhoto(image) { result in
            switch result {
            case .success(let url):
                // Clear pending on success
                defaults.removeObject(forKey: key)
                defaults.synchronize()
                // Persist URL under the provided username and mirror legacy key
                defaults.set(url.absoluteString, forKey: "CaregiverProfileImageURL_\(username)")
                defaults.set(url.absoluteString, forKey: "CaregiverProfileImageURL")
                defaults.synchronize()
                // Notify so any views relying on URL or image can refresh
                NotificationCenter.default.post(name: .SessionChanged, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("ProfilePhotoUpdated"), object: nil)
                completion?(.success(url))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }

    /// Attempt to upload any pending profile photo for the currently signed-in Firebase user.
    /// This scans all pending keys to avoid missing uploads if the username was changed.
    static func tryUploadAnyPendingForCurrentUser() {
        guard Auth.auth().currentUser != nil else { return }
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        let pendingKeys = allKeys.filter { $0.hasPrefix(pendingKeyPrefix) }
        for key in pendingKeys {
            // Extract username suffix after prefix
            let username = String(key.dropFirst(pendingKeyPrefix.count))
            tryUploadPendingIfAny(for: username, completion: nil)
        }
    }

    /// Installs a single auth-state listener that tries pending uploads on sign-in.
    static func installAuthListener() {
        guard authListener == nil else { return }
        authListener = Auth.auth().addStateDidChangeListener { _, user in
            guard user != nil else { return }
            // Try to flush any pending uploads for the current user
            tryUploadAnyPendingForCurrentUser()
        }
    }

    /// Uploads the given image as the current user's profile photo.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - maxDimension: Optional max dimension to resize the image to (preserves aspect ratio). Default 768 px.
    ///   - completion: Called with the public download URL on success.
    static func uploadProfilePhoto(_ image: UIImage, maxDimension: CGFloat = 768, completion: @escaping (Result<URL, Error>) -> Void) {
        // 0) Ensure the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "ProfilePhotoService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not signed in."])) )
            return
        }

        // 1) Resize and compress to keep uploads fast
        let resized = image.resized(maxDimension: maxDimension) ?? image
        guard let data = resized.jpegData(compressionQuality: 0.85) else {
            completion(.failure(NSError(domain: "ProfilePhotoService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not encode JPEG."])) )
            return
        }

        // 2) Build Storage reference (stable path per user)
        let ref = Storage.storage().reference().child("users/\(uid)/profile.jpg")

        // 3) Metadata
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"

        // 4) Upload
        ref.putData(data, metadata: meta) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            // 5) Get a download URL (tokenized)
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let url = url else {
                    completion(.failure(NSError(domain: "ProfilePhotoService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No download URL returned."])) )
                    return
                }

                // 6) Write metadata to Firestore
                let doc = Firestore.firestore().collection("users").document(uid)
                doc.setData([
                    "photoURL": url.absoluteString,
                    "photoUpdatedAt": FieldValue.serverTimestamp()
                ], merge: true) { err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        completion(.success(url))
                    }
                }
            }
        }
    }
}

private extension UIImage {
    /// Returns a resized copy of the image, preserving aspect ratio, if the longest side exceeds `maxDimension`.
    func resized(maxDimension: CGFloat) -> UIImage? {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
