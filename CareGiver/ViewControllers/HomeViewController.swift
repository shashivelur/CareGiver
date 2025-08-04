import UIKit
import CoreData

class HomeViewController: UIViewController {
    
    var currentCaregiver: Caregiver?
    
    @IBOutlet weak var welcomeLabel: UILabel?
    @IBOutlet weak var patientsCountLabel: UILabel?
    @IBOutlet weak var quickActionsStackView: UIStackView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    private func setupUI() {
        title = "Home"
        view.backgroundColor = .systemBackground
        
        // Create UI elements programmatically if storyboard outlets are not connected
        if welcomeLabel == nil {
            createUIElements()
        }
        
        updateUI()
    }
    
    private func createUIElements() {
        // Welcome label
        let welcomeLabelView = UILabel()
        welcomeLabelView.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        welcomeLabelView.textAlignment = .center
        welcomeLabelView.numberOfLines = 0
        welcomeLabel = welcomeLabelView
        
        // Patients count label
        let patientsCountLabelView = UILabel()
        patientsCountLabelView.font = UIFont.systemFont(ofSize: 18)
        patientsCountLabelView.textAlignment = .center
        patientsCountLabelView.textColor = .systemBlue
        patientsCountLabel = patientsCountLabelView
        
        // Stack view for quick actions
        let quickActionsStackViewView = UIStackView()
        quickActionsStackViewView.axis = .vertical
        quickActionsStackViewView.spacing = 16
        quickActionsStackViewView.alignment = .fill
        quickActionsStackViewView.distribution = .fillEqually
        quickActionsStackView = quickActionsStackViewView
        
        // Add quick action buttons
        let addPatientButton = createQuickActionButton(title: "Add New Patient", action: #selector(addPatientTapped))
        let viewPatientsButton = createQuickActionButton(title: "View All Patients", action: #selector(viewPatientsTapped))
        let quickCheckupButton = createQuickActionButton(title: "Quick Checkup", action: #selector(quickCheckupTapped))
        
        quickActionsStackView?.addArrangedSubview(addPatientButton)
        quickActionsStackView?.addArrangedSubview(viewPatientsButton)
        quickActionsStackView?.addArrangedSubview(quickCheckupButton)
        
        // Add to view with constraints
        if let welcomeLabel = welcomeLabel,
           let patientsCountLabel = patientsCountLabel,
           let quickActionsStackView = quickActionsStackView {
            view.addSubview(welcomeLabel)
            view.addSubview(patientsCountLabel)
            view.addSubview(quickActionsStackView)
        
            welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
            patientsCountLabel.translatesAutoresizingMaskIntoConstraints = false
            quickActionsStackView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
                welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                patientsCountLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 20),
                patientsCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                patientsCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                
                quickActionsStackView.topAnchor.constraint(equalTo: patientsCountLabel.bottomAnchor, constant: 40),
                quickActionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                quickActionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
                quickActionsStackView.heightAnchor.constraint(equalToConstant: 180)
            ])
        }
    }
    
    private func createQuickActionButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func updateUI() {
        guard let caregiver = currentCaregiver else {
            welcomeLabel?.text = "Welcome to CareGiver App"
            patientsCountLabel?.text = "Please login to continue"
            return
        }
        
        welcomeLabel?.text = "Welcome, \(caregiver.fullName)!"
        
        let patientsCount = CoreDataManager.shared.fetchPatients(for: caregiver).count
        patientsCountLabel?.text = "You are caring for \(patientsCount) patient\(patientsCount == 1 ? "" : "s")"
    }
    
    @objc private func addPatientTapped() {
        let alert = UIAlertController(title: "Add New Patient", message: "Enter patient information", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "First Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Last Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Email (Optional)"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Phone Number (Optional)"
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let firstName = alert.textFields?[0].text, !firstName.isEmpty,
                  let lastName = alert.textFields?[1].text, !lastName.isEmpty,
                  let caregiver = self.currentCaregiver else {
                self.showAlert(message: "Please enter patient's first and last name")
                return
            }
            
            let email = alert.textFields?[2].text?.isEmpty == false ? alert.textFields?[2].text : nil
            let phoneNumber = alert.textFields?[3].text?.isEmpty == false ? alert.textFields?[3].text : nil
            
            _ = CoreDataManager.shared.createPatient(
                firstName: firstName,
                lastName: lastName,
                dateOfBirth: Date(timeIntervalSinceNow: -365*24*60*60*25), // Default 25 years ago
                email: email,
                phoneNumber: phoneNumber,
                caregiver: caregiver
            )
            
            self.updateUI()
            self.showAlert(message: "Patient added successfully!")
        }
        
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func viewPatientsTapped() {
        guard let caregiver = currentCaregiver else { return }
        
        let patients = CoreDataManager.shared.fetchPatients(for: caregiver)
        
        if patients.isEmpty {
            showAlert(message: "No patients found. Add a patient first.")
            return
        }
        
        let patientsInfo = patients.map { "\($0.fullName) - Age: \($0.age)" }.joined(separator: "\n")
        showAlert(message: "Your Patients:\n\n\(patientsInfo)")
    }
    
    @objc private func quickCheckupTapped() {
        showAlert(message: "Quick Checkup feature coming soon!")
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
