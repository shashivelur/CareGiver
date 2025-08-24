import UIKit
import CoreData

// If you get a 'Cannot find GovernmentAidInfoViewController' error, ensure GovernmentAidInfoViewController.swift is in your target's Compile Sources in Xcode.

class FinancialAssistanceViewController: UIViewController {
    
    var currentCaregiver: Caregiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Financial Assistance"
        view.backgroundColor = .systemBackground
        
        // Add back button functionality
        navigationItem.hidesBackButton = false
        
        // Create main content
        setupMainContent()
    }
    
    private func setupMainContent() {
        // Create scroll view for content
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Header section
        let headerLabel = UILabel()
        headerLabel.text = "Financial Assistance Resources"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textColor = .label
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        
        // Description section
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Find financial support options and resources to help with caregiving expenses."
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        // Resource categories stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        
        // Create resource category cards
        let categories = [
            ("Government Programs", "building.columns", "Medicare, Medicaid, VA benefits, and other federal/state assistance programs"),
            ("Insurance Coverage", "shield.checkered", "Understanding insurance benefits, filing claims, and maximizing coverage"),
            ("Grants & Scholarships", "gift", "Non-profit organizations offering financial aid for caregiving expenses"),
            ("Tax Benefits", "percent", "Tax deductions, credits, and benefits available to caregivers"),
            ("Emergency Funds", "exclamationmark.triangle", "Quick financial assistance for urgent caregiving needs"),
            ("Cost Planning", "chart.line.uptrend.xyaxis", "Budgeting tools and cost estimation for long-term care")
        ]
        
        for (title, iconName, description) in categories {
            let cardView = createResourceCard(title: title, iconName: iconName, description: description)
            stackView.addArrangedSubview(cardView)
        }
        
        // Add all elements to content view
        contentView.addSubview(headerLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(stackView)
        
        // Set up constraints
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            // Header constraints
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Description constraints
            descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Stack view constraints
            stackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func createResourceCard(title: String, iconName: String, description: String) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.label.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.isUserInteractionEnabled = true
        
        // Icon
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: iconName)
        iconView.tintColor = .systemBlue
        iconView.contentMode = .scaleAspectFit
        
        // Title label
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        // Description label
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabel
        descLabel.numberOfLines = 0
        
        // Arrow indicator
        let arrowView = UIImageView()
        arrowView.image = UIImage(systemName: "chevron.right")
        arrowView.tintColor = .tertiaryLabel
        arrowView.contentMode = .scaleAspectFit
        
        // Add subviews
        cardView.addSubview(iconView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(descLabel)
        cardView.addSubview(arrowView)
        
        // Set up constraints
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Icon constraints
            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title constraints
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: arrowView.leadingAnchor, constant: -12),
            
            // Description constraints
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            
            // Arrow constraints
            arrowView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            arrowView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            arrowView.widthAnchor.constraint(equalToConstant: 12),
            arrowView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        return cardView
    }
    
    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cardView = gesture.view else { return }

        // Add visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            cardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                cardView.transform = CGAffineTransform.identity
            }
        }

        // Identify which card was tapped by checking the title label
        if let titleLabel = cardView.subviews.compactMap({ $0 as? UILabel }).first,
           titleLabel.text == "Government Programs" {
            let vc = GovernmentAidInfoViewController()
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        // Default: show alert for other cards
        let alert = UIAlertController(title: "Coming Soon", message: "Detailed financial assistance information will be available in a future update.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
