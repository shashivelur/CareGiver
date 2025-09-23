import UIKit
import CoreData
import CryptoKit
import PhotosUI

class SettingsViewController: UIViewController {
    
    private var tableView: UITableView!
    private let darkModeDefaultsKey = "AppDarkModeEnabled"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Only apply an override if the user has explicitly set a preference; otherwise, follow system
        if UserDefaults.standard.object(forKey: darkModeDefaultsKey) != nil {
            applyAppAppearance(dark: UserDefaults.standard.bool(forKey: darkModeDefaultsKey))
        }
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
        tableView = UITableView(frame: .zero, style: .grouped)
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
    
    private func presentPhotoPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func saveProfileImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.9) {
            UserDefaults.standard.set(data, forKey: "CaregiverProfileImageData")
            NotificationCenter.default.post(name: NSNotification.Name("ProfilePhotoUpdated"), object: nil)
        }
    }
    
    private func applyAppAppearance(dark: Bool) {
        let style: UIUserInterfaceStyle = dark ? .dark : .light
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }

    @objc private func darkModeSwitchChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: darkModeDefaultsKey)
        applyAppAppearance(dark: sender.isOn)
    }
    
    private func presentPatientDeletionFlow() {
        let patients = fetchPatientsForDeletion()
        guard !patients.isEmpty else {
            let alert = UIAlertController(title: "Delete Patient", message: "No patients found to delete.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let pickerVC = PatientSelectionViewController(patients: patients)
        pickerVC.modalPresentationStyle = .pageSheet
        pickerVC.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        pickerVC.onDelete = { [weak self] patient in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                self.presentFinalDeletionConfirmation(for: patient)
            }
        }
        present(pickerVC, animated: true)
    }

    private func presentFinalDeletionConfirmation(for patient: Patient) {
        let alert = UIAlertController(title: "Are you sure?", message: "Are you sure that you want to delete this patient?", preferredStyle: .alert)
        alert.view.tintColor = .systemIndigo

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deletePatient(patient)
        }

        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true)
    }

    private func fetchPatientsForDeletion() -> [Patient] {
        // Prefer caregiver's patients if available; otherwise, fetch all
        if let caregiver = getCurrentCaregiver(), let set = caregiver.patients as? Set<Patient>, !set.isEmpty {
            return set.sorted { (a, b) in
                (a.firstName ?? "") < (b.firstName ?? "")
            }
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        do { return try context.fetch(request) } catch { return [] }
    }

    private func deletePatient(_ patient: Patient) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        context.delete(patient)
        do {
            try context.save()
            // Notify other screens to refresh
            NotificationCenter.default.post(name: NSNotification.Name("PatientCreated"), object: nil)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Failed to delete patient: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func presentPatientEditFlow() {
        let patients = fetchPatientsForDeletion()
        guard !patients.isEmpty else {
            let alert = UIAlertController(title: "Edit Patient", message: "No patients found to edit.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let pickerVC = EditPatientSelectionViewController(patients: patients)
        pickerVC.modalPresentationStyle = .pageSheet
        pickerVC.onCancel = { [weak self] in
            self?.dismiss(animated: true)
        }
        pickerVC.onNext = { [weak self] patient in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                let editor = EditPatientViewController(patient: patient)
                self.navigationController?.pushViewController(editor, animated: true)
            }
        }
        present(pickerVC, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3 // Account Settings: Change Password, Change Username, Edit Profile Photo
        case 1: return 2 // Patient Settings: Edit Patient, Delete Patient
        case 2: return 1 // App Settings: Dark Mode
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Account Settings"
        case 1: return "Patient Settings"
        case 2: return "App Settings"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Change Password"
                cell.imageView?.image = UIImage(systemName: "lock")
            case 1:
                cell.textLabel?.text = "Change Username"
                cell.imageView?.image = UIImage(systemName: "person.badge.key")
            case 2:
                cell.textLabel?.text = "Edit Profile Photo"
                cell.imageView?.image = UIImage(systemName: "photo")
            default:
                break
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Edit Patient"
                cell.imageView?.image = UIImage(systemName: "square.and.pencil")
            case 1:
                cell.textLabel?.text = "Delete Patient"
                cell.imageView?.image = UIImage(systemName: "trash")
            default:
                break
            }
        } else if indexPath.section == 2 {
            cell.textLabel?.text = "Dark Mode"
            cell.imageView?.image = nil
            let toggle = UISwitch()
            let defaults = UserDefaults.standard
            if defaults.object(forKey: darkModeDefaultsKey) != nil {
                toggle.isOn = defaults.bool(forKey: darkModeDefaultsKey)
            } else {
                // No saved preference yet — reflect current system appearance
                toggle.isOn = (traitCollection.userInterfaceStyle == .dark)
            }
            toggle.onTintColor = .systemIndigo
            toggle.addTarget(self, action: #selector(darkModeSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        }
        
        if indexPath.section == 2 {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        
        cell.imageView?.tintColor = .systemIndigo
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 { return }
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                showChangePasswordAlert()
            case 1:
                showChangeUsernameAlert()
            case 2:
                self.presentPhotoPicker()
            default:
                break
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                self.presentPatientEditFlow()
            case 1:
                self.presentPatientDeletionFlow()
            default:
                break
            }
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

extension SettingsViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self = self, let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self.saveProfileImage(image)
            }
        }
    }
}

final class PatientSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let patients: [Patient]
    var onCancel: (() -> Void)?
    var onDelete: ((Patient) -> Void)?

    private let tableView = UITableView()
    private let cancelButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private var selectedIndex: IndexPath? { didSet { updateButtons() } }

    init(patients: [Patient]) {
        self.patients = patients
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Delete Patient"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PatientCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemIndigo, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        deleteButton.isEnabled = false

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, deleteButton])
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let vStack = UIStackView(arrangedSubviews: [tableView, buttonStack])
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            vStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }

    private func updateButtons() {
        deleteButton.isEnabled = (selectedIndex != nil)
        deleteButton.alpha = deleteButton.isEnabled ? 1.0 : 0.5
    }

    @objc private func cancelTapped() { onCancel?() }

    @objc private func deleteTapped() {
        guard let idx = selectedIndex else { return }
        onDelete?(patients[idx.row])
    }

    // MARK: - Table DataSource/Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { patients.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PatientCell", for: indexPath)
        let p = patients[indexPath.row]
        let first = p.firstName ?? ""
        let last = p.lastName ?? ""
        cell.textLabel?.text = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        cell.accessoryType = (indexPath == selectedIndex) ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedIndex == indexPath { selectedIndex = nil } else { selectedIndex = indexPath }
        tableView.visibleCells.enumerated().forEach { (offset, cell) in
            let ip = IndexPath(row: offset, section: 0)
            cell.accessoryType = (ip == selectedIndex) ? .checkmark : .none
        }
    }
}

