import UIKit

    class MonthCalendarView: UIView {
        private var month: Int = 1
        private var year: Int = 2025
        private var dayLabels: [UILabel] = []

        func setMonth(_ month: Int, year: Int) {
            self.month = month
            self.year = year
            setupCalendar()
        }

        private func setupCalendar() {
            // Remove old labels
            dayLabels.forEach { $0.removeFromSuperview() }
            dayLabels.removeAll()

            let calendar = Calendar.current
            let dateComponents = DateComponents(year: year, month: month)
            guard let startOfMonth = calendar.date(from: dateComponents),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return }

            let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
            let totalDays = range.count
            let columns = 7
            let rows = 6
            let cellWidth = bounds.width / CGFloat(columns)
            let cellHeight = bounds.height / CGFloat(rows)

            var day = 1
            for i in 0..<rows * columns {
                let row = i / columns
                let col = i % columns
                let x = CGFloat(col) * cellWidth
                let y = CGFloat(row) * cellHeight

                if i >= firstWeekday && day <= totalDays {
                    let label = UILabel(frame: CGRect(x: x, y: y, width: cellWidth, height: cellHeight))
                    label.text = "\(day)"
                    label.font = .systemFont(ofSize: 10)
                    label.textColor = .black
                    label.textAlignment = .center
                    addSubview(label)
                    dayLabels.append(label)
                    day += 1
                }
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            setupCalendar()
        }
    }
