import UIKit

class VACaregiverFormViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VA Caregiver Support Form"
        view.backgroundColor = .systemBackground
        setupForm()
    }

    private func setupForm() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let nameField = UITextField()
        nameField.placeholder = "Full Name"
        nameField.borderStyle = .roundedRect

        let dobField = UITextField()
        dobField.placeholder = "Date of Birth (MM/DD/YYYY)"
        dobField.borderStyle = .roundedRect

        let veteranNameField = UITextField()
        veteranNameField.placeholder = "Veteran's Full Name"
        veteranNameField.borderStyle = .roundedRect

        let relationshipField = UITextField()
        relationshipField.placeholder = "Relationship to Veteran"
        relationshipField.borderStyle = .roundedRect

        let phoneField = UITextField()
        phoneField.placeholder = "Phone Number"
        phoneField.borderStyle = .roundedRect

        let emailField = UITextField()
        emailField.placeholder = "Email Address"
        emailField.borderStyle = .roundedRect

        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit Application", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        stack.addArrangedSubview(nameField)
        stack.addArrangedSubview(dobField)
        stack.addArrangedSubview(veteranNameField)
        stack.addArrangedSubview(relationshipField)
        stack.addArrangedSubview(phoneField)
        stack.addArrangedSubview(emailField)
        stack.addArrangedSubview(submitButton)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func submitTapped() {
        let alert = UIAlertController(title: "Submitted!", message: "Your VA Caregiver Support application has been submitted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
