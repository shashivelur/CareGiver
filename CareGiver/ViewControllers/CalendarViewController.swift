import UIKit
import UserNotifications
import EventKit

class TrustedPeoplePickerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var trustedPeople: [TrustedPerson] = []
    var selectedPeople: Set<TrustedPerson> = []

    var onSave: (([TrustedPerson]) -> Void)?
    var onCancel: (() -> Void)?

    var preselectedPeople: Set<TrustedPerson> = []

    private let tableView = UITableView()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() { 
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        trustedPeople = loadTrustedPeople()
        selectedPeople = preselectedPeople

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        tableView.tintColor = .systemIndigo
        saveButton.tintColor = .systemIndigo
        cancelButton.tintColor = .systemIndigo

        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [saveButton, cancelButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: stack.topAnchor),

            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trustedPeople.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let person = trustedPeople[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = person.name
        cell.detailTextLabel?.text = person.phone
        cell.accessoryType = selectedPeople.contains(person) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let person = trustedPeople[indexPath.row]
        if selectedPeople.contains(person) {
            selectedPeople.remove(person)
        } else {
            selectedPeople.insert(person)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    @objc private func saveTapped() {
        onSave?(Array(selectedPeople))
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    private func loadTrustedPeople() -> [TrustedPerson] {
        if let data = UserDefaults.standard.data(forKey: "trusted_people_storage_v1"),
           let decoded = try? JSONDecoder().decode([TrustedPerson].self, from: data) {
            return decoded
        }
        return []
    }
}

// MARK: - TimePickerViewController
class TimePickerViewController: UIViewController {
    var onTimeSelected: ((Date) -> Void)?
    var onCancel: (() -> Void)?   // 👈 closure for cancel

    private let picker = UIDatePicker()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(picker)

        saveButton.setTitle("Save", for: .normal)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        picker.tintColor = .systemIndigo
        saveButton.tintColor = .systemIndigo
        cancelButton.tintColor = .systemIndigo

        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            saveButton.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 8),
            cancelButton.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -8)
        ])
    }

    @objc private func saveTapped() {
        onTimeSelected?(picker.date)
        dismiss(animated: true, completion: nil)
    }

    @objc private func cancelTapped() {
        onCancel?() // 👈 return to Add Task popup with existing inputs intact
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - DatePickerViewController
class DatePickerViewController: UIViewController {
    var onDateSelected: ((Date) -> Void)?
    var onCancel: (() -> Void)?

    private let picker = UIDatePicker()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false

        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false

        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(picker)
        view.addSubview(saveButton)
        view.addSubview(cancelButton)
        
        picker.tintColor = .systemIndigo
        saveButton.tintColor = .systemIndigo
        cancelButton.tintColor = .systemIndigo

        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            saveButton.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func saveTapped() {
        onDateSelected?(picker.date)
        dismiss(animated: true)
    }

    @objc private func cancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }
}

// MARK: - Main ViewController

class CalendarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICalendarSelectionSingleDateDelegate {
    var tempTaskTitle: String? { didSet { saveHighlightingData() } }
    var tempStartTimeText: String? { didSet { saveTaskEditData() } }
    var tempEndTimeText: String? { didSet { saveTaskEditData() } }
    var tempStartLocation: String? { didSet { saveTaskEditData() } }
    var tempDestination: String? { didSet { saveTaskEditData() } }
    var tempDescription: String? { didSet { saveTaskEditData() } }
    var tempTrustedPeople: [TrustedPerson] = [] { didSet { saveTaskEditData() } }
    var notificationMinutesBefore: Int = 10 { didSet { saveHighlightingData() } } // default 10 minutes before


    let calendarView = UICalendarView()
    let selectedDateLabel = UILabel()
    let viewModeControl = UISegmentedControl(items: ["Day", "Month", "Year"])
    let hourlyTableView = UITableView()
    let addTaskButton = UIButton(type: .system)
    private var topBar: UIView!
    var currentSelectedDate = Date()
    var tempDateText: String? { didSet { saveHighlightingData() } }
    private var dayNavigationStack: UIStackView!
    var currentCaregiver: Caregiver?
    
    // Apple Calendar integration
    private let eventStore = EKEventStore()

