import UIKit

class DayTimelineView: UIView {
    private let hourHeight: CGFloat = 100  // Stretch space between hours
    private let contentView = UIView()
    private let scrollView = UIScrollView()

    var tasks: [(start: Date, end: Date)] = [] {
        didSet {
            reload()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: hourHeight * 24)
        ])

        addHourLabels()
    }

    private func addHourLabels() {
        for hour in 0..<24 {
            let y = CGFloat(hour) * hourHeight

            let label = UILabel(frame: CGRect(x: 8, y: y, width: 50, height: 20))
            label.text = "\(hour % 12 == 0 ? 12 : hour % 12) \(hour < 12 ? "AM" : "PM")"
            label.font = .systemFont(ofSize: 12)
            label.textColor = .gray
            contentView.addSubview(label)

            // Half-hour line
            let halfLine = UIView(frame: CGRect(x: 60, y: y + hourHeight / 2, width: self.bounds.width - 70, height: 1))
            halfLine.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
            contentView.addSubview(halfLine)
        }
    }

    func reload() {
        // Remove old task blocks
        contentView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

        for task in tasks {
            addTaskBlock(start: task.start, end: task.end)
        }
    }

    private func addTaskBlock(start: Date, end: Date) {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)

        guard let startHour = startComponents.hour,
              let startMinute = startComponents.minute,
              let endHour = endComponents.hour,
              let endMinute = endComponents.minute else { return }

        let startY = CGFloat(startHour) * hourHeight + CGFloat(startMinute) / 60.0 * hourHeight
        let endY = CGFloat(endHour) * hourHeight + CGFloat(endMinute) / 60.0 * hourHeight
        let height = endY - startY

        let taskView = UIView(frame: CGRect(x: 60, y: startY, width: self.bounds.width - 80, height: height))
        taskView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.3)
        taskView.layer.cornerRadius = 10
        taskView.layer.borderWidth = 1.5
        taskView.layer.borderColor = UIColor.red.cgColor
        taskView.tag = 999
        contentView.addSubview(taskView)
    }
}
