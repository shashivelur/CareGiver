import UIKit
import PhotosUI
import SwiftUI

class PrescriptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PHPickerViewControllerDelegate {
    private var tableView: UITableView!
    private var prescriptions: [Prescription] = []
    private let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
    private var selectedImage: UIImage?
    private var selectedWeekdays: Set<Int> = [] // 1=Sunday ... 7=Saturday per Calendar

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Prescriptions"
        view.backgroundColor = .systemBackground
        setupTableView()
        addButton.target = self
        addButton.action = #selector(addPrescriptionTapped)
        navigationItem.rightBarButtonItem = addButton
        loadPrescriptions()
    }

    // MARK: Table setup
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PrescriptionCell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { prescriptions.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PrescriptionCell", for: indexPath)
        let prescription = prescriptions[indexPath.row]
        cell.textLabel?.text = prescription.title
        // Do not show an image on the base prescriptions list
        cell.imageView?.image = nil
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showPrescriptionDetail(for: prescriptions[indexPath.row])
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Add Prescription
    @objc private func addPrescriptionTapped() {
        showPrescriptionEditor(for: nil)
    }

    // MARK: - CRUD
    private func showPrescriptionEditor(for prescription: Prescription?) {
        let editor = PrescriptionEditorViewController(prescription: prescription,
                                                      initialImage: prescription?.photo,
                                                      initialWeekdays: Set(prescription?.repeatWeekdays ?? []))
        editor.onCancel = { [weak self] in self?.dismiss(animated: true) }
        editor.onConfirm = { [weak self] title, notes, weekdays, image, editingId in
            guard let self = self else { return }
            var newPrescription = prescription ?? Prescription(title: title, repeatWeekdays: weekdays.sorted(), notes: notes, photo: image)
            newPrescription.title = title
            newPrescription.notes = notes
            newPrescription.photo = image
            newPrescription.repeatWeekdays = weekdays.sorted()
            if let editingId = editingId, let idx = self.prescriptions.firstIndex(where: { $0.id == editingId }) {
                newPrescription.id = editingId
                self.prescriptions[idx] = newPrescription
            } else if prescription != nil, let idx = self.prescriptions.firstIndex(where: { $0.id == newPrescription.id }) {
                self.prescriptions[idx] = newPrescription
            } else {
                self.prescriptions.append(newPrescription)
            }
            self.savePrescriptions()
            self.tableView.reloadData()
            self.dismiss(animated: true)
        }
        let nav = UINavigationController(rootViewController: editor)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Detail
    private func showPrescriptionDetail(for prescription: Prescription) {
        let detail = PrescriptionDetailViewController(prescription: prescription)
        navigationController?.pushViewController(detail, animated: true)
    }

    private func deletePrescription(_ prescription: Prescription) {
        prescriptions.removeAll(where: { $0.id == prescription.id })
        savePrescriptions()
        tableView.reloadData()
    }

    // MARK: - Persistence (UserDefaults for prototype)
    private func loadPrescriptions() {
        if let data = UserDefaults.standard.data(forKey: "prescriptions_v1"),
            let decoded = try? JSONDecoder().decode([Prescription].self, from: data) {
            prescriptions = decoded
        }
    }
    private func savePrescriptions() {
        if let data = try? JSONEncoder().encode(prescriptions) {
            UserDefaults.standard.set(data, forKey: "prescriptions_v1")
        }
    }
    // MARK: - PHPicker Delegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let self = self, let img = obj as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedImage = img
                // No alert controller update needed anymore
            }
        }
    }
}

// MARK: - Prescription model (simple struct for demo)
struct Prescription: Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var repeatWeekdays: [Int] // 1=Sunday ... 7=Saturday
    var notes: String?
    var photoData: Data?
    var photo: UIImage? {
        get { photoData.flatMap { UIImage(data: $0) } }
        set { photoData = newValue?.jpegData(compressionQuality: 0.8) }
    }

    init(title: String, repeatWeekdays: [Int], notes: String?, photo: UIImage?) {
        self.title = title
        self.repeatWeekdays = repeatWeekdays
        self.notes = notes
        self.photo = photo
    }
}

final class PrescriptionDetailViewController: UIViewController {
    private let prescription: Prescription

