import UIKit
import CoreData

protocol MenuViewControllerDelegate: AnyObject {
    func menuViewController(_ menuViewController: MenuViewController, didSelectMenuItem item: MenuViewController.MenuItem)
}

class MenuViewController: UIViewController {
    
    enum MenuItem: CaseIterable {
        case profile
        case settings
        case notifications
        case reports
        case financialAssistance
        case help
        
        var title: String {
            switch self {
            case .profile: return "Profile"
            case .settings: return "Settings"
            case .notifications: return "Notifications"
            case .reports: return "Reports"
            case .financialAssistance: return "Financial Assistance"
            case .help: return "Help & Support"
            }
        }
        
        var icon: String {
            switch self {
            case .profile: return "person.circle"
            case .settings: return "gear"
            case .notifications: return "bell"
            case .reports: return "chart.bar"
            case .financialAssistance: return "dollarsign.circle"
            case .help: return "questionmark.circle"
            }
        }
    }
    
    weak var delegate: MenuViewControllerDelegate?
    var currentCaregiver: Caregiver?
    
    private let tableView = UITableView()
    private let headerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup header view
        setupHeaderView()
        
        // Setup table view
        setupTableView()
        
        // Layout
        setupConstraints()
        
        // Update header with caregiver info
        updateHeaderInfo()
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemBlue
        
        // Profile image - smaller size
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .white
        profileImageView.contentMode = .scaleAspectFit
        
        // Name label - smaller font
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameLabel.text = "Caregiver Name"
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        // Email label - smaller font
        emailLabel.textColor = .white
        emailLabel.font = UIFont.systemFont(ofSize: 12)
        emailLabel.text = "caregiver@email.com"
        emailLabel.numberOfLines = 1
        emailLabel.adjustsFontSizeToFitWidth = true
        emailLabel.minimumScaleFactor = 0.7
        
        headerView.addSubview(profileImageView)
        headerView.addSubview(nameLabel)
        headerView.addSubview(emailLabel)
        
        view.addSubview(headerView)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Header view - smaller height and better positioning
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Profile image - smaller size
            profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
            profileImageView.widthAnchor.constraint(equalToConstant: 45),
            profileImageView.heightAnchor.constraint(equalToConstant: 45),
            
            // Name label - better positioning
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
            
            // Email label - closer to name
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            // Table view
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateHeaderInfo() {
        guard let caregiver = currentCaregiver else { return }
        
        nameLabel.text = caregiver.fullName
        emailLabel.text = caregiver.email ?? "No email"
    }
}

// MARK: - UITableViewDataSource
extension MenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuItem.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let menuItem = MenuItem.allCases[indexPath.row]
        
        cell.textLabel?.text = menuItem.title
        cell.imageView?.image = UIImage(systemName: menuItem.icon)
        cell.imageView?.tintColor = .systemBlue
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let menuItem = MenuItem.allCases[indexPath.row]
        delegate?.menuViewController(self, didSelectMenuItem: menuItem)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
}
