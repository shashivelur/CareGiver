import UIKit

class YearMonthCell: UICollectionViewCell {
    private let titleLabel = UILabel()
    private let calendarGrid = MonthCalendarView()
    
    var onMonthTapped: ((Int, Int) -> Void)?
    var onDateTapped: ((Date) -> Void)?
    private var month: Int = 1
    private var year: Int = 2025

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .systemIndigo
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        calendarGrid.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(calendarGrid)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 20),

            calendarGrid.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            calendarGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            calendarGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            calendarGrid.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(month: Int, year: Int) {
        self.month = month
        self.year = year
        
        let formatter = DateFormatter()
        titleLabel.text = formatter.monthSymbols[month - 1]
        calendarGrid.setMonth(month, year: year)
        
        // Add tap gesture to the entire cell for month navigation
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        
        // Set up date tap handling in the calendar grid
        calendarGrid.onDateTapped = { [weak self] date in
            self?.onDateTapped?(date)
        }
    }
    
    @objc private func cellTapped() {
        onMonthTapped?(month, year)
    }
}

