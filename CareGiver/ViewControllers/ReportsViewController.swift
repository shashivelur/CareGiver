import UIKit
import PhotosUI

// MARK: - Model
struct Report: Codable {
    var title: String
    var content: String
    var date: Date
    var isReviewed: Bool
    var images: [Data] // Photos as Data
}

// MARK: - Singleton Manager
class ReportsManager {
    static let shared = ReportsManager()
    private init() { loadReports() }

    private let reportsKey = "savedReports"
    var reports: [Report] = []

    func saveReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: reportsKey)
        }
    }

    func loadReports() {
        if let data = UserDefaults.standard.data(forKey: reportsKey),
           let savedReports = try? JSONDecoder().decode([Report].self, from: data) {
            self.reports = savedReports
        }
    }
}

// MARK: - Reports List View
class ReportsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var reports: [Report] {
        get { ReportsManager.shared.reports }
        set { ReportsManager.shared.reports = newValue }
    }

    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        updateEmptyState()
    }

    private func setupUI() {
        title = "Reports"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.tintColor = .systemIndigo

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addReportTapped)
        )
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reportCell")
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 100
        tableView.backgroundColor = .clear
    }

    // MARK: - Add Report
    @objc private func addReportTapped() {
        let editorVC = ReportEditorViewController()
        editorVC.onSave = { [weak self] report in
            self?.reports.insert(report, at: 0)
            ReportsManager.shared.saveReports()
            self?.updateEmptyState()
            self?.tableView.reloadData()
        }
        navigationController?.pushViewController(editorVC, animated: true)
    }

    // MARK: - TableView
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { reports.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reportCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        cell.selectionStyle = .default
        cell.backgroundColor = .secondarySystemBackground
        cell.contentView.backgroundColor = .secondarySystemBackground
        cell.accessoryType = .disclosureIndicator

        let report = reports[indexPath.row]

        // Status dot
        let statusDot = UIView()
        statusDot.backgroundColor = report.isReviewed ? .systemGreen : .systemYellow
        statusDot.layer.cornerRadius = 6
        statusDot.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(statusDot)

        // Title
        let titleLabel = UILabel()
        titleLabel.text = report.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(titleLabel)

        // Content preview
        let previewLabel = UILabel()
        previewLabel.text = report.content
        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(previewLabel)

        // Thumbnail scroll
        let thumbnailScroll = UIScrollView()
        thumbnailScroll.showsHorizontalScrollIndicator = false
        thumbnailScroll.backgroundColor = .clear
        thumbnailScroll.translatesAutoresizingMaskIntoConstraints = false
        thumbnailScroll.isUserInteractionEnabled = false
        cell.contentView.addSubview(thumbnailScroll)

        var lastThumbnail: UIView? = nil
        for imageData in report.images.prefix(5) {
            if let image = UIImage(data: imageData) {
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 6
                imageView.translatesAutoresizingMaskIntoConstraints = false
                thumbnailScroll.addSubview(imageView)

                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalToConstant: 50),
                    imageView.heightAnchor.constraint(equalToConstant: 50),
                    imageView.topAnchor.constraint(equalTo: thumbnailScroll.topAnchor),
                    imageView.bottomAnchor.constraint(equalTo: thumbnailScroll.bottomAnchor),
                    imageView.leadingAnchor.constraint(equalTo: lastThumbnail?.trailingAnchor ?? thumbnailScroll.leadingAnchor, constant: lastThumbnail == nil ? 0 : 8)
                ])
                lastThumbnail = imageView
            }
        }
        if let last = lastThumbnail {
            last.trailingAnchor.constraint(equalTo: thumbnailScroll.trailingAnchor).isActive = true
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            statusDot.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            statusDot.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
            statusDot.widthAnchor.constraint(equalToConstant: 12),
            statusDot.heightAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -30),
            titleLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),

            previewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            previewLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            thumbnailScroll.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            thumbnailScroll.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            thumbnailScroll.topAnchor.constraint(equalTo: previewLabel.bottomAnchor, constant: 4),
            thumbnailScroll.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let report = reports[indexPath.row]
        let editorVC = ReportEditorViewController(report: report)
        editorVC.onSave = { [weak self] updatedReport in
            self?.reports[indexPath.row] = updatedReport
            ReportsManager.shared.saveReports()
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        navigationController?.pushViewController(editorVC, animated: true)
    }

    // MARK: - Swipe Actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
            self.reports.remove(at: indexPath.row)
            ReportsManager.shared.saveReports()
            self.updateEmptyState()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }

        let review = UIContextualAction(style: .normal, title: "Reviewed") { _, _, completion in
            self.reports[indexPath.row].isReviewed.toggle()
            ReportsManager.shared.saveReports()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        review.backgroundColor = .systemIndigo

        return UISwipeActionsConfiguration(actions: [delete, review])
    }

    private func updateEmptyState() {
        if reports.isEmpty {
            let label = UILabel()
            label.text = "📝 No reports yet. Tap + to create one!"
            label.textColor = .secondaryLabel
            label.font = .systemFont(ofSize: 16)
            label.textAlignment = .center
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }
}