    init(prescription: Prescription) {
        self.prescription = prescription
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = prescription.title
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: prescription.photo ?? UIImage(systemName: "pills"))
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: 160).isActive = true

        let notesLabel = UILabel()
        notesLabel.numberOfLines = 0
        notesLabel.text = "Notes: \(prescription.notes ?? "-")"

        let nextDateLabel = UILabel()
        nextDateLabel.font = .preferredFont(forTextStyle: .headline)
        nextDateLabel.text = "Next dose: \(nextDueDateString(for: prescription))"

        stack.addArrangedSubview(imageView)
        stack.addArrangedSubview(notesLabel)
        stack.addArrangedSubview(nextDateLabel)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
    }

    private func nextDueDateString(for prescription: Prescription) -> String {
        let cal = Calendar.current
        let today = Date()
        let todayWeekday = cal.component(.weekday, from: today)
        let sorted = prescription.repeatWeekdays.sorted()
        if let sameOrNext = sorted.first(where: { $0 >= todayWeekday }) {
            if sameOrNext == todayWeekday {
                // today; show today
                return DateFormatter.localizedString(from: today, dateStyle: .medium, timeStyle: .none)
            } else {
                if let nextDate = cal.nextDate(after: today, matching: DateComponents(weekday: sameOrNext), matchingPolicy: .nextTimePreservingSmallerComponents) {
                    return DateFormatter.localizedString(from: nextDate, dateStyle: .medium, timeStyle: .none)
                }
            }
        }
        // Wrap to next week's first day
        if let first = sorted.first, let nextDate = cal.nextDate(after: today, matching: DateComponents(weekday: first), matchingPolicy: .nextTimePreservingSmallerComponents) {
            return DateFormatter.localizedString(from: nextDate, dateStyle: .medium, timeStyle: .none)
        }
        return "-"
    }
}

final class PrescriptionEditorViewController: UIViewController, PHPickerViewControllerDelegate {
    var onCancel: (() -> Void)?
    var onConfirm: ((_ title: String, _ notes: String?, _ weekdays: Set<Int>, _ image: UIImage?, _ editingId: String?) -> Void)?

    private let titleField = UITextField()
    private let notesField = UITextField()
    private let imagePreview = UIImageView()
    private let addPhotoButton = UIButton(type: .system)
    private var weekdayButtons: [UIButton] = []

    private var selectedImage: UIImage?
    private var selectedWeekdays: Set<Int>
    private let editingId: String?
    private let isEdit: Bool

    init(prescription: Prescription?, initialImage: UIImage?, initialWeekdays: Set<Int>) {
        self.selectedImage = initialImage
        self.selectedWeekdays = initialWeekdays
        self.editingId = prescription?.id
        self.isEdit = (prescription != nil)
        super.init(nibName: nil, bundle: nil)
        self.title = isEdit ? "Edit Prescription" : "New Prescription"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavBar()
        setupLayout()

        if let id = editingId {
            // Attempt to prefill using provided context (title/notes already accessible via init caller if needed)
            // For now, fields are empty by default; can be set if needed by extending init.
        }
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: isEdit ? "Save" : "Add", style: .done, target: self, action: #selector(confirmTapped))
        navigationController?.navigationBar.tintColor = .systemIndigo
    }

