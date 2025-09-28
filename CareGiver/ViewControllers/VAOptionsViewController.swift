import UIKit

class VAOptionsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VA Benefits Options"
        view.backgroundColor = .systemBackground
        setupOptions()
    }

    private func setupOptions() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 32
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Info box
        let infoBox = UIView()
        infoBox.backgroundColor = UIColor.systemGray6
        infoBox.layer.cornerRadius = 10
        infoBox.layer.borderColor = UIColor.systemGreen.cgColor
        infoBox.layer.borderWidth = 2
        infoBox.translatesAutoresizingMaskIntoConstraints = false

        let infoLabel = UILabel()
        infoLabel.text = "CAFC stands for Comprehensive Assistance for Family Caregivers, a VA program that provides support and resources to eligible family caregivers of veterans."
        infoLabel.font = UIFont.systemFont(ofSize: 15)
        infoLabel.textColor = .label
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        infoBox.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: infoBox.leadingAnchor, constant: 12),
            infoLabel.trailingAnchor.constraint(equalTo: infoBox.trailingAnchor, constant: -12),
            infoLabel.topAnchor.constraint(equalTo: infoBox.topAnchor, constant: 12),
            infoLabel.bottomAnchor.constraint(equalTo: infoBox.bottomAnchor, constant: -12)
        ])

        // CAFC buttons
        let eligibilityButton = UIButton(type: .system)
        eligibilityButton.setTitle("CAFC: Check Eligibility", for: .normal)
        eligibilityButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        eligibilityButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        eligibilityButton.layer.cornerRadius = 12
        eligibilityButton.setTitleColor(.label, for: .normal)
        eligibilityButton.contentEdgeInsets = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        eligibilityButton.addTarget(self, action: #selector(eligibilityTapped), for: .touchUpInside)

        let continueButton = UIButton(type: .system)
        continueButton.setTitle("CAFC: Continue Application", for: .normal)
        continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        continueButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        continueButton.layer.cornerRadius = 12
        continueButton.setTitleColor(.label, for: .normal)
        continueButton.contentEdgeInsets = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        stack.addArrangedSubview(infoBox)
        stack.addArrangedSubview(eligibilityButton)
        stack.addArrangedSubview(continueButton)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func eligibilityTapped() {
        // CAFCEligibilityViewController reference removed as requested.
        // You may want to show an alert or disable this button.
        let alert = UIAlertController(title: "Not Available", message: "The CAFC eligibility form is currently unavailable.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc private func continueTapped() {
        let url = "https://www.va.gov/family-and-caregiver-benefits/health-and-disability/comprehensive-assistance-for-family-caregivers/apply-form-10-10cg/veteran-information/personal-information#start"
        let vc = GovernmentAidWebViewController(urlString: url, pageTitle: "Comprehensive Assistance Application")
        navigationController?.pushViewController(vc, animated: true)
    }
}
