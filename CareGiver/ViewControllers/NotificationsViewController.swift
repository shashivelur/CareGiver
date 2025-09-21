import UIKit
import UserNotifications

// Model for displaying notifications in the UI
struct AppNotification {
    let title: String
    let body: String
    let date: Date
}

class NotificationsViewController: UIViewController {

    private var notifications: [AppNotification] = []
    private var filteredNotifications: [AppNotification] = []
    private let tableView = UITableView()
    private let searchBar = UISearchBar()
    private let settingsButton = UIButton(type: .system)
    private var notificationDuration: Int = 10 // Default 10 minutes

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        // Load saved notification duration
        loadNotificationDuration()
        
        // Observe for notifications sent within the app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppNotification(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification, // placeholder for your in-app notifications
            object: nil
        )
        
        // Also observe local notifications if needed
        UNUserNotificationCenter.current().delegate = self
    }

    private func setupUI() {
        title = "Notifications"
        view.backgroundColor = .systemBackground

        // Back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Settings button with three dots
        settingsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        settingsButton.showsMenuAsPrimaryAction = true
        settingsButton.menu = createSettingsMenu()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: settingsButton)
        
        // Search bar
        searchBar.placeholder = "Search notifications..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleAppNotification(_ notification: Notification) {
        // Example: you could post notifications like this from anywhere in your app
        // NotificationCenter.default.post(name: .appNotificationReceived, object: nil, userInfo: ["title": "Task", "body": "You have a new task"])
        if let info = notification.userInfo,
           let title = info["title"] as? String,
           let body = info["body"] as? String {
            let newNotification = AppNotification(title: title, body: body, date: Date())
            notifications.insert(newNotification, at: 0) // newest first
            updateFilteredNotifications()
            tableView.reloadData()
        }
    }
    
    private func createSettingsMenu() -> UIMenu {
        let durationAction = UIAction(title: "Notification Duration") { _ in
            self.showDurationSettings()
        }
        
        let clearAction = UIAction(title: "Clear All", attributes: .destructive) { _ in
            self.clearAllNotifications()
        }
        
        return UIMenu(title: "", children: [durationAction, clearAction])
    }
    
    private func showDurationSettings() {
        let alert = UIAlertController(title: "Notification Duration", message: "Set how many minutes before a task you want to be notified", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Minutes before task"
            textField.text = "\(self.notificationDuration)"
            textField.keyboardType = .numberPad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text,
               let duration = Int(text) {
                self.notificationDuration = duration
                UserDefaults.standard.set(duration, forKey: "notification_duration")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func clearAllNotifications() {
        notifications.removeAll()
        updateFilteredNotifications()
        tableView.reloadData()
    }
    
    private func updateFilteredNotifications() {
        if searchBar.text?.isEmpty == false {
            let searchText = searchBar.text!.lowercased()
            filteredNotifications = notifications.filter { notification in
                notification.title.lowercased().contains(searchText) ||
                notification.body.lowercased().contains(searchText)
            }
        } else {
            filteredNotifications = notifications
        }
    }
    
    private func loadNotificationDuration() {
        notificationDuration = UserDefaults.standard.object(forKey: "notification_duration") as? Int ?? 10
    }
}

// MARK: - UITableViewDataSource
extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredNotifications.isEmpty ? 1 : filteredNotifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if filteredNotifications.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text = notifications.isEmpty ? "No notifications at this time." : "No notifications match your search."
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemGray
            cell.selectionStyle = .none
            return cell
        } else {
            let notif = filteredNotifications[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath)
            cell.textLabel?.numberOfLines = 0
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            cell.textLabel?.text = "[\(dateFormatter.string(from: notif.date))] \(notif.title): \(notif.body)"
            cell.selectionStyle = .none
            return cell
        }
    }
}

// MARK: - UISearchBarDelegate
extension NotificationsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilteredNotifications()
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationsViewController: UNUserNotificationCenterDelegate {
    // This will capture local notifications while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let newNotification = AppNotification(title: content.title, body: content.body, date: Date())
        notifications.insert(newNotification, at: 0)
        updateFilteredNotifications()
        tableView.reloadData()
        
        // Show banner even in foreground
        completionHandler([.banner, .sound])
    }
}
