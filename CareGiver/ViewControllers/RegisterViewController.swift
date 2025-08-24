


import UIKit

class RegisterViewController: UIViewController {
    // These will be set from the first step
    var caregiverUsername: String?
    var caregiverPassword: String?

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!
    @IBOutlet weak var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func registerButtonTapped(_ sender: UIButton) {
        guard let username = caregiverUsername, !username.isEmpty,
              let password = caregiverPassword, !password.isEmpty,
              let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let phone = phoneNumberTextField.text, !phone.isEmpty else {
            let alert = UIAlertController(title: "Error", message: "Please fill all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Save to Caregiver profile (not Patient)
        // Example: CoreDataManager.shared.createCaregiver(username: username, password: password, firstName: firstName, lastName: lastName, email: email, phoneNumber: phone, dateOfBirth: dateOfBirthPicker.date)

        let alert = UIAlertController(title: "Success", message: "Caregiver registered!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
