
import UIKit
import CoreData
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
        
        func authenticate(username: String, password: String) -> Bool {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@ AND password == %@", username, password)
            request.fetchLimit = 1
            
            do {
                let result = try context.fetch(request)
                return !result.isEmpty
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
}
