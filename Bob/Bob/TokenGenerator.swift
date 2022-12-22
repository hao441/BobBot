//
//  TokenGenerator.swift
//  APICAll
//
//  Created by Hao on 15/12/2022.
//

import UIKit
import SwiftJWT
import CryptoKit
import Foundation

struct MyClaims: Claims {
    let iss: String
    let scope: String
    let aud: String
    let exp: Int
    let iat: Int
}

enum Errors: Error {
    case invalidJWT
    case unverified
    case couldNotUnwrapJSON
    case invalidAccessToken
}

struct Genre: Decodable {
    let  name: String
}

let iat: Int = Int(Date().timeIntervalSince1970)
let exp: Int = iat + 3600

let myHeader = Header(typ: "JWT")

let myClaims = MyClaims(iss: "mystic-boy@western-dolphin-371610.iam.gserviceaccount.com", scope: "https://www.googleapis.com/auth/dialogflow", aud: "https://oauth2.googleapis.com/token", exp: exp, iat: iat)

let publicString = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs7uNyQT5dwSCQ0OKfC2M
6DmBwXa/2ZYvAac1Oq6KuXJfDV198AiFwCGYag/zWDERsNPztdjUC4e/+L1k0ArT
kxB0zLEFJnEXSchkbkNuPcqe9lo4BPB0+ZcDyzFMnVrgQSbRf7jmNFbB8UIkTqel
GCPg2+uuGiFCRSqwMDBh87H4geLbHBc9/4jf0s+J8c7ylc+ZwdB0Wt7YzoIROSKv
r7lQm6ifppQvtElQq6VSMnQpY5Q0JoDvAkgTk92rVwA/2uNo3hhAc4pF2TQYOQDm
v4wN+aXbYk2k7eoUIfoHfvJ2Deocix0WyeK6QmsXegwyUT+C60n38FRz0kQiH/ee
1QIDAQAB
-----END PUBLIC KEY-----
"""




class TokenGenerator {
    
    init() {
        UserDefaults().set(Date.timeIntervalBetween1970AndReferenceDate, forKey: "time")
    }

    func getJWT() async throws -> String {
        
        var myJWT = JWT(claims: myClaims)
        
        let privateKey = privateString.data(using: .utf8)!

        let jwtSigner = JWTSigner.rs256(privateKey: privateKey)
        
        do {
            let signedJWT = try myJWT.sign(using: jwtSigner)
            print("Created JWT")
            return signedJWT
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }

    func verifyJWT(signedJWT: String) async throws -> String {
        
        let publicKey = publicString.data(using: .utf8)!
        let jwtVerifier = JWTVerifier.rs256(publicKey: publicKey)
        let verified: Bool = JWT<MyClaims>.verify(signedJWT, using: jwtVerifier)

        guard verified else {throw Errors.unverified}
        
        UserDefaults().set(signedJWT, forKey: "signedJWT")
        
        return signedJWT
    }

    

    func gcAccessTokenRequest(verifiedJWT: String) async throws -> String {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        
        let requestBody = "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=\(verifiedJWT)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("oauth2.googleapis.com", forHTTPHeaderField: "Host")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody.data(using: .utf8)
    //
        let task = URLSession.shared.dataTask(with: request)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Errors.invalidJWT }
        let maybeJSON: [String : Any] = try JSONSerialization.jsonObject(with: data) as! [String : Any]
        guard let accessToken = maybeJSON["access_token"] else { throw Errors.couldNotUnwrapJSON }
        
        task.resume()
        return accessToken as! String
    }
    
    func apiCall(gcAccessToken: String, text: String) async throws -> String {
        let url = URL(string: """
        https://us-central1-dialogflow.googleapis.com/v3/projects/western-dolphin-371610/locations/us-central1/agents/81631138-5a43-4195-a85d-c69361a3a8d8/sessions/123456789:detectIntent
        """)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(gcAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue("western-dolphin-371610", forHTTPHeaderField: "x-goog-user-project")

        let requestBody = """
        {
          "queryInput": {
            "text": {
              "text": "\(text)"
            },
            "languageCode": "en"
          },
          "queryParams": {
            "timeZone": "America/Los_Angeles"
          }
        }
        """
        request.httpBody = requestBody.data(using: .utf8)

        let task = URLSession.shared.dataTask(with: request)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw Errors.invalidAccessToken }
        let maybeJSON = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let queryResult = maybeJSON["queryResult"] as! [String : Any]
        let responseMessages = queryResult["responseMessages"] as? [[String: Any]]
        let responseMessage = responseMessages?.first
        let text = responseMessage?["text"] as? [String: Any]
        let textArray = text!["text"] as? [String]
        let message = textArray?.first
        task.resume()
        
        return message!
    }

    func chatWithBot(message: String) async -> String {
        do {
            if UserDefaults().double(forKey: "time") <= Date.timeIntervalBetween1970AndReferenceDate {
                let signedJWT = try await getJWT()
                _ = try await verifyJWT(signedJWT: signedJWT)
                UserDefaults().set(Date.timeIntervalBetween1970AndReferenceDate+3600, forKey: "time")
            }
            do {
                let gcAccessToken = try await gcAccessTokenRequest(verifiedJWT: UserDefaults().string(forKey: "signedJWT")!)
                let response = try await apiCall(gcAccessToken: gcAccessToken, text: message)
                return response
            } catch Errors.couldNotUnwrapJSON {
                print("could not unwrap JSON.")
            } catch Errors.invalidJWT {
                print("invalid JWT")
            } catch Errors.invalidAccessToken {
                print("access token was invalid")
            }
        } catch Errors.unverified {
            print("unverified JWT")
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    
}
