import UIKit

class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        // Add back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Create settings UI
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2 // Account settings
        case 1: return 3 // App settings
        case 2: return 2 // Data settings
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Account"
        case 1: return "App Settings"
        case 2: return "Data & Privacy"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        
        switch indexPath.section {
        case 0: // Account
            cell.textLabel?.text = indexPath.row == 0 ? "Change Password" : "Update Profile"
            cell.imageView?.image = UIImage(systemName: indexPath.row == 0 ? "lock" : "person")
        case 1: // App settings
            let titles = ["Notifications", "Theme", "Language"]
            let icons = ["bell", "paintbrush", "globe"]
            cell.textLabel?.text = titles[indexPath.row]
            cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        case 2: // Data
            cell.textLabel?.text = indexPath.row == 0 ? "Export Data" : "Clear Cache"
            cell.imageView?.image = UIImage(systemName: indexPath.row == 0 ? "square.and.arrow.up" : "trash")
        default:
            break
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .systemBlue
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var message = ""
        switch indexPath.section {
        case 0:
            message = indexPath.row == 0 ? "Change Password feature coming soon!" : "Update Profile feature coming soon!"
        case 1:
            let features = ["Notification settings coming soon!", "Theme settings coming soon!", "Language settings coming soon!"]
            message = features[indexPath.row]
        case 2:
            message = indexPath.row == 0 ? "Export Data feature coming soon!" : "Clear Cache feature coming soon!"
        default:
            break
        }
        
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
