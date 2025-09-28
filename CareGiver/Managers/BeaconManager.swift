import Foundation
import CoreLocation

protocol BeaconManagerDelegate: AnyObject {
    func beaconManager(_ manager: BeaconManager, didRangeBeacons beacons: [CLBeacon], for region: CLBeaconRegion)
    func beaconManager(_ manager: BeaconManager, didEnterRegion region: CLBeaconRegion)
    func beaconManager(_ manager: BeaconManager, didExitRegion region: CLBeaconRegion)
    func beaconManager(_ manager: BeaconManager, didFailWithError error: Error)
}

class BeaconManager: NSObject {
    
    weak var delegate: BeaconManagerDelegate?
    private let locationManager = CLLocationManager()
    private var monitoredRegions: Set<CLBeaconRegion> = []
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func startMonitoring(beacon: BeaconDevice) {
        guard let uuid = UUID(uuidString: beacon.uuid) else { return }
        
        let region = CLBeaconRegion(
            proximityUUID: uuid,
            major: CLBeaconMajorValue(beacon.major),
            minor: CLBeaconMinorValue(beacon.minor),
            identifier: beacon.id.uuidString
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        locationManager.startRangingBeacons(in: region)
        monitoredRegions.insert(region)
    }
    
    func stopMonitoring(beacon: BeaconDevice) {
        let regionToRemove = monitoredRegions.first { $0.identifier == beacon.id.uuidString }
        if let region = regionToRemove {
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(in: region)
            monitoredRegions.remove(region)
        }
    }
    
    func stopAllMonitoring() {
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(in: region)
        }
        monitoredRegions.removeAll()
    }
}

extension BeaconManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        delegate?.beaconManager(self, didRangeBeacons: beacons, for: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        delegate?.beaconManager(self, didEnterRegion: beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let beaconRegion = region as? CLBeaconRegion else { return }
        delegate?.beaconManager(self, didExitRegion: beaconRegion)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.beaconManager(self, didFailWithError: error)
    }
    
    func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
        delegate?.beaconManager(self, didFailWithError: error)
    }
}