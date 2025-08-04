import Foundation
import CoreData

@objc(Caregiver)
public class Caregiver: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Caregiver.entity(), insertInto: context)
    }
    
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")"
    }
    
    var patientsArray: [Patient] {
        let set = patients as? Set<Patient> ?? []
        return set.sorted { $0.firstName ?? "" < $1.firstName ?? "" }
    }
}
