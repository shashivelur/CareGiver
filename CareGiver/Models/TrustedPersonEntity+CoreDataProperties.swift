import Foundation
import CoreData

extension TrustedPersonEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrustedPersonEntity> {
        return NSFetchRequest<TrustedPersonEntity>(entityName: "TrustedPersonEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var phone: String?
    @NSManaged public var email: String?
}

extension TrustedPersonEntity: Identifiable {}




