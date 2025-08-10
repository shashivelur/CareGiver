import UIKit
import SafariServices

// MARK: - Main Chatbot View Controller

class ChatbotViewController: UIViewController {
    
    var currentCaregiver: Caregiver? // Your existing Caregiver model
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Chatbot"
        view.backgroundColor = .systemBackground
        
        // Create buttons
        let buttons = [
            ("View Common FAQs", #selector(openFAQs)),
            ("View Resource Links", #selector(openResources)),
            ("Emotional Support", #selector(openEmotionalSupport)),
            ("Chat with Support", #selector(openChatSupport)),
            ("Community Forum", #selector(openCommunityForum))
        ]
        
        var previousButton: UIButton? = nil
        
        for (title, selector) in buttons {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            button.backgroundColor = UIColor.systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 10
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: selector, for: .touchUpInside)
            view.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                button.widthAnchor.constraint(equalToConstant: 240),
                button.heightAnchor.constraint(equalToConstant: 50),
            ])
            
            if let prev = previousButton {
                button.topAnchor.constraint(equalTo: prev.bottomAnchor, constant: 20).isActive = true
            } else {
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80).isActive = true
            }
            
            previousButton = button
        }
    }
    
    @objc private func openFAQs() {
        let faqVC = FAQViewController()
        navigationController?.pushViewController(faqVC, animated: true)
    }
    
    @objc private func openResources() {
        let resourcesVC = ResourceLinksViewController()
        navigationController?.pushViewController(resourcesVC, animated: true)
    }
    
    @objc private func openEmotionalSupport() {
        let emotionalVC = EmotionalSupportViewController()
        navigationController?.pushViewController(emotionalVC, animated: true)
    }
    
