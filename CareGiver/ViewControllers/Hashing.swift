import Foundation
import CryptoKit

public struct HasherUtil {
    public static func sha256(_ string: String) -> String? {
        guard let data = string.data(using: .utf8) else { return nil }
        return sha256Data(data)
    }
    
    public static func sha256Data(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
