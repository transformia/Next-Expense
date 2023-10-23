//
//  TinkService.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-09-04.
//

import Foundation

class TinkService {
    static let shared = TinkService()
    
    private init() {}
    
//    let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
//    let clientSecret = "79a3313907fd46a193f9b0a196b14bfa" // sandbox
    let clientID = "dd0e0e14037347a8b9a003b869c4de87" // production
    let clientSecret = "4b4393da30d34e7c98f5966c13be504d" // production
    
    let market = "ES"
    let locale = "en_US"
    let externalUserID = "test_user"
    
    var clientAccessToken = ""
    var userAccessToken = ""
    
    
    // Functions for one-time access:
        
    
    
    
    
    // Functions for continuous access - only possible once I have a lot of users, after negotiation with Tink:
    
    func newUser(completion: @escaping (Bool, String?) -> Void) {
        authorizeApp(scope: "user:create") { success, tinkAccessToken in
            if success {
                print("App authorized for user creation")
                self.createUser(tinkAccessToken: tinkAccessToken ?? "", externalUserID: self.externalUserID, market: self.market, locale: self.locale) { success, message in
                    print(message ?? "")
                    if success {
                        print("User \(self.externalUserID) created")
                    } else {
                        completion(false, message)
                    }
                }
            } else {
                print("Failed")
            }
        }
    }
    
