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
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
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
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NotificationCell")
        view.addSubview(tableView)

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

    @objc private func handleAppNotification(_ notification: Notification) {
        // Example: you could post notifications like this from anywhere in your app
        // NotificationCenter.default.post(name: .appNotificationReceived, object: nil, userInfo: ["title": "Task", "body": "You have a new task"])
        if let info = notification.userInfo,
           let title = info["title"] as? String,
           let body = info["body"] as? String {
            let newNotification = AppNotification(title: title, body: body, date: Date())
            notifications.insert(newNotification, at: 0) // newest first
            tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        notifications.isEmpty ? 1 : notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if notifications.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text = "No notifications at this time."
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemGray
            cell.selectionStyle = .none
            return cell
        } else {
            let notif = notifications[indexPath.row]
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

// MARK: - UNUserNotificationCenterDelegate
extension NotificationsViewController: UNUserNotificationCenterDelegate {
    // This will capture local notifications while the app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let newNotification = AppNotification(title: content.title, body: content.body, date: Date())
        notifications.insert(newNotification, at: 0)
        tableView.reloadData()
        
        // Show banner even in foreground
        completionHandler([.banner, .sound])
    }
}