    lazy var yearCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(YearMonthCell.self, forCellWithReuseIdentifier: "MonthCell")
        collectionView.isScrollEnabled = true
        collectionView.backgroundColor = .systemBackground
        collectionView.isHidden = true
        return collectionView
    }()

    let hours: [String] = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return (0..<24).map {
            let date = Calendar.current.date(bySettingHour: $0, minute: 0, second: 0, of: Date())!
            return formatter.string(from: date)
        }
    }()

    private lazy var trustedPeopleButton: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        b.setImage(UIImage(systemName: "person.2.fill", withConfiguration: config), for: .normal)
        b.tintColor = .systemIndigo
        b.accessibilityLabel = "Trusted People"
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Key = date string ("yyyy-MM-dd"), value = [hour: [tasks]]
    var tasksByDateAndHour: [String: [Int: [String]]] = [:] { didSet { saveTasks() } }
    
    // Recently completed tasks (persists, shows last 3)
    var recentlyCompletedTasks: [String] = [] { didSet { saveTasks() } }

    // Map our tasks to Apple Calendar event identifiers for update/delete syncing
    // Key format: "<dateKey>|<hour>|<title>"
    private var taskEventIdByKey: [String: String] = [:]

    // Map our tasks to local notification identifiers so we can cancel when deleted/edited
    // Key format matches eventKey: "<dateKey>|<hour>|<title>"
    private var taskNotificationIdByKey: [String: String] = [:]

    // MARK: - Per-task details persistence
    private struct TaskDetails: Codable, Equatable {
        var startTimeInterval: TimeInterval?
        var endTimeInterval: TimeInterval?
        var startLocation: String?
        var destination: String?
        var description: String?
        var trustedPeople: [TrustedPerson]

        init(
            startTime: Date?,
            endTime: Date?,
            startLocation: String?,
            destination: String?,
            description: String?,
            trustedPeople: [TrustedPerson]
        ) {
            self.startTimeInterval = startTime?.timeIntervalSince1970
            self.endTimeInterval = endTime?.timeIntervalSince1970
            self.startLocation = startLocation
            self.destination = destination
            self.description = description
            self.trustedPeople = trustedPeople
        }

        var startTime: Date? {
            startTimeInterval.map { Date(timeIntervalSince1970: $0) }
        }

        var endTime: Date? {
            endTimeInterval.map { Date(timeIntervalSince1970: $0) }
        }
    }

    private var taskDetailsByKey: [String: TaskDetails] = [:] { didSet { saveTaskDetails() } }

    // Store selected time values and which field was tapped
    var selectedStartTime: Date? { didSet { saveHighlightingData() } }
    var selectedEndTime: Date? { didSet { saveHighlightingData() } }
    var activeTimeField: UITextField?

    var combinedDayTasks: [String] {
        let dateKey = stringFromDate(currentSelectedDate)
        guard let tasksByHour = tasksByDateAndHour[dateKey] else { return [] }
        return tasksByHour.keys.sorted().flatMap { tasksByHour[$0] ?? [] }
    }

    func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func eventKey(dateKey: String, hour: Int, title: String) -> String {
        return "\(dateKey)|\(hour)|\(title)"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        title = "Calendar"
        view.backgroundColor = .systemBackground
        
        // Load saved tasks and notification duration
        loadTasks()
        loadEventIds()
        loadNotificationDuration()
        loadTaskDetails()
        loadNotificationIds()
        
        // Load highlighting and task edit data
        loadHighlightingData()
        loadTaskEditData()
        
        // Observe app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
		// Refresh from Apple Calendar when app becomes active
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(appDidBecomeActive),
			name: UIApplication.didBecomeActiveNotification,
			object: nil
		)
        
        setupSegmentedControl()
        setupCalendarView()
        setupSelectedDateLabel()
        setupHourlyTableView()
        setupAddTaskButton()
		setupYearCollectionView()
		// Initial import from Apple Calendar for the selected day
		importAppleCalendarEvents(for: currentSelectedDate)
		viewModeChanged()
    }

    func setupSegmentedControl() {
        viewModeControl.selectedSegmentIndex = 0
        viewModeControl.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
        viewModeControl.translatesAutoresizingMaskIntoConstraints = false

        // Indigo styling for segmented control
        viewModeControl.tintColor = .systemIndigo
        if #available(iOS 13.0, *) {
            viewModeControl.selectedSegmentTintColor = .systemIndigo
        }

        // Container bar to prevent the segmented control from drifting
        let topBar = UIView()
        self.topBar = topBar
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)

        // Add controls to the container
        trustedPeopleButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(viewModeControl)
        topBar.addSubview(trustedPeopleButton)

        // Connect button tap
        trustedPeopleButton.addTarget(self, action: #selector(openTrustedPeople), for: .touchUpInside)

        // Strengthen intrinsic size behavior so it stays centered and visible
        viewModeControl.setContentHuggingPriority(.required, for: .horizontal)
        viewModeControl.setContentCompressionResistancePriority(.required, for: .horizontal)
        viewModeControl.setContentHuggingPriority(.required, for: .vertical)
        viewModeControl.setContentCompressionResistancePriority(.required, for: .vertical)

        // Layout the container at the top safe area with fixed height
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 48)
        ])

        // Trusted people button vertically centered and pinned to trailing
        NSLayoutConstraint.activate([
            trustedPeopleButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            trustedPeopleButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16)
        ])

        // Segmented control centered vertically and horizontally within the container
        NSLayoutConstraint.activate([
            viewModeControl.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            viewModeControl.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            viewModeControl.leadingAnchor.constraint(greaterThanOrEqualTo: topBar.leadingAnchor, constant: 16),
            viewModeControl.trailingAnchor.constraint(lessThanOrEqualTo: topBar.trailingAnchor, constant: -16)
        ])

        // Prevent overlap with the trusted people button while preserving centering
        let avoidOverlap = viewModeControl.trailingAnchor.constraint(lessThanOrEqualTo: trustedPeopleButton.leadingAnchor, constant: -12)
        avoidOverlap.priority = UILayoutPriority(999)
        avoidOverlap.isActive = true
    }

    func setupCalendarView() {
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.isHidden = true
        calendarView.delegate = self
        
        // Enable date selection
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
        calendarView.tintColor = .systemIndigo
        
        view.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            calendarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func setupSelectedDateLabel() {
        selectedDateLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedDateLabel.textAlignment = .center
        selectedDateLabel.textColor = .darkGray
        selectedDateLabel.text = formattedDate(Date())
        selectedDateLabel.isHidden = false

        let backButton = UIButton(type: .system)
        backButton.setTitle("<", for: .normal)
        backButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        backButton.addTarget(self, action: #selector(previousDay), for: .touchUpInside)
        backButton.tintColor = .systemIndigo

        let forwardButton = UIButton(type: .system)
        forwardButton.setTitle(">", for: .normal)
        forwardButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
        forwardButton.addTarget(self, action: #selector(nextDay), for: .touchUpInside)
        forwardButton.tintColor = .systemIndigo

        selectedDateLabel.numberOfLines = 1
        selectedDateLabel.adjustsFontSizeToFitWidth = true
        selectedDateLabel.minimumScaleFactor = 0.8

        backButton.setContentHuggingPriority(.required, for: .horizontal)
        forwardButton.setContentHuggingPriority(.required, for: .horizontal)
        backButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        forwardButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        selectedDateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        selectedDateLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            forwardButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 28)
        ])

        dayNavigationStack = UIStackView(arrangedSubviews: [backButton, selectedDateLabel, forwardButton])
        dayNavigationStack.axis = .horizontal
        dayNavigationStack.alignment = .center
        dayNavigationStack.distribution = .equalSpacing
        dayNavigationStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dayNavigationStack)

        NSLayoutConstraint.activate([
            dayNavigationStack.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            dayNavigationStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            dayNavigationStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc func previousDay() {
        currentSelectedDate = Calendar.current.date(byAdding: .day, value: -1, to: currentSelectedDate)!
        selectedDateLabel.text = formattedDate(currentSelectedDate)
        importAppleCalendarEvents(for: currentSelectedDate)
        hourlyTableView.reloadData()
    }

    @objc func nextDay() {
        currentSelectedDate = Calendar.current.date(byAdding: .day, value: 1, to: currentSelectedDate)!
        selectedDateLabel.text = formattedDate(currentSelectedDate)
        importAppleCalendarEvents(for: currentSelectedDate)
        hourlyTableView.reloadData()
    }
    
    // MARK: - Navigation Methods
    private func navigateToMonthView(month: Int, year: Int) {
        // Switch to month view
        viewModeControl.selectedSegmentIndex = 1
        viewModeChanged()
        
        // Set the calendar to the selected month
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        if let _ = calendar.date(from: dateComponents) {
            // Set the calendar view to show the selected month
            calendarView.visibleDateComponents = dateComponents
        }
    }
    
    private func navigateToDayView(date: Date) {
        print("DEBUG: navigateToDayView called with date: \(date)")
        // Switch to day view
        viewModeControl.selectedSegmentIndex = 0
        currentSelectedDate = date
        
        // Update the date label
        selectedDateLabel.text = formattedDate(date)
        
        print("DEBUG: About to call viewModeChanged")
        viewModeChanged()
        print("DEBUG: About to reload hourlyTableView")
        importAppleCalendarEvents(for: date)
        hourlyTableView.reloadData()
        print("DEBUG: navigateToDayView completed")
    }

    func setupHourlyTableView() {
        hourlyTableView.translatesAutoresizingMaskIntoConstraints = false
        hourlyTableView.dataSource = self
        hourlyTableView.delegate = self
        hourlyTableView.isScrollEnabled = true
        hourlyTableView.isHidden = true
        hourlyTableView.register(HourTaskCell.self, forCellReuseIdentifier: "HourTaskCell")
        hourlyTableView.register(TaskListCell.self, forCellReuseIdentifier: "TaskListCell")
        hourlyTableView.estimatedRowHeight = 60
        hourlyTableView.rowHeight = UITableView.automaticDimension
        view.addSubview(hourlyTableView)

        NSLayoutConstraint.activate([
            hourlyTableView.topAnchor.constraint(equalTo: selectedDateLabel.bottomAnchor, constant: 5),
            hourlyTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hourlyTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            hourlyTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
    }

    func setupAddTaskButton() {
        addTaskButton.setTitle("Add Task", for: .normal)
        addTaskButton.backgroundColor = .systemIndigo
        addTaskButton.setTitleColor(.white, for: .normal)
        addTaskButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        addTaskButton.layer.cornerRadius = 10
        addTaskButton.translatesAutoresizingMaskIntoConstraints = false
        
        addTaskButton.setContentHuggingPriority(.required, for: .vertical)
        addTaskButton.setContentCompressionResistancePriority(.required, for: .vertical)
        
        addTaskButton.addTarget(self, action: #selector(presentAddTaskPopup), for: .touchUpInside)
        view.addSubview(addTaskButton)

        NSLayoutConstraint.activate([
            addTaskButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            addTaskButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            addTaskButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            addTaskButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Validation helpers
    private func showErrorAlert(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if let presented = presentedViewController, presented is UIAlertController {
            presented.present(alert, animated: true)
        } else {
            present(alert, animated: true)
        }
    }

    private func parseRequiredDateAndTimes(dateString: String?, startTimeString: String?, endTimeString: String?) -> (date: Date, start: Date, end: Date)? {
        // All required
        guard let dateStr = dateString?.trimmingCharacters(in: .whitespacesAndNewlines), !dateStr.isEmpty,
              let startStr = startTimeString?.trimmingCharacters(in: .whitespacesAndNewlines), !startStr.isEmpty,
              let endStr = endTimeString?.trimmingCharacters(in: .whitespacesAndNewlines), !endStr.isEmpty else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        guard let baseDate = dateFormatter.date(from: dateStr) else { return nil }

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        guard let startTimeOnly = timeFormatter.date(from: startStr),
              let endTimeOnly = timeFormatter.date(from: endStr) else { return nil }

        let cal = Calendar.current
        var startComps = cal.dateComponents([.year, .month, .day], from: baseDate)
        let startParts = cal.dateComponents([.hour, .minute], from: startTimeOnly)
        startComps.hour = startParts.hour
        startComps.minute = startParts.minute

        var endComps = cal.dateComponents([.year, .month, .day], from: baseDate)
        let endParts = cal.dateComponents([.hour, .minute], from: endTimeOnly)
        endComps.hour = endParts.hour
        endComps.minute = endParts.minute

        guard let start = cal.date(from: startComps),
              let end = cal.date(from: endComps) else { return nil }
        return (date: baseDate, start: start, end: end)
    }

    @objc func presentAddTaskPopup() {
        // ✅ Reset temp values before showing popup
        self.tempTaskTitle = nil
        self.tempStartTimeText = nil
        self.tempEndTimeText = nil
        self.tempStartLocation = nil
        self.tempDestination = nil
        self.tempDescription = nil
        self.tempDateText = nil
        self.selectedStartTime = nil
        self.selectedEndTime = nil
        self.tempTrustedPeople = []   // 👈 reset trusted people

        let alert = UIAlertController(title: "New Task", message: nil, preferredStyle: .alert)

        alert.addTextField { $0.placeholder = "Title"; $0.text = self.tempTaskTitle ?? "" }
        alert.addTextField { $0.placeholder = "Start Time"; $0.tag = 1; $0.inputView = UIView(); $0.text = self.tempStartTimeText ?? "" }
        alert.addTextField { $0.placeholder = "End Time"; $0.tag = 2; $0.inputView = UIView(); $0.text = self.tempEndTimeText ?? "" }
        alert.addTextField { $0.placeholder = "Start Location (optional)"; $0.text = self.tempStartLocation ?? "" }
        alert.addTextField { $0.placeholder = "Destination (optional)"; $0.text = self.tempDestination ?? "" }
        alert.addTextField { $0.placeholder = "Description (optional)"; $0.text = self.tempDescription ?? "" }
        alert.addTextField { $0.placeholder = "Date"; $0.tag = 100; $0.inputView = UIView(); $0.text = self.tempDateText ?? "" }

        // 👇 NEW Trusted People field
        alert.addTextField {
            $0.placeholder = "Assign Trusted People"
            $0.tag = 200
            $0.inputView = UIView() // disable keyboard
            $0.text = self.tempTrustedPeople.map { $0.name }.joined(separator: ", ")
        }

        // Capture references to text fields
        let startTimeField = alert.textFields?.first(where: { $0.tag == 1 })
        let endTimeField = alert.textFields?.first(where: { $0.tag == 2 })
        let dateField = alert.textFields?.first(where: { $0.tag == 100 })
        let trustedField = alert.textFields?.first(where: { $0.tag == 200 }) // 👈 new

        [startTimeField, endTimeField].forEach { textField in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.timeFieldTapped(_:)))
            textField?.addGestureRecognizer(tap)
            textField?.isUserInteractionEnabled = true
        }

        [dateField].forEach { textField in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.dateFieldTapped(_:)))
            textField?.addGestureRecognizer(tap)
            textField?.isUserInteractionEnabled = true
        }

        [trustedField].forEach { textField in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.trustedPeopleFieldTapped(_:)))
            textField?.addGestureRecognizer(tap)
            textField?.isUserInteractionEnabled = true
        }
        let add = UIAlertAction(title: "Add", style: .default) { _ in
            let fields = alert.textFields ?? []
            self.tempTaskTitle = fields[safe: 0]?.text
            self.tempStartTimeText = fields[safe: 1]?.text
            self.tempEndTimeText = fields[safe: 2]?.text
            self.tempStartLocation = fields[safe: 3]?.text
            self.tempDestination = fields[safe: 4]?.text
            self.tempDescription = fields[safe: 5]?.text
            self.tempDateText = fields[safe: 6]?.text

            // Validate required fields
            guard let title = self.tempTaskTitle?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty else {
                self.showErrorAlert(message: "Fill in all required fields.")
                return
            }

            guard let parsed = self.parseRequiredDateAndTimes(
                dateString: self.tempDateText,
                startTimeString: self.tempStartTimeText,
                endTimeString: self.tempEndTimeText
            ) else {
                self.showErrorAlert(message: "Fill in all required fields.")
                return
            }

            // Validate time ordering
            if parsed.start >= parsed.end {
                self.showErrorAlert(message: "Invalid times. Start time must be before end time.")
                return
            }

            // Proceed with add
            let selectedDate = parsed.date
            let dateKey = self.stringFromDate(selectedDate)

            let hour = Calendar.current.component(.hour, from: parsed.start)

            // Check for time conflicts
            if self.hasTimeConflict(dateKey: dateKey, hour: hour) {
                self.selectedStartTime = parsed.start
                self.selectedEndTime = parsed.end
                self.handleTimeConflict(dateKey: dateKey, hour: hour, newTaskTitle: title, newTaskStartTime: self.selectedStartTime, newTaskEndTime: self.selectedEndTime, newTaskDescription: self.tempDescription, newTaskTrustedPeople: self.tempTrustedPeople)
                return
            }

            if self.tasksByDateAndHour[dateKey] == nil {
                self.tasksByDateAndHour[dateKey] = [:]
            }

            if self.tasksByDateAndHour[dateKey]?[hour] != nil {
                self.tasksByDateAndHour[dateKey]?[hour]?.append(title)
            } else {
                self.tasksByDateAndHour[dateKey]?[hour] = [title]
            }

            // Build start/end dates (already computed)
            let startTimeForNotification = parsed.start
            let startTimeForCalendar = parsed.start
            let endTimeForCalendar = parsed.end

            // Schedule local notification and store identifier mapping
            let key = self.eventKey(dateKey: dateKey, hour: hour, title: title)
            let identifier = self.scheduleTaskNotification(title: title, date: startTimeForNotification, minutesBefore: self.notificationMinutesBefore)
            self.taskNotificationIdByKey[key] = identifier
            self.saveNotificationIds()
            
            // Send notification if trusted people are assigned
            if !self.tempTrustedPeople.isEmpty {
                self.sendTaskAssignmentNotification(taskTitle: title, assignedPeople: self.tempTrustedPeople)
            }

            // Persist all task details
            let detailsKey = self.eventKey(dateKey: dateKey, hour: hour, title: title)
            self.taskDetailsByKey[detailsKey] = TaskDetails(
                startTime: startTimeForCalendar,
                endTime: endTimeForCalendar,
                startLocation: (self.tempStartLocation?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
                destination: (self.tempDestination?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
                description: (self.tempDescription?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
                trustedPeople: self.tempTrustedPeople
            )
            
            // Add to Apple Calendar
            self.addTaskToAppleCalendar(
                title: title,
                startTime: startTimeForCalendar,
                endTime: endTimeForCalendar,
                description: self.tempDescription ?? "",
                dateKey: dateKey,
                hour: hour
            )
            
            // Keep highlighting consistent
            self.tempTaskTitle = title
            self.selectedStartTime = startTimeForCalendar
            self.selectedEndTime = endTimeForCalendar
            let df = DateFormatter()
            df.dateStyle = .medium
            self.tempDateText = df.string(from: selectedDate)
            
            // Reload table view to show the new task
            self.hourlyTableView.reloadData()
        }

        alert.addAction(add)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
    
    func presentEditTaskPopup(for task: String) {
        // Find the task and get its current details
        let dateKey = stringFromDate(currentSelectedDate)
        guard let tasksByHour = tasksByDateAndHour[dateKey] else { return }
        
        // Find the task and get its hour
        var taskHour: Int?
        for (hour, tasks) in tasksByHour {
            if tasks.contains(task) {
                taskHour = hour
                break
            }
        }
        guard let hour = taskHour else { return }
        
        let existingKey = eventKey(dateKey: dateKey, hour: hour, title: task)
        let existingDetails = taskDetailsByKey[existingKey]

        // Prefer saved times if present; otherwise fall back to current highlight/hour-based logic
        var startTimeString: String = ""
        var endTimeString: String = ""
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        if let start = existingDetails?.startTime, let end = existingDetails?.endTime {
            startTimeString = formatter.string(from: start)
            endTimeString = formatter.string(from: end)
        } else if let start = selectedStartTime, let end = selectedEndTime, tempTaskTitle == task {
            startTimeString = formatter.string(from: start)
            endTimeString = formatter.string(from: end)
        } else {
            // Fallback to hour-based logic
            let calendar = Calendar.current
            let startDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
            let endDate = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: Date()) ?? Date()
            startTimeString = formatter.string(from: startDate)
            endTimeString = formatter.string(from: endDate)
        }
        
        let alert = UIAlertController(title: "Edit Task", message: nil, preferredStyle: .alert)
        
        // Task title
        alert.addTextField { textField in
            textField.placeholder = "Task Title"
            textField.text = task
        }
        // Start time
        alert.addTextField { textField in
            textField.placeholder = "Start Time"
            textField.tag = 1
            textField.inputView = UIView()
            textField.text = startTimeString
        }
        // End time
        alert.addTextField { textField in
            textField.placeholder = "End Time"
            textField.tag = 2
            textField.inputView = UIView()
            textField.text = endTimeString
        }
        
        // Start location
        alert.addTextField { textField in
            textField.placeholder = "Start Location (optional)"
            textField.text = existingDetails?.startLocation ?? ""
        }
        
        // Destination
        alert.addTextField { textField in
            textField.placeholder = "Destination (optional)"
            textField.text = existingDetails?.destination ?? ""
        }
        
        // Description
        alert.addTextField { textField in
            textField.placeholder = "Description (optional)"
            textField.text = existingDetails?.description ?? ""
        }
        
        // Date
        alert.addTextField { textField in
            textField.placeholder = "Date"
            textField.tag = 100
            textField.inputView = UIView()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            textField.text = formatter.string(from: self.currentSelectedDate)
        }
        
        // Trusted people
        alert.addTextField { textField in
            textField.placeholder = "Assign Trusted People"
            textField.tag = 200
            textField.inputView = UIView()
            let people = existingDetails?.trustedPeople ?? []
            textField.text = people.map { $0.name }.joined(separator: ", ")
        }

        // Keep the picker's preselected state aligned to the task being edited
        self.tempTrustedPeople = existingDetails?.trustedPeople ?? []
        
        // Capture references to text fields
        let startTimeField = alert.textFields?.first(where: { $0.tag == 1 })
        let endTimeField = alert.textFields?.first(where: { $0.tag == 2 })
        let dateField = alert.textFields?.first(where: { $0.tag == 100 })
        let trustedField = alert.textFields?.first(where: { $0.tag == 200 })
        
        // Add tap gestures for time and date fields
        [startTimeField, endTimeField].forEach { textField in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.timeFieldTapped(_:)))
            textField?.addGestureRecognizer(tap)
            textField?.isUserInteractionEnabled = true
        }
        
        [dateField].forEach { textField in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.dateFieldTapped(_:)))
            textField?.addGestureRecognizer(tap)
            textField?.isUserInteractionEnabled = true
        }
        
        [trustedField].forEach { textField in
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.trustedPeopleFieldTapped(_:)))
            textField?.addGestureRecognizer(tap)
            textField?.isUserInteractionEnabled = true
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let fields = alert.textFields,
                  let newTitle = fields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !newTitle.isEmpty else {
                self.showErrorAlert(message: "Fill in all required fields.")
                return
            }

            // Validate required date/time fields
            let dateString = fields[6].text
            let startString = fields[1].text
            let endString = fields[2].text
            guard let parsed = self.parseRequiredDateAndTimes(dateString: dateString, startTimeString: startString, endTimeString: endString) else {
                self.showErrorAlert(message: "Fill in all required fields.")
                return
            }
            if parsed.start >= parsed.end {
                self.showErrorAlert(message: "Invalid times. Start time must be before end time.")
                return
            }

            self.updateTaskWithNewDetails(
                oldTask: task,
                newTitle: newTitle,
                startTime: startString,
                endTime: endString,
                startLocation: fields[3].text,
                destination: fields[4].text,
                description: fields[5].text,
                date: dateString,
                trustedPeople: fields[7].text,
                originalHour: hour
            )
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func updateTaskWithNewDetails(
        oldTask: String,
        newTitle: String,
        startTime: String?,
        endTime: String?,
        startLocation: String?,
        destination: String?,
        description: String?,
        date: String?,
        trustedPeople: String?,
        originalHour: Int
    ) {
        // Keys and helpers
        let originalDateKey = stringFromDate(currentSelectedDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // Determine target date (fallback to currentSelectedDate)
        let targetDate: Date = {
            if let dateStr = date, let parsed = dateFormatter.date(from: dateStr) {
                return parsed
            } else {
                return currentSelectedDate
            }
        }()
        let targetDateKey = stringFromDate(targetDate)
        
        // Determine target hour (fallback to originalHour)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let targetHour: Int = {
            if let start = startTime, let parsed = timeFormatter.date(from: start) {
                return Calendar.current.component(.hour, from: parsed)
            } else {
                return originalHour
            }
        }()

        // Determine start/end Date values on the target day (if possible)
        let calendar = Calendar.current
        var computedStart: Date?
        var computedEnd: Date?
        if let startText = startTime, let endText = endTime {
            var startComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            if let time = timeFormatter.date(from: startText) {
                let comps = calendar.dateComponents([.hour, .minute], from: time)
                startComponents.hour = comps.hour
                startComponents.minute = comps.minute
            }
            var endComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            if let time = timeFormatter.date(from: endText) {
                let comps = calendar.dateComponents([.hour, .minute], from: time)
                endComponents.hour = comps.hour
                endComponents.minute = comps.minute
            }
            computedStart = calendar.date(from: startComponents)
            computedEnd = calendar.date(from: endComponents)
        }
        
        // Remove old task from original date
        guard var originalTasksByHour = tasksByDateAndHour[originalDateKey] else { return }
        for (hour, tasks) in originalTasksByHour {
            if let index = tasks.firstIndex(of: oldTask) {
                originalTasksByHour[hour]?.remove(at: index)
                if originalTasksByHour[hour]?.isEmpty == true {
                    originalTasksByHour.removeValue(forKey: hour)
                }
                break
            }
        }
        // Write back (or remove) original day
        tasksByDateAndHour[originalDateKey] = originalTasksByHour.isEmpty ? nil : originalTasksByHour
        
        // Cancel old notification mapping (old key)
        let oldKey = eventKey(dateKey: originalDateKey, hour: originalHour, title: oldTask)
        cancelNotificationIfExists(forKey: oldKey)
        
        // Insert updated task into target date/hour
        var targetTasksByHour = tasksByDateAndHour[targetDateKey] ?? [:]
        var list = targetTasksByHour[targetHour] ?? []
        list.append(newTitle)
        targetTasksByHour[targetHour] = list
        tasksByDateAndHour[targetDateKey] = targetTasksByHour

        // Update tempTaskTitle so highlight label updates
        self.tempTaskTitle = newTitle

        // Persist all edited details (including destination/start location/times/trusted people)
        let newKey = eventKey(dateKey: targetDateKey, hour: targetHour, title: newTitle)
        taskDetailsByKey.removeValue(forKey: oldKey)
        taskDetailsByKey[newKey] = TaskDetails(
            startTime: computedStart,
            endTime: computedEnd,
            startLocation: (startLocation?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
            destination: (destination?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
            description: (description?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 },
            trustedPeople: tempTrustedPeople
        )

        // Keep highlighting times consistent with the user's edit
        if let computedStart { self.selectedStartTime = computedStart }
        if let computedEnd { self.selectedEndTime = computedEnd }

        // Update Apple Calendar event
        if let startText = startTime,
           let endText = endTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"

            let baseDate = formatter.date(from: date ?? formatter.string(from: currentSelectedDate)) ?? currentSelectedDate
            let calendar = Calendar.current

            var startComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            if let time = timeFormatter.date(from: startText) {
                let comps = calendar.dateComponents([.hour, .minute], from: time)
                startComponents.hour = comps.hour
                startComponents.minute = comps.minute
            }
            var endComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            if let time = timeFormatter.date(from: endText) {
                let comps = calendar.dateComponents([.hour, .minute], from: time)
                endComponents.hour = comps.hour
                endComponents.minute = comps.minute
            }

            if let newStart = calendar.date(from: startComponents),
               let newEnd = calendar.date(from: endComponents) {
                updateOrCreateCalendarEvent(
                    oldKey: oldKey,
                    newDateKey: targetDateKey,
                    newHour: targetHour,
                    newTitle: newTitle,
                    newStart: newStart,
                    newEnd: newEnd,
                    description: description
                )
                // Schedule a fresh local notification for the edited task and save mapping
                let identifier = scheduleTaskNotification(title: newTitle, date: newStart, minutesBefore: notificationMinutesBefore)
                taskNotificationIdByKey[newKey] = identifier
                saveNotificationIds()
            }
        }

        // UI refresh
        hourlyTableView.reloadData()
    }

    // MARK: - Task details persistence
    private func loadTaskDetails() {
        guard let data = UserDefaults.standard.data(forKey: "task_details_by_key_v1"),
              let decoded = try? JSONDecoder().decode([String: TaskDetails].self, from: data) else {
            return
        }
        taskDetailsByKey = decoded
    }

    private func saveTaskDetails() {
        guard let data = try? JSONEncoder().encode(taskDetailsByKey) else { return }
        UserDefaults.standard.set(data, forKey: "task_details_by_key_v1")
    }

    // MARK: - Notification helper
    // Returns the identifier used so callers can store/cancel later
    @discardableResult
    func scheduleTaskNotification(title: String, date: Date, minutesBefore: Int) -> String {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Task"
        content.body = title
        content.sound = .default

        let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: date) ?? date
        let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for \(triggerDate) (\(minutesBefore) minutes before) id=\(identifier)")
            }
        }
        return identifier
    }
    
    private func cancelNotificationIfExists(forKey key: String) {
        guard let identifier = taskNotificationIdByKey[key] else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        taskNotificationIdByKey.removeValue(forKey: key)
        saveNotificationIds()
    }
    
    func sendTaskAssignmentNotification(taskTitle: String, assignedPeople: [TrustedPerson]) {
        let assignedNames = assignedPeople.map { $0.name }.joined(separator: ", ")
        let title = "Task Assigned"
        let body = assignedNames.isEmpty
            ? "Task updated: \(taskTitle)"
            : "Assigned \(assignedNames) to: \(taskTitle)"

        // Post to notification center for in-app display.
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskAssigned"),
            object: nil,
            userInfo: [
                "title": title,
                "body": body,
                "assignedPeople": assignedNames
            ]
        )
    }
    
    // MARK: - Apple Calendar Integration
    func addTaskToAppleCalendar(title: String, startTime: Date, endTime: Date, description: String, dateKey: String, hour: Int) {
        ensureCalendarAccess { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.createCalendarEvent(title: title, startTime: startTime, endTime: endTime, description: description, dateKey: dateKey, hour: hour)
            } else {
                print("Calendar access denied while adding event")
            }
        }
    }
    
    private func createCalendarEvent(title: String, startTime: Date, endTime: Date, description: String, dateKey: String, hour: Int) {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startTime
        event.endDate = endTime
        event.notes = description
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            let key = eventKey(dateKey: dateKey, hour: hour, title: title)
            taskEventIdByKey[key] = event.eventIdentifier
            saveEventIds()
        } catch {
            print("Error saving event to Apple Calendar: \(error.localizedDescription)")
        }
    }

    private func updateOrCreateCalendarEvent(oldKey: String, newDateKey: String, newHour: Int, newTitle: String, newStart: Date, newEnd: Date, description: String?) {
        ensureCalendarAccess { [weak self] granted in
            guard let self = self else { return }
            guard granted else { return }

            if let identifier = self.taskEventIdByKey[oldKey], let existing = self.eventStore.event(withIdentifier: identifier) {
                existing.title = newTitle
                existing.startDate = newStart
                existing.endDate = newEnd
                existing.notes = description
                do {
                    try self.eventStore.save(existing, span: .thisEvent)
                    let newKey = self.eventKey(dateKey: newDateKey, hour: newHour, title: newTitle)
                    self.taskEventIdByKey.removeValue(forKey: oldKey)
                    self.taskEventIdByKey[newKey] = existing.eventIdentifier
                    self.saveEventIds()
                } catch {
                    print("Failed to update calendar event: \(error.localizedDescription)")
                }
            } else {
                self.createCalendarEvent(title: newTitle, startTime: newStart, endTime: newEnd, description: description ?? "", dateKey: newDateKey, hour: newHour)
            }
        }
    }

    private func deleteCalendarEventIfExists(dateKey: String, hour: Int, title: String) {
        let key = eventKey(dateKey: dateKey, hour: hour, title: title)
        guard let identifier = taskEventIdByKey[key], let event = eventStore.event(withIdentifier: identifier) else {
            return
        }
        do {
            try eventStore.remove(event, span: .thisEvent)
            taskEventIdByKey.removeValue(forKey: key)
            saveEventIds()
        } catch {
            print("Failed to delete calendar event: \(error.localizedDescription)")
        }
    }

    private func ensureCalendarAccess(completion: @escaping (Bool) -> Void) {
        eventStore.requestAccess(to: .event) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }
    
    // MARK: - Import from Apple Calendar (one-way into app)
    private func importAppleCalendarEvents(for date: Date) {
        ensureCalendarAccess { [weak self] granted in
            guard let self = self else { return }
            guard granted else { return }
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) else { return }

            let predicate = self.eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
            let events = self.eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
            let eventsById: [String: EKEvent] = Dictionary(uniqueKeysWithValues: events.map { ($0.eventIdentifier, $0) })

            let dateKey = self.stringFromDate(date)
            var dayDict: [Int: [String]] = self.tasksByDateAndHour[dateKey] ?? [:]

            // Reconcile existing mapped tasks
            for (hour, titles) in dayDict {
                var titlesToKeep: [String] = []
                for title in titles {
                    let oldKey = self.eventKey(dateKey: dateKey, hour: hour, title: title)
                    if let mappedId = self.taskEventIdByKey[oldKey] {
                        if let ev = eventsById[mappedId] {
                            let newHour = calendar.component(.hour, from: ev.startDate)
                            let newTitle = ev.title ?? "Untitled Event"
                            let newKey = self.eventKey(dateKey: dateKey, hour: newHour, title: newTitle)
                            if newKey != oldKey {
                                var list = dayDict[newHour] ?? []
                                if !list.contains(newTitle) { list.append(newTitle) }
                                dayDict[newHour] = list
                                self.taskEventIdByKey.removeValue(forKey: oldKey)
                                self.taskEventIdByKey[newKey] = mappedId
                                if let notifId = self.taskNotificationIdByKey[oldKey] {
                                    self.taskNotificationIdByKey.removeValue(forKey: oldKey)
                                    self.taskNotificationIdByKey[newKey] = notifId
                                }
                            } else {
                                titlesToKeep.append(title)
                            }
                        } else {
                            self.taskEventIdByKey.removeValue(forKey: oldKey)
                            self.cancelNotificationIfExists(forKey: oldKey)
                        }
                    } else {
                        titlesToKeep.append(title)
                    }
                }
                dayDict[hour] = titlesToKeep.isEmpty ? nil : titlesToKeep
            }

            // Add or refresh mappings for today's events
            for event in events {
                let startHour = calendar.component(.hour, from: event.startDate)
                let key = self.eventKey(dateKey: dateKey, hour: startHour, title: event.title)
                if let existingKey = self.taskEventIdByKey.first(where: { $0.value == event.eventIdentifier })?.key, existingKey != key {
                    let comps = existingKey.split(separator: "|")
                    if comps.count == 3, let oldHour = Int(comps[1]) {
                        if var oldList = dayDict[oldHour] {
                            oldList.removeAll { $0 == String(comps[2]) }
                            dayDict[oldHour] = oldList.isEmpty ? nil : oldList
                        }
                    }
                    self.taskEventIdByKey.removeValue(forKey: existingKey)
                }
                self.taskEventIdByKey[key] = event.eventIdentifier

                var list = dayDict[startHour] ?? []
                if !list.contains(event.title) {
                    list.append(event.title)
                }
                dayDict[startHour] = list
            }

            self.tasksByDateAndHour[dateKey] = dayDict
            self.saveEventIds()

            // Update highlight shading to reflect first event for the day
            if let firstEvent = events.first {
                self.tempTaskTitle = firstEvent.title
                self.selectedStartTime = firstEvent.startDate
                self.selectedEndTime = firstEvent.endDate
                let df = DateFormatter()
                df.dateStyle = .medium
                self.tempDateText = df.string(from: date)
            }

            self.hourlyTableView.reloadData()
        }
    }
    
    // MARK: - Task Persistence
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks_by_date_and_hour"),
           let decoded = try? JSONDecoder().decode([String: [Int: [String]]].self, from: data) {
            tasksByDateAndHour = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "recently_completed_tasks"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            recentlyCompletedTasks = decoded
        }
    }
    
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasksByDateAndHour) {
            UserDefaults.standard.set(data, forKey: "tasks_by_date_and_hour")
        }
        
        if let data = try? JSONEncoder().encode(recentlyCompletedTasks) {
            UserDefaults.standard.set(data, forKey: "recently_completed_tasks")
        }
    }

    private func loadEventIds() {
        if let data = UserDefaults.standard.data(forKey: "task_event_ids_v1"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            taskEventIdByKey = decoded
        }
    }

    private func saveEventIds() {
        if let data = try? JSONEncoder().encode(taskEventIdByKey) {
            UserDefaults.standard.set(data, forKey: "task_event_ids_v1")
        }
    }
    
    private func loadNotificationIds() {
        if let data = UserDefaults.standard.data(forKey: "task_notification_ids_v1"),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            taskNotificationIdByKey = decoded
        }
    }
    
    private func saveNotificationIds() {
        if let data = try? JSONEncoder().encode(taskNotificationIdByKey) {
            UserDefaults.standard.set(data, forKey: "task_notification_ids_v1")
        }
    }
    
    private func hasTimeConflict(dateKey: String, hour: Int) -> Bool {
        guard let tasksForDate = tasksByDateAndHour[dateKey] else { return false }
        return tasksForDate[hour] != nil && !tasksForDate[hour]!.isEmpty
    }
    
    private func handleTimeConflict(dateKey: String, hour: Int, newTaskTitle: String, newTaskStartTime: Date?, newTaskEndTime: Date?, newTaskDescription: String?, newTaskTrustedPeople: [TrustedPerson]) {
        guard let existingTasks = tasksByDateAndHour[dateKey]?[hour], !existingTasks.isEmpty else { return }
        
        let existingTaskName = existingTasks.first ?? "Unknown Task"
        
        let alert = UIAlertController(
            title: "Time Conflict", 
            message: "You already have '\(existingTaskName)' scheduled at this time. What would you like to do?", 
            preferredStyle: .alert
        )
        
        let keepExistingAction = UIAlertAction(title: "Keep '\(existingTaskName)'", style: .default)
        
        let replaceAction = UIAlertAction(title: "Replace with '\(newTaskTitle)'", style: .destructive) { _ in
            let oldKey = self.eventKey(dateKey: dateKey, hour: hour, title: existingTaskName)
            self.cancelNotificationIfExists(forKey: oldKey)
            self.tasksByDateAndHour[dateKey]?[hour]?.removeAll()
            
            self.addTaskToSchedule(
                dateKey: dateKey, 
                hour: hour, 
                title: newTaskTitle, 
                startTime: newTaskStartTime, 
                endTime: newTaskEndTime, 
                description: newTaskDescription, 
                trustedPeople: newTaskTrustedPeople
            )
        }
        
        let keepBothAction = UIAlertAction(title: "Keep Both Tasks", style: .default) { _ in
            self.addTaskToSchedule(
                dateKey: dateKey, 
                hour: hour, 
                title: newTaskTitle, 
                startTime: newTaskStartTime, 
                endTime: newTaskEndTime, 
                description: newTaskDescription, 
                trustedPeople: newTaskTrustedPeople
            )
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(keepExistingAction)
        alert.addAction(replaceAction)
        alert.addAction(keepBothAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    private func addTaskToSchedule(dateKey: String, hour: Int, title: String, startTime: Date?, endTime: Date?, description: String?, trustedPeople: [TrustedPerson]) {
        if tasksByDateAndHour[dateKey] == nil {
            tasksByDateAndHour[dateKey] = [:]
        }

        if tasksByDateAndHour[dateKey]?[hour] != nil {
            tasksByDateAndHour[dateKey]?[hour]?.append(title)
        } else {
            tasksByDateAndHour[dateKey]?[hour] = [title]
        }

        // Use the selected date (from dateKey), not today, for notifications and Apple Calendar
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let selectedDate = dateFormatter.date(from: dateKey) else { return }

        let calendar = Calendar.current
        var startTimeForNotification: Date?
        var startTimeForCalendar: Date?
        var endTimeForCalendar: Date?
        if let start = startTime, let end = endTime {
            let startHour = calendar.component(.hour, from: start)
            let startMinute = calendar.component(.minute, from: start)
            let endHour = calendar.component(.hour, from: end)
            let endMinute = calendar.component(.minute, from: end)
            startTimeForNotification = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: selectedDate)
            startTimeForCalendar = startTimeForNotification
            endTimeForCalendar = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: selectedDate)
        }

        if let startTime = startTimeForNotification {
            let key = eventKey(dateKey: dateKey, hour: hour, title: title)
            let identifier = scheduleTaskNotification(title: title, date: startTime, minutesBefore: notificationMinutesBefore)
            taskNotificationIdByKey[key] = identifier
            saveNotificationIds()
        }
        
        if !trustedPeople.isEmpty {
            sendTaskAssignmentNotification(taskTitle: title, assignedPeople: trustedPeople)
        }
        
        if let startTime = startTimeForCalendar, let endTime = endTimeForCalendar {
            addTaskToAppleCalendar(title: title, startTime: startTime, endTime: endTime, description: description ?? "", dateKey: dateKey, hour: hour)
        }
        
        hourlyTableView.reloadData()
    }
    
    private func loadNotificationDuration() {
        notificationMinutesBefore = UserDefaults.standard.object(forKey: "notification_duration") as? Int ?? 10
    }
    
    // MARK: - Highlighting & Task Edit Persistence
    private func saveHighlightingData() {
        var highlightingData: [String: Any] = [:]
        
        if let tempTaskTitle = tempTaskTitle {
            highlightingData["tempTaskTitle"] = tempTaskTitle
        }
        
        if let tempDateText = tempDateText {
            highlightingData["tempDateText"] = tempDateText
        }
        
        if let selectedStartTime = selectedStartTime {
            highlightingData["selectedStartTime"] = selectedStartTime.timeIntervalSince1970
        }
        
        if let selectedEndTime = selectedEndTime {
            highlightingData["selectedEndTime"] = selectedEndTime.timeIntervalSince1970
        }
        
        highlightingData["notificationMinutesBefore"] = notificationMinutesBefore
        
        UserDefaults.standard.set(highlightingData, forKey: "highlighting_data")
    }
    
    private func loadHighlightingData() {
        let highlightingData = UserDefaults.standard.dictionary(forKey: "highlighting_data")
        
        tempTaskTitle = highlightingData?["tempTaskTitle"] as? String
        tempDateText = highlightingData?["tempDateText"] as? String
        
        if let startTimeInterval = highlightingData?["selectedStartTime"] as? TimeInterval {
            selectedStartTime = Date(timeIntervalSince1970: startTimeInterval)
        }
        
        if let endTimeInterval = highlightingData?["selectedEndTime"] as? TimeInterval {
            selectedEndTime = Date(timeIntervalSince1970: endTimeInterval)
        }
        
        if let minutes = highlightingData?["notificationMinutesBefore"] as? Int {
            notificationMinutesBefore = minutes
        }
    }
    
    private func saveTaskEditData() {
        var taskEditData: [String: Any] = [:]
        
        if let tempStartTimeText = tempStartTimeText {
            taskEditData["tempStartTimeText"] = tempStartTimeText
        }
        
        if let tempEndTimeText = tempEndTimeText {
            taskEditData["tempEndTimeText"] = tempEndTimeText
        }
        
        if let tempStartLocation = tempStartLocation {
            taskEditData["tempStartLocation"] = tempStartLocation
        }
        
        if let tempDestination = tempDestination {
            taskEditData["tempDestination"] = tempDestination
        }
        
        if let tempDescription = tempDescription {
            taskEditData["tempDescription"] = tempDescription
        }
        
        UserDefaults.standard.set(taskEditData, forKey: "task_edit_data")
        
        // Save trusted people as JSON
        if let trustedPeopleData = try? JSONEncoder().encode(tempTrustedPeople) {
            UserDefaults.standard.set(trustedPeopleData, forKey: "temp_trusted_people")
        }
    }
    
    private func loadTaskEditData() {
        let taskEditData = UserDefaults.standard.dictionary(forKey: "task_edit_data")
        
        tempStartTimeText = taskEditData?["tempStartTimeText"] as? String
        tempEndTimeText = taskEditData?["tempEndTimeText"] as? String
        tempStartLocation = taskEditData?["tempStartLocation"] as? String
        tempDestination = taskEditData?["tempDestination"] as? String
        tempDescription = taskEditData?["tempDescription"] as? String
        
        if let trustedPeopleData = UserDefaults.standard.data(forKey: "temp_trusted_people"),
           let trustedPeople = try? JSONDecoder().decode([TrustedPerson].self, from: trustedPeopleData) {
            tempTrustedPeople = trustedPeople
        }
    }
    
    @objc private func appWillResignActive() {
        saveHighlightingData()
        saveTaskEditData()
        saveNotificationIds()
    }

	@objc private func appDidBecomeActive() {
		importAppleCalendarEvents(for: currentSelectedDate)
 	}
 
    func setupYearCollectionView() {
        view.addSubview(yearCollectionView)
        yearCollectionView.tintColor = .systemIndigo
        NSLayoutConstraint.activate([
            yearCollectionView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 10),
            yearCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            yearCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            yearCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }

    @objc func viewModeChanged() {
        calendarView.isHidden = true
        dayNavigationStack?.isHidden = true
        hourlyTableView.isHidden = true
        yearCollectionView.isHidden = true
        addTaskButton.isHidden = true

        switch viewModeControl.selectedSegmentIndex {
        case 0: // Day view
            selectedDateLabel.text = formattedDate(currentSelectedDate)
            dayNavigationStack?.isHidden = false
            hourlyTableView.isHidden = false
            addTaskButton.isHidden = false
        case 1: // Month view
            calendarView.isHidden = false
        case 2: // Year view
            yearCollectionView.isHidden = false
        default:
            break
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hours.count + 2 // 1 for combined task list + 1 for recently completed + 24 hours
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dateKey = stringFromDate(currentSelectedDate)
        let tasksForDate = tasksByDateAndHour[dateKey] ?? [:]
        
        if indexPath.row == 0 {
            let combinedTasks = tasksForDate.keys.sorted().flatMap { tasksForDate[$0] ?? [] }
            let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath) as! TaskListCell
            cell.configure(with: combinedTasks)
            cell.delegate = self
            return cell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath) as! TaskListCell
            cell.configure(with: recentlyCompletedTasks, title: "Recently Completed")
            cell.delegate = self
            return cell
        } else {
            let hourIndex = indexPath.row - 2
            let hourText = hours[hourIndex]
            let tasks = tasksForDate[hourIndex] ?? []
            let cell = tableView.dequeueReusableCell(withIdentifier: "HourTaskCell", for: indexPath) as! HourTaskCell
            cell.configure(hourText: hourText, tasks: tasks, hourIndex: hourIndex)

            if tasks.isEmpty {
                cell.showShadedRegion(startMinute: nil, endMinute: nil)
            } else {
                let name = (tasks.count == 1 ? tasks.first : nil)
                cell.showShadedRegion(startMinute: 0, endMinute: 60, taskName: name)
            }
            
            cell.onHighlightTapped = { [weak self] tappedHour, tappedTaskName in
                guard let self = self else { return }
                if let name = tappedTaskName {
                    self.presentEditTaskPopup(for: name)
                } else {
                    let all = tasksForDate[tappedHour] ?? []
                    if all.count == 1, let only = all.first {
                        self.presentEditTaskPopup(for: only)
                    } else if all.count > 1 {
                        let chooser = UIAlertController(title: "Edit Task", message: "Select a task to edit", preferredStyle: .actionSheet)
                        for t in all {
                            chooser.addAction(UIAlertAction(title: t, style: .default, handler: { _ in
                                self.presentEditTaskPopup(for: t)
                            }))
                        }
                        chooser.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        if let pop = chooser.popoverPresentationController {
                            pop.sourceView = tableView
                            pop.sourceRect = tableView.rectForRow(at: indexPath)
                        }
                        self.present(chooser, animated: true)
                    }
                }
            }
            return cell
        }
    }
    
    func timelineTasks(for date: Date) -> [(start: Date, end: Date)] {
        let dateKey = stringFromDate(date)
        guard let tasksByHour = tasksByDateAndHour[dateKey] else { return [] }
        var result: [(start: Date, end: Date)] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        for (hour, titles) in tasksByHour {
            for _ in titles {
                if let start = calendar.date(byAdding: .hour, value: hour, to: today),
                   let end = calendar.date(byAdding: .hour, value: hour+1, to: today) {
                    result.append((start: start, end: end))
                }
            }
        }
        return result
    }
}

