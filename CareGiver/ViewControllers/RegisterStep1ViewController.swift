//
//  RegisterStep1ViewController.swift
//  CareGiver
//
//  Created by Shivank Ahuja on 8/10/25.
//

import UIKit
import CoreData
import CryptoKit
import LocalAuthentication
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


class RegisterStep1ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var birthdayDatePicker: UIDatePicker!
    @IBOutlet weak var nextButton: UIButton!
    
    private let faceIDOptInKeyPrefix = "BiometricEnabled_"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissal()
        
        phoneNumberTextField.delegate = self
        phoneNumberTextField.addTarget(self, action: #selector(phoneEditingChanged(_:)), for: .editingChanged)
    }
    
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        handle = Auth.auth().addStateDidChangeListener { auth, user in
          // ...
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        Auth.auth().removeStateDidChangeListener(handle!)
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        // Require all fields to be filled out before continuing
        let trimmedUsername = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedPassword = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedFirst = firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedLast = lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedEmail = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedPhone = phoneNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if trimmedUsername.isEmpty || trimmedPassword.isEmpty || trimmedFirst.isEmpty || trimmedLast.isEmpty || trimmedEmail.isEmpty || trimmedPhone.isEmpty {
            let alert = UIAlertController(title: "Error", message: "Please fill out all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Validate email format
        guard isValidEmail(trimmedEmail) else {
            let alert = UIAlertController(title: "Invalid Email", message: "Please enter a valid email address.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        // Validate phone number format
        guard isValidPhone(trimmedPhone) else {
            let alert = UIAlertController(title: "Invalid Phone Number", message: "Please enter a 10-digit phone number.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Proceed with local save and Firebase account creation
        if let enteredUsername = self.usernameTextField.text,
           !enteredUsername.isEmpty,
           let _ = self.passwordTextField.text {

            // Compute hashed password once for cloud + local consistency
            guard let hashedPassword = self.sha256(for: trimmedPassword) else {
                let alert = UIAlertController(title: "Error", message: "There was a problem processing your password. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }

            do {
                // Save locally (stores hashed password in Core Data)
                try self.createCaregiver()

                // Create account in Firebase with email and hashed password (to match login flow)
                Auth.auth().createUser(withEmail: trimmedEmail, password: hashedPassword) { authResult, error in
                    if let error = error {
                        print("Firebase account creation failed: \(error.localizedDescription)")
                    } else {
                        print("Firebase account created for email: \(trimmedEmail)")

                        // Save user profile to Firestore using the Auth UID as the document ID
                        let db = Firestore.firestore()
                        guard let uid = authResult?.user.uid else {
                            print("Error: Missing auth UID after account creation.")
                            return
                        }

                        let userData: [String: Any] = [
                            "uid": uid,
                            "username": trimmedUsername,
                            "usernameLowercased": trimmedUsername.lowercased(),
                            "email": trimmedEmail,
                            "firstName": trimmedFirst,
                            "lastName": trimmedLast,
                            "phoneNumber": trimmedPhone,
                            "dateOfBirth": Timestamp(date: self.birthdayDatePicker.date),
                            "createdAt": FieldValue.serverTimestamp()
                        ]

                        db.collection("users").document(uid).setData(userData) { err in
                            if let err = err {
                                print("Failed to save user profile: \(err.localizedDescription)")
                            } else {
                                print("User profile saved to Firestore for uid: \(uid)")
                            }
                        }
                    }
                }

                // Reset per-account profile image so a new account starts clean
                ProfileImageStore.remove(for: enteredUsername)
                // Notify the app that the active session changed so screens can reload data
                NotificationCenter.default.post(name: .SessionChanged, object: nil)

            } catch {
                print("There was an error saving the password. Please try again.")
            }

        } else {
            let alert = UIAlertController(title: "Error", message: "Please fill out all fields.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }

        self.printAllUserProfiles()

        let caregivers = self.fetchCaregivers()
        for c in caregivers {
            print("Username: \(c.username ?? "nil"), Password: \(c.password ?? "nil")")
        }

        // Offer Face ID enablement, then navigate based on choice
        if let username = self.usernameTextField.text, !username.isEmpty {
            self.offerFaceIDEnablement(for: username)
        } else {
            self.navigateToHome()
        }
    }
             
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func phoneEditingChanged(_ textField: UITextField) {
        // Preserve the cursor position as best as possible
        let currentText = textField.text ?? ""
        let digits = currentText.filter { $0.isNumber }
        let formatted = formatAsUSPhone(digits)
        textField.text = formatted
    }

    private func formatAsUSPhone(_ digits: String) -> String {
        // Limit to 10 digits total
        let limited = String(digits.prefix(10))
        let count = limited.count
        if count == 0 { return "" }
        var result = ""
        let chars = Array(limited)
        if count <= 3 {
            result = String(chars[0..<count])
        } else if count <= 6 {
            result = "(\(String(chars[0..<3]))) \(String(chars[3..<count]))"
        } else {
            result = "(\(String(chars[0..<3]))) \(String(chars[3..<6]))-\(String(chars[6..<count]))"
        }
        return result
    }
    
    func sha256(for string: String) -> String? {
        // 1. Convert the string to Data using UTF-8 encoding.
        guard let inputData = string.data(using: .utf8) else {
            print("Error: Could not convert string to Data.")
            return nil
        }
        
        // 2. Compute the SHA256 hash of the Data.
        let digest = SHA256.hash(data: inputData)
        
        // 3. Convert the digest (hashed data) to a hexadecimal string representation.
        //    Each byte of the digest is formatted as a two-digit hexadecimal number.
        let hexString = digest.compactMap { String(format: "%02x", $0) }.joined()
        
        return hexString
    }
    
    func createCaregiver() throws {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        let caregiver = Caregiver(context: context)

        // Save all the fields with proper field names
        let username = (usernameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let rawPassword = (passwordTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let email = (emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let firstName = (firstNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = (lastNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = (phoneNumberTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let dob = birthdayDatePicker.date

        caregiver.username = username
        caregiver.password = sha256(for: rawPassword) // Hash the password locally
        caregiver.email = email
        caregiver.firstName = firstName
        caregiver.lastName = lastName
        caregiver.phoneNumber = phone
        caregiver.dateOfBirth = dob

        // Debug log
        print("=== Saving Caregiver (Local) ===")
        print("Username: \(caregiver.username ?? "nil")")
        print("FirstName: \(caregiver.firstName ?? "nil")")
        print("LastName: \(caregiver.lastName ?? "nil")")
        print("Email: \(caregiver.email ?? "nil")")
        print("Phone: \(caregiver.phoneNumber ?? "nil")")
        print("Birthday: \(caregiver.dateOfBirth?.description ?? "nil")")
        print("===============================")

        try context.save()
        UserDefaults.standard.set(caregiver.username, forKey: "LoggedInUsername")
        UserDefaults.standard.synchronize()
    }
    
    private func navigateToHome() {
        self.performSegue(withIdentifier: "toMainPage", sender: self)
    }

    private func offerFaceIDEnablement(for username: String) {
        let (available, type) = BiometricAuthManager.isBiometryAvailable()
        // If biometrics aren't available, just proceed to home
        guard available else {
            self.navigateToHome()
            return
        }

        let typeName = (type == .faceID) ? "Face ID" : (type == .touchID ? "Touch ID" : "Biometrics")
        let alert = UIAlertController(title: typeName,
                                      message: "Use \(typeName) to sign in faster?",
                                      preferredStyle: .alert)
        
        // Not now: go straight to home without enabling
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: { [weak self] _ in
            self?.navigateToHome()
        }))
        
        // Enable: enable silently (no authenticator prompt) then go to home
        alert.addAction(UIAlertAction(title: "Enable", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            BiometricAuthManager.enableBiometricLogin(for: username, presenting: self, reason: "Authenticate to enable \(typeName)") { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // Toggle in Settings will reflect the enabled state via UserDefaults
                        NotificationCenter.default.post(name: .SessionChanged, object: nil)
                    case .failure(let error):
                        // Even if enabling fails, continue to home to avoid blocking registration flow
                        print("Failed to enable biometrics at registration: \(error.localizedDescription)")
                    }
                    self.navigateToHome()
                }
            }
        }))
        
        present(alert, animated: true)
    }
    
    func printAllUserProfiles() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()

        do {
            let users = try context.fetch(fetchRequest)

            if users.isEmpty {
                print("No users found.")
            } else {
                print("---- All Users ----")
                for (index, user) in users.enumerated() {
                    let username = user.username ?? "nil"
                    let password = user.password ?? "nil"
                    print("\(index + 1). Username: \(username), Password: \(password)")
                }
                print("-------------------")
            }
        } catch {
            print("❌ Failed to fetch users: \(error)")
        }
    }
 
    func fetchCaregivers() -> [Caregiver] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        
        do {
            let caregivers = try context.fetch(request)
            return caregivers
        } catch {
            print("Fetch failed: \(error)")
            return []
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        // Basic RFC 5322 compliant regex (practical subset)
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        // Enforce exactly 10 digits; ignore common formatting characters
        let digitsOnly = phone.filter { $0.isNumber }
        return digitsOnly.count == 10
    }
}

extension Notification.Name {
    static let SessionChanged = Notification.Name("SessionChanged")
}

struct ProfileImageStore {
    private static func key(for username: String) -> String { "CaregiverProfileImageData_\(username)" }

    static func save(_ image: UIImage, for username: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        UserDefaults.standard.set(data, forKey: key(for: username))
    }

    static func load(for username: String) -> UIImage? {
        guard let data = UserDefaults.standard.data(forKey: key(for: username)) else { return nil }
        return UIImage(data: data)
    }

    static func remove(for username: String) {
        UserDefaults.standard.removeObject(forKey: key(for: username))
    }
}

