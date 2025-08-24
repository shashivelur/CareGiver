import UIKit




class RegisterStep2ViewController: UIViewController {
    // These will be set from the first step
    var caregiverUsername: String?
    var caregiverPassword: String?
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!
    @IBOutlet weak var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        
    }
}
