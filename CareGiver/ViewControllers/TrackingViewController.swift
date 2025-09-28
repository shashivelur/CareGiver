import UIKit
import CoreLocation
import MapKit

class TrackingViewController: UIViewController {
    var currentCaregiver: Caregiver?

    // MARK: - UI Components
    private let mapView = MKMapView()
    private let registerButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private let devicesTableView = UITableView()
    private let segmentedControl = UISegmentedControl(items: ["Map View", "Devices"])
    
    // MARK: - Core Location
    private let locationManager = CLLocationManager()
    private let beaconManager = BeaconManager()
    
    // MARK: - Data
    private var registeredBeacons: [BeaconDevice] = []
    private var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupBeaconManager()
        loadRegisteredBeacons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startBeaconMonitoring()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBeaconMonitoring()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        title = "Tracking"
        view.backgroundColor = .systemBackground
        
        // Segmented Control
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        // Register Button
        registerButton.setTitle("Register Beacon Device", for: .normal)
        registerButton.backgroundColor = .systemIndigo
        registerButton.setTitleColor(.white, for: .normal)
        registerButton.layer.cornerRadius = 8
        registerButton.addTarget(self, action: #selector(registerBeaconTapped), for: .touchUpInside)
        
        // Status Label
        statusLabel.text = "Bluetooth and Location permissions required"
        statusLabel.textColor = .systemOrange
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        
        // Map View
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Devices Table View
        devicesTableView.dataSource = self
        devicesTableView.delegate = self
        devicesTableView.register(BeaconDeviceCell.self, forCellReuseIdentifier: "BeaconCell")
        devicesTableView.isHidden = true
        
        // Layout
        [segmentedControl, registerButton, statusLabel, mapView, devicesTableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            registerButton.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            registerButton.heightAnchor.constraint(equalToConstant: 44),
            
            statusLabel.topAnchor.constraint(equalTo: registerButton.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            mapView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            devicesTableView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 16),
            devicesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            devicesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            devicesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupBeaconManager() {
        beaconManager.delegate = self
    }
    
    // MARK: - Actions
    @objc private func segmentChanged() {
        let isMapView = segmentedControl.selectedSegmentIndex == 0
        mapView.isHidden = !isMapView
        devicesTableView.isHidden = isMapView
    }
    
    @objc private func registerBeaconTapped() {
        let registerVC = RegisterBeaconViewController()
        registerVC.delegate = self
        let navController = UINavigationController(rootViewController: registerVC)
        present(navController, animated: true)
    }
    
    // MARK: - Beacon Management
    private func loadRegisteredBeacons() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "RegisteredBeacons"),
           let beacons = try? JSONDecoder().decode([BeaconDevice].self, from: data) {
            registeredBeacons = beacons
            updateMapAnnotations()
            devicesTableView.reloadData()
        }
    }
    
    private func saveRegisteredBeacons() {
        if let data = try? JSONEncoder().encode(registeredBeacons) {
            UserDefaults.standard.set(data, forKey: "RegisteredBeacons")
        }
    }
    
    private func startBeaconMonitoring() {
        guard CLLocationManager.locationServicesEnabled() else {
            updateStatus("Location services disabled")
            return
        }
        
        for beacon in registeredBeacons {
            beaconManager.startMonitoring(beacon: beacon)
        }
        
        if !registeredBeacons.isEmpty {
            updateStatus("Monitoring \(registeredBeacons.count) beacon(s)")
        }
    }
    
    private func stopBeaconMonitoring() {
        beaconManager.stopAllMonitoring()
    }
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
    private func updateMapAnnotations() {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        
        for beacon in registeredBeacons {
            if let location = beacon.lastKnownLocation {
                let annotation = BeaconAnnotation(beacon: beacon)
                annotation.coordinate = location.coordinate
                mapView.addAnnotation(annotation)
            }
        }
    }
}

// MARK: - Location Manager Delegate
extension TrackingViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Center map on user location initially
        if mapView.region.span.latitudeDelta > 1 {
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            updateStatus("Location authorized - Ready to track beacons")
        case .denied, .restricted:
            updateStatus("Location access denied - Cannot track beacons")
        case .notDetermined:
            updateStatus("Requesting location permission...")
        @unknown default:
            updateStatus("Unknown location authorization status")
        }
    }
}

// MARK: - Beacon Manager Delegate
extension TrackingViewController: BeaconManagerDelegate {
    func beaconManager(_ manager: BeaconManager, didRangeBeacons beacons: [CLBeacon], for region: CLBeaconRegion) {
        DispatchQueue.main.async {
            for beacon in beacons {
                if let index = self.registeredBeacons.firstIndex(where: { 
                    $0.uuid == beacon.uuid.uuidString && 
                    $0.major == beacon.major.intValue && 
                    $0.minor == beacon.minor.intValue 
                }) {
                    self.registeredBeacons[index].updateProximity(beacon.proximity, rssi: beacon.rssi)
                    self.registeredBeacons[index].lastSeen = Date()
                    
                    if let currentLocation = self.currentLocation {
                        self.registeredBeacons[index].lastKnownLocation = currentLocation
                    }
                }
            }
            
            self.saveRegisteredBeacons()
            self.updateMapAnnotations()
            self.devicesTableView.reloadData()
            
            if !beacons.isEmpty {
                self.updateStatus("Found \(beacons.count) beacon(s) nearby")
            }
        }
    }
    
    func beaconManager(_ manager: BeaconManager, didEnterRegion region: CLBeaconRegion) {
        updateStatus("Entered beacon region: \(region.identifier)")
    }
    
    func beaconManager(_ manager: BeaconManager, didExitRegion region: CLBeaconRegion) {
        updateStatus("Exited beacon region: \(region.identifier)")
    }
    
    func beaconManager(_ manager: BeaconManager, didFailWithError error: Error) {
        updateStatus("Beacon error: \(error.localizedDescription)")
    }
}

// MARK: - Register Beacon Delegate
extension TrackingViewController: RegisterBeaconDelegate {
    func didRegisterBeacon(_ beacon: BeaconDevice) {
        registeredBeacons.append(beacon)
        saveRegisteredBeacons()
        beaconManager.startMonitoring(beacon: beacon)
        updateMapAnnotations()
        devicesTableView.reloadData()
        updateStatus("Registered new beacon: \(beacon.name)")
    }
}

// MARK: - Map View Delegate
extension TrackingViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let beaconAnnotation = annotation as? BeaconAnnotation else {
            return nil
        }
        
        let identifier = "BeaconAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        }
        
        if let markerView = annotationView as? MKMarkerAnnotationView {
            markerView.markerTintColor = beaconAnnotation.beacon.proximityColor
            markerView.glyphImage = UIImage(systemName: "dot.radiowaves.left.and.right")
        }
        
        return annotationView
    }
}

// MARK: - Table View Data Source & Delegate
extension TrackingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registeredBeacons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeaconCell", for: indexPath) as! BeaconDeviceCell
        cell.configure(with: registeredBeacons[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let beacon = registeredBeacons[indexPath.row]
            beaconManager.stopMonitoring(beacon: beacon)
            registeredBeacons.remove(at: indexPath.row)
            saveRegisteredBeacons()
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateMapAnnotations()
        }
    }
}
