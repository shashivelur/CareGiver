import UIKit

class DetectedBLEDeviceCell: UITableViewCell {
    
    private let deviceTypeView = UIView()
    private let nameLabel = UILabel()
    private let deviceTypeLabel = UILabel()
    private let identifierLabel = UILabel()
    private let rssiLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Device Type View
        deviceTypeView.layer.cornerRadius = 8
        deviceTypeView.translatesAutoresizingMaskIntoConstraints = false
        
        // Name Label
        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .label
        
        // Device Type Label
        deviceTypeLabel.font = .systemFont(ofSize: 14)
        deviceTypeLabel.textColor = .secondaryLabel
        
        // Identifier Label
        identifierLabel.font = .systemFont(ofSize: 12)
        identifierLabel.textColor = .tertiaryLabel
        identifierLabel.numberOfLines = 1
        identifierLabel.lineBreakMode = .byTruncatingMiddle
        
        // RSSI Label
        rssiLabel.font = .systemFont(ofSize: 12)
        rssiLabel.textColor = .tertiaryLabel
        
        [deviceTypeView, nameLabel, deviceTypeLabel, identifierLabel, rssiLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            deviceTypeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            deviceTypeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deviceTypeView.widthAnchor.constraint(equalToConstant: 16),
            deviceTypeView.heightAnchor.constraint(equalToConstant: 16),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: deviceTypeView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            deviceTypeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            deviceTypeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            deviceTypeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            identifierLabel.topAnchor.constraint(equalTo: deviceTypeLabel.bottomAnchor, constant: 4),
            identifierLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            identifierLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            rssiLabel.centerYAnchor.constraint(equalTo: identifierLabel.centerYAnchor),
            rssiLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            rssiLabel.leadingAnchor.constraint(greaterThanOrEqualTo: identifierLabel.trailingAnchor, constant: 8)
        ])
    }
    
    func configure(with device: DetectedBLEDevice) {
        nameLabel.text = device.name.isEmpty ? "Unknown Device" : device.name
        deviceTypeLabel.text = device.deviceType
        identifierLabel.text = device.identifier
        rssiLabel.text = "RSSI: \(device.rssi)"
        
        // Set color based on device type
        if device.isAppleDevice {
            deviceTypeView.backgroundColor = .systemBlue
        } else {
            deviceTypeView.backgroundColor = .systemGray
        }
    }
}