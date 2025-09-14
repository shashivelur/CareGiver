import UIKit

class AidDetailViewController: UIViewController {
    private let titleText: String

    init(titleText: String) {
        self.titleText = titleText
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = titleText
        setupForm()
    }

    private func setupForm() {
        let formStack = UIStackView()
        formStack.axis = .vertical
        formStack.spacing = 16
        formStack.translatesAutoresizingMaskIntoConstraints = false

        let infoLabel = UILabel()
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = UIFont.systemFont(ofSize: 16)
        infoLabel.textColor = .label
        infoLabel.text = formInfoText(for: titleText)

        let nameField = UITextField()
        nameField.placeholder = "Full Name"
        nameField.borderStyle = .roundedRect

        let idField = UITextField()
        idField.placeholder = idPlaceholder(for: titleText)
        idField.borderStyle = .roundedRect

        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Submit Application", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        formStack.addArrangedSubview(infoLabel)
        formStack.addArrangedSubview(nameField)
        formStack.addArrangedSubview(idField)
        formStack.addArrangedSubview(submitButton)

        view.addSubview(formStack)
        NSLayoutConstraint.activate([
            formStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            formStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            formStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func formInfoText(for aidType: String) -> String {
        switch aidType {
        case "VA page":
            return "Fill out the form below to apply for VA Benefits."
        case "Medicare page":
            return "Fill out the form below to apply for Medicare."
        case "Medicaid page":
            return "Fill out the form below to apply for Medicaid."
        case "SSDI page":
            return "Fill out the form below to apply for Social Security Disability Insurance (SSDI)."
        default:
            return "Fill out the form below to apply."
        }
    }

    private func idPlaceholder(for aidType: String) -> String {
        switch aidType {
        case "VA page":
            return "VA ID Number"
        case "Medicare page":
            return "Medicare Number"
        case "Medicaid page":
            return "Medicaid Number"
        case "SSDI page":
            return "Social Security Number"
        default:
            return "ID Number"
        }
    }

    @objc private func submitTapped() {
        let alert = UIAlertController(title: "Submitted!", message: "Your application has been submitted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
