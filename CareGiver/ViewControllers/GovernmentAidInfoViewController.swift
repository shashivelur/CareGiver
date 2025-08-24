import UIKit

class GovernmentAidInfoViewController: UIViewController {
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

    let vaBox = createInfoBox(title: "VA Benefits", description: "VA provides health care, disability, and caregiver support for veterans with dementia, including respite care and financial aid for family caregivers.")
    let medicareBox = createInfoBox(title: "Medicare", description: "Medicare covers hospital, medical, and some home health services for dementia patients. Caregivers can use these benefits for patient care needs.")
    let medicaidBox = createInfoBox(title: "Medicaid", description: "Medicaid helps pay for long-term care, home care, and support services for dementia patients, easing costs for caregivers.")
    let socialSecurityBox = createInfoBox(title: "Social Security Disability Insurance (SSDI)", description: "SSDI gives monthly payments to people with dementia. Caregivers can help patients apply and manage benefits.")

        stackView.addArrangedSubview(vaBox)
        stackView.addArrangedSubview(medicareBox)
        stackView.addArrangedSubview(medicaidBox)
        stackView.addArrangedSubview(socialSecurityBox)

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
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
