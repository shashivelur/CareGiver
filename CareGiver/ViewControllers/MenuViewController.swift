import UIKit
import SideMenu
import CoreData

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
    
    var currentCaregiver: Caregiver?
    
    private let tableView = UITableView()
    private let headerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentCaregiver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeaderInfo()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupHeaderView()
        setupTableView()
        setupConstraints()
        updateHeaderInfo()
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemBlue
        
        profileImageView.image = UIImage(systemName: "person.circle.fill")
        profileImageView.tintColor = .white
        profileImageView.contentMode = .scaleAspectFit
        
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.text = "Caregiver's Name"
        nameLabel.numberOfLines = 1
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.8
        
        emailLabel.textColor = .white.withAlphaComponent(0.9)
        emailLabel.font = UIFont.systemFont(ofSize: 14)
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
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            profileImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            nameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateHeaderInfo() {
        guard let caregiver = currentCaregiver else {
            nameLabel.text = "Caregiver"
            emailLabel.text = "No email"
            return
        }
        
        let firstName = caregiver.firstName ?? ""
        let lastName = caregiver.lastName ?? ""
        nameLabel.text = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        emailLabel.text = caregiver.email ?? "No email"
    }
    
    private func loadCurrentCaregiver() {
        if currentCaregiver != nil { return }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let caregivers = try context.fetch(request)
            currentCaregiver = caregivers.first
            updateHeaderInfo()
        } catch {
            print("Error loading caregiver: \(error)")
        }
    }
    
    // This function MUST be inside the class
    private func navigateToViewController(for menuItem: MenuItem) {
        print("Attempting to navigate to: \(menuItem.title)")
        
        // Post notification and dismiss
        NotificationCenter.default.post(name: NSNotification.Name("MenuItemSelected"), object: menuItem)
        print("Notification posted")
        
        // Try to dismiss the side menu
        if let sideMenuController = self.navigationController as? SideMenuNavigationController {
            print("Dismissing side menu")
            sideMenuController.dismiss(animated: true) {
                print("Side menu dismissed")
            }
        } else {
            print("Not a side menu controller, using regular dismiss")
            dismiss(animated: true) {
                print("Regular dismiss completed")
            }
        }
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
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.imageView?.image = UIImage(systemName: menuItem.icon)
        cell.imageView?.tintColor = .systemBlue
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = .systemBackground
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let menuItem = MenuItem.allCases[indexPath.row]
        print("Menu item selected: \(menuItem.title)")
        navigateToViewController(for: menuItem)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