final class EditPatientSelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let patients: [Patient]
    var onCancel: (() -> Void)?
    var onNext: ((Patient) -> Void)?

    private let tableView = UITableView()
    private let cancelButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private var selectedIndex: IndexPath? { didSet { updateButtons() } }

    init(patients: [Patient]) {
        self.patients = patients
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Edit Patient"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EditPatientCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.systemIndigo, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        nextButton.setTitle("Next", for: .normal)
        nextButton.setTitleColor(.systemIndigo, for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        nextButton.isEnabled = false

        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, nextButton])
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let vStack = UIStackView(arrangedSubviews: [tableView, buttonStack])
        vStack.axis = .vertical
        vStack.spacing = 12
        vStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStack)

        NSLayoutConstraint.activate([
            vStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            vStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            vStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            vStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            tableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }

    private func updateButtons() {
        nextButton.isEnabled = (selectedIndex != nil)
        nextButton.alpha = nextButton.isEnabled ? 1.0 : 0.5
    }

    @objc private func cancelTapped() { onCancel?() }
    @objc private func nextTapped() {
        guard let idx = selectedIndex else { return }
        onNext?(patients[idx.row])
    }

    // MARK: - Table DataSource/Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { patients.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditPatientCell", for: indexPath)
        let p = patients[indexPath.row]
        let first = p.firstName ?? ""
        let last = p.lastName ?? ""
        cell.textLabel?.text = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        cell.accessoryType = (indexPath == selectedIndex) ? .checkmark : .none
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedIndex == indexPath { selectedIndex = nil } else { selectedIndex = indexPath }
        tableView.visibleCells.enumerated().forEach { (offset, cell) in
            let ip = IndexPath(row: offset, section: 0)
            cell.accessoryType = (ip == selectedIndex) ? .checkmark : .none
        }
    }
}

final class EditPatientViewController: UIViewController {
    private let patient: Patient

    // UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let firstNameField = UITextField()
    private let lastNameField = UITextField()
    private let emailField = UITextField()
    private let phoneField = UITextField()
    private let dobPicker = UIDatePicker()
    private let veteranSwitch = UISwitch()
    private let incomeButton = UIButton(type: .system)

    private let incomeOptions = ["$100,000 or less", "$100,000 to $200,000", "$200,000 to $300,000", "$300,000 and above"]
    private var selectedIncome: String = ""

