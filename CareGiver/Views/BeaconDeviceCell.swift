import UIKit

class BeaconDeviceCell: UITableViewCell {
    
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()
    private let proximityView = UIView()
    private let lastSeenLabel = UILabel()
    private let detailsLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Name Label
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        
        // Status Label
        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        // Proximity View
        proximityView.layer.cornerRadius = 6
        proximityView.translatesAutoresizingMaskIntoConstraints = false
        
        // Last Seen Label
        lastSeenLabel.font = .systemFont(ofSize: 12)
        lastSeenLabel.textColor = .secondaryLabel
        
        // Details Label
        detailsLabel.font = .systemFont(ofSize: 12)
        detailsLabel.textColor = .tertiaryLabel
        detailsLabel.numberOfLines = 0
        
        [nameLabel, statusLabel, proximityView, lastSeenLabel, detailsLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            proximityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            proximityView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            proximityView.widthAnchor.constraint(equalToConstant: 12),
            proximityView.heightAnchor.constraint(equalToConstant: 12),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: proximityView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            lastSeenLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 4),
            lastSeenLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            lastSeenLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            detailsLabel.topAnchor.constraint(equalTo: lastSeenLabel.bottomAnchor, constant: 4),
            detailsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with beacon: BeaconDevice) {
        nameLabel.text = beacon.name
        proximityView.backgroundColor = beacon.proximityColor
        
        if beacon.isNearby {
            statusLabel.text = "\(beacon.proximityString) • RSSI: \(beacon.rssi)"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "Not detected"
            statusLabel.textColor = .systemRed
        }
        
        if let lastSeen = beacon.lastSeen {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            lastSeenLabel.text = "Last seen: \(formatter.string(from: lastSeen))"
        } else {
            lastSeenLabel.text = "Never detected"
        }
        
        detailsLabel.text = "UUID: \(beacon.uuid)\nMajor: \(beacon.major) • Minor: \(beacon.minor)"
    }
}