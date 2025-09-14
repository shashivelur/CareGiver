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
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Make cell non-selectable
        selectionStyle = .none
        
        // Configure title label
        titleLabel.text = "Tasks for Today"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure task stack
        taskStack.axis = .vertical
        taskStack.spacing = 8
        taskStack.alignment = .fill
        taskStack.distribution = .fill
        taskStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to content view
        contentView.addSubview(titleLabel)
        contentView.addSubview(taskStack)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Title label constraints
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Task stack constraints
            taskStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            taskStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            taskStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            taskStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with tasks: [String]) {
        self.tasks = tasks
        self.taskCheckedStates = Array(repeating: false, count: tasks.count)
        
        // Clear existing task views
        taskStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if tasks.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No tasks for today"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = UIFont.systemFont(ofSize: 16)
            emptyLabel.textAlignment = .center
            taskStack.addArrangedSubview(emptyLabel)
        } else {
            // Add task rows
            for (index, task) in tasks.enumerated() {
                let taskRow = createTaskRow(task: task, index: index)
                taskStack.addArrangedSubview(taskRow)
            }
        }
    }
    
    private func createTaskRow(task: String, index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let checkbox = UIButton(type: .system)
        checkbox.setImage(UIImage(systemName: "circle"), for: .normal)
        checkbox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkbox.tintColor = .systemBlue
        checkbox.tag = index
        checkbox.addTarget(self, action: #selector(checkboxTapped(_:)), for: .touchUpInside)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        
        let taskLabel = UILabel()
        taskLabel.text = task
        taskLabel.font = UIFont.systemFont(ofSize: 16)
        taskLabel.textColor = .label
        taskLabel.numberOfLines = 0
        taskLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let deleteButton = UIButton(type: .system)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(checkbox)
        containerView.addSubview(taskLabel)
        containerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            // Container height
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            // Checkbox constraints
            checkbox.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            checkbox.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            checkbox.widthAnchor.constraint(equalToConstant: 30),
            checkbox.heightAnchor.constraint(equalToConstant: 30),
            
            // Task label constraints
            taskLabel.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 12),
            taskLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            taskLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -12),
            
            // Delete button constraints
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        return containerView
    }
    
    @objc private func checkboxTapped(_ sender: UIButton) {
        let index = sender.tag
        taskCheckedStates[index].toggle()
        sender.isSelected = taskCheckedStates[index]
        
        // Update label appearance
        if let containerView = sender.superview,
           let taskLabel = containerView.subviews.compactMap({ $0 as? UILabel }).first {
            taskLabel.textColor = taskCheckedStates[index] ? .secondaryLabel : .label
            taskLabel.alpha = taskCheckedStates[index] ? 0.6 : 1.0
        }
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        let task = tasks[index]
        delegate?.didRequestDelete(task: task)
    }
}
