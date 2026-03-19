import UIKit

class HourTaskCell: UITableViewCell {
    
    private let hourLabel = UILabel()
    private let hourLine = UIView()
    private let shadeView = UIView()
    private let taskLabel = UILabel()
    
    // Store multiple shaded regions for overlapping tasks
    private var shadedRegions: [(startFraction: CGFloat, heightFraction: CGFloat, color: UIColor)] = []
    
    // Keep track of the hour index and tasks shown in this cell
    private var hourIndex: Int = 0
    private var currentTasks: [String] = []
    
    // Callback invoked when the shaded highlight is tapped
    var onHighlightTapped: ((Int, String?) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        selectionStyle = .none
        
        // Hour label
        hourLabel.font = UIFont.boldSystemFont(ofSize: 14)
        hourLabel.textColor = .label
        hourLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Hour line
        hourLine.backgroundColor = .lightGray
        hourLine.translatesAutoresizingMaskIntoConstraints = false
        
        // Shaded region
        shadeView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        shadeView.translatesAutoresizingMaskIntoConstraints = true // we set frame manually
        shadeView.layer.cornerRadius = 4
        contentView.addSubview(shadeView)
        
        // Tap on shaded region to edit
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleShadeTap))
        shadeView.addGestureRecognizer(tap)
        shadeView.isUserInteractionEnabled = true
        
        // Task label
        taskLabel.font = UIFont.systemFont(ofSize: 14)
        taskLabel.textColor = .label
        taskLabel.textAlignment = .center
        taskLabel.numberOfLines = 0
        shadeView.addSubview(taskLabel)
        
        // Add other subviews
        contentView.addSubview(hourLabel)
        contentView.addSubview(hourLine)
        
        NSLayoutConstraint.activate([
            hourLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hourLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            hourLine.leadingAnchor.constraint(equalTo: hourLabel.trailingAnchor, constant: 8),
            hourLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hourLine.centerYAnchor.constraint(equalTo: hourLabel.centerYAnchor),
            hourLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    // Existing API kept for compatibility
    func configure(hourText: String, tasks: [String]) {
        hourLabel.text = hourText
        currentTasks = tasks
        if tasks.count > 1 {
            taskLabel.text = tasks.joined(separator: "\n")
        } else {
            taskLabel.text = tasks.first
        }
    }
    
    // New overload that also stores hour index
    func configure(hourText: String, tasks: [String], hourIndex: Int) {
        self.hourIndex = hourIndex
        configure(hourText: hourText, tasks: tasks)
    }
    
    // Call this with startMinute/endMinute of the task
    func showShadedRegion(startMinute: Int?, endMinute: Int?, taskName: String? = nil) {
        guard let start = startMinute, let end = endMinute else {
            shadeView.isHidden = true
            shadedRegions.removeAll()
            return
        }
        
        shadeView.isHidden = false
        // Store as fractions, not pixels - fix the 30-minute mark issue
        let startFraction = CGFloat(start) / 60.0
        let heightFraction = CGFloat(max(0, end - start)) / 60.0
        
        // Clear existing regions and add new one - only one highlighting at a time
        shadedRegions.removeAll()
        shadedRegions.append((startFraction: startFraction, heightFraction: heightFraction, color: UIColor.systemRed.withAlphaComponent(0.3)))
        
        // Update task label if provided
        if let taskName = taskName {
            taskLabel.text = taskName
        }
        
        setNeedsLayout()
    }
    
    // Add multiple overlapping tasks
    func addShadedRegion(startMinute: Int, endMinute: Int, color: UIColor = UIColor.systemBlue.withAlphaComponent(0.3)) {
        let startFraction = CGFloat(startMinute) / 60.0
        let heightFraction = CGFloat(max(0, endMinute - startMinute)) / 60.0
        
        shadedRegions.append((startFraction: startFraction, heightFraction: heightFraction, color: color))
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !shadedRegions.isEmpty else {
            shadeView.isHidden = true
            return
        }
        
        let totalHeight = contentView.bounds.height
        let x = hourLabel.frame.maxX + 12
        let width = contentView.bounds.width - x - 16
        
        // Only handle single region to prevent multiple highlighting
        if shadedRegions.count == 1 {
            let region = shadedRegions[0]
            let y = region.startFraction * totalHeight
            let h = region.heightFraction * totalHeight
            
            // Ensure proper positioning without 30-minute mark separation
            shadeView.frame = CGRect(x: x, y: y, width: width, height: h)
            shadeView.backgroundColor = region.color
            
            // Center the task label inside the shaded region
            let labelHeight: CGFloat = min(20, h)
            taskLabel.frame = CGRect(
                x: 4,
                y: max(0, (h - labelHeight) / 2),
                width: shadeView.bounds.width - 8,
                height: labelHeight
            )
        }
        
        shadeView.isHidden = false
    }
    
    @objc private func handleShadeTap() {
        // If there’s exactly one task, pass its name; otherwise nil so controller can present a chooser
        let taskName: String? = (currentTasks.count == 1 ? currentTasks.first : nil)
        onHighlightTapped?(hourIndex, taskName)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        onHighlightTapped = nil
        currentTasks = []
        hourIndex = 0
        // We intentionally keep shadedRegions so highlight doesn’t flicker away
    }
}

