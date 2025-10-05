import Foundation
import CoreData
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

/// Utility to mirror Patient CRUD to Firestore under users/{uid}/patients
enum PatientCloudSync {
    /// Compute a Firestore-safe, stable document ID for a Patient using its Core Data objectID.
    /// We base64-encode the objectID URI and make it URL/firestore safe by replacing '/', '+', and removing '='.
    static func patientDocId(for objectID: NSManagedObjectID) -> String {
        let uriString = objectID.uriRepresentation().absoluteString
        guard let data = uriString.data(using: .utf8) else {
            return UUID().uuidString
        }
        let b64 = data.base64EncodedString()
        let safe = b64
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return safe
    }
    
    /// URL-safe base64 of SHA256(data), trimmed of '='
    private static func urlSafeHash(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        let b64 = Data(digest).base64EncodedString()
        return b64
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Stable cross-device document id based on user id and patient identifiers
    static func stablePatientDocId(for patient: Patient, uid: String) -> String {
        let email = (patient.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !email.isEmpty {
            return urlSafeHash("uid:\(uid)|email:\(email)")
        }
        let first = (patient.firstName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let last = (patient.lastName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let dobStr: String = {
            if let dob = patient.dateOfBirth {
                let fmt = ISO8601DateFormatter()
                fmt.formatOptions = [.withFullDate]
                return fmt.string(from: dob)
            }
            return ""
        }()
        return urlSafeHash("uid:\(uid)|name:\(first) \(last)|dob:\(dobStr)")
    }

    /// Upsert (create/update) a patient document in Firestore for the current Firebase user.
    static func upsertPatient(_ patient: Patient) {
        guard let uid = Auth.auth().currentUser?.uid else {
            // No Firebase session; skip cloud sync
            return
        }
        let docId = stablePatientDocId(for: patient, uid: uid)
        let ref = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("patients")
            .document(docId)
        let data = serialize(patient: patient)
        ref.setData(data, merge: true) { error in
            if let error = error {
                print("PatientCloudSync upsert failed: \(error.localizedDescription)")
            }
        }
        // Attempt to remove any legacy doc that used the Core Data objectID-based id
        let legacyId = patientDocId(for: patient.objectID)
        if legacyId != docId {
            let legacyRef = Firestore.firestore()
                .collection("users").document(uid)
                .collection("patients").document(legacyId)
            legacyRef.delete { _ in /* ignore errors */ }
        }
    }

    /// Delete a patient document from Firestore for the current Firebase user using the Core Data objectID.
    static func deletePatient(with objectID: NSManagedObjectID) {
        guard let uid = Auth.auth().currentUser?.uid else {
            // No Firebase session; skip cloud sync
            return
        }
        let docId = patientDocId(for: objectID)
        let ref = Firestore.firestore()
            .collection("users")
            .document(uid)
            .collection("patients")
            .document(docId)
        ref.delete { error in
            if let error = error {
                print("PatientCloudSync delete failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Delete a patient document using stable id; also attempt legacy id cleanup
    static func deletePatient(patient: Patient) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let stableId = stablePatientDocId(for: patient, uid: uid)
        let legacyId = patientDocId(for: patient.objectID)
        let base = Firestore.firestore().collection("users").document(uid).collection("patients")
        base.document(stableId).delete { _ in /* ignore */ }
        if legacyId != stableId {
            base.document(legacyId).delete { _ in /* ignore */ }
        }
    }

    /// Delete a patient document by precomputed ids (stable and optional legacy)
    static func deletePatientByIds(stableId: String, legacyId: String?, uid: String) {
        let base = Firestore.firestore().collection("users").document(uid).collection("patients")
        base.document(stableId).delete { _ in /* ignore */ }
        if let legacyId = legacyId, legacyId != stableId {
            base.document(legacyId).delete { _ in /* ignore */ }
        }
    }

    /// Convert a Patient managed object into a Firestore-ready dictionary.
    private static func serialize(patient: Patient) -> [String: Any] {
        var dict: [String: Any] = [
            "firstName": patient.firstName ?? "",
            "lastName": patient.lastName ?? "",
            "email": patient.email ?? "",
            "phoneNumber": patient.phoneNumber ?? "",
            "veteranStatus": patient.veteranStatus,
            "incomeRange": patient.incomeRange ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let dob = patient.dateOfBirth {
            dict["dateOfBirth"] = Timestamp(date: dob)
        }
        // Ensure createdAt exists; if not, use now (but do not mutate Core Data here)
        if let created = patient.createdAt {
            dict["createdAt"] = Timestamp(date: created)
        } else {
            dict["createdAt"] = Timestamp(date: Date())
        }
        return dict
    }
}

