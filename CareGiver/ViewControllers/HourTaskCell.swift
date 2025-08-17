import UIKit
class HourTaskCell: UITableViewCell {

    private let hourLabel = UILabel()
    private let hourLine = UIView()

    private let shadeView = UIView()
    private let taskLabel = UILabel()

    private var shadedStartY: CGFloat?
    private var shadedHeight: CGFloat?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Hour label
        hourLabel.font = UIFont.boldSystemFont(ofSize: 14)
        hourLabel.textColor = .black
        hourLabel.translatesAutoresizingMaskIntoConstraints = false

        // Line to the right of hour label
        hourLine.backgroundColor = .lightGray
        hourLine.translatesAutoresizingMaskIntoConstraints = false

        // Red shaded region
        shadeView.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        shadeView.translatesAutoresizingMaskIntoConstraints = true // we’ll set frame manually
        contentView.addSubview(shadeView)

        // Task label inside shaded region
        taskLabel.font = UIFont.systemFont(ofSize: 14)
        taskLabel.textColor = .black
        taskLabel.textAlignment = .center
        taskLabel.numberOfLines = 0
        shadeView.addSubview(taskLabel)

        // Add other subviews
        contentView.addSubview(hourLabel)
        contentView.addSubview(hourLine)

        // Layout
        NSLayoutConstraint.activate([
            hourLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hourLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            hourLine.leadingAnchor.constraint(equalTo: hourLabel.trailingAnchor, constant: 8),
            hourLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            hourLine.centerYAnchor.constraint(equalTo: hourLabel.centerYAnchor),
            hourLine.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    func configure(hourText: String, tasks: [String]) {
        hourLabel.text = hourText

        if let firstTask = tasks.first {
            taskLabel.text = firstTask
        } else {
            taskLabel.text = nil
        }
    }

    func showShadedRegion(startMinute: Int?, endMinute: Int?) {
        guard let start = startMinute, let end = endMinute else {
            shadeView.isHidden = true
            shadedStartY = nil
            shadedHeight = nil
            return
        }

        shadeView.isHidden = false
        let totalHeight = contentView.bounds.height
        shadedStartY = CGFloat(start) / 60.0 * totalHeight
        shadedHeight = CGFloat(end - start) / 60.0 * totalHeight
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let startY = shadedStartY, let height = shadedHeight {
            let x = hourLabel.frame.maxX + 12
            let width = contentView.bounds.width - x - 16
            shadeView.frame = CGRect(x: x, y: startY, width: width, height: height)

            // Center the task label in the shaded region
            taskLabel.frame = CGRect(x: 4,
                                     y: (height - 20) / 2,
                                     width: shadeView.bounds.width - 8,
                                     height: 20)
            shadeView.isHidden = false
        } else {
            shadeView.isHidden = true
        }
    }
}
