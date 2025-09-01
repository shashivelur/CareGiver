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
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
         if let enteredUsername = usernameTextField.text,
            !enteredUsername.isEmpty,
            let enteredPassword = passwordTextField.text,
              enteredPassword.count >= 8 {
             
             
             guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
             let context = appDelegate.persistentContainer.viewContext
             
             do {
                 try createCaregiver(username: enteredUsername, password: enteredPassword)
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
    
    func createCaregiver(username: String, password: String) throws {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        // If you generated NSManagedObject subclasses, you can use Caregiver directly:
        let caregiver = Caregiver(context: context)
        caregiver.username = username
        caregiver.password = password  // for production: store in Keychain instead

        try context.save()
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
    
    
    