// MARK: - Report Editor with Photos
class ReportEditorViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var report: Report?
    var onSave: ((Report) -> Void)?
    
    private let mediaContainer = UIView()
    private let primaryImageView = UIImageView()
    private let addPhotoButton = UIButton(type: .system)
    private var mediaHeightConstraint: NSLayoutConstraint?
    private var imageAspectConstraint: NSLayoutConstraint?
    
    private let titleField = UITextField()
    private let textView = UITextView()
    private var images: [UIImage] = []
    
    init(report: Report? = nil) {
        self.report = report
        super.init(nibName: nil, bundle: nil)
        if let reportImages = report?.images {
            self.images = reportImages.compactMap { UIImage(data: $0) }
        }
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.tintColor = .systemIndigo
        setupUI()
    }
    
    private func setupUI() {
        title = "Report"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        navigationItem.rightBarButtonItem?.tintColor = .systemIndigo
        
        titleField.placeholder = "Title"
        titleField.font = .systemFont(ofSize: 20, weight: .bold)
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.text = report?.title
        view.addSubview(titleField)
        
        textView.font = .systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = report?.content
        view.addSubview(textView)
        
        addPhotoButton.setTitle("Add Photo", for: .normal)
        addPhotoButton.tintColor = .systemIndigo
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        
        mediaContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mediaContainer)
        
        primaryImageView.clipsToBounds = true
        primaryImageView.contentMode = .scaleAspectFit
        primaryImageView.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addSubview(primaryImageView)
        
        mediaContainer.addSubview(addPhotoButton)
        
        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleField.heightAnchor.constraint(equalToConstant: 40),
            
            textView.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 200),
            
            mediaContainer.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            mediaContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            mediaContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            primaryImageView.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
            primaryImageView.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
            primaryImageView.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),
            primaryImageView.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),
            
            addPhotoButton.centerXAnchor.constraint(equalTo: mediaContainer.centerXAnchor),
            addPhotoButton.centerYAnchor.constraint(equalTo: mediaContainer.centerYAnchor)
        ])
        
        mediaHeightConstraint = mediaContainer.heightAnchor.constraint(equalToConstant: 200)
        mediaHeightConstraint?.isActive = true
        
        updateMediaUI()
    }
    
    @objc private func saveTapped() {
        guard let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !titleText.isEmpty else { return }
        let contentText = textView.text ?? ""
        let imageDataArray = images.compactMap { $0.pngData() }
        
        let newReport = Report(
            title: titleText,
            content: contentText,
            date: report?.date ?? Date(),
            isReviewed: report?.isReviewed ?? false,
            images: imageDataArray
        )
        
        onSave?(newReport)
        ReportsManager.shared.saveReports()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func addPhotoTapped() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self?.images.append(image)
                            self?.updateMediaUI()
                        }
                    }
                }
            }
        }
    }
    
    private func updateMediaUI() {
        // Deactivate any previous aspect/height constraints before applying new ones
        if let oldAspect = imageAspectConstraint {
            oldAspect.isActive = false
            imageAspectConstraint = nil
        }

        if let firstImage = images.first {
            primaryImageView.image = firstImage
            primaryImageView.isHidden = false
            addPhotoButton.isHidden = true

            // Remove default fixed height; size container based on image aspect within limits
            mediaHeightConstraint?.isActive = false

            // Maintain aspect by tying container height to its width (so image can aspect-fit inside)
            let aspect = firstImage.size.height / max(firstImage.size.width, 1)
            let aspectHeight = mediaContainer.heightAnchor.constraint(equalTo: mediaContainer.widthAnchor, multiplier: aspect)
            aspectHeight.priority = .defaultHigh // allow cap constraint to win if needed
            aspectHeight.isActive = true
            imageAspectConstraint = aspectHeight
        } else {
            primaryImageView.image = nil
            primaryImageView.isHidden = true
            addPhotoButton.isHidden = false

            // No image: ensure a reasonable default height
            if mediaHeightConstraint == nil {
                mediaHeightConstraint = mediaContainer.heightAnchor.constraint(equalToConstant: 200)
            }
            mediaHeightConstraint?.isActive = true
        }

        view.layoutIfNeeded()
    }
}

