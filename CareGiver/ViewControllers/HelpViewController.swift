import UIKit

// -----------------------------
// MARK: - HelpViewController
// -----------------------------
class HelpViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let searchController = UISearchController(searchResultsController: nil)

    // Data model for the help menu
    private let helpSections: [(title: String, items: [(title: String, icon: String, message: String)])] = [
        ("App Guide", [
            ("Overview", "book", "Welcome! This Help Center shows you how to use the app. You can search topics, browse FAQs, or contact support directly."),
            ("Navigation", "map", "Use the bottom tab bar to switch between Patients, Tasks, and Resources. Settings and Help are in the menu.")
        ]),
        ("Support", [
            ("FAQ", "questionmark.circle", "Browse frequently asked questions with detailed answers."),
            ("Contact Support", "phone", "Need help? Tap here to email or call us directly."),
            ("Send Feedback", "envelope", "Share suggestions or report issues to help us improve.")
        ])
    ]

    private var filteredSections: [(title: String, items: [(title: String, icon: String, message: String)])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        filteredSections = helpSections
        setupUI()
    }

    private func setupUI() {
        title = "Help & Support"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationController?.navigationBar.tintColor = .systemIndigo

        // search
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Help Topics"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        // table
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: Table datasource + delegate
extension HelpViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { filteredSections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredSections[section].items.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        filteredSections[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let item = filteredSections[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "HelpCell", for: indexPath)
        cell.textLabel?.text = item.title
        cell.imageView?.image = UIImage(systemName: item.icon)
        cell.imageView?.tintColor = .systemIndigo
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.numberOfLines = 0
        cell.backgroundColor = .secondarySystemBackground
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filteredSections[indexPath.section].items[indexPath.row]

        switch item.title {
        case "FAQ":
            navigationController?.pushViewController(CGHelpFAQViewController(), animated: true)
        case "Contact Support":
            navigationController?.pushViewController(CGSupportOptionsViewController(), animated: true)
        case "Send Feedback":
            navigationController?.pushViewController(CGFeedbackViewController(), animated: true)
        default:
            let vc = CGHelpDetailViewController(titleText: item.title, messageText: item.message)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: Search
extension HelpViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let q = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !q.isEmpty else {
            filteredSections = helpSections
            tableView.reloadData()
            return
        }

        filteredSections = helpSections.compactMap { section in
            let filtered = section.items.filter { item in
                item.title.lowercased().contains(q) || item.message.lowercased().contains(q)
            }
            return filtered.isEmpty ? nil : (title: section.title, items: filtered)
        }
        tableView.reloadData()
    }
}

// -----------------------------
// MARK: - Simple detail view
// -----------------------------
final class CGHelpDetailViewController: UIViewController {
    private let titleText: String
    private let messageText: String

    init(titleText: String, messageText: String) {
        self.titleText = titleText
        self.messageText = messageText
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = titleText
        view.backgroundColor = .systemBackground

        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.font = .systemFont(ofSize: 16)
        tv.text = messageText
        tv.backgroundColor = .systemBackground
        view.addSubview(tv)
        tv.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tv.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            tv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tv.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
    }
}

// -----------------------------
// MARK: - FAQ (unique name)
// -----------------------------
final class CGHelpFAQViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let faqs: [(q: String, a: String)] = [
        ("How do I add a patient?", "Go to Patients tab, tap +, and fill out the form."),
        ("How do I reset my password?", "Open Settings > Account > Reset Password.")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FAQs"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .systemIndigo
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CGFAQCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension CGHelpFAQViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { faqs.count }
    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "CGFAQCell", for: indexPath)
        cell.textLabel?.text = faqs[indexPath.row].q
        cell.textLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        let faq = faqs[indexPath.row]
        let vc = CGHelpDetailViewController(titleText: faq.q, messageText: faq.a)
        navigationController?.pushViewController(vc, animated: true)
        tv.deselectRow(at: indexPath, animated: true)
    }
}

// -----------------------------
// MARK: - Support (unique name)
// -----------------------------
final class CGSupportOptionsViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Support"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .systemIndigo

        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.text = "Contact support:\n\n• Email: support@example.com\n• Phone: 1-800-123-4567"

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
}

// -----------------------------
// MARK: - Feedback
// -----------------------------
final class CGFeedbackViewController: UIViewController {
    private let textView = UITextView()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Send Feedback"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .systemIndigo

        textView.font = .systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.text = ""

        let submit = UIButton(type: .system)
        submit.setTitle("Submit", for: .normal)
        submit.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        view.addSubview(textView)
        view.addSubview(submit)
        textView.translatesAutoresizingMaskIntoConstraints = false
        submit.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 200),

            submit.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 20),
            submit.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func submitTapped() {
        let trimmed = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            let a = UIAlertController(title: "Empty", message: "Please type feedback before submitting.", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }
        let a = UIAlertController(title: "Thanks", message: "Your feedback was submitted.", preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.navigationController?.popViewController(animated: true)
        })
        present(a, animated: true)
    }
}

