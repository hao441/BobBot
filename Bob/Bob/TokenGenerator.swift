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

let privateString = """
    -----BEGIN PRIVATE KEY-----
    MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCzu43JBPl3BIJD
    Q4p8LYzoOYHBdr/Zli8BpzU6roq5cl8NXX3wCIXAIZhqD/NYMRGw0/O12NQLh7/4
    vWTQCtOTEHTMsQUmcRdJyGRuQ249yp72WjgE8HT5lwPLMUydWuBBJtF/uOY0VsHx
    QiROp6UYI+Db664aIUJFKrAwMGHzsfiB4tscFz3/iN/Sz4nxzvKVz5nB0HRa3tjO
    ghE5Iq+vuVCbqJ+mlC+0SVCrpVIydCljlDQmgO8CSBOT3atXAD/a42jeGEBzikXZ
    NBg5AOa/jA35pdtiTaTt6hQh+gd+8nYN6hyLHRbJ4rpCaxd6DDJRP4LrSffwVHPS
    RCIf957VAgMBAAECggEADRB8QykjKAFSJakGazXVaPjrI2CqG9sUkiJxFlGjIE09
    twc9dQHtlPRsM4NyzQ2OC2Qwsh5vdWIZ9G7x4cRzshwvXUSdyvhL+M9B65jnrcKp
    cN9IdKV030KYoj+0Ybi+FcZIUqgiRZor0UldQcFiWQGcoee8+UXDHyt18J7Hs/Kz
    pFsJ111dlrXj4UIDpXdhEi1mSc/vwAW/3QYVZzoWzxWu/ZPTr3AWjkk2J80+WMTm
    buut/ENM276UINjmEXflqKQSPUJlUJty6JgXNwifkAKdNgpP9M+fCD/NGx1g7MbH
    J8skl/o+9/oZm9dFjHaI0uZ2XCgQq4UlILUQ+XPkSQKBgQDx8LtTNsgblKmcF0N5
    x+cP1LjswpsGEyMuDGphPks6BDQ8KyU9sLd1v75P/ipSRm6Nz/Ih+tzEufhs2KBk
    io/QJ5a8DgTQwA7Mzuy3aEN0//pqwFyp2YUWZfNmIMbuMNqX9DwT8NfU62vJgRf1
    BBA++gHz2M3KyJVi7GmCu32kaQKBgQC+LWDAotYJJH0GRh6IzycDi6j0pY9HgnTi
    nmmd4UMfyROoxcDcDhV5rTCaYmmKOBORq+PoEaSdjPPwVMi/aO321sS4q+AVpcPA
    S8YC6bXm+SCjmubguxeyNRtS/QyQ03n1a1V6Pbai7GSOmo7wViOl/Jt+kWF2wone
    pW/p6g1pjQKBgG6+ECCg3KuzOoeWJm6hz+PxLMxCr47yR5IWYMMuLmTZ88buwNci
    AnfFUqlu35RVZNlIq75eA5uQvGOmLJSY0Acpd9eQWyfqIVwiAzxYXzg4yzj93+xn
    AoIkHGtM6YGxnv0a8Dz4avKs5+OOUZb3SzBoY2hofpopgieLqygKBhKxAoGAMiHM
    K3vBaE+SFaFOU0ooQqsCMtuh1XvyS/ruZIwJIcvjvs3CdT/RMW4SLeBbafA2WGQz
    g+2Cs3WAqI3xDWQftr4OxY+pVouH+pz+6a2qIeTyUa53xi4LpRKSzWGfel4E/Ej7
    E2pJRtGCAIWFwJ00cIESjF7Ojnvh1CtQQR1Nw9ECgYEAnBinRZCKzExjCS3pw46Q
    89VxFFOYfpcJy05bxwG64XUX9MW2nS+pSh4c7vb45jR/kTOPlrSs6/cyAuHSoiNs
    7Om/wLgkgcunba/jisaXtL6qTnBzaeDX5JbrPROnhKrNN1lzx95ACm6tKfBIQ+ib
    CaOUKM3ODFmYYAXmPfAI9r8=
    -----END PRIVATE KEY-----
    """

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
