//
//  RegisterStep1ViewController.swift
//  CareGiver
//
//  Created by Shivank Ahuja on 8/10/25.
//

import UIKit
import CoreData
import CryptoKit


class RegisterStep1ViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    @IBOutlet weak var birthdayDatePicker: UIDatePicker!
    @IBOutlet weak var nextButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardDismissal()
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
         if let enteredUsername = usernameTextField.text,
            !enteredUsername.isEmpty,
            let enteredPassword = passwordTextField.text,
              enteredPassword.count >= 8 {
             
             
             guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
             let context = appDelegate.persistentContainer.viewContext
             
             do {
                 try createCaregiver()
                 
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
             present(alert, animated: true)
             return
         }
         
         
        
        printAllUserProfiles()
             
        let caregivers = fetchCaregivers()
        for c in caregivers {
            print("Username: \(c.username ?? "nil"), Password: \(c.password ?? "nil")")
        }

        
        self.performSegue(withIdentifier: "toMainPage", sender: self)
    }
             
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
        caregiver.username = usernameTextField.text
        caregiver.password = sha256(for: passwordTextField.text ?? "") // Hash the password
        caregiver.email = emailTextField.text
        caregiver.firstName = firstNameTextField.text
        caregiver.lastName = lastNameTextField.text  // This was at the end - move it up
        caregiver.phoneNumber = phoneNumberTextField.text
        
        // Check if your Core Data model uses 'birthday' or 'dateOfBirth'
        // In ProfileViewController you're looking for 'birthday', so use that:
        caregiver.dateOfBirth = birthdayDatePicker.date
        // OR if your model actually uses 'dateOfBirth', then update ProfileViewController
        
        // Add debug print to see what's being saved
        print("=== Saving Caregiver ===")
        print("Username: \(caregiver.username ?? "nil")")
        print("FirstName: \(caregiver.firstName ?? "nil")")
        print("LastName: \(caregiver.lastName ?? "nil")")
        print("Email: \(caregiver.email ?? "nil")")
        print("Phone: \(caregiver.phoneNumber ?? "nil")")
        print("Birthday: \(caregiver.dateOfBirth?.description ?? "nil")")
        print("========================")

        try context.save()
        UserDefaults.standard.set(caregiver.username, forKey: "LoggedInUsername")
        UserDefaults.standard.synchronize()
        
        print("Caregiver saved successfully!")
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

