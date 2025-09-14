    import UIKit
    import UserNotifications

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
    
    var taskDescription: String = ""
    var selectedDate: Date = Date()
    
    // ✅ Fix: Define the closure property with proper type annotation
    var onTimeSelected: ((Date, Date) -> Void)?
    
    private let startTimePicker = UIDatePicker()
    private let endTimePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Select Time"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        // Configure date pickers
        startTimePicker.datePickerMode = .time
        startTimePicker.preferredDatePickerStyle = .wheels
        startTimePicker.translatesAutoresizingMaskIntoConstraints = false
        
        endTimePicker.datePickerMode = .time
        endTimePicker.preferredDatePickerStyle = .wheels
        endTimePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // Labels
        let startLabel = UILabel()
        startLabel.text = "Start Time"
        startLabel.font = UIFont.boldSystemFont(ofSize: 18)
        startLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let endLabel = UILabel()
        endLabel.text = "End Time"
        endLabel.font = UIFont.boldSystemFont(ofSize: 18)
        endLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let taskLabel = UILabel()
        taskLabel.text = "Task: \(taskDescription)"
        taskLabel.font = UIFont.systemFont(ofSize: 16)
        taskLabel.textColor = .secondaryLabel
        taskLabel.numberOfLines = 0
        taskLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(taskLabel)
        view.addSubview(startLabel)
        view.addSubview(startTimePicker)
        view.addSubview(endLabel)
        view.addSubview(endTimePicker)
        
        NSLayoutConstraint.activate([
            taskLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            taskLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            taskLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            startLabel.topAnchor.constraint(equalTo: taskLabel.bottomAnchor, constant: 30),
            startLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            startTimePicker.topAnchor.constraint(equalTo: startLabel.bottomAnchor, constant: 10),
            startTimePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            endLabel.topAnchor.constraint(equalTo: startTimePicker.bottomAnchor, constant: 30),
            endLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            endTimePicker.topAnchor.constraint(equalTo: endLabel.bottomAnchor, constant: 10),
            endTimePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Set default end time to 1 hour after start time
        if let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: startTimePicker.date) {
            endTimePicker.date = oneHourLater
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneTapped() {
        let startTime = startTimePicker.date
        let endTime = endTimePicker.date
        
        // Validate that end time is after start time
        if endTime <= startTime {
            let alert = UIAlertController(title: "Invalid Time", message: "End time must be after start time", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // ✅ Call the closure with the selected times
        onTimeSelected?(startTime, endTime)
        dismiss(animated: true)
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
    import UIKit

    class CalendarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
        var tempTaskTitle: String?
        var tempStartTimeText: String?
        var tempEndTimeText: String?
        var tempStartLocation: String?
        var tempDestination: String?
        var tempDescription: String?
        var tempTrustedPeople: [TrustedPerson] = []
        var notificationMinutesBefore: Int = 10 // default 10 minutes before


        let calendarView = UICalendarView()
        let selectedDateLabel = UILabel()
        let viewModeControl = UISegmentedControl(items: ["Day", "Month", "Year"])
        var hourlyTableView = UITableView()
        var addTaskButton = UIButton(type: .system)
        var currentSelectedDate = Date()
        var tempDateText: String?
        private var dayNavigationStack: UIStackView!
        var currentCaregiver: Caregiver?

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
            collectionView.backgroundColor = .white
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
            b.tintColor = .systemBlue
            b.accessibilityLabel = "Trusted People"
            b.translatesAutoresizingMaskIntoConstraints = false
            return b
        }()

        // Key = date string ("yyyy-MM-dd"), value = [hour: [tasks]]
        var tasksByDateAndHour: [String: [Int: [String]]] = [:]

        // Store selected time values and which field was tapped
        var selectedStartTime: Date?
        var selectedEndTime: Date?
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

            setupSegmentedControl()
            setupCalendarView()
            setupSelectedDateLabel()
            setupHourlyTableView()
            setupAddTaskButton()
            setupYearCollectionView()
            viewModeChanged()
        }
        

        
        func setupSegmentedControl() {
            viewModeControl.selectedSegmentIndex = 0
            viewModeControl.addTarget(self, action: #selector(viewModeChanged), for: .valueChanged)
            viewModeControl.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(viewModeControl)
            view.addSubview(trustedPeopleButton)

            // ✅ Connect button tap
            trustedPeopleButton.addTarget(self, action: #selector(openTrustedPeople), for: .touchUpInside)

            NSLayoutConstraint.activate([
                trustedPeopleButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
                trustedPeopleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
            ])

            NSLayoutConstraint.activate([
                viewModeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                viewModeControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }

        func setupCalendarView() {
                calendarView.translatesAutoresizingMaskIntoConstraints = false
                calendarView.isHidden = true
                
                // ✅ Add delegate to handle date selection
                calendarView.delegate = self
                
                // ✅ Configure calendar to allow date selection
                let selection = UICalendarSelectionSingleDate(delegate: self)
                calendarView.selectionBehavior = selection
                
                view.addSubview(calendarView)
                NSLayoutConstraint.activate([
                    calendarView.topAnchor.constraint(equalTo: viewModeControl.bottomAnchor, constant: 10),
                    calendarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                    calendarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                    calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
                ])
            }

        @objc func addTaskTapped() {
            let alert = UIAlertController(title: "Add Task", message: "Enter task details", preferredStyle: .alert)
            
            alert.addTextField { textField in
                textField.placeholder = "Task description"
            }
            
            let addAction = UIAlertAction(title: "Add", style: .default) { _ in
                guard let taskText = alert.textFields?[0].text, !taskText.isEmpty else {
                    return
                }
                
                // Show time picker for the task
                self.showTaskTimePicker(taskDescription: taskText)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            alert.addAction(addAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        }
        
        private func showTaskTimePicker(taskDescription: String) {
            let timePickerVC = TimePickerViewController()
            timePickerVC.taskDescription = taskDescription
            timePickerVC.selectedDate = currentSelectedDate
            
            // ✅ Fix: Use the correct property name
            timePickerVC.onTimeSelected = { [weak self] startTime, endTime in
                self?.addTask(description: taskDescription, startTime: startTime, endTime: endTime, date: self?.currentSelectedDate ?? Date())
            }
            
            let navController = UINavigationController(rootViewController: timePickerVC)
            present(navController, animated: true)
        }
        
        private func addTask(description: String, startTime: Date, endTime: Date, date: Date) {
            let dateKey = stringFromDate(date)
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: startTime)
            
            // Initialize the dictionary structure if needed
            if tasksByDateAndHour[dateKey] == nil {
                tasksByDateAndHour[dateKey] = [:]
            }
            
            if tasksByDateAndHour[dateKey]?[hour] == nil {
                tasksByDateAndHour[dateKey]?[hour] = []
            }
            
            // Add the task
            tasksByDateAndHour[dateKey]?[hour]?.append(description)
            
            // Store the time selection for highlighting
            selectedStartTime = startTime
            selectedEndTime = endTime
            tempDateText = stringFromDate(date)
            
            // Reload the table view to show the new task
            hourlyTableView.reloadData()
            
            print("Added task: \(description) at \(hour):00 on \(dateKey)")
        }
        
        
        func setupSelectedDateLabel() {
            selectedDateLabel.translatesAutoresizingMaskIntoConstraints = false
            selectedDateLabel.textAlignment = .center
            selectedDateLabel.textColor = .darkGray
            selectedDateLabel.text = formattedDate(Date()) // ✅ Remove "Today is:" from initial setup
            selectedDateLabel.isHidden = false

            let backButton = UIButton(type: .system)
            backButton.setTitle("<", for: .normal)
            backButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
            backButton.addTarget(self, action: #selector(previousDay), for: .touchUpInside)

            let forwardButton = UIButton(type: .system)
            forwardButton.setTitle(">", for: .normal)
            forwardButton.titleLabel?.font = .boldSystemFont(ofSize: 20)
            forwardButton.addTarget(self, action: #selector(nextDay), for: .touchUpInside)

            dayNavigationStack = UIStackView(arrangedSubviews: [backButton, selectedDateLabel, forwardButton])
            dayNavigationStack.axis = .horizontal
            dayNavigationStack.alignment = .center
            dayNavigationStack.distribution = .equalSpacing
            dayNavigationStack.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(dayNavigationStack)

            NSLayoutConstraint.activate([
                dayNavigationStack.topAnchor.constraint(equalTo: viewModeControl.bottomAnchor, constant: 10),
                dayNavigationStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                dayNavigationStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
            ])
        }

        @objc func previousDay() {
            currentSelectedDate = Calendar.current.date(byAdding: .day, value: -1, to: currentSelectedDate)!
            selectedDateLabel.text = formattedDate(currentSelectedDate) // ✅ Remove "Today is:"
            hourlyTableView.reloadData() // ✅ Reload to show tasks for the new date
        }

        @objc func nextDay() {
            currentSelectedDate = Calendar.current.date(byAdding: .day, value: 1, to: currentSelectedDate)!
            selectedDateLabel.text = formattedDate(currentSelectedDate) // ✅ Remove "Today is:"
            hourlyTableView.reloadData() // ✅ Reload to show tasks for the new date
        }

        func setupHourlyTableView() {
            hourlyTableView = UITableView()
            hourlyTableView.delegate = self
            hourlyTableView.dataSource = self
            
            // Register BOTH cell types
            hourlyTableView.register(HourTaskCell.self, forCellReuseIdentifier: "HourTaskCell")
            hourlyTableView.register(TaskListCell.self, forCellReuseIdentifier: "TaskListCell")
            
            // Disable selection at table view level
            hourlyTableView.allowsSelection = false
            
            // Use automatic row height for dynamic content
            hourlyTableView.rowHeight = UITableView.automaticDimension
            hourlyTableView.estimatedRowHeight = 60
            
            hourlyTableView.translatesAutoresizingMaskIntoConstraints = false
            hourlyTableView.isHidden = false
            view.addSubview(hourlyTableView)

            // ✅ Constrain to safe area instead of addTaskButton
            NSLayoutConstraint.activate([
                hourlyTableView.topAnchor.constraint(equalTo: dayNavigationStack.bottomAnchor, constant: 10),
                hourlyTableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                hourlyTableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                hourlyTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80) // Leave space for button
            ])
        }

        // ✅ Make sure addTaskButton is also added to the main view
        func setupAddTaskButton() {
            addTaskButton = UIButton(type: .system)
            addTaskButton.setTitle("Add Task", for: .normal)
            addTaskButton.backgroundColor = .systemBlue
            addTaskButton.setTitleColor(.white, for: .normal)
            addTaskButton.layer.cornerRadius = 8
            addTaskButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            addTaskButton.addTarget(self, action: #selector(addTaskTapped), for: .touchUpInside)
            addTaskButton.translatesAutoresizingMaskIntoConstraints = false
            
            // ✅ Add to the same view as hourlyTableView
            view.addSubview(addTaskButton)
            
            NSLayoutConstraint.activate([
                addTaskButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
                addTaskButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
                addTaskButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                addTaskButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }

        // ✅ Add this delegate method to handle different row heights
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            if indexPath.row == 0 {
                // TaskListCell - use automatic dimension
                return UITableView.automaticDimension
            } else {
                // HourTaskCell - fixed height
                return 60
            }
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

                guard let title = self.tempTaskTitle, !title.isEmpty else { return }

                // Parse date and time and add task
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                let selectedDate = dateFormatter.date(from: self.tempDateText ?? "") ?? Date()
                let dateKey = self.stringFromDate(selectedDate)

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"
                var hour = 0
                if let startTime = self.tempStartTimeText,
                   let date = timeFormatter.date(from: startTime) {
                    hour = Calendar.current.component(.hour, from: date)
                }

                if self.tasksByDateAndHour[dateKey] == nil {
                    self.tasksByDateAndHour[dateKey] = [:]
                }

                if self.tasksByDateAndHour[dateKey]?[hour] != nil {
                    self.tasksByDateAndHour[dateKey]?[hour]?.append(title)
                } else {
                    self.tasksByDateAndHour[dateKey]?[hour] = [title]
                }

                if let startTime = self.selectedStartTime {
                    self.scheduleTaskNotification(title: title, date: startTime, minutesBefore: self.notificationMinutesBefore)
                }
                
                // Reload table view to show the new task
                self.hourlyTableView.reloadData()
            }

            alert.addAction(add)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            present(alert, animated: true)
        }

        // MARK: - Notification helper
        func scheduleTaskNotification(title: String, date: Date, minutesBefore: Int) {
            let content = UNMutableNotificationContent()
            content.title = "Upcoming Task"
            content.body = title
            content.sound = .default

            let triggerDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: date) ?? date
            let triggerComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                    print("Notification scheduled for \(triggerDate) (\(minutesBefore) minutes before)")
                }
            }
        }

        func setupYearCollectionView() {
            view.addSubview(yearCollectionView)
            NSLayoutConstraint.activate([
                yearCollectionView.topAnchor.constraint(equalTo: viewModeControl.bottomAnchor, constant: 10),
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
                selectedDateLabel.text = formattedDate(currentSelectedDate) // ✅ Use currentSelectedDate instead of Date()
                dayNavigationStack?.isHidden = false
                hourlyTableView.isHidden = false
                addTaskButton.isHidden = false
                hourlyTableView.reloadData() // ✅ Reload to show tasks for current date
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
            return hours.count + 1 // 1 for combined task list + 24 hours
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
            } else {
                let hourIndex = indexPath.row - 1
                let hourText = hours[hourIndex]
                let tasks = tasksForDate[hourIndex] ?? []
                let cell = tableView.dequeueReusableCell(withIdentifier: "HourTaskCell", for: indexPath) as! HourTaskCell
                cell.configure(hourText: hourText, tasks: tasks)

                // Only highlight for the selected date and time
                if let start = selectedStartTime, let end = selectedEndTime, let tempDateText = tempDateText {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .medium
                    let selectedTaskDate = dateFormatter.date(from: tempDateText)
                    let isCurrentDate = Calendar.current.isDate(selectedTaskDate ?? Date(), inSameDayAs: currentSelectedDate)
                    if isCurrentDate {
                        let calendar = Calendar.current
                        var startHour = calendar.component(.hour, from: start)
                        var startMinute = calendar.component(.minute, from: start)
                        startMinute += 30
                        if startMinute >= 60 {
                            startMinute -= 60
                            startHour += 1
                        }

                        var endHour = calendar.component(.hour, from: end)
                        var endMinute = calendar.component(.minute, from: end)
                        endMinute += 30
                        if endMinute >= 60 {
                            endMinute -= 60
                            endHour += 1
                        }

                        if hourIndex == startHour && hourIndex == endHour {
                            cell.showShadedRegion(startMinute: startMinute, endMinute: endMinute)
                        } else if hourIndex == startHour {
                            cell.showShadedRegion(startMinute: startMinute, endMinute: 60)
                        } else if hourIndex > startHour && hourIndex < endHour {
                            cell.showShadedRegion(startMinute: 0, endMinute: 60)
                        } else if hourIndex == endHour {
                            cell.showShadedRegion(startMinute: 0, endMinute: endMinute)
                        } else {
                            cell.showShadedRegion(startMinute: nil, endMinute: nil)
                        }
                    } else {
                        cell.showShadedRegion(startMinute: nil, endMinute: nil)
                    }
                } else {
                    cell.showShadedRegion(startMinute: nil, endMinute: nil)
                }
                return cell
            }
        }

        // Helper to get all tasks for a specific date as (start, end) tuples for DayTimelineView
        func timelineTasks(for date: Date) -> [(start: Date, end: Date)] {
            let dateKey = stringFromDate(date)
            guard let tasksByHour = tasksByDateAndHour[dateKey] else { return [] }
            var result: [(start: Date, end: Date)] = []
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: date)
            for (hour, titles) in tasksByHour {
                for _ in titles {
                    // For demo, assume each task is 1 hour. You can adjust as needed.
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
        func didRequestDelete(task: String) {
            let dateKey = stringFromDate(currentSelectedDate)
            guard var tasksByHour = tasksByDateAndHour[dateKey] else { return }

            for (hour, tasks) in tasksByHour {
                if let index = tasks.firstIndex(of: task) {
                    tasksByHour[hour]?.remove(at: index)
                    if tasksByHour[hour]?.isEmpty == true {
                        tasksByHour.removeValue(forKey: hour)
                    }
                    break
                }
            }

            tasksByDateAndHour[dateKey] = tasksByHour.isEmpty ? nil : tasksByHour
            hourlyTableView.reloadData()
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
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 24) / 3
        return CGSize(width: width, height: 160)
    }

    // ✅ Add this method to handle month selection
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedMonth = indexPath.item + 1
        let currentYear = 2025 // You might want to make this dynamic
        
        // Create a date for the first day of the selected month
        let dateComponents = DateComponents(year: currentYear, month: selectedMonth, day: 1)
        if let selectedDate = Calendar.current.date(from: dateComponents) {
            currentSelectedDate = selectedDate
            
            // Switch to month view to show the selected month
            viewModeControl.selectedSegmentIndex = 1
            viewModeChanged()
            
            // Update calendar to show the selected month
            let calendarDateComponents = DateComponents(year: currentYear, month: selectedMonth)
            calendarView.visibleDateComponents = calendarDateComponents
            
            print("Selected month: \(selectedMonth), year: \(currentYear)")
        }
    }

    @objc func timeFieldTapped(_ sender: UITapGestureRecognizer) {
        guard let textField = sender.view as? UITextField else { return }

        // ✅ Create a simple time picker alert instead of a custom view controller
        let timePickerAlert = UIAlertController(title: "Select Time", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        
        timePickerAlert.view.addSubview(timePicker)
        
        NSLayoutConstraint.activate([
            timePicker.centerXAnchor.constraint(equalTo: timePickerAlert.view.centerXAnchor),
            timePicker.topAnchor.constraint(equalTo: timePickerAlert.view.topAnchor, constant: 50)
        ])
        
        let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
            let selectedDate = timePicker.date
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
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        timePickerAlert.addAction(selectAction)
        timePickerAlert.addAction(cancelAction)
        
        // ✅ Present from the main view controller, not from the alert
        if let presentedAlert = self.presentedViewController {
            presentedAlert.present(timePickerAlert, animated: true)
        } else {
            self.present(timePickerAlert, animated: true)
        }
    }

    @objc func dateFieldTapped(_ sender: UITapGestureRecognizer) {
        guard let textField = sender.view as? UITextField else { return }

        // ✅ Create a simple date picker alert instead of a custom view controller
        let datePickerAlert = UIAlertController(title: "Select Date", message: "\n\n\n\n\n\n", preferredStyle: .alert)
        
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        datePickerAlert.view.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: datePickerAlert.view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: datePickerAlert.view.topAnchor, constant: 50)
        ])
        
        let selectAction = UIAlertAction(title: "Select", style: .default) { _ in
            let selectedDate = datePicker.date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let dateString = formatter.string(from: selectedDate)
            self.tempDateText = dateString
            textField.text = dateString
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        datePickerAlert.addAction(selectAction)
        datePickerAlert.addAction(cancelAction)
        
        // ✅ Present from the main view controller, not from the alert
        if let presentedAlert = self.presentedViewController {
            presentedAlert.present(datePickerAlert, animated: true)
        } else {
            self.present(datePickerAlert, animated: true)
        }
    }

        @objc private func openTrustedPeople() {
            let trustedVC = TrustedPeopleViewController()
            let navVC = UINavigationController(rootViewController: trustedVC) // adds a nav bar
            present(navVC, animated: true)
        }
    
        @objc private func trustedPeopleFieldTapped(_ sender: UITapGestureRecognizer) {
            guard let textField = sender.view as? UITextField,
                  let alert = self.presentedViewController as? UIAlertController else { return }

            let pickerVC = TrustedPeoplePickerViewController()
            pickerVC.modalPresentationStyle = .overFullScreen

            // Preload already selected
            pickerVC.preselectedPeople = Set(self.tempTrustedPeople)

            // Handle save
            pickerVC.onSave = { selected in
                self.tempTrustedPeople = selected
                textField.text = selected.map { $0.name }.joined(separator: ", ")
                pickerVC.dismiss(animated: true)
            }

            // Handle cancel
            pickerVC.onCancel = {
                pickerVC.dismiss(animated: true)
            }

            alert.present(pickerVC, animated: true)
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

// MARK: - UICalendarSelectionSingleDateDelegate
// ✅ This handles clicking on a day in month view
extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let selectedDate = Calendar.current.date(from: dateComponents) else { return }
        
        // Update the current selected date
        currentSelectedDate = selectedDate
        
        // Switch to day view to show the selected date
        viewModeControl.selectedSegmentIndex = 0  // 👈 This switches to day view
        viewModeChanged()
        
        // Update the date label
        selectedDateLabel.text = formattedDate(selectedDate)
        
        // Reload the table view to show tasks for the selected date
        hourlyTableView.reloadData()
        
        print("Selected date: \(selectedDate)")
    }
}

// MARK: - UICalendarViewDelegate
extension CalendarViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        // Optional: Add decorations for dates with tasks
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let dateKey = stringFromDate(date)
        
        if tasksByDateAndHour[dateKey] != nil {
            return .default(color: .systemBlue, size: .large)
        }
        
        return nil
    }
}


