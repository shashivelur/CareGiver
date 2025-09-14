//
//  Patient+CoreDataProperties.swift
//  CareGiver
//
//  Created by Shivank Ahuja on 9/13/25.
//
//

import Foundation
import CoreData


extension Patient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Patient> {
        return NSFetchRequest<Patient>(entityName: "Patient")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var email: String?
    @NSManaged public var firstName: String?
    @NSManaged public var incomeRange: String?
    @NSManaged public var lastName: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var veteranStatus: Bool
    @NSManaged public var caregiver: Caregiver?

}

extension Patient : Identifiable {

}
