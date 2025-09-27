import UIKit
import ChatGPTSwift

class ChatbotViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var currentCaregiver: Caregiver? // Required property to fix errors

    private let tableView = UITableView()
    private let messageInputContainer = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    
    private var messages: [(String, Bool)] = [] // (Message, isUser)
    private var chatGPTAPI: ChatGPTAPI?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        // Initialize ChatGPTAPI with your API key
        chatGPTAPI = ChatGPTAPI(apiKey: "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")
        
        setupTableView()
        setupInputComponents()
        setupConstraints()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        view.addSubview(tableView)
    }

    private func setupInputComponents() {
        messageInputContainer.backgroundColor = .secondarySystemBackground
        messageInputContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageInputContainer)

        messageTextField.placeholder = "Type a message..."
        messageTextField.borderStyle = .roundedRect
        messageTextField.delegate = self
        messageTextField.textColor = .label
        messageTextField.backgroundColor = .tertiarySystemBackground
        messageTextField.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainer.addSubview(messageTextField)

        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sendButton.tintColor = .systemBlue
        sendButton.setTitleColor(.systemBlue, for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainer.addSubview(sendButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputContainer.topAnchor),

            // Input container
            messageInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputContainer.heightAnchor.constraint(equalToConstant: 50),

            // Text field
            messageTextField.leadingAnchor.constraint(equalTo: messageInputContainer.leadingAnchor, constant: 10),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            messageTextField.heightAnchor.constraint(equalToConstant: 36),

            // Send button
            sendButton.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -10),
            sendButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor)
        ])
    }

    @objc private func sendButtonTapped() {
        guard let userMessage = messageTextField.text, !userMessage.isEmpty else { return }
        
        // Add user message to the chat
        messages.append((userMessage, true))
        tableView.reloadData()
        messageTextField.text = ""
        
        // Send the message to ChatGPT API
        Task {
            do {
                if let response = try await chatGPTAPI?.sendMessage(text:userMessage) {
                    DispatchQueue.main.async {
                        // Add ChatGPT response to the chat
                        self.messages.append((response, false))
                        self.tableView.reloadData()
                        self.scrollToBottom()
                    }
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }

    private func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let message = messages[indexPath.row]
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.textLabel?.text = message.0
        cell.textLabel?.textColor = .label
        cell.textLabel?.textAlignment = message.1 ? .right : .left
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}

