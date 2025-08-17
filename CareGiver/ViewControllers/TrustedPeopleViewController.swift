import UIKit

// MARK: - Model
struct TrustedPerson: Codable, Equatable {
    var name: String
    var phone: String
    var email: String
}

// MARK: - Cell
final class TrustedPersonCell: UITableViewCell {
    let nameLabel = UILabel()
    let optionsButton = UIButton(type: .system)

    var onOptionsTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel.font = .systemFont(ofSize: 17, weight: .regular)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        optionsButton.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        optionsButton.translatesAutoresizingMaskIntoConstraints = false
        optionsButton.addTarget(self, action: #selector(optionsTap), for: .touchUpInside)

        contentView.addSubview(nameLabel)
        contentView.addSubview(optionsButton)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.widthAnchor.constraint(equalToConstant: 32),
            optionsButton.heightAnchor.constraint(equalToConstant: 32),
        ])
        selectionStyle = .none
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func optionsTap() { onOptionsTapped?() }
}

// MARK: - View Controller
final class TrustedPeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // Simple persistence (UserDefaults)
    private let storageKey = "trusted_people_storage_v1"

    private var trustedPeople: [TrustedPerson] = [] {
        didSet { savePeople() }
    }

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Trusted People"
        l.font = .boldSystemFont(ofSize: 22)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        b.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        b.tintColor = .secondaryLabel
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Trusted Person", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = .systemBlue
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 10
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let sectionLabel: UILabel = {
        let l = UILabel()
        l.text = "Trusted People"
        l.font = .boldSystemFont(ofSize: 17)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.tableFooterView = UIView()
        return t
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // Load saved people
        trustedPeople = loadPeople()

        // Top bar
        view.addSubview(titleLabel)
        view.addSubview(closeButton)

        // Stack
        let stack = UIStackView(arrangedSubviews: [addButton, sectionLabel, tableView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])

        // Table setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TrustedPersonCell.self, forCellReuseIdentifier: "TrustedPersonCell")

        // Actions
        addButton.addTarget(self, action: #selector(addPersonTapped), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    // MARK: Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func addPersonTapped() {
        presentAddOrEditAlert(title: "Add Trusted Person", existing: nil) { [weak self] newPerson in
            guard let self = self else { return }
            self.trustedPeople.append(newPerson)
            self.tableView.reloadData()
        }
    }

    private func editPerson(at index: Int) {
        let person = trustedPeople[index]
        presentAddOrEditAlert(title: "Edit Trusted Person", existing: person) { [weak self] updated in
            guard let self = self else { return }
            self.trustedPeople[index] = updated
            self.tableView.reloadData()
        }
    }

    private func deletePerson(at index: Int) {
        trustedPeople.remove(at: index)
        tableView.reloadData()
    }

    // MARK: Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trustedPeople.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let person = trustedPeople[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrustedPersonCell", for: indexPath) as! TrustedPersonCell
        cell.nameLabel.text = person.name
        cell.onOptionsTapped = { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }
            let menu = UIAlertController(title: person.name, message: nil, preferredStyle: .actionSheet)
            menu.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in
                self.editPerson(at: indexPath.row)
            }))
            menu.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.deletePerson(at: indexPath.row)
            }))
            menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            // iPad popover anchor
            if let pop = menu.popoverPresentationController {
                pop.sourceView = cell.optionsButton
                pop.sourceRect = cell.optionsButton.bounds
            }
            self.present(menu, animated: true)
        }
        return cell
    }

    // MARK: Small popup (like your Add Task) using UIAlertController
    private func presentAddOrEditAlert(title: String,
                                       existing: TrustedPerson?,
                                       onSave: @escaping (TrustedPerson) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        alert.addTextField { tf in
            tf.placeholder = "Full Name"
            tf.text = existing?.name
        }
        alert.addTextField { tf in
            tf.placeholder = "Phone Number"
            tf.keyboardType = .phonePad
            tf.text = existing?.phone
        }
        alert.addTextField { tf in
            tf.placeholder = "Email Address"
            tf.keyboardType = .emailAddress
            tf.autocapitalizationType = .none
            tf.text = existing?.email
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            let name  = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let phone = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let email = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty, !phone.isEmpty, !email.isEmpty else { return }
            onSave(TrustedPerson(name: name, phone: phone, email: email))
        }))

        present(alert, animated: true)
    }

    // MARK: Persistence
    private func savePeople() {
        do {
            let data = try JSONEncoder().encode(trustedPeople)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save trusted people: \(error)")
        }
    }

    private func loadPeople() -> [TrustedPerson] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        do {
            return try JSONDecoder().decode([TrustedPerson].self, from: data)
        } catch {
            print("Failed to load trusted people: \(error)")
            return []
        }
    }
}