    init(patient: Patient) {
        self.patient = patient
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Patient"
        view.backgroundColor = .systemBackground

        setupNavBar()
        setupScroll()
        setupForm()
        populateFields()
        setupKeyboardHandling()
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
    }

    private func setupScroll() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupForm() {
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])

        // Configure fields
        configure(textField: firstNameField, placeholder: "First Name")
        configure(textField: lastNameField, placeholder: "Last Name")
        configure(textField: emailField, placeholder: "Email", keyboard: .emailAddress)
        configure(textField: phoneField, placeholder: "Phone Number", keyboard: .phonePad)

        dobPicker.datePickerMode = .date
        dobPicker.preferredDatePickerStyle = .compact
        dobPicker.maximumDate = Date()

        incomeButton.setTitle("Select Income Range", for: .normal)
        incomeButton.contentHorizontalAlignment = .left
        incomeButton.backgroundColor = .secondarySystemBackground
        incomeButton.layer.cornerRadius = 8
        incomeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        incomeButton.tintColor = .systemIndigo
        incomeButton.addTarget(self, action: #selector(incomeTapped), for: .touchUpInside)

        // Build sections
        stackView.addArrangedSubview(formSection(title: "First Name", content: firstNameField))
        stackView.addArrangedSubview(formSection(title: "Last Name", content: lastNameField))
        stackView.addArrangedSubview(formSection(title: "Email", content: emailField))
        stackView.addArrangedSubview(formSection(title: "Phone Number", content: phoneField))
        stackView.addArrangedSubview(formSection(title: "Date of Birth", content: dobPicker))

        let veteranRow = UIStackView()
        veteranRow.axis = .horizontal
        veteranRow.alignment = .center
        veteranRow.spacing = 12
        let veteranLabel = UILabel()
        veteranLabel.text = "Veteran"
        veteranLabel.font = .systemFont(ofSize: 16)
        veteranRow.addArrangedSubview(veteranLabel)
        veteranRow.addArrangedSubview(veteranSwitch)
        stackView.addArrangedSubview(formSection(title: "Veteran Status", content: veteranRow))

        stackView.addArrangedSubview(formSection(title: "Family Income Range", content: incomeButton))

        // tap to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func configure(textField: UITextField, placeholder: String, keyboard: UIKeyboardType = .default) {
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        textField.keyboardType = keyboard
        textField.autocapitalizationType = .words
    }

    private func formSection(title: String, content: UIView) -> UIView {
        let container = UIView()
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        content.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(content)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            content.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func populateFields() {
        firstNameField.text = patient.firstName
        lastNameField.text = patient.lastName
        emailField.text = patient.email
        phoneField.text = patient.phoneNumber
        if let dob = patient.dateOfBirth { dobPicker.date = dob }
        veteranSwitch.isOn = patient.veteranStatus
        selectedIncome = patient.incomeRange ?? ""
        if selectedIncome.isEmpty {
            incomeButton.setTitle("Select Income Range", for: .normal)
        } else {
            incomeButton.setTitle(selectedIncome, for: .normal)
        }
    }

    // MARK: - Actions
    @objc private func saveTapped() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        patient.firstName = firstNameField.text
        patient.lastName = lastNameField.text
        patient.email = emailField.text
        patient.phoneNumber = phoneField.text
        patient.dateOfBirth = dobPicker.date
        patient.veteranStatus = veteranSwitch.isOn
        patient.incomeRange = selectedIncome

        do {
            try context.save()
            NotificationCenter.default.post(name: NSNotification.Name("PatientCreated"), object: nil)
            navigationController?.popViewController(animated: true)
        } catch {
            let alert = UIAlertController(title: "Error", message: "Failed to save changes: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    @objc private func incomeTapped() {
        let alert = UIAlertController(title: "Select Income Range", message: nil, preferredStyle: .actionSheet)
        for option in incomeOptions {
            alert.addAction(UIAlertAction(title: option, style: .default, handler: { [weak self] _ in
                self?.selectedIncome = option
                self?.incomeButton.setTitle(option, for: .normal)
            }))
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = alert.popoverPresentationController {
            pop.sourceView = incomeButton
            pop.sourceRect = incomeButton.bounds
        }
        present(alert, animated: true)
    }

    @objc private func endEditing() { view.endEditing(true) }

    // MARK: - Keyboard handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kbChange(_ note: Notification) {
        guard let userInfo = note.userInfo,
              let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let kbFrame = view.convert(endFrame, from: nil)
        let bottomInset = max(0, view.bounds.maxY - kbFrame.origin.y - view.safeAreaInsets.bottom)
        scrollView.contentInset.bottom = bottomInset + 12
        scrollView.scrollIndicatorInsets.bottom = bottomInset + 12
    }

    @objc private func kbHide(_ note: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
}

