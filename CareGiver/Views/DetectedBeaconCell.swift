import UIKit
import CoreLocation

class DetectedBeaconCell: UITableViewCell {
    
    private let signalStrengthView = UIView()
    private let uuidLabel = UILabel()
    private let identifierLabel = UILabel()
    private let proximityLabel = UILabel()
    private let rssiLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Signal Strength View
        signalStrengthView.layer.cornerRadius = 8
        signalStrengthView.translatesAutoresizingMaskIntoConstraints = false
        
        // UUID Label
        uuidLabel.font = .systemFont(ofSize: 14, weight: .medium)
        uuidLabel.textColor = .label
        uuidLabel.numberOfLines = 1
        uuidLabel.lineBreakMode = .byTruncatingMiddle
        
        // Identifier Label
        identifierLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        identifierLabel.textColor = .label
        
        // Proximity Label
        proximityLabel.font = .systemFont(ofSize: 14)
        proximityLabel.textColor = .secondaryLabel
        
        // RSSI Label
        rssiLabel.font = .systemFont(ofSize: 12)
        rssiLabel.textColor = .tertiaryLabel
        
        [signalStrengthView, uuidLabel, identifierLabel, proximityLabel, rssiLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            signalStrengthView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            signalStrengthView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            signalStrengthView.widthAnchor.constraint(equalToConstant: 16),
            signalStrengthView.heightAnchor.constraint(equalToConstant: 16),
            
            identifierLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            identifierLabel.leadingAnchor.constraint(equalTo: signalStrengthView.trailingAnchor, constant: 12),
            identifierLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            uuidLabel.topAnchor.constraint(equalTo: identifierLabel.bottomAnchor, constant: 2),
            uuidLabel.leadingAnchor.constraint(equalTo: identifierLabel.leadingAnchor),
            uuidLabel.trailingAnchor.constraint(equalTo: identifierLabel.trailingAnchor),
            
            proximityLabel.topAnchor.constraint(equalTo: uuidLabel.bottomAnchor, constant: 4),
            proximityLabel.leadingAnchor.constraint(equalTo: identifierLabel.leadingAnchor),
            proximityLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            rssiLabel.centerYAnchor.constraint(equalTo: proximityLabel.centerYAnchor),
            rssiLabel.trailingAnchor.constraint(equalTo: identifierLabel.trailingAnchor),
            rssiLabel.leadingAnchor.constraint(greaterThanOrEqualTo: proximityLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(with beacon: CLBeacon) {
        identifierLabel.text = "Major: \(beacon.major), Minor: \(beacon.minor)"
        uuidLabel.text = beacon.proximityUUID.uuidString
        rssiLabel.text = "RSSI: \(beacon.rssi)"
        
        // Set proximity text and color
        switch beacon.proximity {
        case .immediate:
            proximityLabel.text = "Immediate"
            signalStrengthView.backgroundColor = .systemRed
        case .near:
            proximityLabel.text = "Near"
            signalStrengthView.backgroundColor = .systemOrange
        case .far:
            proximityLabel.text = "Far"
            signalStrengthView.backgroundColor = .systemBlue
        case .unknown:
            proximityLabel.text = "Unknown"
            signalStrengthView.backgroundColor = .systemGray
        @unknown default:
            proximityLabel.text = "Unknown"
            signalStrengthView.backgroundColor = .systemGray
        }
    }
}