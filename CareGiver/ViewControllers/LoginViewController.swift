import UIKit
import CoreData

class LoginViewController: UIViewController {
    
    private var usernameTextField: UITextField!
    private var loginButton: UIButton!
    private var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Configure the view
        view.backgroundColor = .systemBackground
        title = "CareGiver App"
        
        // Create UI elements
        createUIElements()
        setupConstraints()
    }
    
    private func createUIElements() {
        // Username text field
        usernameTextField = UITextField()
        usernameTextField.placeholder = "Username"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // Login button
        loginButton = UIButton(type: .system)
        loginButton.setTitle("Login", for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Register button
        registerButton = UIButton(type: .system)
        registerButton.setTitle("Register New Caregiver", for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.backgroundColor = .systemGreen
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to view
        view.addSubview(usernameTextField)
        view.addSubview(loginButton)
        view.addSubview(registerButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Username field
            usernameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            usernameTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Login button
            loginButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            loginButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Register button
            registerButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            registerButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    
    @objc private func loginButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty else {
            showAlert(message: "Please enter a username")
            return
        }
        
        // Check if caregiver exists
        if let caregiver = CoreDataManager.shared.findCaregiver(username: username) {
            // Login successful, navigate to main app
            navigateToMainApp(caregiver: caregiver)
        } else {
            showAlert(message: "Caregiver not found. Please register first.")
        }
    }
    
    @objc private func registerButtonTapped() {
        // Navigate to registration screen programmatically
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    private func navigateToMainApp(caregiver: Caregiver) {
        let mainTabBarController = MainTabBarController()
        mainTabBarController.currentCaregiver = caregiver
        
        // Create a new navigation controller with the tab bar controller as root
        let navController = UINavigationController(rootViewController: mainTabBarController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
