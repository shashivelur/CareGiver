import UIKit

protocol TaskListCellDelegate: AnyObject {
    func didRequestDelete(task: String)
    func didCompleteTask(task: String)
    func didUncompleteTask(task: String)
    func didRequestEdit(task: String)
}

class TaskListCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let taskStack = UIStackView()
    private let scrollView = UIScrollView()
    private let contentViewForScroll = UIView()

    private var taskCheckedStates: [Bool] = []
    private var tasks: [String] = []
    private let maxVisibleTasks = 3
    private let taskHeight: CGFloat = 50
    private var isRecentlyCompletedSection: Bool = false

    weak var delegate: TaskListCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel.text = "Tasks"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        taskStack.axis = .vertical
        taskStack.spacing = 10
        taskStack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentViewForScroll.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(scrollView)
        scrollView.addSubview(contentViewForScroll)
        contentViewForScroll.addSubview(taskStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            contentViewForScroll.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentViewForScroll.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentViewForScroll.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentViewForScroll.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentViewForScroll.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            taskStack.topAnchor.constraint(equalTo: contentViewForScroll.topAnchor),
            taskStack.leadingAnchor.constraint(equalTo: contentViewForScroll.leadingAnchor),
            taskStack.trailingAnchor.constraint(equalTo: contentViewForScroll.trailingAnchor),
            taskStack.bottomAnchor.constraint(equalTo: contentViewForScroll.bottomAnchor)
        ])
    }

    func configure(with tasks: [String], title: String = "Tasks") {
        self.tasks = tasks
        self.titleLabel.text = title
        self.isRecentlyCompletedSection = title == "Recently Completed"
        taskCheckedStates = Array(repeating: false, count: tasks.count)

        taskStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, task) in tasks.enumerated() {
            let taskView = createTaskView(task: task, index: index)
            taskStack.addArrangedSubview(taskView)
        }
        
        // Enable scrolling if more than maxVisibleTasks
        scrollView.isScrollEnabled = tasks.count > maxVisibleTasks
    }

    private func createTaskView(task: String, index: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center
        container.distribution = .fill

        let checkbox = CheckboxButton()
        checkbox.isChecked = isRecentlyCompletedSection ? true : taskCheckedStates[index] // Always checked for recently completed
        checkbox.tag = index
        checkbox.addTarget(self, action: #selector(checkboxToggled(_:)), for: .valueChanged)

        let label = UILabel()
        label.text = task
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.textColor = .black
        label.isUserInteractionEnabled = false // Prevent task completion on label tap

        let optionsButton = UIButton(type: .system)
        optionsButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        optionsButton.tintColor = .gray
        optionsButton.showsMenuAsPrimaryAction = true
        optionsButton.menu = createContextMenu(forTaskAt: index)

        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        optionsButton.setContentHuggingPriority(.required, for: .horizontal)

        container.addArrangedSubview(checkbox)
        container.addArrangedSubview(label)
        container.addArrangedSubview(optionsButton)

        return container
    }

    private func createContextMenu(forTaskAt index: Int) -> UIMenu {
        let taskToDelete = tasks[index]

        // Don't show edit/delete options for recently completed tasks
        if isRecentlyCompletedSection {
            let completedAction = UIAction(title: "Completed", image: UIImage(systemName: "checkmark.circle.fill")) { _ in
                // Do nothing - this is just informational
            }
            completedAction.attributes = .disabled
            return UIMenu(title: "", children: [completedAction])
        }

        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            self.delegate?.didRequestDelete(task: taskToDelete)
        }

        let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
            self.delegate?.didRequestEdit(task: taskToDelete)
        }

        return UIMenu(title: "", children: [edit, delete])
    }

    @objc private func checkboxToggled(_ sender: CheckboxButton) {
        taskCheckedStates[sender.tag] = sender.isChecked
        let task = tasks[sender.tag]
        
        if isRecentlyCompletedSection {
            // For recently completed tasks, allow unchecking
            if !sender.isChecked {
                delegate?.didUncompleteTask(task: task)
            }
        } else {
            // For active tasks, handle completion
            if sender.isChecked {
                delegate?.didCompleteTask(task: task)
            }
        }
    }
}
