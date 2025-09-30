import UIKit
import CoreData
import CryptoKit  // Add this import
import LocalAuthentication

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
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both username and password")
            return
        }
        
        if authenticate(username: username, password: password) {
            // ✅ Success — navigate to the next screen
            performSegue(withIdentifier: "toHomePageFromLogin", sender: self)
        } else {
            // ❌ Failure
            showAlert(message: "Invalid username or password")
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
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func showAlert(message: String) {
        let alert = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

