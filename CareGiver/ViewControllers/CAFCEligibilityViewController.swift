import UIKit

class CAFCEligibilityViewController: UIViewController {
    private let questions = [
        "Is the Veteran enrolled in VA health care?",
        "Does the Veteran need personal care services for at least 6 months?",
        "Is the care needed due to a serious injury or illness incurred in the line of duty?",
        "Is the caregiver at least 18 years old?"
    ]
    private var answers: [Bool?] = [nil, nil, nil, nil]
    private var resultLabel: UILabel!
    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "CAFC Eligibility"
        setupUI()
    }

    private func setupUI() {
        stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])

        for (i, q) in questions.enumerated() {
            let qLabel = UILabel()
            qLabel.text = q
            qLabel.font = UIFont.systemFont(ofSize: 18)
            qLabel.numberOfLines = 0
            stack.addArrangedSubview(qLabel)

            let buttonStack = UIStackView()
            buttonStack.axis = .horizontal
            buttonStack.spacing = 16
            buttonStack.distribution = .fillEqually

            let yesButton = UIButton(type: .system)
            yesButton.setTitle("Yes", for: .normal)
            yesButton.tag = i * 2
            yesButton.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
            buttonStack.addArrangedSubview(yesButton)

            let noButton = UIButton(type: .system)
            noButton.setTitle("No", for: .normal)
            noButton.tag = i * 2 + 1
            noButton.addTarget(self, action: #selector(answerTapped(_:)), for: .touchUpInside)
            buttonStack.addArrangedSubview(noButton)

            stack.addArrangedSubview(buttonStack)
        }

        let submitButton = UIButton(type: .system)
        submitButton.setTitle("Check Eligibility", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        submitButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        submitButton.layer.cornerRadius = 12
        submitButton.setTitleColor(.label, for: .normal)
        submitButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        stack.addArrangedSubview(submitButton)

        resultLabel = UILabel()
        resultLabel.font = UIFont.boldSystemFont(ofSize: 20)
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.isHidden = true
        stack.addArrangedSubview(resultLabel)
    }

    @objc private func answerTapped(_ sender: UIButton) {
        let qIndex = sender.tag / 2
        let isYes = sender.tag % 2 == 0
        answers[qIndex] = isYes
        // Optionally update button UI to reflect selection
    }

    @objc private func submitTapped() {
        guard !answers.contains(where: { $0 == nil }) else {
            resultLabel.text = "Please answer all questions."
            resultLabel.textColor = .systemOrange
            resultLabel.isHidden = false
            return
        }
        let eligible = answers.allSatisfy { $0 == true }
        resultLabel.text = eligible ? "You are likely eligible for CAFC." : "You are likely NOT eligible for CAFC."
        resultLabel.textColor = eligible ? .systemGreen : .systemRed
        resultLabel.isHidden = false
    }
}
