import UIKit
import FirebaseAuth
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(profilePhotoUpdated), name: NSNotification.Name("ProfilePhotoUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged), name: NSNotification.Name("SessionChanged"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentCaregiver()
        loadProfileImageFromDefaults()
        updateHeaderInfo()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        setupHeaderView()
        setupTableView()
        setupConstraints()
        setupLogoutFooter()
        updateHeaderInfo()
    }
    
    private func setupHeaderView() {
        headerView.backgroundColor = .systemIndigo
        
        // Updated profile image configuration
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = .systemIndigo
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 30 // Make it circular (half of width/height)
        profileImageView.clipsToBounds = true // Clip to circular shape
        
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
        
        loadProfileImageFromDefaults()
        
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
    
    private func setupLogoutFooter() {
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Log Out", for: .normal)
        logoutButton.setTitleColor(.systemIndigo, for: .normal)
        logoutButton.backgroundColor = .clear
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        if let username = UserDefaults.standard.string(forKey: "LoggedInUsername") {
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", username)
            request.fetchLimit = 1
            do {
                currentCaregiver = try context.fetch(request).first
            } catch {
                print("Error loading caregiver by username: \(error)")
                currentCaregiver = nil
            }
        } else {
            // Fallback: first caregiver if no session
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.fetchLimit = 1
            do { currentCaregiver = try context.fetch(request).first } catch { currentCaregiver = nil }
        }
        updateHeaderInfo()
    }
    
    private func loadProfileImageFromDefaults() {
        if let username = UserDefaults.standard.string(forKey: "LoggedInUsername"),
           let data = UserDefaults.standard.data(forKey: "CaregiverProfileImageData_\(username)"),
           let image = UIImage(data: data) {
            self.profileImageView.image = image
            self.profileImageView.tintColor = nil
            self.profileImageView.contentMode = .scaleAspectFill
            self.profileImageView.clipsToBounds = true
        } else if let data = UserDefaults.standard.data(forKey: "CaregiverProfileImageData"),
                  let image = UIImage(data: data) {
            // Legacy fallback
            self.profileImageView.image = image
            self.profileImageView.tintColor = nil
            self.profileImageView.contentMode = .scaleAspectFill
            self.profileImageView.clipsToBounds = true
        } else {
            // Default placeholder that is visible on indigo background
            self.profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            self.profileImageView.tintColor = .white
            self.profileImageView.contentMode = .scaleAspectFit
            self.profileImageView.clipsToBounds = true
        }
    }
    
    @objc private func profilePhotoUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.loadProfileImageFromDefaults()
        }
    }
    
    @objc private func sessionChanged() {
        loadCurrentCaregiver()
        loadProfileImageFromDefaults()
        updateHeaderInfo()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    @objc private func logoutTapped() {
        // Clear logged-in session
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "LoggedInUsername")
        defaults.synchronize()
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        NotificationCenter.default.post(name: NSNotification.Name("SessionChanged"), object: nil)

        // Dismiss the side menu first, then reset to login
        if let sideMenuController = self.navigationController as? SideMenuNavigationController {
            sideMenuController.dismiss(animated: true) { [weak self] in
                self?.resetToLoginRoot()
            }
        } else {
            dismiss(animated: true) { [weak self] in
                self?.resetToLoginRoot()
            }
        }
    }

    private func resetToLoginRoot() {
        // Reset app root to the initial view controller (Login)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let initial = storyboard.instantiateInitialViewController()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        window.rootViewController = initial
        window.makeKeyAndVisible()
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
        cell.imageView?.tintColor = .systemIndigo
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
