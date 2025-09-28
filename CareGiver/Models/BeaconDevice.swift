import Foundation
import CoreLocation
import UIKit

struct BeaconDevice: Codable {
    let id: UUID
    let name: String
    let uuid: String
    let major: Int
    let minor: Int
    let description: String
    let dateRegistered: Date
    
    // Non-codable properties - these will be set at runtime
    var proximity: CLProximity = .unknown
    var rssi: Int = 0
    var lastSeen: Date?
    
    // Store location as codable components instead of CLLocation
    private var lastKnownLatitude: Double?
    private var lastKnownLongitude: Double?
    
    // Computed property to get/set CLLocation
    var lastKnownLocation: CLLocation? {
        get {
            guard let lat = lastKnownLatitude, let lon = lastKnownLongitude else {
                return nil
            }
            return CLLocation(latitude: lat, longitude: lon)
        }
        set {
            if let location = newValue {
                lastKnownLatitude = location.coordinate.latitude
                lastKnownLongitude = location.coordinate.longitude
            } else {
                lastKnownLatitude = nil
                lastKnownLongitude = nil
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, uuid, major, minor, description, dateRegistered
        case lastSeen, lastKnownLatitude, lastKnownLongitude
    }
    
    init(name: String, uuid: String, major: Int, minor: Int, description: String) {
        self.id = UUID()
        self.name = name
        self.uuid = uuid
        self.major = major
        self.minor = minor
        self.description = description
        self.dateRegistered = Date()
        self.proximity = .unknown
        self.rssi = 0
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        uuid = try container.decode(String.self, forKey: .uuid)
        major = try container.decode(Int.self, forKey: .major)
        minor = try container.decode(Int.self, forKey: .minor)
        description = try container.decode(String.self, forKey: .description)
        dateRegistered = try container.decode(Date.self, forKey: .dateRegistered)
        lastSeen = try container.decodeIfPresent(Date.self, forKey: .lastSeen)
        lastKnownLatitude = try container.decodeIfPresent(Double.self, forKey: .lastKnownLatitude)
        lastKnownLongitude = try container.decodeIfPresent(Double.self, forKey: .lastKnownLongitude)
        
        // Set non-codable properties to defaults
        proximity = .unknown
        rssi = 0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(major, forKey: .major)
        try container.encode(minor, forKey: .minor)
        try container.encode(description, forKey: .description)
        try container.encode(dateRegistered, forKey: .dateRegistered)
        try container.encodeIfPresent(lastSeen, forKey: .lastSeen)
        try container.encodeIfPresent(lastKnownLatitude, forKey: .lastKnownLatitude)
        try container.encodeIfPresent(lastKnownLongitude, forKey: .lastKnownLongitude)
    }
    
    mutating func updateProximity(_ proximity: CLProximity, rssi: Int) {
        self.proximity = proximity
        self.rssi = rssi
    }
    
    var proximityString: String {
        switch proximity {
        case .immediate: return "Immediate"
        case .near: return "Near"
        case .far: return "Far"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
    
    var proximityColor: UIColor {
        switch proximity {
        case .immediate: return .systemRed
        case .near: return .systemOrange
        case .far: return .systemBlue
        case .unknown: return .systemGray
        @unknown default: return .systemGray
        }
    }
    
    var isNearby: Bool {
        guard let lastSeen = lastSeen else { return false }
        return Date().timeIntervalSince(lastSeen) < 30 // Consider nearby if seen in last 30 seconds
    }
}
