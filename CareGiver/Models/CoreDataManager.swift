import Foundation
import CoreData
import UIKit

class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CareGiver")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // MARK: - Core Data Saving support

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Caregiver Operations
    
    func createCaregiver(username: String, firstName: String, lastName: String, email: String, phoneNumber: String, dateOfBirth: Date) -> Caregiver {
        let caregiver = Caregiver(context: context)
        caregiver.username = username
        caregiver.firstName = firstName
        caregiver.lastName = lastName
        caregiver.email = email
        caregiver.phoneNumber = phoneNumber
        caregiver.dateOfBirth = dateOfBirth
        caregiver.createdAt = Date()
        
        saveContext()
        return caregiver
    }
    
    func fetchCaregivers() -> [Caregiver] {
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching caregivers: \(error)")
            return []
        }
    }
    
    func findCaregiver(username: String) -> Caregiver? {
        let request: NSFetchRequest<Caregiver> = Caregiver.fetchRequest()
        request.predicate = NSPredicate(format: "username == %@", username)
        
        do {
            let caregivers = try context.fetch(request)
            return caregivers.first
        } catch {
            print("Error finding caregiver: \(error)")
            return nil
        }
    }
    
    // MARK: - Patient Operations
    
    func createPatient(firstName: String, lastName: String, dateOfBirth: Date, email: String?, phoneNumber: String?, caregiver: Caregiver) -> Patient {
        let patient = Patient(context: context)
        patient.firstName = firstName
        patient.lastName = lastName
        patient.dateOfBirth = dateOfBirth
        patient.email = email
        patient.phoneNumber = phoneNumber
        patient.createdAt = Date()
        patient.caregiver = caregiver
        
        saveContext()
        return patient
    }
    
    func fetchPatients(for caregiver: Caregiver) -> [Patient] {
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        request.predicate = NSPredicate(format: "caregiver == %@", caregiver)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching patients: \(error)")
            return []
        }
    }
    
    func fetchAllPatients() -> [Patient] {
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching all patients: \(error)")
            return []
        }
    }
}
