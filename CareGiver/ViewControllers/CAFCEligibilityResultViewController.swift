import UIKit

class CAFCEligibilityResultViewController: UIViewController {
    private let eligible: Bool
    init(eligible: Bool) {
        self.eligible = eligible
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "CAFC Eligibility Result"
        setupUI()
    }
    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 32
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        let resultLabel = UILabel()
        resultLabel.text = eligible ? "You are likely eligible for CAFC." : "You are likely NOT eligible for CAFC."
        resultLabel.font = UIFont.boldSystemFont(ofSize: 22)
        resultLabel.textColor = eligible ? .systemGreen : .systemRed
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        stack.addArrangedSubview(resultLabel)

        if eligible {
            let continueButton = UIButton(type: .system)
            continueButton.setTitle("Continue to CAFC form", for: .normal)
            continueButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            continueButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
            continueButton.layer.cornerRadius = 12
            continueButton.setTitleColor(.label, for: .normal)
            continueButton.contentEdgeInsets = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
            continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
            stack.addArrangedSubview(continueButton)
        }

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    @objc private func continueTapped() {
        let url = "https://www.va.gov/family-and-caregiver-benefits/health-and-disability/comprehensive-assistance-for-family-caregivers/apply-form-10-10cg/veteran-information/personal-information#start"
        let vc = GovernmentAidWebViewController(urlString: url, pageTitle: "Comprehensive Assistance Application")
        navigationController?.pushViewController(vc, animated: true)
    }
}
