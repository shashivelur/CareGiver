import Foundation
import CoreData

extension Patient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Patient> {
        return NSFetchRequest<Patient>(entityName: "Patient")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var email: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var caregiver: Caregiver?

}
