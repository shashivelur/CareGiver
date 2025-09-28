import Foundation

struct DetectedBLEDevice {
    let identifier: String
    let name: String
    let rssi: Int
    let advertisementData: [String: Any]
    let detectionTime: Date
    
    init(identifier: String, name: String, rssi: Int, advertisementData: [String: Any]) {
        self.identifier = identifier
        self.name = name
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.detectionTime = Date()
    }
    
    var deviceType: String {
        // Try to determine device type from advertisement data
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let manufacturerDataString = manufacturerData.map { String(format: "%02X", $0) }.joined()
            
            // Apple manufacturer ID is 0x004C
            if manufacturerDataString.hasPrefix("4C00") {
                // Try to identify specific Apple devices based on advertisement patterns
                if name.contains("AirPods") {
                    return "AirPods"
                } else if name.contains("Apple Watch") || name.contains("Watch") {
                    return "Apple Watch"
                } else if manufacturerDataString.count >= 8 {
                    // AirTags have specific patterns in their manufacturer data
                    let typeCode = String(manufacturerDataString.prefix(8))
                    switch typeCode {
                    case "4C001207": return "AirTag"
                    case "4C001006": return "iPhone"
                    case "4C000F05": return "Apple Watch"
                    default: return "Apple Device"
                    }
                }
                return "Apple Device"
            }
        }
        
        // Check service UUIDs
        if let serviceUUIDs = advertisementData["kCBAdvDataServiceUUIDs"] as? [String] {
            for uuid in serviceUUIDs {
                switch uuid.uppercased() {
                case "FD6F": return "AirPods/AirTag"
                case "D0611E78-BBB4-4591-A5F8-487910AE4366": return "Apple Continuity Device"
                default: break
                }
            }
        }
        
        // Fallback to name-based detection
        if name.isEmpty || name == "Unknown Device" {
            return "BLE Device"
        } else {
            return name
        }
    }
    
    var isAppleDevice: Bool {
        return deviceType.contains("Apple") || 
               deviceType.contains("iPhone") ||
               deviceType.contains("iPad") ||
               deviceType.contains("AirPods") ||
               deviceType.contains("AirTag") ||
               deviceType.contains("Apple Watch")
    }
}