// MARK: - TaskListCellDelegate
extension CalendarViewController: TaskListCellDelegate {
    func didRequestDelete(task: String, atFlatIndex: Int) {
        let dateKey = stringFromDate(currentSelectedDate)
        guard var tasksByHour = tasksByDateAndHour[dateKey] else { return }

        var flatIdx = 0
        var targetHour: Int?
        var targetTaskIndex: Int?
        for hour in tasksByHour.keys.sorted() {
            let tasks = tasksByHour[hour] ?? []
            for (taskIndex, _) in tasks.enumerated() {
                if flatIdx == atFlatIndex {
                    targetHour = hour
                    targetTaskIndex = taskIndex
                    break
                }
                flatIdx += 1
            }
            if targetHour != nil { break }
        }

        let hour: Int
        let index: Int
        if let h = targetHour, let i = targetTaskIndex {
            hour = h
            index = i
        } else {
            guard let pair = tasksByHour.first(where: { $0.value.contains(task) }),
                  let i = pair.value.firstIndex(of: task) else { return }
            hour = pair.key
            index = i
        }

        let key = eventKey(dateKey: dateKey, hour: hour, title: task)
        cancelNotificationIfExists(forKey: key)
        deleteCalendarEventIfExists(dateKey: dateKey, hour: hour, title: task)
        
        var updated = tasksByHour[hour] ?? []
        updated.remove(at: index)
        tasksByHour[hour] = updated.isEmpty ? nil : updated
        if tasksByHour[hour] == nil {
            tasksByHour.removeValue(forKey: hour)
        }

        var full = tasksByDateAndHour
        full[dateKey] = tasksByHour.isEmpty ? nil : tasksByHour
        tasksByDateAndHour = full
        saveTasks()

        if tempTaskTitle == task {
            tempTaskTitle = nil
            selectedStartTime = nil
            selectedEndTime = nil
            tempDateText = nil
        }

        hourlyTableView.reloadData()
    }
    
