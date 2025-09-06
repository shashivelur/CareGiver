import UIKit
import CoreData

class ProfileViewController: UIViewController {
    
    var currentCaregiver: Caregiver?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Profile"
        view.backgroundColor = .systemBackground
        
        // Add back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Create profile UI
        let scrollView = UIScrollView()
        let contentView = UIView()
        
        // Profile image
        let profileImageView = UIImageView()
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .systemBlue
        profileImageView.contentMode = .scaleAspectFit
        
        // Info labels
        let nameLabel = createInfoLabel(title: "Name:", value: currentCaregiver?.firstName ?? "N/A")
        let emailLabel = createInfoLabel(title: "Email:", value: currentCaregiver?.email ?? "N/A")
        let phoneLabel = createInfoLabel(title: "Phone:", value: currentCaregiver?.phoneNumber ?? "N/A")
        let usernameLabel = createInfoLabel(title: "Username:", value: currentCaregiver?.username ?? "N/A")
        
        // Patients count
        let patientsCount = currentCaregiver != nil ? CoreDataManager.shared.fetchPatients(for: currentCaregiver!).count : 0
        let patientsLabel = createInfoLabel(title: "Patients:", value: "\(patientsCount)")
        
        // Stack view for info
        let stackView = UIStackView(arrangedSubviews: [nameLabel, emailLabel, phoneLabel, usernameLabel, patientsLabel])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        
        // Add to content view
        contentView.addSubview(profileImageView)
        contentView.addSubview(stackView)
        
        // Add to scroll view
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        
        // Setup constraints
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            stackView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 30),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func createInfoLabel(title: String, value: String) -> UIView {
        let containerView = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .systemGray
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.textColor = .label
        valueLabel.numberOfLines = 0
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            
            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
