import UIKit
import ContactsUI
import Contacts

// MARK: - Model
struct TrustedPerson: Codable, Equatable, Hashable {
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

        nameLabel.font = .systemFont(ofSize: 17)
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
            optionsButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        selectionStyle = .none
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    @objc private func optionsTap() { onOptionsTapped?() }
}

// MARK: - ViewController
final class TrustedPeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let storageKey = "trusted_people_storage_v1"
    private var trustedPeople: [TrustedPerson] = [] { didSet { savePeople() } }

    private let tableView = UITableView()

    private let addFromContactsButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add From Contacts", for: .normal)
        b.backgroundColor = .systemGreen
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let addButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Add Trusted Person", for: .normal)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 10
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        trustedPeople = loadPeople()

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TrustedPersonCell.self, forCellReuseIdentifier: "TrustedPersonCell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        view.addSubview(addButton)
        view.addSubview(addFromContactsButton)

        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 48),

            addFromContactsButton.topAnchor.constraint(equalTo: addButton.bottomAnchor, constant: 12),
            addFromContactsButton.leadingAnchor.constraint(equalTo: addButton.leadingAnchor),
            addFromContactsButton.trailingAnchor.constraint(equalTo: addButton.trailingAnchor),
            addFromContactsButton.heightAnchor.constraint(equalToConstant: 48),

            tableView.topAnchor.constraint(equalTo: addFromContactsButton.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        addButton.addTarget(self, action: #selector(addPersonTapped), for: .touchUpInside)
        addFromContactsButton.addTarget(self, action: #selector(addFromContactsTapped), for: .touchUpInside)
    }

    // MARK: - TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { trustedPeople.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let person = trustedPeople[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrustedPersonCell", for: indexPath) as! TrustedPersonCell
        cell.nameLabel.text = person.name
        cell.onOptionsTapped = { [weak self] in
            guard let self = self else { return }
            let menu = UIAlertController(title: person.name, message: nil, preferredStyle: .actionSheet)
            menu.addAction(UIAlertAction(title: "Edit", style: .default, handler: { _ in self.editPerson(at: indexPath.row) }))
            menu.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in self.deletePerson(at: indexPath.row) }))
            menu.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let pop = menu.popoverPresentationController {
                pop.sourceView = cell.optionsButton
                pop.sourceRect = cell.optionsButton.bounds
            }
            self.present(menu, animated: true)
        }
        return cell
    }

    // MARK: - Add / Edit
    @objc private func addPersonTapped() { presentAddOrEditAlert(title: "Add Trusted Person", existing: nil) { [weak self] newPerson in
        self?.trustedPeople.append(newPerson)
        self?.tableView.reloadData()
    }}

    private func editPerson(at index: Int) {
        presentAddOrEditAlert(title: "Edit Trusted Person", existing: trustedPeople[index]) { [weak self] updated in
            self?.trustedPeople[index] = updated
            self?.tableView.reloadData()
        }
    }

    private func deletePerson(at index: Int) {
        trustedPeople.remove(at: index)
        tableView.reloadData()
    }

    private func presentAddOrEditAlert(title: String, existing: TrustedPerson?, onSave: @escaping (TrustedPerson) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Full Name"; $0.text = existing?.name }
        alert.addTextField { $0.placeholder = "Phone Number"; $0.keyboardType = .phonePad; $0.text = existing?.phone }
        alert.addTextField { $0.placeholder = "Email"; $0.keyboardType = .emailAddress; $0.autocapitalizationType = .none; $0.text = existing?.email }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let name = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let phone = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let email = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty, !phone.isEmpty, !email.isEmpty
            else { return }
            onSave(TrustedPerson(name: name, phone: phone, email: email))
        })
        present(alert, animated: true)
    }

    // MARK: - Contacts
    @objc private func addFromContactsTapped() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    let picker = CNContactPickerViewController()
                    picker.delegate = self
                    self.present(picker, animated: true)
                } else {
                    let alert = UIAlertController(title: "Permission Denied", message: "Enable Contacts access in Settings", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    // MARK: - Storage
    private func savePeople() {
        if let data = try? JSONEncoder().encode(trustedPeople) { UserDefaults.standard.set(data, forKey: storageKey) }
    }
    private func loadPeople() -> [TrustedPerson] {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TrustedPerson].self, from: data) { return decoded }
        return []
    }
}

// MARK: - CNContactPickerDelegate
extension TrustedPeopleViewController: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
        let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
        let email = contact.emailAddresses.first?.value as String? ?? ""
        let newPerson = TrustedPerson(name: name, phone: phone, email: email)
        trustedPeople.append(newPerson)
        tableView.reloadData()
    }
}

