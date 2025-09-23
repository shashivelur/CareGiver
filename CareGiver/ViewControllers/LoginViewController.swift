import UIKit
import CoreData
import CryptoKit  // Add this import

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Login", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