    func authorizeApp(scope: String, completion: @escaping (Bool, String?) -> Void) {
        print("Authorizing the app")
        
        let url = URL(string: "https://api.tink.com/api/v1/oauth/token")!
        
        let requestBody = NSMutableData(data: "client_id=\(clientID)".data(using: .utf8)!)
        requestBody.append("&client_secret=\(clientSecret)".data(using: .utf8)!)
        requestBody.append("&grant_type=client_credentials".data(using: .utf8)!)
        requestBody.append("&scope=\(scope)".data(using: .utf8)!)
        
        let header = ["Content-Type": "application/x-www-form-urlencoded"]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = header
        request.httpBody = requestBody as Data
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let data = data else {
                print("Empty data")
                return
            }
            
            do {
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let accessToken = jsonData["access_token"] as? String {
//                        print("Client access Token:", accessToken)
                        self.clientAccessToken = accessToken
                        print("Client access token received")
                        completion(true, accessToken)
                    } else {
                        print("Error: Access token not found in JSON")
                        print(jsonData)
                        completion(false, "Error: Access token not found in JSON")
                    }
                } else {
                    completion(false, "Error decoding JSON")
                }
            } catch {
                completion(false, "Error decoding JSON: \(error)")
            }
            
        }.resume()
    }
    
    private func createUser(tinkAccessToken: String, externalUserID: String, market: String, locale: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "https://api.tink.com/api/v1/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody: [String: Any] = [
            "external_user_id": externalUserID,
            "market": market,
            "locale": locale
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            completion(false, "Error encoding JSON for the request body")
            return
        }
        
        request.addValue("Bearer \(tinkAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completion(false, error!.localizedDescription)
                return
            }
            guard let data = data else {
                completion(false, "Empty data")
                return
            }
            
            do {
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let externalUserID = jsonData["external_user_id"] as? String, let userID = jsonData["user_id"] as? String {
                        completion(true, "User created: \(externalUserID), Tink user id: \(userID)")
                    } else {
                        completion(false, jsonData["errorMessage"] as? String)
                    }
                } else {
                    completion(false, "Error decoding JSON")
                }
            } catch {
                completion(false, "Error decoding JSON: \(error)")
            }
        }.resume()
    }
    
    func giveAccess(completion: @escaping (Bool, String?) -> Void) {
        authorizeApp(scope: "authorization:grant") { success, clientAccessToken in
            if success {
                print("Client access token generated")
                self.clientAccessToken = clientAccessToken ?? ""
                
                TinkService.shared.grantUserAccess(tinkAccessToken: clientAccessToken ?? "", externalUserID: TinkService.shared.externalUserID) { success, tinkLinkURL in
                    if success {
                        print(tinkLinkURL ?? "")
                        completion(true, tinkLinkURL ?? "")
//                        openURL(URL(string: tinkLinkURL!)!)
                    }
                    else {
                        print("Tink link wan't generated")
                    }
                }
            }
            else {
                print("Failed to generate client access token")
            }
        }
    }
    
    private func grantUserAccess(tinkAccessToken: String, externalUserID: String, completion: @escaping (Bool, String?) -> Void) {
        print("Granting access to user with access token \(tinkAccessToken)")
        
        let actor_client_id = "df05e4b379934cd09963197cc855bfe9"
        
        let url = URL(string: "https://api.tink.com/api/v1/oauth/authorization-grant/delegate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody = "external_user_id=\(externalUserID)&id_hint=Michael%20Frisk&actor_client_id=\(actor_client_id)&scope=credentials:read,credentials:refresh,credentials:write,providers:read,user:read,authorization:read"
                
//        print("Request body:")
//        print(requestBody)
        
        request.httpBody = requestBody.data(using: .utf8)
        
        request.addValue("Bearer \(tinkAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let data = data else {
                print("Empty data")
                return
            }
            
            do {
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let code = jsonData["code"] as? String {
//                        print("Code: ", code)
                        
                        let tinkLinkURL = "https://link.tink.com/1.0/transactions/connect-accounts?client_id=\(self.clientID)&state=MyStateCode&redirect_uri=nextexpenseapp%3A%2F%2F&authorization_code=\(code)&market=\(self.market)&locale=\(self.locale)"
                        
//                        print(tinkLinkURL)
                        
                        completion(true, tinkLinkURL)
                        
//                        openURL(URL(string: tinkLinkURL)!)
                        
                    } else {
                        print("Error: Code was not received")
                        print(jsonData)
                    }
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error decoding JSON:", error)
            }
            
        }.resume()
    }
    
    func getUserAccessToken() {
        print("Getting user access code")
        
        
        // ONLY IF THE CLIENT ACCESS TOKEN HAS EXPIRED - PUT IT INSIDE A FAILED FUNCTION?:
        
        /*authorizeApp(scope: "authorization:grant") { success, clientAccessToken in
            if success {
                print("Client access token generated")
                completion(true, clientAccessToken)
            }
            else {
                print("Failed to generate client access token")
            }
        }*/
        
        
        let url = URL(string: "https://api.tink.com/api/v1/oauth/authorization-grant")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody = "external_user_id=\(TinkService.shared.externalUserID)&scope=accounts:read,balances:read,transactions:read,provider-consents:read"
        
        request.httpBody = requestBody.data(using: .utf8)
        
        request.addValue("Bearer \(self.clientAccessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let data = data else {
                print("Empty data")
                return
            }
            
            do {
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let code = jsonData["code"] as? String {
//                        print("Code:", code)
                        
                        // EXCHANGE THE CODE FOR THE USER TOKENS
                        print("Exchanging code for user access tokens")
                        
                        
                        let url = URL(string: "https://api.tink.com/api/v1/oauth/token")!
                        
                        let requestBody = NSMutableData(data: "code=\(code)".data(using: .utf8)!)
                        requestBody.append("&client_id=\(self.clientID)".data(using: .utf8)!)
                        requestBody.append("&client_secret=\(self.clientSecret)".data(using: .utf8)!)
                        requestBody.append("&grant_type=authorization_code".data(using: .utf8)!)
                        
                        let header = ["Content-Type": "application/x-www-form-urlencoded"]
                        
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        request.allHTTPHeaderFields = header
                        request.httpBody = requestBody as Data
                        
                        URLSession.shared.dataTask(with: request) { (data, response, error) in
                            guard error == nil else {
                                print(error!.localizedDescription)
                                return
                            }
                            guard let data = data else {
                                print("Empty data")
                                return
                            }
                            
                            do {
                                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                                    print(jsonData)
                                    if let userAccessToken = jsonData["access_token"] as? String {
//                                        print("User access Token:", userAccessToken)
                                        print("User access token received")
                                        self.userAccessToken = userAccessToken
                                        UserDefaults.standard.set(userAccessToken, forKey: "UserAccessToken")
//                                        completion(true, userAccessToken)
                                    } else {
                                        print("Error: User tokens not found in JSON")
                                        print(jsonData)
                                    }
                                } else {
                                    print("Error decoding JSON")
                                }
                            } catch {
                                print("Error decoding JSON:", error)
                            }
                        }.resume()
                        
                    } else {
                        print("Error: Code not found in JSON")
                        print(jsonData)
                    }
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error decoding JSON:", error)
            }
            
        }.resume()
        
    }
    
    func getTransactions(completion: @escaping (Bool, [[String: Any]]) -> Void) {
        print("Fetching transactions")
        
        let url = URL(string: "https://api.tink.com/data/v2/transactions")!
        
        let header = ["Authorization": "Bearer \(UserDefaults.standard.string(forKey: "UserAccessToken") ?? self.userAccessToken)"]
//        let header = ["Authorization": "Bearer \(self.userAccessToken)"]
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = header
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let data = data else {
                print("Empty data")
                return
            }

            do {
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                    print("Transaction Data:")
//                    print(jsonData)
                    
                    if let tinkTransactions = jsonData["transactions"] as? [[String: Any]] {
                        completion(true, tinkTransactions)                        
                    } else {
                        print("No transaction info found")
                    }
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error decoding JSON:", error)
            }
            
        }.resume()
    }
    
}
