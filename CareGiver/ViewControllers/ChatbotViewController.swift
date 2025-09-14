import UIKit
import SafariServices

// MARK: - Chatbot View Controller (Keyword Bot)
class ChatbotViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var currentCaregiver: Caregiver? // Required property to fix errors

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

    // MARK: - TableView Setup
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
            sendButton.centerYAnchor.constraint(equalTo: messageInputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
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

        // Align text left or right
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

    // MARK: - Send Message
    @objc private func sendButtonTapped() {
        guard let text = messageTextField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }

        appendMessage(text, isUser: true)
        messageTextField.text = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let response = self.getBotResponse(for: text)
            self.appendMessage(response, isUser: false)
        }
    }

    private func appendMessage(_ text: String, isUser: Bool) {
        messages.append(Message(text: text, isUser: isUser))
        tableView.reloadData()

        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func getBotResponse(for userInput: String) -> String {
        let lower = userInput.lowercased()

        let keywordResponses: [(keywords: [String], response: String)] = [
            (["hello","hi","hey","greetings"], "Hello! How can I assist you today?"),
            (["medication","medicine","pill","dose","pharmacy"], "Remember to take your medication on time. Ask if you need help!"),
            (["stress","tired","overwhelmed","anxious","sad"], "Take breaks and practice self-care. You're doing great!"),
            (["help","support","assist","guide","advice"], "I'm here to help! What do you need assistance with?"),
            (["emergency","urgent","danger","911","accident"], "If this is an emergency, please call your local emergency services immediately."),
            (["thank","thanks","appreciate","grateful"], "You're welcome! Let me know if you need anything else."),
            (["goodbye","bye","see you","later","cya"], "Goodbye! Take care and reach out anytime."),
            (["appointment","doctor","clinic","checkup","hospital"], "Make sure to schedule regular appointments and follow doctor's instructions."),
            (["symptom","pain","fever","cough","headache"], "Monitor symptoms and contact a healthcare professional if needed."),
            (["nutrition","diet","food","meal","healthy"], "A balanced diet is important. Include fruits, vegetables, and enough water."),
            (["exercise","walk","stretch","fitness","movement"], "Regular exercise can help both you and your patient stay healthy."),
            (["sleep","rest","insomnia","nap","tired"], "Adequate rest is essential. Try to maintain a sleep routine."),
            (["appointment","schedule","calendar","reminder","plan"], "Use a planner or reminder app to keep track of schedules."),
            (["cleaning","housework","laundry","chores","tidy"], "Break tasks into small steps and take breaks as needed."),
            (["medicare","insurance","policy","coverage","claim"], "Check your insurance policy and contact the provider for details."),
            (["behavior","mood","temper","angry","sad"], "Observe patterns and provide comfort. Contact professionals if necessary."),
            (["safety","fall","hazard","risk","danger"], "Ensure the home is safe. Remove hazards and supervise activities if needed."),
            (["hydration","water","drink","thirsty","dehydrated"], "Keep hydrated. Drink enough water throughout the day."),
            (["emotional","support","therapy","counseling","mental"], "Seeking emotional support or counseling is always okay."),
            (["equipment","wheelchair","walker","cane","assistive"], "Check that all medical equipment is functioning properly."),
            (["reminder","alert","notification","alarm","timer"], "Set reminders for medication, appointments, and daily tasks."),
            (["appointment","doctor","dentist","eye","specialist"], "Keep track of all healthcare appointments."),
            (["temperature","blood pressure","heart rate","pulse","oxygen"], "Monitor vital signs regularly."),
            (["emergency","hospital","ambulance","911","urgent"], "Call emergency services if there is immediate danger."),
            (["calm","relax","breathe","meditation","mindfulness"], "Take a moment to breathe and relax."),
            (["family","friend","support","network","help"], "Reach out to your support network when needed."),
            (["insurance","coverage","plan","policy","claim"], "Review insurance coverage to avoid unexpected costs."),
            (["task","schedule","plan","organize","priority"], "Organize tasks by priority and take breaks."),
            (["symptoms","check","monitor","observe","health"], "Keep a log of symptoms and share with the doctor."),
            (["diet","nutrition","meal","healthy","food"], "Maintain a balanced diet for you and your patient."),
            (["exercise","walk","stretch","movement","fitness"], "Regular physical activity is beneficial."),
            (["sleep","rest","nap","bedtime","insomnia"], "Maintain a regular sleep schedule."),
            (["stress","anxiety","relaxation","calm","mental"], "Try mindfulness exercises or take a short break."),
            (["appointment","doctor","clinic","checkup","schedule"], "Ensure all appointments are noted and not missed."),
            (["question","ask","information","help","support"], "Feel free to ask me any questions."),
            (["danger","urgent","alert","emergency","risk"], "Call emergency services if required."),
            (["thank you","thanks","appreciate","grateful","ty"], "You're welcome!"),
            (["good night","bye","see you","later","cya"], "Goodbye! Take care."),
            (["hydration","drink","water","thirsty","fluid"], "Remember to drink water regularly."),
            (["medication","dose","pill","medicine","pharmacy"], "Take your medications as prescribed."),
            (["check","reminder","alert","task","note"], "Set reminders to stay organized."),
            (["mood","feel","happy","sad","tired"], "Keep track of feelings and take care of yourself."),
            (["support","help","assist","guide","care"], "I’m here to assist whenever needed."),
            (["emergency","911","urgent","danger","hospital"], "In emergencies, call for help immediately."),
            (["food","meal","snack","diet","nutrition"], "Eat balanced meals throughout the day."),
            (["exercise","movement","walk","stretch","fitness"], "Stay active daily for better health."),
            (["rest","sleep","nap","tired","insomnia"], "Ensure enough rest and sleep."),
            (["appointment","schedule","doctor","clinic","reminder"], "Keep track of appointments for better care."),
            (["family","friend","network","support","caregiver"], "Reach out for help from friends or family."),
        ]

        for (keywords, response) in keywordResponses {
            for keyword in keywords {
                if lower.contains(keyword) { return response }
            }
        }

        return "Sorry, I didn't understand that. Could you please rephrase?"
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
