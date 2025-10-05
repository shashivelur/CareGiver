import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Utility to mirror Report creation to Firestore under users/{uid}/reports
enum ReportsCloudSync {
    /// Create a report document (and upload images) in Firestore for the current Firebase user.
    /// - Parameter report: The report to create.
    static func createReport(_ report: Report) {
        guard let uid = Auth.auth().currentUser?.uid else {
            // Not signed in; skip cloud save
            return
        }
        let db = Firestore.firestore()
        let reports = db.collection("users").document(uid).collection("reports")
        // Pre-generate a document ID so we can upload images into a scoped folder
        let docRef = reports.document()
        let reportId = docRef.documentID

        // Upload images (if any) to Storage and collect download URLs
        let storage = Storage.storage()
        let basePath = "users/\(uid)/reports/\(reportId)/images"
        let group = DispatchGroup()
        var imageURLs: [String] = []

        for (index, data) in report.images.enumerated() {
            group.enter()
            let fileName = String(format: "image_%03d.png", index)
            let ref = storage.reference(withPath: basePath + "/" + fileName)
            let metadata = StorageMetadata()
            metadata.contentType = "image/png"
            ref.putData(data, metadata: metadata) { _, error in
                if let error = error {
                    print("ReportsCloudSync image upload failed: \(error.localizedDescription)")
                    group.leave()
                    return
                }
                ref.downloadURL { url, _ in
                    if let url = url { imageURLs.append(url.absoluteString) }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            var dict: [String: Any] = [
                "title": report.title,
                "content": report.content,
                "isReviewed": report.isReviewed,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            dict["date"] = Timestamp(date: report.date)
            dict["imageURLs"] = imageURLs

            docRef.setData(dict, merge: true) { error in
                if let error = error {
                    print("ReportsCloudSync createReport failed: \(error.localizedDescription)")
                } else {
                    print("ReportsCloudSync: report saved for user \(uid) with id \(reportId)")
                }
            }
        }
    }

    /// Fetch all reports for current user; returns array of (id, Report)
    static func fetchReports(completion: @escaping ([(id: String, report: Report)]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("reports")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("ReportsCloudSync fetchReports failed: \(error.localizedDescription)")
                    completion([])
                    return
                }
                var results: [(id: String, report: Report)] = []
                for doc in snapshot?.documents ?? [] {
                    let data = doc.data()
                    let title = (data["title"] as? String) ?? ""
                    let content = (data["content"] as? String) ?? ""
                    let isReviewed = (data["isReviewed"] as? Bool) ?? false
                    let date: Date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                    // Images are not downloaded here to keep startup fast; you can extend to fetch if needed.
                    let report = Report(title: title, content: content, date: date, isReviewed: isReviewed, images: [])
                    results.append((id: doc.documentID, report: report))
                }
                completion(results)
            }
    }
}