    func didCompleteTask(task: String) {
        recentlyCompletedTasks.append(task)
        if recentlyCompletedTasks.count > 3 {
            recentlyCompletedTasks.removeFirst(recentlyCompletedTasks.count - 3)
        }
        
        let dateKey = stringFromDate(currentSelectedDate)
        guard var tasksByHour = tasksByDateAndHour[dateKey] else { return }

        for (hour, tasks) in tasksByHour {
            guard let index = tasks.firstIndex(of: task) else { continue }
            let key = eventKey(dateKey: dateKey, hour: hour, title: task)
            cancelNotificationIfExists(forKey: key)
            
            var updated = tasksByHour[hour] ?? []
            updated.remove(at: index)
            tasksByHour[hour] = updated.isEmpty ? nil : updated
            if tasksByHour[hour] == nil { tasksByHour.removeValue(forKey: hour) }
            break
        }

        tasksByDateAndHour[dateKey] = tasksByHour.isEmpty ? nil : tasksByHour
        saveTasks()
        hourlyTableView.reloadData()
    }
    
    func didUncompleteTask(task: String) {
        if let index = recentlyCompletedTasks.firstIndex(of: task) {
            recentlyCompletedTasks.remove(at: index)
        }
        
        let dateKey = stringFromDate(currentSelectedDate)
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        var dayTasks = tasksByDateAndHour[dateKey] ?? [:]
        var hourTasks = dayTasks[currentHour] ?? []
        hourTasks.append(task)
        dayTasks[currentHour] = hourTasks
        tasksByDateAndHour[dateKey] = dayTasks
        
        saveTasks()
        hourlyTableView.reloadData()
    }
    
