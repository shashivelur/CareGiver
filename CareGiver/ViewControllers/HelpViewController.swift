import UIKit

class HelpViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Help & Support"
        view.backgroundColor = .systemBackground
        
        // Add back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Create help UI
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpCell")
        
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

extension HelpViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4 // Help topics
        case 1: return 3 // Support
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Help Topics"
        case 1: return "Support"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HelpCell", for: indexPath)
        
        switch indexPath.section {
        case 0: // Help topics
            let titles = ["Getting Started", "Managing Patients", "Using Features", "Troubleshooting"]
            let icons = ["play.circle", "person.2", "gear", "wrench"]
            cell.textLabel?.text = titles[indexPath.row]
            cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
        case 1: // Support
            let titles = ["Contact Support", "Send Feedback", "Privacy Policy"]
            let icons = ["phone", "envelope", "doc.text"]
            cell.textLabel?.text = titles[indexPath.row]
            cell.imageView?.image = UIImage(systemName: icons[indexPath.row])
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
            let helpMessages = [
                "Getting Started: Welcome to CareGiver! Register as a caregiver, add patients, and explore features.",
                "Managing Patients: Add patients, view their information, and track their health data.",
                "Using Features: Navigate using the tab bar and hamburger menu to access all features.",
                "Troubleshooting: Contact support if you encounter any issues."
            ]
            message = helpMessages[indexPath.row]
        case 1:
            let supportMessages = [
                "Contact Support: Email us at support@caregiver.com for assistance.",
                "Send Feedback: We'd love to hear from you! Send feedback to improve the app.",
                "Privacy Policy: Your privacy is important to us. Read our privacy policy for details."
            ]
            message = supportMessages[indexPath.row]
        default:
            break
        }
        
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
