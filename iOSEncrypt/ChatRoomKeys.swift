//
//  ChatRoomKeys.swift
//  iOSEncrypt
//
//  Created by Yuhan Liu on 11/3/21.
//

import Foundation

/// Represents a chatroom and the keys associated with the chatroom
class ChatRoomKeys {
  let privateKey: SecKey

  var publicKey: SecKey {
    return SecKeyCopyPublicKey(self.privateKey)!
  }

  /**
     Creates a new chatroom with a given (chatroom) ID. Note that the ID must be encodable in UTF8.

     If the chatroom ID has not been created before, a new private key will be generated and stored in the device's
     keychain. If the chatroom ID exists, the private key from that chatroom will be reused.

     The init function will throw an error if a random key cannot be created.
     */
  init(chatroomId: String) throws {
    if let privateKey = ChatRoomKeys.getPrivKey(with: chatroomId) {
      // we found an existing private key
      self.privateKey = privateKey
    } else {
      // we need to make a new private key
      let tag = ChatRoomKeys.getTag(from: chatroomId)
      let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: 2048,
        kSecPrivateKeyAttrs as String: [
          kSecAttrIsPermanent as String: true,
          kSecAttrApplicationTag as String: tag
        ]
      ]
      var error: Unmanaged<CFError>?
      guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
        throw error!.takeRetainedValue() as Error
      }
      self.privateKey = privateKey
    }
  }

  /**
   Takes an encrypted AES256 key received from the server and decrypts it with the local private key.
   */
  func decrypt(symmetricKey: String) throws -> String {
    let ciphertextData = CFDataCreateWithBytesNoCopy(
      kCFAllocatorSystemDefault,
      symmetricKey,
      symmetricKey.lengthOfBytes(using: .utf8),
      kCFAllocatorSystemDefault)!
    var error: Unmanaged<CFError>?
    guard
      let decryptedData = SecKeyCreateDecryptedData(
        self.privateKey,
        .rsaEncryptionRaw, ciphertextData, &error)
    else {
      throw error!.takeRetainedValue() as Error
    }
    return
      (CFStringCreateFromExternalRepresentation(
        kCFAllocatorSystemDefault,
        decryptedData, kCFStringEncodingASCII)! as String)
  }

  func encode(message: String, with aesKey: String) -> String {
    return ""
  }

  private static func getPrivKey(with chatroomId: String) -> SecKey? {
    let tag = ChatRoomKeys.getTag(from: chatroomId)
    let getquery: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: tag,
      kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
      kSecReturnRef as String: true
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(getquery as CFDictionary, &item)
    guard status == errSecSuccess else { return nil }
    // swiftlint:disable force_cast
    return (item as! SecKey)
    // swiftlint:enable force_cast
  }

  private static func getTag(from chatroomId: String) -> Data {
    return "com.iiDecide.chatrooms.\(chatroomId)".data(using: .utf8)!
  }

}
