import UIKit

class GovernmentAidInfoViewController: UIViewController {
    private var vaBox: UIView?
    private var medicareBox: UIView?
    private var medicaidBox: UIView?
    private var socialSecurityBox: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Government Aid Benefits"
        setupInfoBoxes()
    }

    private func setupInfoBoxes() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        vaBox = createInfoBox(title: "VA Benefits", description: "VA provides health care, disability, and caregiver support for veterans with dementia, including respite care and financial aid for family caregivers.")
        medicareBox = createInfoBox(title: "Medicare", description: "Medicare covers hospital, medical, and some home health services for dementia patients. Caregivers can use these benefits for patient care needs.")
        medicaidBox = createInfoBox(title: "Medicaid", description: "Medicaid helps pay for long-term care, home care, and support services for dementia patients, easing costs for caregivers.")
        socialSecurityBox = createInfoBox(title: "Social Security Disability Insurance (SSDI)", description: "SSDI gives monthly payments to people with dementia. Caregivers can help patients apply and manage benefits.")

        if let vaBox = vaBox {
            let tap = UITapGestureRecognizer(target: self, action: #selector(vaBoxTapped))
            vaBox.addGestureRecognizer(tap)
            vaBox.isUserInteractionEnabled = true
            stackView.addArrangedSubview(vaBox)
        }
        if let medicareBox = medicareBox {
            let tap = UITapGestureRecognizer(target: self, action: #selector(medicareBoxTapped))
            medicareBox.addGestureRecognizer(tap)
            medicareBox.isUserInteractionEnabled = true
            stackView.addArrangedSubview(medicareBox)
        }
        if let medicaidBox = medicaidBox {
            let tap = UITapGestureRecognizer(target: self, action: #selector(medicaidBoxTapped))
            medicaidBox.addGestureRecognizer(tap)
            medicaidBox.isUserInteractionEnabled = true
            stackView.addArrangedSubview(medicaidBox)
        }
        if let socialSecurityBox = socialSecurityBox {
            let tap = UITapGestureRecognizer(target: self, action: #selector(ssdiBoxTapped))
            socialSecurityBox.addGestureRecognizer(tap)
            socialSecurityBox.isUserInteractionEnabled = true
            stackView.addArrangedSubview(socialSecurityBox)
        }

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
    }

    // MARK: - Box Tap Handlers
    @objc private func vaBoxTapped() {
        let vc = GovernmentAidWebViewController(urlString: "https://www.va.gov/caregiver-support/", pageTitle: "VA Benefits Application")
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func medicareBoxTapped() {
        let vc = GovernmentAidWebViewController(urlString: "https://www.medicare.gov/basics/get-started-with-medicare", pageTitle: "Medicare Application")
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func medicaidBoxTapped() {
        let vc = GovernmentAidWebViewController(urlString: "https://www.medicaid.gov/medicaid/how-to-apply/index.html", pageTitle: "Medicaid Application")
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc private func ssdiBoxTapped() {
        let vc = GovernmentAidWebViewController(urlString: "https://www.ssa.gov/benefits/disability/", pageTitle: "SSDI Application")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func createInfoBox(title: String, description: String) -> UIView {
    let box = UIView()
    box.backgroundColor = UIColor.secondarySystemBackground
    box.layer.cornerRadius = 12
    box.layer.shadowColor = UIColor.black.cgColor
    box.layer.shadowOpacity = 0.08
    box.layer.shadowOffset = CGSize(width: 0, height: 2)
    box.layer.shadowRadius = 4
    box.translatesAutoresizingMaskIntoConstraints = false
    // Add green border to indicate eligibility
    box.layer.borderColor = UIColor.systemGreen.cgColor
    box.layer.borderWidth = 3
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 15)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        vStack.axis = .vertical
        vStack.spacing = 8
        vStack.translatesAutoresizingMaskIntoConstraints = false
        
        box.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            vStack.topAnchor.constraint(equalTo: box.topAnchor, constant: 16),
            vStack.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -16)
        ])
        return box
    }
}
