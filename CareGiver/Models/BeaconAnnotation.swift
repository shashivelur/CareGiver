import MapKit

class BeaconAnnotation: NSObject, MKAnnotation {
    let beacon: BeaconDevice
    var coordinate: CLLocationCoordinate2D
    
    var title: String? {
        return beacon.name
    }
    
    var subtitle: String? {
        return beacon.proximityString
    }
    
    init(beacon: BeaconDevice) {
        self.beacon = beacon
        self.coordinate = beacon.lastKnownLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        super.init()
    }
}