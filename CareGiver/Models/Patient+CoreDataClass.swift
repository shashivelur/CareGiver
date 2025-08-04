import Foundation
import CoreData

@objc(Patient)
public class Patient: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Patient.entity(), insertInto: context)
    }
    
    var fullName: String {
        return "\(firstName ?? "") \(lastName ?? "")"
    }
    
    var age: Int {
        guard let dateOfBirth = dateOfBirth else { return 0 }
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year ?? 0
    }
}
