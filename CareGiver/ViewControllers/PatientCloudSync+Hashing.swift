import Foundation
import CoreData

/// Extension on PatientCloudSync to handle hashing of patient data before cloud operations and decoding when loading.
/// 
/// This approach hashes textual patient fields (firstName, lastName, email, phoneNumber, incomeRange) using a one-way SHA256 hash before sending them to the cloud,
/// improving privacy by never storing cleartext personally identifiable information in the cloud.
/// Non-text fields (dateOfBirth, veteranStatus) are sent in cleartext form.
/// Due to the one-way nature of hashing, decoding cannot restore original text fields from their hashes. The app must maintain local plaintext in Core Data as the source of truth.
/// This extension provides helpers to upsert hashed patient data and decode non-hashed fields from a hashed dictionary.
extension PatientCloudSync {
    
    /// Hook for performing the actual upsert with a hashed payload.
    /// Set this from elsewhere in the app to provide the concrete cloud upsert implementation.
    /// Example:
    /// PatientCloudSync.performUpsert = { payload in
    ///     CloudClient.shared.upsertPatient(payload)
    /// }
    static var performUpsert: (([String: Any]) -> Void)?
    
    /// Upserts a patient to the cloud with textual fields hashed using SHA256.
    /// - Parameter patient: The Patient object to be upserted.
    static func upsertHashedPatient(_ patient: Patient) {
        var payload: [String: Any] = [:]
        
        // Hash textual fields with SHA256, skip if nil
        if let firstName = patient.firstName {
            payload["firstName"] = HasherUtil.sha256(firstName)
        }
        if let lastName = patient.lastName {
            payload["lastName"] = HasherUtil.sha256(lastName)
        }
        if let email = patient.email {
            payload["email"] = HasherUtil.sha256(email)
        }
        if let phoneNumber = patient.phoneNumber {
            payload["phoneNumber"] = HasherUtil.sha256(phoneNumber)
        }
        if let incomeRange = patient.incomeRange {
            payload["incomeRange"] = HasherUtil.sha256(incomeRange)
        }
        
        // Non-text fields
        if let dob = patient.dateOfBirth {
            payload["dateOfBirth"] = dob.timeIntervalSince1970
        }
        payload["veteranStatus"] = patient.veteranStatus
        
        // Stable identifier for matching
        payload["localObjectURI"] = patient.objectID.uriRepresentation().absoluteString
        
        // Timestamp of update
        payload["updatedAt"] = Date().timeIntervalSince1970
        
        upsertHashedPayload(payload)
    }
    
    /// Internal helper to forward the hashed patient payload to the underlying upsert API.
    /// Attempts to call the provided performUpsert hook.
    /// - Parameter payload: Dictionary containing hashed and non-hashed patient data.
    private static func upsertHashedPayload(_ payload: [String: Any]) {
        if let performUpsert {
            performUpsert(payload)
        } else {
            #if DEBUG
            print("[PatientCloudSync] performUpsert not set; skipping cloud upsert for payload with keys: \(payload.keys.sorted())")
            #endif
        }
    }
    
    /// Decodes patient fields from a hashed dictionary into the given Patient object.
    /// 
    /// Due to the one-way nature of SHA256 hashing, textual fields cannot be restored from their hashes.
    /// This method only updates non-text fields (dateOfBirth, veteranStatus) and leaves textual fields unchanged.
    /// The app must maintain plaintext locally in Core Data as the source of truth.
    /// - Parameters:
    ///   - hashed: Dictionary containing hashed and non-hashed patient data from the cloud.
    ///   - patient: The Patient object to update.
    static func decodePatientFields(from hashed: [String: Any], into patient: Patient) {
        if let dobTimestamp = hashed["dateOfBirth"] as? TimeInterval {
            patient.dateOfBirth = Date(timeIntervalSince1970: dobTimestamp)
        }
        
        if let veteranStatus = hashed["veteranStatus"] as? Bool {
            patient.veteranStatus = veteranStatus
        }
        
        // Text fields are hashed and cannot be reversed, so leave existing patient values unchanged.
        // This includes firstName, lastName, email, phoneNumber, incomeRange.
    }
}