    @objc private func openChatSupport() {
        let chatVC = ChatSupportViewController()
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    @objc private func openCommunityForum() {
        let forumVC = CommunityForumViewController()
        navigationController?.pushViewController(forumVC, animated: true)
    }
}

// MARK: - FAQ View Controller

class FAQViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let faqs = [
        ("How do I manage medication schedules?", "Use a pill organizer and set daily reminders to ensure medications are taken on time."),
        ("What should I do if the patient has a fever?", "Monitor their temperature, keep them hydrated, and contact a healthcare professional if it gets too high."),
        ("How can I reduce caregiver stress?", "Take regular breaks, ask for help when needed, and practice self-care activities."),
        ("When should I call emergency services?", "If the patient experiences severe difficulty breathing, chest pain, or loss of consciousness, call emergency services immediately.")
    ]
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Common FAQs"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FAQCell")
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        faqs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "FAQCell", for: indexPath)
        cell.textLabel?.text = faqs[indexPath.row].0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let answer = faqs[indexPath.row].1
        let alert = UIAlertController(title: "Answer", message: answer, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Resource Links View Controller

class ResourceLinksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let resources = [
        ("Caregiver Support Network", "https://www.caregiver.org/"),
        ("MedlinePlus - Caregiving", "https://medlineplus.gov/caregiving.html"),
        ("National Institute on Aging", "https://www.nia.nih.gov/health/caregiving"),
        ("Family Caregiver Alliance", "https://www.caregiver.org/resource/caregiver-health/")
    ]
    
    let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Resource Links"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ResourceCell")
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        resources.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ResourceCell", for: indexPath)
        cell.textLabel?.text = resources[indexPath.row].0
        cell.textLabel?.textColor = .systemBlue
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let urlString = resources[indexPath.row].1
        if let url = URL(string: urlString) {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Emotional Support View Controller

class EmotionalSupportViewController: UIViewController {
    
    let motivationalQuotes = [
        "You are stronger than you think.",
        "Every day is a new beginning.",
        "Your care makes a difference.",
        "Take it one step at a time.",
        "Remember to take care of yourself too."
    ]
    
    let quoteLabel = UILabel()
    let questionLabel = UILabel()
    let buttonsStackView = UIStackView()
    let historyButton = UIButton(type: .system)
    
    var checkInHistory: [(feeling: String, date: Date)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Emotional Support"
        view.backgroundColor = .systemBackground
        
        setupUI()
        showRandomQuote()
    }
    
    private func setupUI() {
        quoteLabel.font = UIFont.italicSystemFont(ofSize: 22)
        quoteLabel.textColor = .systemBlue
        quoteLabel.numberOfLines = 0
        quoteLabel.textAlignment = .center
        quoteLabel.translatesAutoresizingMaskIntoConstraints = false
        
        questionLabel.text = "How are you feeling today?"
        questionLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        questionLabel.textAlignment = .center
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        buttonsStackView.axis = .horizontal
        buttonsStackView.alignment = .center
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.spacing = 20
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let goodButton = createButton(title: "Good", color: .systemGreen)
        goodButton.addTarget(self, action: #selector(feelingButtonTapped(_:)), for: .touchUpInside)
        let okayButton = createButton(title: "Okay", color: .systemOrange)
        okayButton.addTarget(self, action: #selector(feelingButtonTapped(_:)), for: .touchUpInside)
        let notGreatButton = createButton(title: "Not Great", color: .systemRed)
        notGreatButton.addTarget(self, action: #selector(feelingButtonTapped(_:)), for: .touchUpInside)
        
        buttonsStackView.addArrangedSubview(goodButton)
        buttonsStackView.addArrangedSubview(okayButton)
        buttonsStackView.addArrangedSubview(notGreatButton)
        
        historyButton.setTitle("View Past Check-Ins", for: .normal)
        historyButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        historyButton.translatesAutoresizingMaskIntoConstraints = false
        historyButton.addTarget(self, action: #selector(showHistory), for: .touchUpInside)
        
        view.addSubview(quoteLabel)
        view.addSubview(questionLabel)
        view.addSubview(buttonsStackView)
        view.addSubview(historyButton)
        
        NSLayoutConstraint.activate([
            quoteLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            quoteLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            quoteLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            questionLabel.topAnchor.constraint(equalTo: quoteLabel.bottomAnchor, constant: 40),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            buttonsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 30),
            buttonsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 50),
            buttonsStackView.widthAnchor.constraint(equalToConstant: 300),
            
            historyButton.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 40),
            historyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            historyButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func createButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = color
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return btn
    }
    
    private func showRandomQuote() {
        quoteLabel.text = "\"\(motivationalQuotes.randomElement() ?? "")\""
    }
    
    @objc private func feelingButtonTapped(_ sender: UIButton) {
        guard let title = sender.currentTitle else { return }
        var message = ""
        
        switch title {
        case "Good":
            message = "That's awesome! Keep taking care of yourself."
        case "Okay":
            message = "Thanks for sharing. Remember, it's okay to take breaks."
        case "Not Great":
            message = "Hang in there! Consider reaching out to friends or professionals."
        default:
            break
        }
        
        // Record the response with current date
        checkInHistory.append((feeling: title, date: Date()))
        
        let alert = UIAlertController(title: "Support", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Thanks", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showHistory() {
        let historyVC = CheckInHistoryViewController()
        historyVC.history = checkInHistory
        navigationController?.pushViewController(historyVC, animated: true)
    }
}

// MARK: - Check-In History View Controller

class CheckInHistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var history: [(feeling: String, date: Date)] = []
    let tableView = UITableView()
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Past Check-Ins"
        view.backgroundColor = .systemBackground
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.frame = view.bounds
        view.addSubview(tableView)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        let entry = history[indexPath.row]
        let dateStr = dateFormatter.string(from: entry.date)
        cell.textLabel?.text = "\(entry.feeling) — \(dateStr)"
        return cell
    }
}

// MARK: - Chat Support View Controller

class ChatSupportViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
    struct Message {
        let text: String
        let isUser: Bool
    }
    
    private var messages: [Message] = []
    
    private let tableView = UITableView()
    private let messageInputContainer = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chat with Support"
        view.backgroundColor = .systemBackground
        
        setupTableView()
        setupInputComponents()
        setupConstraints()
        
        // Dismiss keyboard on tap outside
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }
    
    private func setupInputComponents() {
        messageInputContainer.backgroundColor = UIColor(white: 0.95, alpha: 1)
        messageInputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageInputContainer)
        
        messageTextField.placeholder = "Type a message..."
        messageTextField.borderStyle = .roundedRect
        messageTextField.delegate = self
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainer.addSubview(messageTextField)
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainer.addSubview(sendButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view top, left, right
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Bottom is top of message input container
            tableView.bottomAnchor.constraint(equalTo: messageInputContainer.topAnchor),
            
            // Input container left, right, bottom
            messageInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // Text field left, centerY, right to send button
            messageTextField.leadingAnchor.constraint(equalTo: messageInputContainer.leadingAnchor, constant: 10),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageTextField.heightAnchor.constraint(equalToConstant: 36),
            
            // Send button right, centerY, fixed width
            sendButton.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -10),
            sendButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        cell.textLabel?.text = message.text
        cell.textLabel?.numberOfLines = 0
        
        // Align text left or right depending on sender
        if message.isUser {
            cell.textLabel?.textAlignment = .right
            cell.textLabel?.textColor = .systemBlue
        } else {
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.textColor = .label
        }
        cell.selectionStyle = .none
        return cell
    }
    
    // MARK: - Send message
    
    @objc private func sendButtonTapped() {
        guard let text = messageTextField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        appendMessage(text, isUser: true)
        messageTextField.text = ""
        
        // Simulate bot response after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let lowercased = text.lowercased()
            var response = "Sorry, I didn't understand that."
            
            if lowercased.contains("hello") || lowercased.contains("hi") {
                response = "Hello! How can I assist you today?"
            } else if lowercased.contains("medication") {
                response = "Remember to take your medication on time!"
            } else if lowercased.contains("help") {
                response = "I'm here to help! What do you need assistance with?"
            }
            
            self.appendMessage(response, isUser: false)
        }
    }
    
    private func appendMessage(_ text: String, isUser: Bool) {
        messages.append(Message(text: text, isUser: isUser))
        tableView.reloadData()
        
        // Scroll to bottom
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return true
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

// MARK: - Community Forum View Controller

class CommunityForumViewController: UIViewController {
    
    let descriptionLabel = UILabel()
    let forumLinkButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Community Forum"
        view.backgroundColor = .systemBackground
        
        setupUI()
    }
    
    private func setupUI() {
        descriptionLabel.text = """
        Welcome to the Community Forum!
        
        Here, caregivers share advice, support each other, and discuss challenges.
        
        Tap the button below to visit the official forum site.
        """
        descriptionLabel.font = UIFont.systemFont(ofSize: 18)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .label
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        forumLinkButton.setTitle("Go to Forum", for: .normal)
        forumLinkButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        forumLinkButton.backgroundColor = .systemBlue
        forumLinkButton.setTitleColor(.white, for: .normal)
        forumLinkButton.layer.cornerRadius = 12
        forumLinkButton.translatesAutoresizingMaskIntoConstraints = false
        forumLinkButton.addTarget(self, action: #selector(openForumURL), for: .touchUpInside)
        
        view.addSubview(descriptionLabel)
        view.addSubview(forumLinkButton)
        
        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            descriptionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            
            forumLinkButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 30),
            forumLinkButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            forumLinkButton.widthAnchor.constraint(equalToConstant: 160),
            forumLinkButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func openForumURL() {
        guard let url = URL(string: "https://www.caregiver.org/community-forum") else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    
    
}


















































































































































































































































































































































































































































































































































































































































































































