    func didRequestEdit(task: String) {
        presentEditTaskPopup(for: task)
    }
}

// MARK: - UICollectionView
extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MonthCell", for: indexPath) as! YearMonthCell
        let month = indexPath.item + 1
        cell.configure(month: month, year: 2025)
        
        cell.onMonthTapped = { [weak self] month, year in
            self?.navigateToMonthView(month: month, year: year)
        }
        
        cell.onDateTapped = { [weak self] date in
            self?.navigateToDayView(date: date)
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 24) / 3
        return CGSize(width: width, height: 160)
    }

    @objc func timeFieldTapped(_ sender: UITapGestureRecognizer) {
        guard let textField = sender.view as? UITextField,
              let alert = self.presentedViewController as? UIAlertController else { return }

        let pickerVC = TimePickerViewController()
        pickerVC.modalPresentationStyle = .overFullScreen
        pickerVC.onTimeSelected = { [weak self, weak pickerVC] selectedDate in
            guard let self = self else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            let timeString = formatter.string(from: selectedDate)

            if textField.tag == 1 {
                self.selectedStartTime = selectedDate
                self.tempStartTimeText = timeString
            } else if textField.tag == 2 {
                self.selectedEndTime = selectedDate
                self.tempEndTimeText = timeString
            }

            textField.text = timeString
            self.hourlyTableView.reloadData()
            pickerVC?.dismiss(animated: true)
        }
        pickerVC.onCancel = { [weak pickerVC] in pickerVC?.dismiss(animated: true) }

        alert.present(pickerVC, animated: true)
    }

    @objc func dateFieldTapped(_ sender: UITapGestureRecognizer) {
        guard let textField = sender.view as? UITextField,
              let alert = self.presentedViewController as? UIAlertController else { return }

        let pickerVC = DatePickerViewController()
        pickerVC.modalPresentationStyle = .overFullScreen
        pickerVC.onDateSelected = { [weak self, weak pickerVC] selectedDate in
            guard let self = self else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: selectedDate)
            self.tempDateText = dateString
            textField.text = dateString
            self.hourlyTableView.reloadData()
            pickerVC?.dismiss(animated: true)
        }
        pickerVC.onCancel = { [weak pickerVC] in pickerVC?.dismiss(animated: true) }

        alert.present(pickerVC, animated: true)
    }
    @objc private func openTrustedPeople() {
        let trustedVC = TrustedPeopleViewController()
        present(trustedVC, animated: true)
    }
    @objc private func trustedPeopleFieldTapped(_ sender: UITapGestureRecognizer) {
        guard let textField = sender.view as? UITextField,
              let alert = self.presentedViewController as? UIAlertController else { return }

        let pickerVC = TrustedPeoplePickerViewController()
        pickerVC.modalPresentationStyle = .overFullScreen

        pickerVC.preselectedPeople = Set(self.tempTrustedPeople)

        pickerVC.onSave = { [weak self, weak pickerVC] selected in
            guard let self = self else { return }
            self.tempTrustedPeople = selected
            textField.text = selected.map { $0.name }.joined(separator: ", ")
            pickerVC?.dismiss(animated: true)
        }

        pickerVC.onCancel = { [weak pickerVC] in
            pickerVC?.dismiss(animated: true)
        }

        alert.present(pickerVC, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            let dateKey = stringFromDate(currentSelectedDate)
            let tasksForDate = tasksByDateAndHour[dateKey] ?? [:]
            let combinedTasks = tasksForDate.keys.sorted().flatMap { tasksForDate[$0] ?? [] }
            let taskCount = max(1, min(3, combinedTasks.count))
            return CGFloat(50 + (taskCount * 50))
        } else if indexPath.row == 1 {
            let completedCount = max(1, min(3, recentlyCompletedTasks.count))
            return CGFloat(50 + (completedCount * 50))
        } else {
            return 80
        }
    }
}

// MARK: - Safe Array Index
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
extension CalendarViewController: UNUserNotificationCenterDelegate {
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.banner, .sound])
}
}

// MARK: - UICalendarViewDelegate
extension CalendarViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, didSelectDate dateComponents: DateComponents) {
        guard let date = Calendar.current.date(from: dateComponents) else { 
            return 
        }
        navigateToDayView(date: date)
    }
}

// MARK: - UICalendarSelectionSingleDateDelegate
extension CalendarViewController {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { 
            return 
        }
        navigateToDayView(date: date)
    }
}

