import UIKit
import CoreLocation
import CoreBluetooth

protocol RegisterBeaconDelegate: AnyObject {
    func didRegisterBeacon(_ beacon: BeaconDevice)
}

class RegisterBeaconViewController: UIViewController {
    
    weak var delegate: RegisterBeaconDelegate?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Scanning UI
    private let scanButton = UIButton(type: .system)
    private let scanStatusLabel = UILabel()
    private let detectedDevicesTableView = UITableView()
    private let segmentedControl = UISegmentedControl(items: ["iBeacons", "BLE Devices", "Manual"])
    
    // Manual entry form
    private let formStackView = UIStackView()
    private let nameTextField = UITextField()
    private let uuidTextField = UITextField()
    private let majorTextField = UITextField()
    private let minorTextField = UITextField()
    private let descriptionTextView = UITextView()
    private let registerButton = UIButton(type: .system)
    
    // MARK: - Detection
    private let locationManager = CLLocationManager()
    private var bluetoothManager: CBCentralManager?
    private var detectedBeacons: [CLBeacon] = []
    private var detectedBLEDevices: [DetectedBLEDevice] = []
    private var isScanning = false
    private var scanTimer: Timer?
    
    // Common UUIDs to scan for
    private let commonUUIDs = [
        "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0", // Estimote
        "B9407F30-F5F8-466E-AFF9-25556B57FE6D", // Estimote
        "FDA50693-A4E2-4FB1-AFCF-C6EB07647825", // Kontakt.io
        "F7826DA6-4FA2-4E98-8024-BC5B71E0893E", // Kontakt.io
        "8492E75F-4FD6-469D-B132-043FE94921D8", // Gimbal
        "EBEFD083-70A2-47C8-9837-E7B5634DF524", // Roximity
        "ACFD065E-C3C0-11E3-9BBE-1A514932AC01", // AltBeacon
        "550E8400-E29B-41D4-A716-446655440000",  // Generic test UUID
        // Apple specific UUIDs
        "D0611E78-BBB4-4591-A5F8-487910AE4366", // Apple Continuity
        "8667556C-9A37-4C91-84ED-54EE27D90049", // Apple Watch
        "UUID-1234-5678-9ABC-DEF012345678"       // Generic/Custom
    ]
    
