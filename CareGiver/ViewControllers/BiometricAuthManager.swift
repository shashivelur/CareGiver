import Foundation
import LocalAuthentication
import Security
import CryptoKit
import UIKit

struct BiometricAuthManager {
    private static let service = "com.caregiverapp.biometric-login-token"
    private static let lastUserKey = "LastBiometricUsername"

    // MARK: - Public: Availability
    static func isBiometryAvailable() -> (available: Bool, type: LABiometryType) {
        let ctx = LAContext()
        var error: NSError?
        let available = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        print("[Biometric] isBiometryAvailable available=\(available) type=\(ctx.biometryType.rawValue) error=\(error?.localizedDescription ?? "nil")")
        return (available, ctx.biometryType)
    }

    // MARK: - Public: Enable
    static func enableBiometricLogin(for username: String,
                                     presenting viewController: UIViewController,
                                     reason: String = "Authenticate to enable Face ID",
                                     completion: @escaping (Result<Void, Error>) -> Void) {
        print("[Biometric] Enabling biometric login for user=\(username)")
        // Generate a random 32-byte token and save it with biometry protection.
        let token = randomToken(length: 32)
        let ctx = LAContext()
        do {
            try saveToken(token, for: username, context: ctx)
            let hash = sha256Hex(token)
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: enabledKey(for: username))
            defaults.set(hash, forKey: tokenHashKey(for: username))
            defaults.set(username, forKey: lastUserKey)
            print("[Biometric] Biometric enabled; token saved and hash stored for user=\(username)")
            completion(.success(()))
        } catch {
            print("[Biometric] Enable failed error=\(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    // MARK: - Public: Try Login
    static func tryBiometricLogin(for username: String,
                                  presenting viewController: UIViewController,
                                  reason: String = "Authenticate to sign in",
                                  completion: @escaping (Result<Void, Error>) -> Void) {
        let defaults = UserDefaults.standard
        print("[Biometric] tryBiometricLogin username=\(username)")
        guard defaults.bool(forKey: enabledKey(for: username)) else {
            print("[Biometric] enabled=\(defaults.bool(forKey: enabledKey(for: username)))")
            completion(.failure(NSError(domain: "Biometric", code: -2, userInfo: [NSLocalizedDescriptionKey: "Face ID not enabled for this account."])) )
            return
        }
        print("[Biometric] enabled=\(defaults.bool(forKey: enabledKey(for: username)))")
        guard let expectedHash = defaults.string(forKey: tokenHashKey(for: username)) else {
            completion(.failure(NSError(domain: "Biometric", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing biometric token hash."])) )
            return
        }

        let ctx = LAContext()
        DispatchQueue.main.async {
            do {
                ctx.localizedReason = reason
                print("[Biometric] Attempting token read via Keychain (will prompt)")
                guard let token = try readToken(for: username, context: ctx, prompt: reason) else {
                    completion(.failure(NSError(domain: "Biometric", code: -4, userInfo: [NSLocalizedDescriptionKey: "No biometric token found."])) )
                    return
                }
                let hash = sha256Hex(token)
                if hash == expectedHash {
                    print("[Biometric] Token hash matched; login success for user=\(username)")
                    UserDefaults.standard.set(username, forKey: lastUserKey)
                    completion(.success(()))
                } else {
                    print("[Biometric] Token hash mismatch; prompting re-enable")
                    completion(.failure(NSError(domain: "Biometric", code: -5, userInfo: [NSLocalizedDescriptionKey: "Biometric token mismatch. Please re-enable Face ID."])) )
                }
            } catch {
                print("[Biometric] tryBiometricLogin error=\(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Public: Disable
    static func disableBiometricLogin(for username: String) {
        _ = try? deleteToken(for: username)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: enabledKey(for: username))
        defaults.removeObject(forKey: tokenHashKey(for: username))
        if defaults.string(forKey: lastUserKey) == username {
            defaults.removeObject(forKey: lastUserKey)
        }
    }

    // MARK: - Public: Migration on username change
    static func migrateBiometricCredentials(from oldUsername: String, to newUsername: String) {
        print("[Biometric] Migrating credentials from '\(oldUsername)' to '\(newUsername)'")
        let defaults = UserDefaults.standard
        let wasEnabled = defaults.bool(forKey: enabledKey(for: oldUsername))
        guard wasEnabled else { return }

        // Try to read token with authentication-less context (won't prompt). If it fails due to auth, we still can move via update.
        do {
            // Fetch the token data by copying the Keychain item and re-inserting under new account
            if let token = try readToken(for: oldUsername, context: LAContext(), prompt: nil) {
                // Delete old, save new
                _ = try? deleteToken(for: oldUsername)
                try saveToken(token, for: newUsername, context: LAContext())
            } else {
                // If we can't read (due to auth), attempt to update the account attribute directly
                try updateAccount(from: oldUsername, to: newUsername)
            }
            print("[Biometric] Keychain migration completed")
        } catch {
            print("[Biometric] Migration failed; disabling old credentials. error=\(error.localizedDescription)")
            // If anything fails, disable to avoid broken state
            disableBiometricLogin(for: oldUsername)
            return
        }

        // Move defaults keys
        if let hash = defaults.string(forKey: tokenHashKey(for: oldUsername)) {
            defaults.set(hash, forKey: tokenHashKey(for: newUsername))
        }
        defaults.set(true, forKey: enabledKey(for: newUsername))
        defaults.removeObject(forKey: enabledKey(for: oldUsername))
        defaults.removeObject(forKey: tokenHashKey(for: oldUsername))

        if defaults.string(forKey: lastUserKey) == oldUsername {
            defaults.set(newUsername, forKey: lastUserKey)
        }
    }

    // MARK: - Defaults Keys
    private static func enabledKey(for username: String) -> String { "BiometricEnabled_\(username)" }
    private static func tokenHashKey(for username: String) -> String { "BiometricTokenHash_\(username)" }

    // MARK: - Crypto
    private static func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomToken(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes)
    }

    // MARK: - Access Control Helpers
    private static func makeAccessControlCandidates() -> [SecAccessControl] {
        var result: [SecAccessControl] = []
        #if targetEnvironment(simulator)
        // Simulator: no passcode concept. Prefer variants that work without passcode.
        let simulatorCombos: [(CFTypeRef, SecAccessControlCreateFlags, String)] = [
            (kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.biometryAny, .userPresence], "Sim: WhenUnlockedThisDeviceOnly + biometryAny + userPresence"),
            (kSecAttrAccessibleWhenUnlocked,           [.biometryAny, .userPresence], "Sim: WhenUnlocked + biometryAny + userPresence"),
            (kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.biometryAny],            "Sim: WhenUnlockedThisDeviceOnly + biometryAny")
        ]
        for (cls, flags, label) in simulatorCombos {
            if let ac = SecAccessControlCreateWithFlags(nil, cls, flags, nil) { print("[Biometric] Using AC candidate: \(label)"); result.append(ac) }
        }
        #else
        // Devices: try strongest first, then relax.
        let deviceCombos: [(CFTypeRef, SecAccessControlCreateFlags, String)] = [
            (kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet],              "Dev: WhenPasscodeSetThisDeviceOnly + biometryCurrentSet"),
            (kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    [.biometryCurrentSet],              "Dev: WhenUnlockedThisDeviceOnly + biometryCurrentSet"),
            (kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    [.biometryAny],                     "Dev: WhenUnlockedThisDeviceOnly + biometryAny"),
            (kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet, .userPresence], "Dev: WhenPasscodeSetThisDeviceOnly + biometryCurrentSet + userPresence"),
            (kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    [.biometryCurrentSet, .userPresence], "Dev: WhenUnlockedThisDeviceOnly + biometryCurrentSet + userPresence"),
            (kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    [.biometryAny, .userPresence],       "Dev: WhenUnlockedThisDeviceOnly + biometryAny + userPresence")
        ]
        for (cls, flags, label) in deviceCombos {
            if let ac = SecAccessControlCreateWithFlags(nil, cls, flags, nil) { print("[Biometric] Using AC candidate: \(label)"); result.append(ac) }
        }
        #endif
        return result
    }

    private static func statusMessage(_ status: OSStatus) -> String {
        if let s = SecCopyErrorMessageString(status, nil) as String? { return "\(status) (\(s))" }
        return "\(status)"
    }

    // MARK: - Keychain helpers
    private static func saveToken(_ token: Data, for username: String, context: LAContext) throws {
        // Delete any existing item first
        _ = try? deleteToken(for: username)

        let candidates = makeAccessControlCandidates()
        var lastStatus: OSStatus = errSecParam
        for ac in candidates {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: username,
                kSecValueData as String: token,
                kSecAttrAccessControl as String: ac
            ]
            let status = SecItemAdd(query as CFDictionary, nil)
            if status == errSecSuccess {
                print("[Biometric] SecItemAdd success for user=\(username)")
                return
            } else {
                print("[Biometric] SecItemAdd failed with AC candidate status=\(statusMessage(status)) user=\(username)")
                lastStatus = status
                continue
            }
        }
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(lastStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to save token with any access control: \(statusMessage(lastStatus))"])
    }

    private static func readToken(for username: String, context: LAContext, prompt: String? = nil) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUIAllow,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let prompt = prompt {
            query[kSecUseOperationPrompt as String] = prompt
        }

        print("[Biometric] SecItemCopyMatching for user=\(username) prompt='\(prompt ?? "nil")'")
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        print("[Biometric] SecItemCopyMatching status=\(statusMessage(status))")
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to read token: \(status)"])
        }
        if let data = item as? Data { print("[Biometric] Read token length=\(data.count) bytes") }
        return item as? Data
    }

    private static func deleteToken(for username: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: username
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { return true }
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to delete token: \(status)"])
    }

    private static func updateAccount(from oldUsername: String, to newUsername: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: oldUsername
        ]
        let attrs: [String: Any] = [kSecAttrAccount as String: newUsername]
        let status = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to migrate token account: \(status)"])
        }
    }
}
