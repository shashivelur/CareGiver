import Foundation
import CoreData

extension Caregiver {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Caregiver> {
        return NSFetchRequest<Caregiver>(entityName: "Caregiver")
    }

    @NSManaged public var username: String?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var patients: NSSet?
    @NSManaged public var password: String?

}

// MARK: Generated accessors for patients
extension Caregiver {

    @objc(addPatientsObject:)
    @NSManaged public func addToPatients(_ value: Patient)

    @objc(removePatientsObject:)
    @NSManaged public func removeFromPatients(_ value: Patient)

    @objc(addPatients:)
    @NSManaged public func addToPatients(_ values: NSSet)

    @objc(removePatients:)
    @NSManaged public func removeFromPatients(_ values: NSSet)

}