    private func setupLayout() {
        let scroll = UIScrollView()
        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 16
        content.alignment = .fill

        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        // Title
        let titleContainer = UIView()
        let titleLabel = UILabel()
        titleLabel.text = "Title"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        titleField.borderStyle = .roundedRect
        titleField.placeholder = "Title"
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.text = isEdit ? (editingId.flatMap { id in
            // If needed, prefill title here by caller or by looking up model externally.
            // No direct model available here, so left blank.
            return nil
        } ?? "") : ""

        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(titleField)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            titleField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            titleField.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor),
            titleField.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            titleField.heightAnchor.constraint(equalToConstant: 44)
        ])
        content.addArrangedSubview(titleContainer)

        // Notes
        let notesContainer = UIView()
        let notesLabel = UILabel()
        notesLabel.text = "Notes (optional)"
        notesLabel.font = .boldSystemFont(ofSize: 16)
        notesLabel.translatesAutoresizingMaskIntoConstraints = false

        notesField.borderStyle = .roundedRect
        notesField.placeholder = "Notes"
        notesField.translatesAutoresizingMaskIntoConstraints = false

        notesContainer.addSubview(notesLabel)
        notesContainer.addSubview(notesField)
        NSLayoutConstraint.activate([
            notesLabel.topAnchor.constraint(equalTo: notesContainer.topAnchor),
            notesLabel.leadingAnchor.constraint(equalTo: notesContainer.leadingAnchor),
            notesLabel.trailingAnchor.constraint(equalTo: notesContainer.trailingAnchor),
            notesField.topAnchor.constraint(equalTo: notesLabel.bottomAnchor, constant: 8),
            notesField.leadingAnchor.constraint(equalTo: notesContainer.leadingAnchor),
            notesField.trailingAnchor.constraint(equalTo: notesContainer.trailingAnchor),
            notesField.bottomAnchor.constraint(equalTo: notesContainer.bottomAnchor),
            notesField.heightAnchor.constraint(equalToConstant: 44)
        ])
        content.addArrangedSubview(notesContainer)

        // Photo row
        let photoContainer = UIStackView()
        photoContainer.axis = .horizontal
        photoContainer.alignment = .center
        photoContainer.spacing = 12

        imagePreview.image = selectedImage ?? UIImage(systemName: "pills")
        imagePreview.contentMode = .scaleAspectFill
        imagePreview.clipsToBounds = true
        imagePreview.layer.cornerRadius = 8
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        imagePreview.widthAnchor.constraint(equalToConstant: 64).isActive = true
        imagePreview.heightAnchor.constraint(equalToConstant: 64).isActive = true

        addPhotoButton.setTitle("Add Photo", for: .normal)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)

        photoContainer.addArrangedSubview(imagePreview)
        photoContainer.addArrangedSubview(addPhotoButton)
        content.addArrangedSubview(photoContainer)

        // Weekday selection
        let daysLabel = UILabel()
        daysLabel.text = "Repeat on"
        daysLabel.font = .boldSystemFont(ofSize: 16)
        content.addArrangedSubview(daysLabel)

        let daysStack = UIStackView()
        daysStack.axis = .horizontal
        daysStack.alignment = .fill
        daysStack.distribution = .fillEqually
        daysStack.spacing = 6

        let symbols = Calendar.current.shortWeekdaySymbols
        weekdayButtons = symbols.enumerated().map { (idx, sym) in
            let b = UIButton(type: .system)
            b.setTitle(sym, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            b.layer.cornerRadius = 8
            b.layer.borderWidth = 1
            b.layer.borderColor = UIColor.separator.cgColor
            b.tag = idx + 1
            b.addTarget(self, action: #selector(toggleWeekday(_:)), for: .touchUpInside)
            updateWeekdayButton(b)
            return b
        }
        weekdayButtons.forEach { daysStack.addArrangedSubview($0) }
        // Ensure initial selection state is applied to buttons
        for button in weekdayButtons {
            updateWeekdayButton(button)
        }
        content.addArrangedSubview(daysStack)

        // Prefill fields if editing (title/notes not available in this scope, leave as-is)
        if isEdit {
            // Caller can extend initializer to pass title/notes in the future.
            titleField.text = titleField.text ?? ""
            notesField.text = notesField.text ?? ""
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() { onCancel?() }

    @objc private func confirmTapped() {
        let title = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = notesField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !selectedWeekdays.isEmpty else { return }
        onConfirm?(title, notes, selectedWeekdays, selectedImage, editingId)
    }

    @objc private func addPhotoTapped() {
        let picker = PHPickerViewController(configuration: PHPickerConfiguration())
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func toggleWeekday(_ sender: UIButton) {
        let day = sender.tag
        if selectedWeekdays.contains(day) { selectedWeekdays.remove(day) } else { selectedWeekdays.insert(day) }
        updateWeekdayButton(sender)
    }

    private func updateWeekdayButton(_ button: UIButton) {
        let selected = selectedWeekdays.contains(button.tag)
        button.backgroundColor = selected ? UIColor.systemBlue.withAlphaComponent(0.15) : .clear
        button.setTitleColor(selected ? .systemBlue : .label, for: .normal)
    }

    // MARK: - PHPicker
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] obj, _ in
            guard let self = self, let img = obj as? UIImage else { return }
            DispatchQueue.main.async {
                self.selectedImage = img
                self.imagePreview.image = img
            }
        }
    }
}