    // Apple service UUIDs for BLE scanning
    private let appleServiceUUIDs = [
        CBUUID(string: "D0611E78-BBB4-4591-A5F8-487910AE4366"), // Apple Continuity
        CBUUID(string: "FD6F"),                                   // AirPods/AirTags
        CBUUID(string: "74EC2172-0BAD-4D01-8F77-997B2BE0722A"), // Apple Watch
        CBUUID(string: "9FA480E0-4967-4542-9390-D343DC5D04AE"), // Handoff
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupBluetoothManager()
        setupKeyboardHandling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    deinit {
        stopScanning()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupUI() {
        title = "Register Device"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Segmented Control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        setupScanningUI()
        setupManualEntryUI()
        setupLayout()
    }
    
    private func setupScanningUI() {
        // Scan Button
        scanButton.setTitle("Scan for Devices", for: .normal)
        scanButton.backgroundColor = .systemBlue
        scanButton.setTitleColor(.white, for: .normal)
        scanButton.layer.cornerRadius = 8
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        
        // Scan Status Label
        scanStatusLabel.text = "Tap 'Scan' to detect nearby devices"
        scanStatusLabel.textColor = .secondaryLabel
        scanStatusLabel.font = .systemFont(ofSize: 14)
        scanStatusLabel.textAlignment = .center
        scanStatusLabel.numberOfLines = 0
        
        // Detected Devices Table
        detectedDevicesTableView.dataSource = self
        detectedDevicesTableView.delegate = self
        detectedDevicesTableView.register(DetectedBeaconCell.self, forCellReuseIdentifier: "DetectedBeaconCell")
        detectedDevicesTableView.register(DetectedBLEDeviceCell.self, forCellReuseIdentifier: "DetectedBLEDeviceCell")
        detectedDevicesTableView.layer.borderColor = UIColor.separator.cgColor
        detectedDevicesTableView.layer.borderWidth = 1
        detectedDevicesTableView.layer.cornerRadius = 8
        detectedDevicesTableView.isHidden = true
    }
    
    private func setupManualEntryUI() {
        // Form Stack View
        formStackView.axis = .vertical
        formStackView.spacing = 16
        formStackView.isHidden = true
        
        setupFormFields()
        
        // Add to form stack
        let labels = ["Device Name:", "UUID:", "Major:", "Minor:", "Description:"]
        let fields = [nameTextField, uuidTextField, majorTextField, minorTextField, descriptionTextView]
        
        for (index, field) in fields.enumerated() {
            let label = UILabel()
            label.text = labels[index]
            label.font = .systemFont(ofSize: 16, weight: .medium)
            
            formStackView.addArrangedSubview(label)
            formStackView.addArrangedSubview(field)
            
            if field == uuidTextField {
                let generateButton = UIButton(type: .system)
                generateButton.setTitle("Generate Sample UUID", for: .normal)
                generateButton.addTarget(self, action: #selector(generateUUITapped), for: .touchUpInside)
                formStackView.addArrangedSubview(generateButton)
            }
        }
        
        formStackView.addArrangedSubview(registerButton)
        
        // Set heights
        [nameTextField, uuidTextField, majorTextField, minorTextField].forEach {
            $0.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        descriptionTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        registerButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func setupFormFields() {
        nameTextField.placeholder = "Device Name (e.g., Patient Room 101)"
        nameTextField.borderStyle = .roundedRect
        
        uuidTextField.placeholder = "UUID"
        uuidTextField.borderStyle = .roundedRect
        uuidTextField.autocapitalizationType = .allCharacters
        
        majorTextField.placeholder = "Major (0-65535)"
        majorTextField.borderStyle = .roundedRect
        majorTextField.keyboardType = .numberPad
        
        minorTextField.placeholder = "Minor (0-65535)"
        minorTextField.borderStyle = .roundedRect
        minorTextField.keyboardType = .numberPad
        
        descriptionTextView.layer.borderColor = UIColor.separator.cgColor
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.font = .systemFont(ofSize: 16)
        descriptionTextView.text = "Optional description..."
        descriptionTextView.textColor = .placeholderText
        descriptionTextView.delegate = self
        
        registerButton.setTitle("Register Device", for: .normal)
        registerButton.backgroundColor = .systemIndigo
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [segmentedControl, scanButton, scanStatusLabel, detectedDevicesTableView, formStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        formStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            scanButton.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
            scanButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scanButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            scanButton.heightAnchor.constraint(equalToConstant: 44),
            
            scanStatusLabel.topAnchor.constraint(equalTo: scanButton.bottomAnchor, constant: 12),
            scanStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            scanStatusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            detectedDevicesTableView.topAnchor.constraint(equalTo: scanStatusLabel.bottomAnchor, constant: 16),
            detectedDevicesTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            detectedDevicesTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            detectedDevicesTableView.heightAnchor.constraint(equalToConstant: 250),
            
            formStackView.topAnchor.constraint(equalTo: detectedDevicesTableView.bottomAnchor, constant: 20),
            formStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            formStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func setupBluetoothManager() {
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Scanning
    private func startScanning() {
        guard let bluetoothManager = bluetoothManager else { return }
        
        let selectedMode = segmentedControl.selectedSegmentIndex
        
        switch selectedMode {
        case 0: // iBeacons
            startBeaconScanning()
        case 1: // BLE Devices
            startBLEScanning()
        default: // Manual
            return
        }
        
        isScanning = true
        scanButton.setTitle("Stop Scanning", for: .normal)
        scanButton.backgroundColor = .systemRed
        detectedDevicesTableView.isHidden = false
        
        // Auto-stop scanning after 30 seconds
        scanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            self.stopScanning()
            self.updateScanStatus("Scan completed")
        }
    }
    
    private func startBeaconScanning() {
        print("Starting beacon scanning...")
        
        guard CLLocationManager.locationServicesEnabled() else {
            updateScanStatus("Location services are disabled. Please enable in Settings.")
            showLocationSettingsAlert()
            return
        }
        
        let authStatus = locationManager.authorizationStatus
        print("Location authorization status: \(authStatus.rawValue)")
        
        switch authStatus {
        case .notDetermined:
            updateScanStatus("Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
            return
        case .denied, .restricted:
            updateScanStatus("Location permission denied. Please enable in Settings.")
            showLocationSettingsAlert()
            return
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            updateScanStatus("Unknown location permission status")
            return
        }
        
        // Check if ranging is available
        guard CLLocationManager.isRangingAvailable() else {
            updateScanStatus("Beacon ranging is not available on this device")
            return
        }
        
        detectedBeacons.removeAll()
        detectedDevicesTableView.reloadData()
        updateScanStatus("Scanning for iBeacons...")
        
        // Start scanning for common UUIDs
        var regionsStarted = 0
        for uuidString in commonUUIDs {
            if let uuid = UUID(uuidString: uuidString) {
                let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuidString)
                region.notifyOnEntry = true
                region.notifyOnExit = true
                
                locationManager.startMonitoring(for: region)
                locationManager.startRangingBeacons(in: region)
                regionsStarted += 1
                
                print("Started ranging for UUID: \(uuidString)")
            } else {
                print("Invalid UUID: \(uuidString)")
            }
        }
        
        if regionsStarted == 0 {
            updateScanStatus("No valid UUIDs to scan for")
        } else {
            updateScanStatus("Scanning \(regionsStarted) beacon regions...")
        }
    }
    
    private func startBLEScanning() {
        print("Starting BLE scanning...")
        
        guard let bluetoothManager = bluetoothManager else {
            updateScanStatus("Bluetooth manager not available")
            return
        }
        
        print("Bluetooth state: \(bluetoothManager.state.rawValue)")
        
        switch bluetoothManager.state {
        case .unknown, .resetting:
            updateScanStatus("Bluetooth is initializing...")
            return
        case .unsupported:
            updateScanStatus("Bluetooth is not supported on this device")
            return
        case .unauthorized:
            updateScanStatus("Bluetooth access denied. Please enable in Settings.")
            showBluetoothSettingsAlert()
            return
        case .poweredOff:
            updateScanStatus("Bluetooth is turned off. Please enable Bluetooth.")
            showBluetoothSettingsAlert()
            return
        case .poweredOn:
            break
        @unknown default:
            updateScanStatus("Unknown Bluetooth state")
            return
        }
        
        detectedBLEDevices.removeAll()
        detectedDevicesTableView.reloadData()
        updateScanStatus("Scanning for BLE devices...")
        
        // Scan for all devices (pass nil for services to find all devices)
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ]
        
        bluetoothManager.scanForPeripherals(withServices: nil, options: options)
        print("BLE scanning started")
    }
    
    private func stopScanning() {
        guard isScanning else { return }
        
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil
        
        // Stop beacon scanning
        for uuidString in commonUUIDs {
            if let uuid = UUID(uuidString: uuidString) {
                let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuidString)
                locationManager.stopRangingBeacons(in: region)
            }
        }
        
        // Stop BLE scanning
        bluetoothManager?.stopScan()
        
        scanButton.setTitle("Scan for Devices", for: .normal)
        scanButton.backgroundColor = .systemBlue
        
        let selectedMode = segmentedControl.selectedSegmentIndex
        let count = selectedMode == 0 ? detectedBeacons.count : detectedBLEDevices.count
        let deviceType = selectedMode == 0 ? "beacon(s)" : "BLE device(s)"
        
        if count == 0 {
            updateScanStatus("No \(deviceType) detected nearby")
        } else {
            updateScanStatus("Found \(count) \(deviceType). Tap to select one.")
        }
    }
    
    private func updateScanStatus(_ message: String) {
        DispatchQueue.main.async {
            self.scanStatusLabel.text = message
        }
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let selectedMode = segmentedControl.selectedSegmentIndex
        
        if selectedMode == 2 { // Manual
            detectedDevicesTableView.isHidden = true
            scanButton.isHidden = true
            scanStatusLabel.isHidden = true
            formStackView.isHidden = false
        } else {
            detectedDevicesTableView.isHidden = false
            scanButton.isHidden = false
            scanStatusLabel.isHidden = false
            formStackView.isHidden = true
            
            // Clear previous results when switching modes
            detectedBeacons.removeAll()
            detectedBLEDevices.removeAll()
            detectedDevicesTableView.reloadData()
            
            let deviceType = selectedMode == 0 ? "iBeacons" : "BLE devices"
            updateScanStatus("Tap 'Scan' to detect nearby \(deviceType)")
        }
    }
    
    @objc private func scanButtonTapped() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @objc private func cancelTapped() {
        stopScanning()
        dismiss(animated: true)
    }
    
    @objc private func generateUUITapped() {
        uuidTextField.text = UUID().uuidString
    }
    
    @objc private func registerTapped() {
        guard validateForm() else { return }
        
        let beacon = BeaconDevice(
            name: nameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            uuid: uuidTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines),
            major: Int(majorTextField.text!) ?? 0,
            minor: Int(minorTextField.text!) ?? 0,
            description: getDescriptionText()
        )
        
        delegate?.didRegisterBeacon(beacon)
        dismiss(animated: true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.scrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Device Selection
    private func selectDetectedBeacon(_ beacon: CLBeacon) {
        uuidTextField.text = beacon.proximityUUID.uuidString
        majorTextField.text = String(beacon.major.intValue)
        minorTextField.text = String(beacon.minor.intValue)
        nameTextField.text = "Beacon \(beacon.major):\(beacon.minor)"
        
        segmentedControl.selectedSegmentIndex = 2
        segmentChanged()
    }
    
    private func selectDetectedBLEDevice(_ device: DetectedBLEDevice) {
        // Generate a pseudo-beacon configuration for BLE devices
        let pseudoUUID = generatePseudoUUID(from: device.identifier)
        
        uuidTextField.text = pseudoUUID
        majorTextField.text = "1"
        minorTextField.text = String(abs(device.identifier.hashValue % 65536))
        nameTextField.text = device.name
        descriptionTextView.text = "BLE Device: \(device.deviceType)"
        descriptionTextView.textColor = .label
        
        segmentedControl.selectedSegmentIndex = 2
        segmentChanged()
    }
    
    private func generatePseudoUUID(from identifier: String) -> String {
        // Generate a consistent UUID based on the device identifier
        let hash = identifier.hashValue
        let uuid = UUID()
        return uuid.uuidString
    }
    
    // MARK: - Validation
    private func validateForm() -> Bool {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showAlert(title: "Invalid Name", message: "Please enter a device name.")
            return false
        }
        
        guard let uuidString = uuidTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              UUID(uuidString: uuidString) != nil else {
            showAlert(title: "Invalid UUID", message: "Please enter a valid UUID.")
            return false
        }
        
        guard let majorText = majorTextField.text,
              let major = Int(majorText),
              major >= 0 && major <= 65535 else {
            showAlert(title: "Invalid Major", message: "Major must be between 0 and 65535.")
            return false
        }
        
        guard let minorText = minorTextField.text,
              let minor = Int(minorText),
              minor >= 0 && minor <= 65535 else {
            showAlert(title: "Invalid Minor", message: "Minor must be between 0 and 65535.")
            return false
        }
        
        return true
    }
    
    private func getDescriptionText() -> String {
        let text = descriptionTextView.text ?? ""
        return text == "Optional description..." ? "" : text
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Alerts
    private func showLocationSettingsAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "Please enable location services in Settings to detect iBeacon devices.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showBluetoothSettingsAlert() {
        let alert = UIAlertController(
            title: "Bluetooth Access Required",
            message: "Please enable Bluetooth in Settings to detect BLE devices.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Bluetooth Central Manager Delegate
extension RegisterBeaconViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Bluetooth state updated to: \(central.state.rawValue)")
        
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                if self.isScanning && self.segmentedControl.selectedSegmentIndex == 1 {
                    self.startBLEScanning()
                }
            case .poweredOff:
                self.updateScanStatus("Bluetooth is turned off")
            case .unauthorized:
                self.updateScanStatus("Bluetooth access denied")
            case .unsupported:
                self.updateScanStatus("Bluetooth not supported")
            case .unknown, .resetting:
                self.updateScanStatus("Bluetooth state unknown")
            @unknown default:
                self.updateScanStatus("Unknown Bluetooth state")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Discovered peripheral: \(peripheral.name ?? "Unknown") with RSSI: \(RSSI)")
        
        let device = DetectedBLEDevice(
            identifier: peripheral.identifier.uuidString,
            name: peripheral.name ?? "Unknown Device",
            rssi: RSSI.intValue,
            advertisementData: advertisementData
        )
        
        DispatchQueue.main.async {
            // Check if we already have this device
            if !self.detectedBLEDevices.contains(where: { $0.identifier == device.identifier }) {
                self.detectedBLEDevices.append(device)
                self.detectedBLEDevices.sort { $0.rssi > $1.rssi }
                self.detectedDevicesTableView.reloadData()
                
                self.updateScanStatus("Found \(self.detectedBLEDevices.count) BLE device(s). Tap to select one.")
            }
        }
    }
}

// MARK: - Location Manager Delegate
extension RegisterBeaconViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization changed to: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isScanning && segmentedControl.selectedSegmentIndex == 0 {
                DispatchQueue.main.async {
                    self.startBeaconScanning()
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.updateScanStatus("Location access denied - Cannot scan for beacons")
            }
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        print("Did range \(beacons.count) beacons in region: \(region.identifier)")
        
        DispatchQueue.main.async {
            for beacon in beacons {
                print("Found beacon: UUID=\(beacon.proximityUUID), Major=\(beacon.major), Minor=\(beacon.minor), RSSI=\(beacon.rssi)")
                
                if !self.detectedBeacons.contains(where: { existing in
                    existing.proximityUUID == beacon.proximityUUID &&
                    existing.major == beacon.major &&
                    existing.minor == beacon.minor
                }) {
                    self.detectedBeacons.append(beacon)
                }
            }
            
            self.detectedBeacons.sort { $0.rssi > $1.rssi }
            self.detectedDevicesTableView.reloadData()
            
            if !self.detectedBeacons.isEmpty {
                self.updateScanStatus("Found \(self.detectedBeacons.count) beacon(s). Tap to select one.")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        print("Ranging failed for region \(region.identifier): \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.updateScanStatus("Ranging failed: \(error.localizedDescription)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }
}

// MARK: - Table View Data Source & Delegate
extension RegisterBeaconViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let selectedMode = segmentedControl.selectedSegmentIndex
        return selectedMode == 0 ? detectedBeacons.count : detectedBLEDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let selectedMode = segmentedControl.selectedSegmentIndex
        
        if selectedMode == 0 { // iBeacons
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetectedBeaconCell", for: indexPath) as! DetectedBeaconCell
            cell.configure(with: detectedBeacons[indexPath.row])
            return cell
        } else { // BLE Devices
            let cell = tableView.dequeueReusableCell(withIdentifier: "DetectedBLEDeviceCell", for: indexPath) as! DetectedBLEDeviceCell
            cell.configure(with: detectedBLEDevices[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedMode = segmentedControl.selectedSegmentIndex
        
        if selectedMode == 0 { // iBeacons
            let beacon = detectedBeacons[indexPath.row]
            selectDetectedBeacon(beacon)
        } else { // BLE Devices
            let device = detectedBLEDevices[indexPath.row]
            selectDetectedBLEDevice(device)
        }
        
        stopScanning()
    }
}

// MARK: - Text View Delegate
extension RegisterBeaconViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Optional description..." {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Optional description..."
            textView.textColor = .placeholderText
        }
    }
}