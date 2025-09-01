    import UIKit

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

        let calendarView = UICalendarView()
        let selectedDateLabel = UILabel()
        let viewModeControl = UISegmentedControl(items: ["Day", "Month", "Year"])
        let hourlyTableView = UITableView()
        let addTaskButton = UIButton(type: .system)
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
            view.addSubview(calendarView)
            NSLayoutConstraint.activate([
                calendarView.topAnchor.constraint(equalTo: viewModeControl.bottomAnchor, constant: 10),
                calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        func setupSelectedDateLabel() {
            selectedDateLabel.translatesAutoresizingMaskIntoConstraints = false
            selectedDateLabel.textAlignment = .center
            selectedDateLabel.textColor = .darkGray
            selectedDateLabel.text = "Today is: \(formattedDate(Date()))"
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
                dayNavigationStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                dayNavigationStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }

        @objc func previousDay() {
            currentSelectedDate = Calendar.current.date(byAdding: .day, value: -1, to: currentSelectedDate)!
            selectedDateLabel.text = "Today is: \(formattedDate(currentSelectedDate))"
        }

        @objc func nextDay() {
            currentSelectedDate = Calendar.current.date(byAdding: .day, value: 1, to: currentSelectedDate)!
            selectedDateLabel.text = "Today is: \(formattedDate(currentSelectedDate))"
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
                hourlyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hourlyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hourlyTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
            ])
        }

        func setupAddTaskButton() {
            addTaskButton.setTitle("Add Task", for: .normal)
            addTaskButton.backgroundColor = .systemBlue
            addTaskButton.setTitleColor(.white, for: .normal)
            addTaskButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
            addTaskButton.layer.cornerRadius = 10
            addTaskButton.translatesAutoresizingMaskIntoConstraints = false
            addTaskButton.addTarget(self, action: #selector(presentAddTaskPopup), for: .touchUpInside)
            view.addSubview(addTaskButton)

            NSLayoutConstraint.activate([
                addTaskButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                addTaskButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                addTaskButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                addTaskButton.heightAnchor.constraint(equalToConstant: 50)
            ])
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

            let alert = UIAlertController(title: "New Task", message: nil, preferredStyle: .alert)

            alert.addTextField { $0.placeholder = "Title"; $0.text = self.tempTaskTitle ?? "" }
            alert.addTextField { $0.placeholder = "Start Time"; $0.tag = 1; $0.inputView = UIView(); $0.text = self.tempStartTimeText ?? "" }
            alert.addTextField { $0.placeholder = "End Time"; $0.tag = 2; $0.inputView = UIView(); $0.text = self.tempEndTimeText ?? "" }
            alert.addTextField { $0.placeholder = "Start Location (optional)"; $0.text = self.tempStartLocation ?? "" }
            alert.addTextField { $0.placeholder = "Destination (optional)"; $0.text = self.tempDestination ?? "" }
            alert.addTextField { $0.placeholder = "Description (optional)"; $0.text = self.tempDescription ?? "" }
            alert.addTextField { $0.placeholder = "Date"; $0.tag = 100; $0.inputView = UIView(); $0.text = self.tempDateText ?? "" }

            // Capture references to text fields
            let startTimeField = alert.textFields?.first(where: { $0.tag == 1 })
            let endTimeField = alert.textFields?.first(where: { $0.tag == 2 })
            let dateField = alert.textFields?.first(where: { $0.tag == 100 })

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

                // Parse date and time and add task (same logic as before)
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

                self.hourlyTableView.reloadData()
            }

            alert.addAction(add)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            present(alert, animated: true)
        }

        func setupYearCollectionView() {
            view.addSubview(yearCollectionView)
            NSLayoutConstraint.activate([
                yearCollectionView.topAnchor.constraint(equalTo: viewModeControl.bottomAnchor, constant: 10),
                yearCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
                yearCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
                yearCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                selectedDateLabel.text = "Today is: \(formattedDate(Date()))"
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

        @objc func timeFieldTapped(_ sender: UITapGestureRecognizer) {
            guard let textField = sender.view as? UITextField,
                  let alert = self.presentedViewController as? UIAlertController else { return }

            let pickerVC = TimePickerViewController()
            pickerVC.modalPresentationStyle = .overFullScreen
            pickerVC.onTimeSelected = { selectedDate in
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
                pickerVC.dismiss(animated: true)
            }
            pickerVC.onCancel = { pickerVC.dismiss(animated: true) }

            alert.present(pickerVC, animated: true)
        }

        @objc func dateFieldTapped(_ sender: UITapGestureRecognizer) {
            guard let textField = sender.view as? UITextField,
                  let alert = self.presentedViewController as? UIAlertController else { return }

            let pickerVC = DatePickerViewController()
            pickerVC.modalPresentationStyle = .overFullScreen
            pickerVC.onDateSelected = { selectedDate in
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let dateString = formatter.string(from: selectedDate)
                self.tempDateText = dateString
                textField.text = dateString
                pickerVC.dismiss(animated: true)
            }
            pickerVC.onCancel = { pickerVC.dismiss(animated: true) }

            alert.present(pickerVC, animated: true)
        }
        @objc private func openTrustedPeople() {
            let trustedVC = TrustedPeopleViewController()
            let navVC = UINavigationController(rootViewController: trustedVC) // adds a nav bar
            present(navVC, animated: true)
        }


        // MARK: - TableView Delegate
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80 // Or 100, depending on how much vertical spacing you want
        }
    }

    // MARK: - Safe Array Index
    extension Collection {
        subscript(safe index: Index) -> Element? {
            return indices.contains(index) ? self[index] : nil
        }
    }
