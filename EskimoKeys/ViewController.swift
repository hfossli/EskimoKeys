//
//  ViewController.swift
//  EskimoKeys
//
//  Created by Håvard Fossli on 13.01.2017.
//  Copyright © 2017 Agens. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var publicKey: SecKey? = nil
    var privateKey: SecKey? = nil
    
    override func viewDidAppear(animated: Bool) {
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            self.generate()
            self.sign()
        }
    }
    
    func generate() {
        let uuidStr = NSUUID().UUIDString
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            [.UserPresence, .PrivateKeyUsage],
            nil
            )!
        
        let err = SecKeyGeneratePair([
            kSecAttrTokenID as String:          kSecAttrTokenIDSecureEnclave,
            kSecAttrKeyType as String:          kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String:    256,
            kSecAttrApplicationTag as String:  uuidStr,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String:  true,
                kSecAttrAccessControl as String:access,
            ]
            ] as NSDictionary, &publicKey, &privateKey)
        if err != errSecSuccess {
            NSLog("generate error %d", err)
        } else {
            NSLog("generate success")
            
            let addErr = SecItemAdd([
                kSecClass as String:                kSecClassKey,
                kSecValueRef as String:            publicKey!,
                kSecAttrApplicationTag as String:  uuidStr
                ] as NSDictionary, nil)
            if addErr != errSecSuccess {
                NSLog("add error %d", addErr)
            } else {
                NSLog("add success")
            }
        }
    }
    
    func sign() {
        // Create some unique data to sign.
        
        let stringToSign = NSString(format: "This string was signed after %@.", NSDate())
        let dataToSign = stringToSign.dataUsingEncoding(NSUTF8StringEncoding)!
        
        // Start off our shell script with some lines that put that data in "dataToSign.dat".
        
        var shellScriptLines = [ "#! /bin/sh" ]
        shellScriptLines.append(String(format: "echo %@ | xxd -r -p > dataToSign.dat", QHex.hexStringWithData(dataToSign)))
        
        // Now add lines for each key.
        
        if let privateKey = privateKey, let publicKey = publicKey {
            let _ = try? self.signData(dataToSign, withPrivateKey: privateKey, publicKey: publicKey, shellScriptLines: &shellScriptLines)
        }
        
        // Finally print the script.
        
        for l in shellScriptLines {
            print(l)
        }
    }
    
    func signData(dataToSign: NSData, withPrivateKey privateKey: SecKey, publicKey: SecKey, inout shellScriptLines: [String]) throws {
        //let digestToSign = CommonCryptoAccess.sha1DigestForData(dataToSign)
        let digestToSign = CommonCryptoAccess.sha256DigestForData(dataToSign)
        
        // There's no reliable API to get the correct signature buffer length to use
        // <rdar://problem/23128926> so we hard code 128 as the theoretical maximum.
        
        let signature = NSMutableData(length: 128)!
        var signatureLength = signature.length
        let signErr = SecKeyRawSign(privateKey, .PKCS1, UnsafePointer(digestToSign.bytes), digestToSign.length, UnsafeMutablePointer(signature.mutableBytes), &signatureLength)
        guard signErr == errSecSuccess else {
            NSLog("verify sign error %d", signErr)
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(signErr), userInfo: nil)
        }
        signature.length = signatureLength
        
        // Add a command to create "signature.dat".
        
        shellScriptLines.append(String(format: "echo %@ | xxd -r -p > signature.dat", QHex.hexStringWithData(signature)))
        
        var matchResult: AnyObject? = nil
        let err = SecItemCopyMatching([
            kSecClass as String:                kSecClassKey,
            kSecValueRef as String:            publicKey,
            kSecReturnData as String:          true
            ] as NSDictionary, &matchResult)
        if err != errSecSuccess {
            NSLog("match error %d", err)
        } else if let keyRaw = matchResult as? NSData {
            
            // We take the raw key and prepend an ASN.1 prefix to it.  The end result is an
            // ASN.1 SubjectPublicKeyInfo structure, which is what OpenSSL is looking for.
            //
            // See the following DevForums post for more details on this.
            //
            // <https://forums.developer.apple.com/message/84684#84684>.
            
            let keyHeader = QHex.dataWithValidHexString("3059301306072a8648ce3d020106082a8648ce3d030107034200")
            let keyASN1 = NSMutableData(data: keyHeader)
            keyASN1.appendData(keyRaw)
            
            // Convert the key to Base64 then wrap it up as "key.pem".
            
            let keyBase64 = keyASN1.base64EncodedStringWithOptions([.Encoding64CharacterLineLength])
            shellScriptLines.append("cat > key.pem <<EOF")
            shellScriptLines.append("-----BEGIN PUBLIC KEY-----")
            shellScriptLines.appendContentsOf( keyBase64.componentsSeparatedByString("\r\n") )
            shellScriptLines.append("-----END PUBLIC KEY-----")
            shellScriptLines.append("EOF")
        } else {
            NSLog("match cast problem")
        }
        
        // Add a command to verify the signature.
        //
        // IMPORTANT: -ecdsa-with-SHA1 is a bit of a hack that works in the ancient version
        // of OpenSSL that's built in to OS X.  Alas, ecdsa-with-SHA256 does not work. If
        // you need to use a long digest, SHA256 say, you should replace this with "-sha256".
        // That won't work on OS X but will work with other, more modern versions of OpenSSL,
        // where it detects the key type and does an ECDSA digest.
        
        shellScriptLines.append("openssl dgst -ecdsa-with-SHA1 -verify key.pem -signature signature.dat dataToSign.dat")
    }


}

