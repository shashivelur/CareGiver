import UIKit
import CoreData

class ProfileViewController: UIViewController {
    
    private var currentCaregiver: Caregiver?
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var profileImageView: UIImageView!
    private var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadCurrentCaregiver()
        setupUI()
        populateUserInfo()
    }
    
    private func loadCurrentCaregiver() {
           guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
               print("Could not get app delegate")
               return
           }
           let context = appDelegate.persistentContainer.viewContext
           
           // Check what's stored in UserDefaults
           let loggedInUsername = UserDefaults.standard.string(forKey: "LoggedInUsername")
           print("Looking for username from UserDefaults: '\(loggedInUsername ?? "nil")'")
           
           // First, try to get the caregiver from UserDefaults if we stored the logged-in user's info
           if let loggedInUsername = loggedInUsername {
               let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
               request.predicate = NSPredicate(format: "username == %@", loggedInUsername)
               request.fetchLimit = 1
               
               do {
                   let caregivers = try context.fetch(request)
                   if let caregiver = caregivers.first {
                       currentCaregiver = caregiver
                       print("Found logged-in caregiver: \(caregiver.username ?? "no username")")
                       print("Caregiver first name: \(caregiver.firstName ?? "nil")")
                       return
                   }
               } catch {
                   print("Error loading caregiver by username: \(error)")
               }
           }
           
           // Debug: Let's see ALL caregivers in the database
           let allRequest: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
           do {
               let allCaregivers = try context.fetch(allRequest)
               print("Total caregivers in database: \(allCaregivers.count)")
               
               for (index, caregiver) in allCaregivers.enumerated() {
                   print("Caregiver \(index + 1): username='\(caregiver.username ?? "nil")', firstName='\(caregiver.firstName ?? "nil")'")
               }
           } catch {
               print("Error fetching all caregivers: \(error)")
           }
           
           // Fallback: get any caregiver
           let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
           request.fetchLimit = 1
           
           do {
               let caregivers = try context.fetch(request)
               if let caregiver = caregivers.first {
                   currentCaregiver = caregiver
                   print("Found caregiver (fallback): \(caregiver.username ?? "no username")")
                   print("Fallback caregiver first name: \(caregiver.firstName ?? "nil")")
               } else {
                   print("No caregivers found at all!")
               }
           } catch {
               print("Error loading caregiver: \(error)")
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
        profileImageView.image = UIImage(named: "ProfilePhoto") // Replace with your image name
        profileImageView.tintColor = nil // Remove tint for custom images
        profileImageView.contentMode = .scaleAspectFill // Better for photos
        profileImageView.layer.cornerRadius = 60 // Make it circular (half of 120)
        profileImageView.clipsToBounds = true // Clip to circular shape
        profileImageView.translatesAutoresizingMaskIntoConstraints = false // Required for Auto Layout
        
        // Add to the view hierarchy
        contentView.addSubview(profileImageView)
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
    
    private func populateUserInfo() {
        // Clear existing rows
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard let caregiver = currentCaregiver else {
            let noDataRow = createInfoRow(title: "No Data", value: "No caregiver data found")
            stackView.addArrangedSubview(noDataRow)
            return
        }
        
        // Debug: Print all the values to see what's actually stored
        print("=== Caregiver Debug Info ===")
        print("First Name: '\(caregiver.firstName ?? "nil")'")
        print("Last Name: '\(caregiver.lastName ?? "nil")'")
        print("Username: '\(caregiver.username ?? "nil")'")
        print("Email: '\(caregiver.email ?? "nil")'")
        print("Phone Number: '\(caregiver.phoneNumber ?? "nil")'")
        print("Birthday: '\(caregiver.dateOfBirth?.description ?? "nil")'")
        print("=============================")
        
        // Add each field as a separate row - Show actual data, not defaults
        addInfoRow(title: "First Name", value: caregiver.firstName)
        addInfoRow(title: "Last Name", value: caregiver.lastName)
        addInfoRow(title: "Username", value: caregiver.username)
        addInfoRow(title: "Email", value: caregiver.email)
        addInfoRow(title: "Phone Number", value: caregiver.phoneNumber)
        
        // Add birthday if it exists
        if let birthday = caregiver.dateOfBirth {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let birthdayString = formatter.string(from: birthday)
            addInfoRow(title: "Birthday", value: birthdayString)
        } else {
            addInfoRow(title: "Birthday", value: "Not set")
        }
        
        // Add total patients count
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
        
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        
        do {
            let patients = try context.fetch(request)
            return patients.count
        } catch {
            print("Error fetching patients count: \(error)")
            return 0
        }
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
