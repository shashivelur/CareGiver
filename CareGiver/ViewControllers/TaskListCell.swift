import UIKit

protocol TaskListCellDelegate: AnyObject {
    func didRequestDelete(task: String)
}

class TaskListCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let taskStack = UIStackView()

    private var taskCheckedStates: [Bool] = []
    private var tasks: [String] = []

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

        contentView.addSubview(titleLabel)
        contentView.addSubview(taskStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            taskStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            taskStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            taskStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            taskStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with tasks: [String]) {
        self.tasks = tasks
        taskCheckedStates = Array(repeating: false, count: tasks.count)

        taskStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (index, task) in tasks.enumerated() {
            let taskView = createTaskView(task: task, index: index)
            taskStack.addArrangedSubview(taskView)
        }
    }

    private func createTaskView(task: String, index: Int) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.spacing = 8
        container.alignment = .center
        container.distribution = .fill

        let checkbox = CheckboxButton()
        checkbox.isChecked = taskCheckedStates[index]
        checkbox.tag = index
        checkbox.addTarget(self, action: #selector(checkboxToggled(_:)), for: .valueChanged)

        let label = UILabel()
        label.text = task
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        label.textColor = .black

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

        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
            self.delegate?.didRequestDelete(task: taskToDelete)
        }

        let edit = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { _ in
            // You can add edit logic here
        }

        return UIMenu(title: "", children: [edit, delete])
    }

    @objc private func checkboxToggled(_ sender: CheckboxButton) {
        taskCheckedStates[sender.tag] = sender.isChecked
    }
}
