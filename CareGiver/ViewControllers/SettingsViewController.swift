import UIKit
import CoreData
import CryptoKit

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
        navigationController?.navigationBar.tintColor = .systemIndigo
        
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
    
    // Add the sha256 function for password hashing
    private func sha256(for string: String) -> String? {
        guard let inputData = string.data(using: .utf8) else {
            print("Error: Could not convert string to Data.")
            return nil
        }
        
        let digest = SHA256.hash(data: inputData)
        let hexString = digest.compactMap { String(format: "%02x", $0) }.joined()
        return hexString
    }
    
    // Get current caregiver from Core Data
    private func getCurrentCaregiver() -> Caregiver? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext
        
        // Get the logged-in username from UserDefaults
        if let loggedInUsername = UserDefaults.standard.string(forKey: "LoggedInUsername") {
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", loggedInUsername)
            request.fetchLimit = 1
            
            do {
                let caregivers = try context.fetch(request)
                return caregivers.first
            } catch {
                print("Error loading caregiver: \(error)")
            }
        }
        
        return nil
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2 // Change Password and Change Username
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Account Settings"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Change Password"
            cell.imageView?.image = UIImage(systemName: "lock")
        case 1:
            cell.textLabel?.text = "Change Username"
            cell.imageView?.image = UIImage(systemName: "person.badge.key")
        default:
            break
        }
        
        cell.accessoryType = .disclosureIndicator
        cell.imageView?.tintColor = .systemIndigo
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            showChangePasswordAlert()
        case 1:
            showChangeUsernameAlert()
        default:
            break
        }
    }
    
    private func showChangePasswordAlert() {
        let alert = UIAlertController(title: "Change Password", message: "Enter your new password", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Current Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "New Password"
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Confirm New Password"
            textField.isSecureTextEntry = true
        }
        
        let changeAction = UIAlertAction(title: "Change", style: .default) { _ in
            guard let currentPassword = alert.textFields?[0].text, !currentPassword.isEmpty,
                  let newPassword = alert.textFields?[1].text, !newPassword.isEmpty,
                  let confirmPassword = alert.textFields?[2].text, !confirmPassword.isEmpty else {
                self.showAlert(message: "Please fill in all fields")
                return
            }
            
            if newPassword != confirmPassword {
                self.showAlert(message: "New passwords don't match")
                return
            }
            
            // Validate current password and change to new password
            self.changePassword(currentPassword: currentPassword, newPassword: newPassword)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(changeAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func changePassword(currentPassword: String, newPassword: String) {
        guard let caregiver = getCurrentCaregiver() else {
            showAlert(message: "Could not find your account")
            return
        }
        
        // Hash the current password to verify it matches
        guard let hashedCurrentPassword = sha256(for: currentPassword) else {
            showAlert(message: "Error processing current password")
            return
        }
        
        // Verify current password is correct
        if caregiver.password != hashedCurrentPassword {
            showAlert(message: "Current password is incorrect")
            return
        }
        
        // Hash the new password
        guard let hashedNewPassword = sha256(for: newPassword) else {
            showAlert(message: "Error processing new password")
            return
        }
        
        // Update password in Core Data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            showAlert(message: "Could not access database")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        caregiver.password = hashedNewPassword
        
        do {
            try context.save()
            showAlert(message: "Password changed successfully!")
            print("Password updated for user: \(caregiver.username ?? "unknown")")
        } catch {
            showAlert(message: "Failed to save password change: \(error.localizedDescription)")
            print("Error saving password change: \(error)")
        }
    }
    
    private func showChangeUsernameAlert() {
        let alert = UIAlertController(title: "Change Username", message: "Enter your new username", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "New Username"
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        let changeAction = UIAlertAction(title: "Change", style: .default) { _ in
            guard let newUsername = alert.textFields?[0].text, !newUsername.isEmpty else {
                self.showAlert(message: "Please enter a new username")
                return
            }
            
            // Change the username
            self.changeUsername(newUsername: newUsername)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(changeAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func changeUsername(newUsername: String) {
        guard let caregiver = getCurrentCaregiver() else {
            showAlert(message: "Could not find your account")
            return
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            showAlert(message: "Could not access database")
            return
        }
        
        let context = appDelegate.persistentContainer.viewContext
        
        // Check if username already exists
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", newUsername)
        
        do {
            let existingCaregivers = try context.fetch(request)
            if !existingCaregivers.isEmpty {
                showAlert(message: "Username '\(newUsername)' is already taken")
                return
            }
        } catch {
            showAlert(message: "Error checking username availability: \(error.localizedDescription)")
            return
        }
        
        // Update username in Core Data
        let oldUsername = caregiver.username
        caregiver.username = newUsername
        
        do {
            try context.save()
            
            // Update UserDefaults with new username
            UserDefaults.standard.set(newUsername, forKey: "LoggedInUsername")
            UserDefaults.standard.synchronize()
            
            showAlert(message: "Username changed successfully!")
            print("Username updated from '\(oldUsername ?? "unknown")' to '\(newUsername)'")
        } catch {
            showAlert(message: "Failed to save username change: \(error.localizedDescription)")
            print("Error saving username change: \(error)")
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Settings", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
