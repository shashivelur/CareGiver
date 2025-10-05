import UIKit
import SideMenu
import CoreData
import MapKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var defaultMessageLabel: UILabel!
    private var upcomingTasksLabel: UILabel!
    private var tasksStackView: UIStackView!
    private var mapView: MKMapView!
    private var addPatientButton: UIButton!
    private var patientTabsScrollView: UIScrollView!
    private var patientTabsStackView: UIStackView!
    private var selectedPatientIndex = 0
    private var patients: [Patient] = []
    private var defaultViewHeightConstraint: NSLayoutConstraint?
    private var isLoadingPatients = false
    private var patientsListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Home"
        setupAddPatientButton()
        setupScrollView()
        loadPatients()
        checkPatientStatus()
        
        
        // Listen for patient creation notifications
        NotificationCenter.default.addObserver(self, selector: #selector(patientCreated), name: NSNotification.Name("PatientCreated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionChanged), name: NSNotification.Name("SessionChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(patientCreated), name: NSNotification.Name("PatientUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(patientCreated), name: NSNotification.Name("PatientDeleted"), object: nil)
    }
    
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let h = handle {
            Auth.auth().removeStateDidChangeListener(h)
            handle = nil
        }
        patientsListener?.remove()
        patientsListener = nil
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPatients()
        checkPatientStatus()
        handle = Auth.auth().addStateDidChangeListener { auth, user in
            self.startPatientsListener()
        }
        if Auth.auth().currentUser != nil { startPatientsListener() }
    }
    

    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func patientCreated() {
        DispatchQueue.main.async {
            self.loadPatients()
            self.checkPatientStatus()
        }
    }
    
    @objc private func sessionChanged() {
        selectedPatientIndex = 0
        loadPatients()
        checkPatientStatus()
        // Restart cloud listener for the current auth state
        patientsListener?.remove()
        patientsListener = nil
        if Auth.auth().currentUser != nil {
            startPatientsListener()
        }
    }
    
    private func getCurrentCaregiver(context: NSManagedObjectContext) -> Caregiver? {
        if let username = UserDefaults.standard.string(forKey: "LoggedInUsername") {
            let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
            request.predicate = NSPredicate(format: "username == %@", username)
            request.fetchLimit = 1
            do { return try context.fetch(request).first } catch { return nil }
        }
        return nil
    }
    
    private func loadPatients() {
        // Always show local data first for immediate UI updates
        loadPatientsFromCoreData()
        checkPatientStatus()

        // Then, if signed into Firebase, fetch cloud in the background and merge into Core Data.
        // After cloud merge, refresh local data again.
        guard !isLoadingPatients else { return }
        isLoadingPatients = true

        if Auth.auth().currentUser != nil {
            fetchPatientsFromCloud { [weak self] _ in
                guard let self = self else { return }
                self.loadPatientsFromCoreData()
                self.checkPatientStatus()
                self.isLoadingPatients = false
            }
        } else {
            isLoadingPatients = false
        }
    }
    
    private func loadPatientsFromCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        if let caregiver = getCurrentCaregiver(context: context) {
            let request: NSFetchRequest<Patient> = Patient.fetchRequest()
            request.predicate = NSPredicate(format: "caregiver == %@", caregiver)
            do {
                patients = try context.fetch(request)
                if patients.isEmpty {
                    selectedPatientIndex = 0
                } else if selectedPatientIndex >= patients.count {
                    selectedPatientIndex = max(0, patients.count - 1)
                }
            } catch {
                print("Error loading patients: \(error)")
                patients = []
                selectedPatientIndex = 0
            }
        } else {
            patients = []
            selectedPatientIndex = 0
        }
    }
    
    private func fetchPatientsFromCloud(completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("patients").getDocuments { [weak self] snapshot, error in
            guard let self = self else { completion(false); return }
            if let error = error {
                print("Failed to fetch patients from cloud: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                completion(false)
                return
            }
            let context = appDelegate.persistentContainer.viewContext
            guard let caregiver = self.getCurrentCaregiver(context: context) else {
                completion(false)
                return
            }

            let docs = snapshot?.documents ?? []
            for doc in docs {
                let data = doc.data()
                let firstName = (data["firstName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let lastName = (data["lastName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let email = (data["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let phone = (data["phoneNumber"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
                let veteran = (data["veteranStatus"] as? Bool) ?? false
                let income = (data["incomeRange"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

                var dob: Date? = nil
                if let ts = data["dateOfBirth"] as? Timestamp {
                    dob = ts.dateValue()
                }
                var createdAt: Date? = nil
                if let ts = data["createdAt"] as? Timestamp {
                    createdAt = ts.dateValue()
                }

                // Upsert strategy: prefer email match; else match by (first+last+dob) for this caregiver
                var existing: Patient? = nil
                if let email = email, !email.isEmpty {
                    let req: NSFetchRequest<Patient> = Patient.fetchRequest()
                    req.predicate = NSPredicate(format: "caregiver == %@ AND email == %@", caregiver, email)
                    req.fetchLimit = 1
                    existing = try? context.fetch(req).first
                }
                if existing == nil {
                    // Fallback to name + DOB match for this caregiver
                    if let first = firstName, let last = lastName, let dob = dob {
                        let req: NSFetchRequest<Patient> = Patient.fetchRequest()
                        req.predicate = NSPredicate(format: "caregiver == %@ AND firstName == %@ AND lastName == %@ AND dateOfBirth == %@", caregiver, first, last, dob as NSDate)
                        req.fetchLimit = 1
                        existing = try? context.fetch(req).first
                    }
                }

                if let patient = existing {
                    // Local-wins during manual fetch to avoid clobbering just-edited data
                    if patient.createdAt == nil { patient.createdAt = createdAt ?? patient.createdAt }
                    patient.caregiver = caregiver
                } else {
                    let patient = Patient(context: context)
                    patient.firstName = firstName
                    patient.lastName = lastName
                    patient.email = email
                    patient.phoneNumber = phone
                    patient.dateOfBirth = dob
                    patient.veteranStatus = veteran
                    patient.incomeRange = income
                    patient.createdAt = createdAt ?? Date()
                    patient.caregiver = caregiver
                }
            }

            do {
                try context.save()
                completion(true)
            } catch {
                print("Failed to upsert cloud patients into Core Data: \(error)")
                completion(false)
            }
        }
    }
    
    private func startPatientsListener() {
        patientsListener?.remove()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        patientsListener = db.collection("users").document(uid).collection("patients")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Patients snapshot listener error: \(error.localizedDescription)")
                    return
                }
                guard let snapshot = snapshot else { return }
                self.applyPatientChanges(from: snapshot)
            }
    }
    
    private func applyPatientChanges(from snapshot: QuerySnapshot) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        guard let caregiver = getCurrentCaregiver(context: context) else { return }

        for change in snapshot.documentChanges {
            let data = change.document.data()
            let firstName = (data["firstName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = (data["lastName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = (data["email"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = (data["phoneNumber"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let veteran = (data["veteranStatus"] as? Bool) ?? false
            let income = (data["incomeRange"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

            var dob: Date? = nil
            if let ts = data["dateOfBirth"] as? Timestamp { dob = ts.dateValue() }
            var createdAt: Date? = nil
            if let ts = data["createdAt"] as? Timestamp { createdAt = ts.dateValue() }

            // Find existing patient by email or (name + DOB) for this caregiver
            var existing: Patient? = nil
            if let email = email, !email.isEmpty {
                let req: NSFetchRequest<Patient> = Patient.fetchRequest()
                req.predicate = NSPredicate(format: "caregiver == %@ AND email == %@", caregiver, email)
                req.fetchLimit = 1
                existing = try? context.fetch(req).first
            }
            if existing == nil, let first = firstName, let last = lastName, let dob = dob {
                let req: NSFetchRequest<Patient> = Patient.fetchRequest()
                req.predicate = NSPredicate(format: "caregiver == %@ AND firstName == %@ AND lastName == %@ AND dateOfBirth == %@", caregiver, first, last, dob as NSDate)
                req.fetchLimit = 1
                existing = try? context.fetch(req).first
            }

            switch change.type {
            case .added, .modified:
                let patient = existing ?? Patient(context: context)
                // Cloud-wins for live listener so remote edits are visible
                patient.firstName = firstName
                patient.lastName = lastName
                patient.email = email
                patient.phoneNumber = phone
                patient.dateOfBirth = dob
                patient.veteranStatus = veteran
                patient.incomeRange = income
                if patient.createdAt == nil { patient.createdAt = createdAt ?? Date() }
                patient.caregiver = caregiver
            case .removed:
                if let toDelete = existing {
                    context.delete(toDelete)
                }
            @unknown default:
                break
            }
        }

        do {
            try context.save()
            DispatchQueue.main.async {
                self.loadPatientsFromCoreData()
                self.checkPatientStatus()
            }
        } catch {
            print("Failed to apply patient changes from listener: \(error)")
        }
    }
    
    private func setupAddPatientButton() {
        addPatientButton = UIButton(type: .system)
        addPatientButton.tintColor = .systemIndigo
        addPatientButton.setTitle(" Add Patient", for: .normal)
        addPatientButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addPatientButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addPatientButton.addTarget(self, action: #selector(addPatientTapped), for: .touchUpInside)
        
        let barButton = UIBarButtonItem(customView: addPatientButton)
        navigationItem.rightBarButtonItem = barButton
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
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
    
    private func checkPatientStatus() {
        if patients.isEmpty {
            showDefaultView()
        } else {
            showPatientHomeView()
        }
    }
    
    private func setupPatientTabs() {
        // Remove existing tabs if any
        patientTabsScrollView?.removeFromSuperview()
        
        patientTabsScrollView = UIScrollView()
        patientTabsScrollView.showsHorizontalScrollIndicator = false
        patientTabsScrollView.translatesAutoresizingMaskIntoConstraints = false
        patientTabsScrollView.clipsToBounds = false
        
        patientTabsStackView = UIStackView()
        patientTabsStackView.axis = .horizontal
        patientTabsStackView.spacing = 8
        patientTabsStackView.alignment = .center
        patientTabsStackView.distribution = .equalSpacing
        patientTabsStackView.isLayoutMarginsRelativeArrangement = true
        patientTabsStackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        patientTabsStackView.translatesAutoresizingMaskIntoConstraints = false
        patientTabsStackView.clipsToBounds = false
        
        patientTabsScrollView.addSubview(patientTabsStackView)
        contentView.addSubview(patientTabsScrollView)
        
        // Calculate tab width based on number of patients
        let maxTabWidth: CGFloat = min(120, view.frame.width / CGFloat(patients.count) - 16)
        
        for (index, patient) in patients.enumerated() {
            let tabButton = UIButton(type: .system)
            tabButton.setTitle(patient.firstName ?? "Patient \(index + 1)", for: .normal)
            tabButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            let isSelected = (index == selectedPatientIndex)
            tabButton.backgroundColor = tabBackgroundColor(forSelected: isSelected)
            tabButton.setTitleColor(tabTextColor(forSelected: isSelected), for: .normal)
            tabButton.layer.cornerRadius = 8
            tabButton.layer.shadowColor = UIColor.black.cgColor
            tabButton.layer.shadowOpacity = isSelected ? 0 : cardShadowOpacity()
            tabButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            tabButton.layer.shadowRadius = 4
            tabButton.tag = index
            tabButton.addTarget(self, action: #selector(patientTabTapped(_:)), for: .touchUpInside)
            tabButton.translatesAutoresizingMaskIntoConstraints = false
            
            patientTabsStackView.addArrangedSubview(tabButton)
            
            NSLayoutConstraint.activate([
                tabButton.heightAnchor.constraint(equalToConstant: 36),
                tabButton.widthAnchor.constraint(greaterThanOrEqualToConstant: maxTabWidth)
            ])
        }
        
        NSLayoutConstraint.activate([
            patientTabsScrollView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            patientTabsScrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            patientTabsScrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            patientTabsScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            patientTabsStackView.topAnchor.constraint(equalTo: patientTabsScrollView.contentLayoutGuide.topAnchor),
            patientTabsStackView.bottomAnchor.constraint(equalTo: patientTabsScrollView.contentLayoutGuide.bottomAnchor),
            patientTabsStackView.centerXAnchor.constraint(equalTo: patientTabsScrollView.frameLayoutGuide.centerXAnchor),
            patientTabsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: patientTabsScrollView.contentLayoutGuide.leadingAnchor),
            patientTabsStackView.trailingAnchor.constraint(lessThanOrEqualTo: patientTabsScrollView.contentLayoutGuide.trailingAnchor),
            patientTabsStackView.heightAnchor.constraint(equalTo: patientTabsScrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    @objc private func patientTabTapped(_ sender: UIButton) {
        selectedPatientIndex = sender.tag
        updateTabAppearance()
        showSelectedPatientInfo()
    }
    
    private func updateTabAppearance() {
        for (index, view) in patientTabsStackView.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                let isSelected = (index == selectedPatientIndex)
                button.backgroundColor = tabBackgroundColor(forSelected: isSelected)
                button.setTitleColor(tabTextColor(forSelected: isSelected), for: .normal)
                button.layer.shadowColor = UIColor.black.cgColor
                button.layer.shadowOpacity = isSelected ? 0 : cardShadowOpacity()
                button.layer.shadowOffset = CGSize(width: 0, height: 2)
                button.layer.shadowRadius = 4
            }
        }
    }
    
    // New helper methods for tab colors
    private func tabBackgroundColor(forSelected selected: Bool) -> UIColor {
        if selected { return .systemIndigo }
        return traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.14, alpha: 1.0) : .white
    }
    private func tabTextColor(forSelected selected: Bool) -> UIColor {
        return selected ? .white : .label
    }
    
    private func showDefaultView() {
        clearContentView()
        
        defaultMessageLabel = UILabel()
        defaultMessageLabel.text = "Please create a patient to continue."
        defaultMessageLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        defaultMessageLabel.textAlignment = .center
        defaultMessageLabel.textColor = .secondaryLabel
        defaultMessageLabel.numberOfLines = 0
        defaultMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(defaultMessageLabel)
        
        NSLayoutConstraint.activate([
            defaultMessageLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            defaultMessageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            defaultMessageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            defaultMessageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Ensure the contentView is at least as tall as the visible area, but allow it to grow when needed
        defaultViewHeightConstraint?.isActive = false
        let minHeight = contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor)
        minHeight.priority = UILayoutPriority(999)
        minHeight.isActive = true
        defaultViewHeightConstraint = minHeight
    }
    
    private func showPatientHomeView() {
        clearContentView()
        
        if patients.count > 1 {
            setupPatientTabs()
        }
        
        showSelectedPatientInfo()
    }
    
    private func showSelectedPatientInfo() {
            // Remove existing patient info views
            contentView.subviews.forEach { view in
                if view != patientTabsScrollView {
                    view.removeFromSuperview()
                }
            }
            
            guard selectedPatientIndex < patients.count else { return }
            let selectedPatient = patients[selectedPatientIndex]
            
            let topAnchor = patients.count > 1 ? patientTabsScrollView.bottomAnchor : contentView.topAnchor
            let topConstant: CGFloat = patients.count > 1 ? 20 : 20
            
            // Patient Info Section
            let patientInfoView = createPatientInfoView(for: selectedPatient)
            contentView.addSubview(patientInfoView)
            
            // Upcoming tasks label
            upcomingTasksLabel = UILabel()
            upcomingTasksLabel.text = "Upcoming Tasks"
            upcomingTasksLabel.font = UIFont.boldSystemFont(ofSize: 24)
            upcomingTasksLabel.textColor = .systemIndigo
            upcomingTasksLabel.translatesAutoresizingMaskIntoConstraints = false
            
            // Tasks stack view
            tasksStackView = UIStackView()
            tasksStackView.axis = .vertical
            tasksStackView.spacing = 12
            tasksStackView.alignment = .fill
            tasksStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // Add 3 sample task boxes
            for i in 1...3 {
                let taskBox = createTaskBox(title: "Task \(i)", description: "Sample task description \(i)")
                tasksStackView.addArrangedSubview(taskBox)
            }
            
            // Map view
            mapView = MKMapView()
            mapView.translatesAutoresizingMaskIntoConstraints = false
            mapView.layer.cornerRadius = 12
            
            // Set location to 10606 Marbury Court, Austin, Texas
            let coordinate = CLLocationCoordinate2D(latitude: 30.3461, longitude: -97.8147)
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: false)
            
            // Add annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "10606 Marbury Court"
            annotation.subtitle = "Austin, Texas"
            mapView.addAnnotation(annotation)
            
            contentView.addSubview(upcomingTasksLabel)
            contentView.addSubview(tasksStackView)
            contentView.addSubview(mapView)
            
            NSLayoutConstraint.activate([
                patientInfoView.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
                patientInfoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                patientInfoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                
                upcomingTasksLabel.topAnchor.constraint(equalTo: patientInfoView.bottomAnchor, constant: 20),
                upcomingTasksLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                upcomingTasksLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                
                tasksStackView.topAnchor.constraint(equalTo: upcomingTasksLabel.bottomAnchor, constant: 16),
                tasksStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                tasksStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                
                mapView.topAnchor.constraint(equalTo: tasksStackView.bottomAnchor, constant: 20),
                mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
                mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
                mapView.heightAnchor.constraint(equalToConstant: 250),
                mapView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
            ])
            
            // Force layout update without manually overriding contentSize; Auto Layout will determine it
            DispatchQueue.main.async {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
    
    private func createPatientInfoView(for patient: Patient) -> UIView {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.tag = 1001 // patient info card
            applyCardStyle(to: containerView)
            
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 8
            stackView.alignment = .leading
            stackView.translatesAutoresizingMaskIntoConstraints = false
            
            let nameLabel = UILabel()
            let firstName = patient.firstName ?? ""
            let lastName = patient.lastName ?? ""
            nameLabel.text = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
            nameLabel.textColor = .systemIndigo
            
            let emailLabel = UILabel()
            emailLabel.text = "Email: \(patient.email ?? "N/A")"
            emailLabel.font = UIFont.systemFont(ofSize: 16)
            emailLabel.textColor = .label
            
            let phoneLabel = UILabel()
            phoneLabel.text = "Phone: \(patient.phoneNumber ?? "N/A")"
            phoneLabel.font = UIFont.systemFont(ofSize: 16)
            phoneLabel.textColor = .label
            
            let dobLabel = UILabel()
            if let dob = patient.dateOfBirth {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                dobLabel.text = "Date of Birth: \(formatter.string(from: dob))"
            } else {
                dobLabel.text = "Date of Birth: N/A"
            }
            dobLabel.font = UIFont.systemFont(ofSize: 16)
            dobLabel.textColor = .label
            
            let veteranLabel = UILabel()
            veteranLabel.text = "Veteran Status: \(patient.veteranStatus ? "Yes" : "No")"
            veteranLabel.font = UIFont.systemFont(ofSize: 16)
            veteranLabel.textColor = .label
            
            // Simplified income range access - just use the property directly
            let incomeLabel = UILabel()
            incomeLabel.text = "Income Range: \(patient.incomeRange ?? "N/A")"
            incomeLabel.font = UIFont.systemFont(ofSize: 16)
            incomeLabel.textColor = .label
            
            // Debug: Print patient data to see what's actually there
            print("=== Patient Debug Info ===")
            print("First Name: '\(patient.firstName ?? "nil")'")
            print("Last Name: '\(patient.lastName ?? "nil")'")
            print("Email: '\(patient.email ?? "nil")'")
            print("Phone: '\(patient.phoneNumber ?? "nil")'")
            print("DOB: '\(patient.dateOfBirth?.description ?? "nil")'")
            print("Veteran: \(patient.veteranStatus)")
            print("Income Range: '\(patient.incomeRange ?? "nil")'")
            print("==========================")
            
            stackView.addArrangedSubview(nameLabel)
            stackView.addArrangedSubview(emailLabel)
            stackView.addArrangedSubview(phoneLabel)
            stackView.addArrangedSubview(dobLabel)
            stackView.addArrangedSubview(veteranLabel)
            stackView.addArrangedSubview(incomeLabel)
            
            containerView.addSubview(stackView)
            
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
                stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
            ])
            
            return containerView
        }
    
    private func createTaskBox(title: String, description: String) -> UIView {
        let box = UIView()
        box.translatesAutoresizingMaskIntoConstraints = false
        box.tag = 1002 // task box
        applyCardStyle(to: box)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .systemIndigo
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = .label
        descLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        box.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: box.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -16),
            box.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
        
        return box
    }
    
    // MARK: - Card styling (light/dark)
    private func cardBackgroundColor() -> UIColor {
        return traitCollection.userInterfaceStyle == .dark ? UIColor(white: 0.14, alpha: 1.0) : .white
    }

    private func cardShadowOpacity() -> Float {
        return traitCollection.userInterfaceStyle == .dark ? 0.35 : 0.1
    }

    private func applyCardStyle(to view: UIView) {
        view.backgroundColor = cardBackgroundColor()
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = cardShadowOpacity()
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.masksToBounds = false
    }

    private func updateCardStylesForCurrentAppearance() {
        // Update top-level patient info card and task boxes added directly to contentView
        contentView.subviews.forEach { sub in
            if sub.tag == 1001 || sub.tag == 1002 { // 1001: patient card, 1002: task box
                applyCardStyle(to: sub)
            }
        }
        // Update any task boxes inside the tasks stack view
        tasksStackView?.arrangedSubviews.forEach { applyCardStyle(to: $0) }
    }

    // Added call to updateTabAppearance() on dark mode change
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateCardStylesForCurrentAppearance()
            updateTabAppearance()
        }
    }
    
    private func clearContentView() {
        // Deactivate any default view height constraint so patient layout can expand naturally
        defaultViewHeightConstraint?.isActive = false
        defaultViewHeightConstraint = nil
        contentView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    @objc private func addPatientTapped() {
        let addPatientVC = AddPatientViewController()
        let navController = UINavigationController(rootViewController: addPatientVC)
        present(navController, animated: true)
    }
}

// MARK: - Add Patient View Controller
class AddPatientViewController: UIViewController {
    
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var firstNameTextField: UITextField!
    private var lastNameTextField: UITextField!
    private var emailTextField: UITextField!
    private var phoneTextField: UITextField!
    private var dateOfBirthPicker: UIDatePicker!
    private var veteranCheckbox: UIButton!
    private var veteranLabel: UILabel!
    private var incomeDropdown: UIButton!
    private var isVeteran = false
    
    private let incomeOptions = ["$100,000 or less", "$100,000 to $200,000", "$200,000 to $300,000", "$300,000 and above"]
    private var selectedIncome = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Add Patient"
        setupNavigationBar()
        setupScrollView()
        setupUI()
        setupKeyboardDismissal()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
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
    
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // First Name
        firstNameTextField = createTextField(placeholder: "First Name")
        firstNameTextField.tintColor = .systemIndigo
        stackView.addArrangedSubview(createFormSection(title: "First Name", content: firstNameTextField))
        
        // Last Name
        lastNameTextField = createTextField(placeholder: "Last Name")
        lastNameTextField.tintColor = .systemIndigo
        stackView.addArrangedSubview(createFormSection(title: "Last Name", content: lastNameTextField))
        
        // Email
        emailTextField = createTextField(placeholder: "Email")
        emailTextField.tintColor = .systemIndigo
        emailTextField.keyboardType = .emailAddress
        stackView.addArrangedSubview(createFormSection(title: "Email", content: emailTextField))
        
        // Phone Number
        phoneTextField = createTextField(placeholder: "Phone Number")
        phoneTextField.tintColor = .systemIndigo
        phoneTextField.keyboardType = .phonePad
        stackView.addArrangedSubview(createFormSection(title: "Phone Number", content: phoneTextField))
        
        // Date of Birth
        dateOfBirthPicker = UIDatePicker()
        dateOfBirthPicker.tintColor = .systemIndigo
        dateOfBirthPicker.datePickerMode = .date
        dateOfBirthPicker.preferredDatePickerStyle = .compact
        dateOfBirthPicker.maximumDate = Date()
        stackView.addArrangedSubview(createFormSection(title: "Date of Birth", content: dateOfBirthPicker))
        
        // Veteran Status
        let veteranContainer = UIView()
        veteranCheckbox = UIButton(type: .system)
        veteranCheckbox.tintColor = .systemIndigo
        veteranCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        veteranCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        veteranCheckbox.addTarget(self, action: #selector(veteranCheckboxTapped), for: .touchUpInside)
        veteranCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        veteranLabel = UILabel()
        veteranLabel.text = "Are they a veteran?"
        veteranLabel.font = UIFont.systemFont(ofSize: 16)
        veteranLabel.translatesAutoresizingMaskIntoConstraints = false
        
        veteranContainer.addSubview(veteranCheckbox)
        veteranContainer.addSubview(veteranLabel)
        
        NSLayoutConstraint.activate([
            veteranCheckbox.leadingAnchor.constraint(equalTo: veteranContainer.leadingAnchor),
            veteranCheckbox.centerYAnchor.constraint(equalTo: veteranContainer.centerYAnchor),
            veteranCheckbox.widthAnchor.constraint(equalToConstant: 24),
            veteranCheckbox.heightAnchor.constraint(equalToConstant: 24),
            
            veteranLabel.leadingAnchor.constraint(equalTo: veteranCheckbox.trailingAnchor, constant: 8),
            veteranLabel.centerYAnchor.constraint(equalTo: veteranContainer.centerYAnchor),
            veteranLabel.trailingAnchor.constraint(equalTo: veteranContainer.trailingAnchor),
            
            veteranContainer.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        stackView.addArrangedSubview(createFormSection(title: "Veteran Status", content: veteranContainer))
        
        // Income Dropdown
        incomeDropdown = UIButton(type: .system)
        incomeDropdown.tintColor = .systemIndigo
        incomeDropdown.setTitle("Select Income Range", for: .normal)
        incomeDropdown.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        incomeDropdown.contentHorizontalAlignment = .left
        incomeDropdown.backgroundColor = .secondarySystemBackground
        incomeDropdown.layer.cornerRadius = 8
        incomeDropdown.addTarget(self, action: #selector(incomeDropdownTapped), for: .touchUpInside)
        incomeDropdown.translatesAutoresizingMaskIntoConstraints = false
        incomeDropdown.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        stackView.addArrangedSubview(createFormSection(title: "Family Income Range", content: incomeDropdown))
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -100)
        ])
        
        // Ensure content view height is at least as tall as the stack view
        let contentHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualTo: stackView.heightAnchor, constant: 140)
        contentHeightConstraint.priority = UILayoutPriority(999)
        contentHeightConstraint.isActive = true
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return textField
    }
    
    private func createFormSection(title: String, content: UIView) -> UIView {
        let container = UIView()
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .label
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
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func veteranCheckboxTapped() {
        isVeteran.toggle()
        veteranCheckbox.isSelected = isVeteran
    }
    
    @objc private func incomeDropdownTapped() {
        let alertController = UIAlertController(title: "Select Income Range", message: nil, preferredStyle: .actionSheet)
        
        for option in incomeOptions {
            let action = UIAlertAction(title: option, style: .default) { _ in
                self.selectedIncome = option
                self.incomeDropdown.setTitle(option, for: .normal)
            }
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = incomeDropdown
            popover.sourceRect = incomeDropdown.bounds
        }
        
        present(alertController, animated: true)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty,
              !selectedIncome.isEmpty else {
            showAlert(message: "Please fill in all fields")
            return
        }
        
        savePatient()
    }
    
    private func getCurrentCaregiver() -> Caregiver? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext
        guard let username = UserDefaults.standard.string(forKey: "LoggedInUsername") else { return nil }
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        request.fetchLimit = 1
        do { return try context.fetch(request).first } catch { return nil }
    }
    
    private func savePatient() {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            guard let caregiver = getCurrentCaregiver() else {
                showAlert(message: "Could not determine current account. Please try again.")
                return
            }
            
            let patient = Patient(context: context)
            patient.firstName = firstNameTextField.text
            patient.lastName = lastNameTextField.text
            patient.email = emailTextField.text
            patient.phoneNumber = phoneTextField.text
            patient.dateOfBirth = dateOfBirthPicker.date
            patient.veteranStatus = isVeteran
            patient.incomeRange = selectedIncome  // Simple property assignment
            patient.caregiver = caregiver
            
            do {
                try context.save()
                PatientCloudSync.upsertPatient(patient)
                print("Patient saved successfully with income: \(selectedIncome)")
                
                NotificationCenter.default.post(name: NSNotification.Name("PatientCreated"), object: nil)
                dismiss(animated: true)
            } catch {
                print("Failed to save patient: \(error)")
                showAlert(message: "Failed to save patient: \(error.localizedDescription)")
            }
        }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


// --- Assuming EditPatientViewController exists in this file ---
// Insert the following modification in EditPatientViewController's saveTapped method:
/*
    do {
        try context.save()
        PatientCloudSync.upsertPatient(self.patient)
        NotificationCenter.default.post(name: NSNotification.Name("PatientUpdated"), object: nil)
        dismiss(animated: true)
    } catch {
        showAlert(message: error.localizedDescription)
    }
*/

// --- Assuming SettingsViewController exists in this file ---
// Modify the deletePatient(_:) method as follows:

/*
private func deletePatient(_ patient: Patient) {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
    let context = appDelegate.persistentContainer.viewContext
    
    let objectID = patient.objectID
    
    context.delete(patient)
    
    do {
        try context.save()
        PatientCloudSync.deletePatient(with: objectID)
        NotificationCenter.default.post(name: NSNotification.Name("PatientDeleted"), object: nil)
    } catch {
        print("Failed to delete patient: \(error)")
    }
}
*/
