import UIKit
import CoreData

class RegisterViewController: UIViewController {
    
    private var usernameTextField: UITextField!
    private var firstNameTextField: UITextField!
    private var lastNameTextField: UITextField!
    private var emailTextField: UITextField!
    private var phoneNumberTextField: UITextField!
    private var dateOfBirthPicker: UIDatePicker!
    private var registerButton: UIButton!
    private var addPatientButton: UIButton!
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    
    private var patients: [PatientInfo] = []
    
    struct PatientInfo {
        let firstName: String
        let lastName: String
        let dateOfBirth: Date
        let email: String?
        let phoneNumber: String?
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Register Caregiver"
        view.backgroundColor = .systemBackground
        
        // Create scroll view
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Create content view
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Create form elements
        createFormElements()
        setupConstraints()
        
        // Add back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
    }
    
    private func createFormElements() {
        // Username field
        usernameTextField = createTextField(placeholder: "Username")
        
        // First name field
        firstNameTextField = createTextField(placeholder: "First Name")
        
        // Last name field
        lastNameTextField = createTextField(placeholder: "Last Name")
        
        // Email field
        emailTextField = createTextField(placeholder: "Email")
        emailTextField.keyboardType = .emailAddress
        
        // Phone number field
        phoneNumberTextField = createTextField(placeholder: "Phone Number")
        phoneNumberTextField.keyboardType = .phonePad
        
        // Date of birth picker
        dateOfBirthPicker = UIDatePicker()
        dateOfBirthPicker.datePickerMode = .date
        dateOfBirthPicker.preferredDatePickerStyle = .wheels
        dateOfBirthPicker.maximumDate = Date()
        dateOfBirthPicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Add patient button
        addPatientButton = UIButton(type: .system)
        addPatientButton.setTitle("Add Patient (Optional)", for: .normal)
        addPatientButton.layer.cornerRadius = 8
        addPatientButton.backgroundColor = .systemOrange
        addPatientButton.setTitleColor(.white, for: .normal)
        addPatientButton.addTarget(self, action: #selector(addPatientButtonTapped), for: .touchUpInside)
        addPatientButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Register button
        registerButton = UIButton(type: .system)
        registerButton.setTitle("Register", for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.backgroundColor = .systemBlue
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all elements to content view
        [usernameTextField, firstNameTextField, lastNameTextField, emailTextField, 
         phoneNumberTextField, dateOfBirthPicker, addPatientButton, registerButton].forEach {
            contentView.addSubview($0)
        }
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Form elements constraints
            usernameTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            usernameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            usernameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            firstNameTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 16),
            firstNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            firstNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            firstNameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            lastNameTextField.topAnchor.constraint(equalTo: firstNameTextField.bottomAnchor, constant: 16),
            lastNameTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            lastNameTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            lastNameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            emailTextField.topAnchor.constraint(equalTo: lastNameTextField.bottomAnchor, constant: 16),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            
            phoneNumberTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            phoneNumberTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            phoneNumberTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 44),
            
            dateOfBirthPicker.topAnchor.constraint(equalTo: phoneNumberTextField.bottomAnchor, constant: 16),
            dateOfBirthPicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateOfBirthPicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            dateOfBirthPicker.heightAnchor.constraint(equalToConstant: 150),
            
            addPatientButton.topAnchor.constraint(equalTo: dateOfBirthPicker.bottomAnchor, constant: 20),
            addPatientButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addPatientButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addPatientButton.heightAnchor.constraint(equalToConstant: 44),
            
            registerButton.topAnchor.constraint(equalTo: addPatientButton.bottomAnchor, constant: 20),
            registerButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            registerButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            registerButton.heightAnchor.constraint(equalToConstant: 44),
            registerButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addPatientButtonTapped() {
        showAddPatientAlert()
    }
    
    @objc private func registerButtonTapped() {
        guard validateInput() else { return }
        
        // Create caregiver
        let caregiver = CoreDataManager.shared.createCaregiver(
            username: usernameTextField.text!,
            firstName: firstNameTextField.text!,
            lastName: lastNameTextField.text!,
            email: emailTextField.text!,
            phoneNumber: phoneNumberTextField.text!,
            dateOfBirth: dateOfBirthPicker.date
        )
        
        // Create patients
        for patientInfo in patients {
            _ = CoreDataManager.shared.createPatient(
                firstName: patientInfo.firstName,
                lastName: patientInfo.lastName,
                dateOfBirth: patientInfo.dateOfBirth,
                email: patientInfo.email,
                phoneNumber: patientInfo.phoneNumber,
                caregiver: caregiver
            )
        }
        
        showAlert(message: "Registration successful! You can now login.") {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func validateInput() -> Bool {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(message: "Please enter a username")
            return false
        }
        
        // Check if username already exists
        if CoreDataManager.shared.findCaregiver(username: username) != nil {
            showAlert(message: "Username already exists. Please choose a different one.")
            return false
        }
        
        guard let firstName = firstNameTextField.text, !firstName.isEmpty else {
            showAlert(message: "Please enter your first name")
            return false
        }
        
        guard let lastName = lastNameTextField.text, !lastName.isEmpty else {
            showAlert(message: "Please enter your last name")
            return false
        }
        
        guard let email = emailTextField.text, !email.isEmpty else {
            showAlert(message: "Please enter your email")
            return false
        }
        
        guard let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty else {
            showAlert(message: "Please enter your phone number")
            return false
        }
        
        return true
    }
    
    private func showAddPatientAlert() {
        let alert = UIAlertController(title: "Add Patient", message: "Enter patient information", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "First Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Last Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Email (Optional)"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Phone Number (Optional)"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let firstName = alert.textFields?[0].text, !firstName.isEmpty,
                  let lastName = alert.textFields?[1].text, !lastName.isEmpty else {
                self.showAlert(message: "Please enter patient's first and last name")
                return
            }
            
            let email = alert.textFields?[2].text?.isEmpty == false ? alert.textFields?[2].text : nil
            let phoneNumber = alert.textFields?[3].text?.isEmpty == false ? alert.textFields?[3].text : nil
            
            // For simplicity, using current date as patient's date of birth
            // In a real app, you'd have a separate date picker for this
            let patient = PatientInfo(
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: Date(timeIntervalSinceNow: -365*24*60*60*25), // 25 years ago as default
                email: email,
                phoneNumber: phoneNumber
            )
            
            self.patients.append(patient)
            self.updatePatientsList()
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func updatePatientsList() {
        // Update the button title to show number of patients added
        addPatientButton.setTitle("Patients Added: \(patients.count)", for: .normal)
    }
    
    private func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
