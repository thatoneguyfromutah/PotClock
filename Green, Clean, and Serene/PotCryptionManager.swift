import UIKit
import Foundation
import UniformTypeIdentifiers
import CommonCrypto

class PotCryptionManager: NSObject {
    
    static let sharedInstance = PotCryptionManager()
    
    func encrypt(data: Data, key: String) -> Data? {
        
        let keyData = key.data(using: .utf8)!
        let inputData = data as NSData
        let encryptedData = NSMutableData(length: Int(inputData.length) + kCCBlockSizeAES128)!
        let keyLength = size_t(kCCKeySizeAES128)
        let operation = CCOperation(kCCEncrypt)
        let algorithm = CCAlgorithm(kCCAlgorithmAES)
        let options = CCOptions(kCCOptionPKCS7Padding)

        var numBytesEncrypted: size_t = 0

        let cryptStatus = CCCrypt(
            operation,
            algorithm,
            options,
            (keyData as NSData).bytes, keyLength,
            nil,
            inputData.bytes, inputData.length,
            encryptedData.mutableBytes, encryptedData.length,
            &numBytesEncrypted
        )

        if cryptStatus == kCCSuccess {
            encryptedData.length = Int(numBytesEncrypted)
            return encryptedData as Data
        }

        return nil
    }
    
    func decrypt(data: Data, key: String) -> Data? {
        
        let keyData = key.data(using: .utf8)!
        let inputData = data as NSData
        let decryptedData = NSMutableData(length: Int(inputData.length) + kCCBlockSizeAES128)!
        let keyLength = size_t(kCCKeySizeAES128)
        let operation = CCOperation(kCCDecrypt)
        let algorithm = CCAlgorithm(kCCAlgorithmAES)
        let options = CCOptions(kCCOptionPKCS7Padding)
        
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = CCCrypt(
            operation,
            algorithm,
            options,
            (keyData as NSData).bytes, keyLength,
            nil,
            inputData.bytes, inputData.length,
            decryptedData.mutableBytes, decryptedData.length,
            &numBytesDecrypted
        )
        
        if cryptStatus == kCCSuccess {
            decryptedData.length = Int(numBytesDecrypted)
            return decryptedData as Data
        }
        
        return nil
    }
}
