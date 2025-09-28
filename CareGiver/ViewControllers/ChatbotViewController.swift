import UIKit
import ChatGPTSwift

class ChatbotViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate {
    var currentCaregiver: Caregiver? // Required property to fix errors

    private let tableView = UITableView()
    private let messageInputContainer = UIView()
    private let messageTextView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendButton = UIButton(type: .system)
    private var messageInputBottomConstraint: NSLayoutConstraint!
    
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
        
        // Keyboard handling
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        // Tap anywhere to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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

        // Configure growing text view
        messageTextView.backgroundColor = .tertiarySystemBackground
        messageTextView.textColor = .label
        messageTextView.font = UIFont.preferredFont(forTextStyle: .body)
        messageTextView.isScrollEnabled = false
        messageTextView.delegate = self
        messageTextView.layer.cornerRadius = 8
        messageTextView.layer.masksToBounds = true
        messageTextView.textContainerInset = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainer.lineBreakMode = .byWordWrapping
        messageTextView.returnKeyType = .send
        // Disable hyphenation so lines don't end with dashes
        messageTextView.layoutManager.usesDefaultHyphenation = false
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 0
        var typingAttrs = messageTextView.typingAttributes
        typingAttrs[.paragraphStyle] = paragraphStyle
        messageTextView.typingAttributes = typingAttrs
        // Ensure the send button keeps its space
        messageTextView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        messageTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        messageTextView.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainer.addSubview(messageTextView)

        // Placeholder label to mimic UITextField placeholder
        placeholderLabel.text = "Type a message..."
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = UIFont.preferredFont(forTextStyle: .body)
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        messageTextView.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: messageTextView.leadingAnchor, constant: 10),
            placeholderLabel.topAnchor.constraint(equalTo: messageTextView.topAnchor, constant: 8),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: messageTextView.trailingAnchor, constant: -10)
        ])

        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        sendButton.setTitleColor(.systemIndigo, for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        messageInputContainer.addSubview(sendButton)
        
        sendButton.setContentHuggingPriority(.required, for: .horizontal)
        sendButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupConstraints() {
        messageInputBottomConstraint = messageInputContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        NSLayoutConstraint.activate([
            // Table view
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: messageInputContainer.topAnchor),

            // Input container
            messageInputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputBottomConstraint,
            messageInputContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),

            // Text view
            messageTextView.leadingAnchor.constraint(equalTo: messageInputContainer.leadingAnchor, constant: 10),
            messageTextView.topAnchor.constraint(equalTo: messageInputContainer.topAnchor, constant: 7),
            messageTextView.bottomAnchor.constraint(equalTo: messageInputContainer.bottomAnchor, constant: -7),
            messageTextView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),

            // Send button
            sendButton.trailingAnchor.constraint(equalTo: messageInputContainer.trailingAnchor, constant: -10),
            sendButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor)
        ])
    }

    @objc private func sendButtonTapped() {
        let userMessage = messageTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        // Add user message to the chat
        messages.append((userMessage, true))
        tableView.reloadData()
        messageTextView.text = ""
        placeholderLabel.isHidden = false
        
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

    @objc private func handleKeyboardNotification(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let endFrame = endFrameValue.cgRectValue
        let endFrameInView = view.convert(endFrame, from: view.window)
        let overlap = max(0, view.bounds.maxY - endFrameInView.origin.y)
        let safeBottom = view.safeAreaInsets.bottom

        // Move the input container up by the keyboard height (minus safe area if present)
        messageInputBottomConstraint.constant = -max(0, overlap - safeBottom)

        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            sendButtonTapped()
            return false
        }
        return true
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
