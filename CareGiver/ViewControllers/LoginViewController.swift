import UIKit
import CoreData
import CryptoKit  // Add this import
import LocalAuthentication
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var faceIDButton: UIButton?
    
    private var didAttemptAutoBiometric = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        faceIDButton?.isHidden = true

        // Dismiss keyboard when tapping outside text fields
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoPromptBiometricIfAvailable()
    }
    
    private func autoPromptBiometricIfAvailable() {
        // Ensure we only prompt once per appearance
        guard !didAttemptAutoBiometric else { return }
        didAttemptAutoBiometric = true

        // Prefer typed username; otherwise use last biometric username
        let typed = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let candidate = !typed.isEmpty ? typed : (UserDefaults.standard.string(forKey: "LastBiometricUsername") ?? "")
        guard !candidate.isEmpty else { return }

        let (available, _) = BiometricAuthManager.isBiometryAvailable()
        let enabled = UserDefaults.standard.bool(forKey: "BiometricEnabled_\(candidate)")
        guard available && enabled else { return }

        // Only auto-prompt if password fields are empty to avoid interrupting manual entry
        if (usernameTextField.text?.isEmpty ?? true) || (passwordTextField.text?.isEmpty ?? true) {
            attemptFaceIDLogin(for: candidate)
        }
    }
    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        guard let usernameOrEmail = usernameTextField.text, !usernameOrEmail.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both username and password")
            return
        }

        // Compute hashed password once for both cloud and local auth
        guard let hashedPassword = sha256(for: password) else {
            showAlert(message: "Error processing password")
            return
        }

        // Try cloud first: if input looks like an email, use it; otherwise try to resolve via Firestore username mapping.
        let trimmed = usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let tryLocalFallback: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.tryLocalAuth(username: usernameOrEmail, password: password)
        }

        let attemptFirebaseSignIn: (String) -> Void = { [weak self] email in
            guard let self = self else { return }
            Auth.auth().signIn(withEmail: email, password: hashedPassword) { [weak self] authResult, error in
                guard let self = self else { return }
                if let error = error {
                    print("Firebase sign-in failed: \(error.localizedDescription). Falling back to local auth.")
                    tryLocalFallback()
                    return
                }

                // On Firebase success, pull profile from Firestore and sync to local Core Data, then proceed
                let proceedToHome: (String) -> Void = { sessionUsername in
                    UserDefaults.standard.set(sessionUsername, forKey: "LoggedInUsername")
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: .SessionChanged, object: nil)
                    self.performSegue(withIdentifier: "toHomePageFromLogin", sender: self)
                }

                guard let uid = authResult?.user.uid else {
                    let sessionUsername = self.resolveUsernameForSession(typed: trimmed, email: email)
                    proceedToHome(sessionUsername)
                    return
                }

                Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, err in
                    guard let self = self else { return }
                    if let err = err {
                        print("Failed to fetch Firestore profile: \(err.localizedDescription)")
                        let sessionUsername = self.resolveUsernameForSession(typed: trimmed, email: email)
                        proceedToHome(sessionUsername)
                        return
                    }

                    if let data = snapshot?.data() {
                        self.upsertLocalCaregiver(from: data)
                        let sessionUsername = (data["username"] as? String).flatMap { raw -> String? in
                            let trimmedUsername = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                            return trimmedUsername.isEmpty ? nil : trimmedUsername
                        } ?? self.resolveUsernameForSession(typed: trimmed, email: email)
                        proceedToHome(sessionUsername)
                    } else {
                        let sessionUsername = self.resolveUsernameForSession(typed: trimmed, email: email)
                        proceedToHome(sessionUsername)
                    }
                }
            }
        }

        if trimmed.contains("@") {
            // Direct email
            attemptFirebaseSignIn(trimmed)
        } else {
            // Username: resolve via Firestore, then attempt cloud sign-in; on failure, fallback to local
            resolveEmailFromCloud(for: trimmed) { [weak self] resolvedEmail in
                guard let self = self else { return }
                if let email = resolvedEmail {
                    attemptFirebaseSignIn(email)
                } else {
                    print("Could not resolve username to email in Firestore; falling back to local auth.")
                    tryLocalFallback()
                }
            }
        }
    }
    
    @IBAction func faceIDLoginTapped(_ sender: UIButton) {
        // Determine which username to use. If a username is typed, use it; else use last biometric username.
        let typed = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = !typed.isEmpty ? typed : (UserDefaults.standard.string(forKey: "LastBiometricUsername") ?? "")
        guard !username.isEmpty else {
            showAlert(message: "Please enter your username first to use Face ID")
            return
        }
        attemptFaceIDLogin(for: username)
    }
    
    // Add the sha256 function (same as in RegisterStep1ViewController)
    func sha256(for string: String) -> String? {
        guard let inputData = string.data(using: .utf8) else {
            print("Error: Could not convert string to Data.")
            return nil
        }
        
        let digest = SHA256.hash(data: inputData)
        let hexString = digest.compactMap { String(format: "%02x", $0) }.joined()
        return hexString
    }
    
    func authenticate(username: String, password: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Hash the entered password before comparing
        guard let hashedPassword = sha256(for: password) else {
            print("Failed to hash password")
            return false
        }
        
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@ AND password == %@", username, hashedPassword)
        request.fetchLimit = 1
        
        do {
            let result = try context.fetch(request)
            if !result.isEmpty {
                // Save the logged-in username to UserDefaults
                UserDefaults.standard.set(username, forKey: "LoggedInUsername")
                UserDefaults.standard.synchronize()
                
                // Notify the app to refresh any visible headers/profile views and allow SceneDelegate to sync legacy key first
                NotificationCenter.default.post(name: .SessionChanged, object: nil)
                
                // Optional: keep legacy global image mirrored to the current user for backward compatibility
                let defaults = UserDefaults.standard
                let namespacedKey = "CaregiverProfileImageData_\(username)"
                if let perUserData = defaults.data(forKey: namespacedKey) {
                    // Ensure global mirrors the current user's photo for backward compatibility
                    defaults.set(perUserData, forKey: "CaregiverProfileImageData")
                }
                
                return true
            }
            return false
        } catch {
            print("Login fetch failed: \(error)")
            return false
        }
    }
    
    private func configureFaceIDAvailability(for username: String) {
        let (available, _) = BiometricAuthManager.isBiometryAvailable()
        let enabled = UserDefaults.standard.bool(forKey: "BiometricEnabled_\(username)")
        let shouldShow = available && enabled
        faceIDButton?.isHidden = !shouldShow

        // Optional: auto-prompt when arriving on this screen if we have both username and Face ID enabled
        if shouldShow {
            // Do not auto-prompt if user is actively typing
            if (usernameTextField.text?.isEmpty ?? true) && (passwordTextField.text?.isEmpty ?? true) {
                attemptFaceIDLogin(for: username)
            }
        }
    }
    
    private func attemptFaceIDLogin(for username: String) {
        BiometricAuthManager.tryBiometricLogin(for: username, presenting: self, reason: "Authenticate to sign in") { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                // On success, set session and segue
                UserDefaults.standard.set(username, forKey: "LoggedInUsername")
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: .SessionChanged, object: nil)
                self.performSegue(withIdentifier: "toHomePageFromLogin", sender: self)
            case .failure(let error):
                // If failed due to not enabled or mismatch, show message and keep password flow
                print("Biometric login failed: \(error.localizedDescription)")
                // Optionally present a gentle message
            }
        }
    }
    
    private func tryLocalAuth(username: String, password: String) {
        if authenticate(username: username, password: password) {
            performSegue(withIdentifier: "toHomePageFromLogin", sender: self)
        } else {
            showAlert(message: "Invalid username or password")
        }
    }

    // Resolve an email to use for Firebase from the typed username/email or local Core Data
    private func resolveEmail(for usernameOrEmail: String) -> String? {
        let trimmed = usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("@") {
            return trimmed
        }

        // Look up caregiver by username to find their email
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", trimmed)
        request.fetchLimit = 1
        do {
            if let cg = try context.fetch(request).first, let email = cg.email, !email.isEmpty {
                return email
            }
        } catch {
            print("resolveEmail lookup by username failed: \(error)")
        }
        return nil
    }

    // Cloud username -> email resolver using Firestore
    private func resolveEmailFromCloud(for username: String, completion: @escaping (String?) -> Void) {
        let lower = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        Firestore.firestore()
            .collection("users")
            .whereField("usernameLowercased", isEqualTo: lower)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Username lookup in Firestore failed: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let doc = snapshot?.documents.first else {
                    completion(nil)
                    return
                }
                let email = doc.data()["email"] as? String
                completion(email)
            }
    }

    // Decide which username to persist in session after a Firebase success
    private func resolveUsernameForSession(typed: String, email: String) -> String {
        let trimmedTyped = typed.trimmingCharacters(in: .whitespacesAndNewlines)

        // If typed value is already a username (no '@'), prefer it
        if !trimmedTyped.contains("@") {
            return trimmedTyped
        }

        // Otherwise, try to find a local caregiver by email to obtain their username
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return trimmedTyped }
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        request.fetchLimit = 1
        do {
            if let cg = try context.fetch(request).first, let uname = cg.username, !uname.isEmpty {
                return uname
            }
        } catch {
            print("resolveUsernameForSession lookup by email failed: \(error)")
        }

        // Fallback: store the typed value (which may be the email). This keeps the session non-empty.
        return trimmedTyped
    }
    
    // Upsert the caregiver in Core Data using Firestore user profile data
    private func upsertLocalCaregiver(from data: [String: Any]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let username = (data["username"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (data["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstName = data["firstName"] as? String
        let lastName = data["lastName"] as? String
        let phoneNumber = data["phoneNumber"] as? String
        let dob = (data["dateOfBirth"] as? Timestamp)?.dateValue()

        var caregiver: Caregiver?

        if let username = username, !username.isEmpty {
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", username)
            request.fetchLimit = 1
            caregiver = try? context.fetch(request).first
        }

        if caregiver == nil, let email = email, !email.isEmpty {
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            request.fetchLimit = 1
            caregiver = try? context.fetch(request).first
        }

        if caregiver == nil {
            caregiver = Caregiver(context: context)
        }

        caregiver?.username = username ?? caregiver?.username
        caregiver?.email = email ?? caregiver?.email
        caregiver?.firstName = firstName ?? caregiver?.firstName
        caregiver?.lastName = lastName ?? caregiver?.lastName
        caregiver?.phoneNumber = phoneNumber ?? caregiver?.phoneNumber
        caregiver?.dateOfBirth = dob ?? caregiver?.dateOfBirth

        do {
            try context.save()
        } catch {
            print("Failed to upsert local caregiver from cloud: \(error)")
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

