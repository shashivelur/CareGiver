import UIKit
import CoreData
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController {
    
    private var currentCaregiver: Caregiver?
    // Cloud profile cache (preferred source)
    private struct CloudProfile {
        let uid: String
        let username: String?
        let firstName: String?
        let lastName: String?
        let email: String?
        let phoneNumber: String?
        let dateOfBirth: Date?
    }
    private var cloudProfile: CloudProfile?
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var profileImageView: UIImageView!
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCurrentCaregiver()
        setupUI()
        populateUserInfo()
        fetchCloudProfileForActiveUser()
        NotificationCenter.default.addObserver(self, selector: #selector(profilePhotoUpdated), name: NSNotification.Name("ProfilePhotoUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged), name: NSNotification.Name("SessionChanged"), object: nil)
        loadProfileImageFromDefaults()
    }
    
    private func loadCurrentCaregiver() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Could not get app delegate")
            currentCaregiver = nil
            return
        }
        let context = appDelegate.persistentContainer.viewContext

        // Resolve the active session username only
        guard let loggedInUsername = UserDefaults.standard.string(forKey: "LoggedInUsername"), !loggedInUsername.isEmpty else {
            print("No active LoggedInUsername in UserDefaults")
            currentCaregiver = nil
            return
        }

        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", loggedInUsername)
        request.fetchLimit = 1

        do {
            let caregivers = try context.fetch(request)
            currentCaregiver = caregivers.first
            if currentCaregiver == nil {
                print("No caregiver found for active username: \(loggedInUsername)")
            }
        } catch {
            print("Error loading caregiver by username: \(error)")
            currentCaregiver = nil
        }
    }
    
    private func fetchCloudProfileForActiveUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No Firebase Auth user; skipping cloud profile fetch.")
            return
        }
        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Cloud profile fetch failed: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else {
                print("No cloud profile found for uid: \(uid)")
                return
            }
            // Map Firestore fields to our cloud profile model
            let username = data["username"] as? String
            let firstName = data["firstName"] as? String
            let lastName = data["lastName"] as? String
            let email = data["email"] as? String
            let phoneNumber = data["phoneNumber"] as? String
            let dob: Date?
            if let ts = data["dateOfBirth"] as? Timestamp {
                dob = ts.dateValue()
            } else {
                dob = nil
            }
            self.cloudProfile = CloudProfile(uid: uid, username: username, firstName: firstName, lastName: lastName, email: email, phoneNumber: phoneNumber, dateOfBirth: dob)
            DispatchQueue.main.async {
                self.populateUserInfo()
            }
        }
    }
    
    private func setupUI() {
        title = "Profile"
        view.backgroundColor = .systemBackground
        
        // Add back button
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        setupScrollView()
        setupProfileImage()
        setupStackView()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupProfileImage() {
        // Create the profile image view
        profileImageView = UIImageView()
        
        // Configure the image view
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = .systemIndigo
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 60 // Make it circular (half of 120)
        profileImageView.clipsToBounds = true // Clip to circular shape
        profileImageView.translatesAutoresizingMaskIntoConstraints = false // Required for Auto Layout
        
        // Add to the view hierarchy
        contentView.addSubview(profileImageView)
        loadProfileImageFromDefaults()
    }
    
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Profile image constraints
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 120),
            profileImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // StackView constraints
            stackView.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }
    
    private func loadProfileImageFromDefaults() {
        if let username = UserDefaults.standard.string(forKey: "LoggedInUsername"),
           let data = UserDefaults.standard.data(forKey: "CaregiverProfileImageData_\(username)"),
           let image = UIImage(data: data) {
            self.profileImageView.image = image
            self.profileImageView.tintColor = nil
            self.profileImageView.contentMode = .scaleAspectFill
        } else if let data = UserDefaults.standard.data(forKey: "CaregiverProfileImageData"),
                  let image = UIImage(data: data) {
            // Legacy fallback
            self.profileImageView.image = image
            self.profileImageView.tintColor = nil
            self.profileImageView.contentMode = .scaleAspectFill
        } else {
            // Default system placeholder
            self.profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
            self.profileImageView.tintColor = .systemIndigo
            self.profileImageView.contentMode = .scaleAspectFit
        }
    }
    
    private func populateUserInfo() {
        // Clear existing rows
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Prefer cloud profile if available
        if let p = cloudProfile {
            let fullName = "\(p.firstName ?? "") \(p.lastName ?? "")".trimmingCharacters(in: .whitespaces)
            addInfoRow(title: "First Name", value: p.firstName)
            addInfoRow(title: "Last Name", value: p.lastName)
            addInfoRow(title: "Username", value: p.username)
            addInfoRow(title: "Email", value: p.email)
            addInfoRow(title: "Phone Number", value: p.phoneNumber)
            if let dob = p.dateOfBirth {
                let fmt = DateFormatter()
                fmt.dateStyle = .medium
                addInfoRow(title: "Birthday", value: fmt.string(from: dob))
            } else {
                addInfoRow(title: "Birthday", value: "Not set")
            }
            let patientsCount = getPatientsCount()
            addInfoRow(title: "Total Patients", value: "\(patientsCount)")
            return
        }

        // Fallback: use local Core Data for the active user only
        guard let caregiver = currentCaregiver else {
            let noDataRow = createInfoRow(title: "No Data", value: "No caregiver data found for the active user")
            stackView.addArrangedSubview(noDataRow)
            return
        }

        addInfoRow(title: "First Name", value: caregiver.firstName)
        addInfoRow(title: "Last Name", value: caregiver.lastName)
        addInfoRow(title: "Username", value: caregiver.username)
        addInfoRow(title: "Email", value: caregiver.email)
        addInfoRow(title: "Phone Number", value: caregiver.phoneNumber)
        if let birthday = caregiver.dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            addInfoRow(title: "Birthday", value: formatter.string(from: birthday))
        } else {
            addInfoRow(title: "Birthday", value: "Not set")
        }
        let patientsCount = getPatientsCount()
        addInfoRow(title: "Total Patients", value: "\(patientsCount)")
    }
    
    private func addInfoRow(title: String, value: String?) {
        let displayValue = value ?? "Not specified"
        let row = createInfoRow(title: title, value: displayValue)
        stackView.addArrangedSubview(row)
        
        // Add separator except for last item
        let separator = createSeparator()
        stackView.addArrangedSubview(separator)
    }
    
    private func createInfoRow(title: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.textColor = .secondaryLabel
        valueLabel.numberOfLines = 0
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15),
            
            valueLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 15),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 10),
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            valueLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -15)
        ])
        
        return containerView
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return separator
    }
    
    private func getPatientsCount() -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return 0 }
        let context = appDelegate.persistentContainer.viewContext

        // Determine the current caregiver by LoggedInUsername
        if let username = UserDefaults.standard.string(forKey: "LoggedInUsername") {
            let caregiverRequest: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            caregiverRequest.predicate = NSPredicate(format: "username == %@", username)
            caregiverRequest.fetchLimit = 1
            do {
                if let caregiver = try context.fetch(caregiverRequest).first {
                    let request: NSFetchRequest<Patient> = Patient.fetchRequest()
                    request.predicate = NSPredicate(format: "caregiver == %@", caregiver)
                    return try context.fetch(request).count
                }
            } catch {
                print("Error fetching patients count: \(error)")
                return 0
            }
        }
        return 0
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func profilePhotoUpdated() {
        DispatchQueue.main.async { [weak self] in
            self?.loadProfileImageFromDefaults()
        }
    }
    
    @objc private func sessionChanged() {
        loadCurrentCaregiver()
        populateUserInfo()
        fetchCloudProfileForActiveUser()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

