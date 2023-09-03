//
//  ContentView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI
import CoreData

class TinkService {
    static let shared = TinkService()
    
    private init() {}
    
//    private var tinkAccessToken = ""
    
    let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
    let clientSecret = "79a3313907fd46a193f9b0a196b14bfa" // sandbox
//        let clientID = "dd0e0e14037347a8b9a003b869c4de87" // production
//        let clientSecret = "4b4393da30d34e7c98f5966c13be504d" // production
    
    let market = "SE"
    let locale = "en_US"
    let externalUserID = "user_102"
    
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
    
    private func authorizeApp(scope: String, completion: @escaping (Bool, String?) -> Void) {
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
                        print("Access Token:", accessToken)
                        completion(true, accessToken)
//                        self.tinkAccessToken = accessToken
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
                        print("Code: ", code)
                        
                        let tinkLinkURL = "https://link.tink.com/1.0/transactions/connect-accounts?client_id=\(self.clientID)&state=MyStateCode&redirect_uri=nextexpenseapp%3A%2F%2F&authorization_code=\(code)&market=GB&locale=en_US"
                        
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
    
    func getUserAccessToken(tinkAccessToken: String) {
        print("Getting user access code")
        
        
        // ONLY IF THE CLIENT ACCESS TOKEN HAS EXPIRED - PUT IT INSIDE A FAILED FUNCTION?:
        /*
        authorizeApp(scope: "authorization:grant") { success, clientAccessToken in
            if success {
                print("Client access token generated")
                
            }
            else {
                print("Failed to generate client access token")
            }
        }
         */
        
        
        let url = URL(string: "https://api.tink.com/api/v1/oauth/authorization-grant")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody = "external_user_id=\(TinkService.shared.externalUserID)&scope=accounts:read,balances:read,transactions:read,provider-consents:read"
        
        request.httpBody = requestBody.data(using: .utf8)
        
        request.addValue("Bearer \(tinkAccessToken)", forHTTPHeaderField: "Authorization")
        
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
                        print("Code:", code)
                        
                        // EXCHANGE THE CODE FOR THE USER TOKENS
                        print("Exchanging code for user access tokens")
                        
                        let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
                        let clientSecret = "79a3313907fd46a193f9b0a196b14bfa" // sandbox
                        //        let clientID = "dd0e0e14037347a8b9a003b869c4de87" // production
                        //        let clientSecret = "4b4393da30d34e7c98f5966c13be504d" // production
                        
                        
                        let url = URL(string: "https://api.tink.com/api/v1/oauth/token")!
                        
                        let requestBody = NSMutableData(data: "code=\(code)".data(using: .utf8)!)
                        requestBody.append("&client_id=\(clientID)".data(using: .utf8)!)
                        requestBody.append("&client_secret=\(clientSecret)".data(using: .utf8)!)
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
                                    print(jsonData)
                                    if let accessToken = jsonData["access_token"] as? String, let refreshToken = jsonData["refresh_token"] as? String {
                                        print("Access Token:", accessToken)
                                        print("Refresh Token:", refreshToken)
                                        userAccessToken = accessToken
                                        //                            tinkRefreshToken = refreshToken
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
    
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to create periods if none exist yet (only on the first launch of the app
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the balances in the PeriodBalances class - delete this if that didn't work
    
    class PeriodBalances: ObservableObject {
        @Published var incomeBudget = 0.0 // total budget on all categories with type "Income"
        @Published var incomeActual = 0.0 // total actual on all categories with type "Income"
        @Published var expensesBudget = 0.0 // total budget on all categories with type "Expense"
        @Published var expensesActual = 0.0 // total actual on all categories with type "Expense"
        @Published var totalBalanceBudget = 0.0 // total balances of all budget accounts
        @Published var totalBalanceExternal = 0.0 // total balances of all external accounts
        @Published var totalBalance = 0.0 // total balances of all accounts
        @Published var showBalanceAnimation = false // determines whether the category balance change animation is shown the next time I open one of the views its defined in, or not
        @Published var balanceAfter = false // determines which balance is being shown - the one before or the one after the transaction was created
        @Published var category = Category() // category for which the animation will be shown
        @Published var remainingBudgetBefore = 0.0 // remaining balance of that category before the latest change
        @Published var remainingBudgetAfter = 0.0 // remaining balance of that category after the latest change
        
        var budgetAvailable: Double {
            return expensesBudget - expensesActual
        }
    }
    @StateObject var periodBalances = PeriodBalances() // create the period balances - added to the environment further down
    
    class SelectedPeriod: ObservableObject {
        @Published var period = Period()
        @Published var periodStartDate = Date()
        @Published var periodChangedManually = false // detects whether the user has changed period manually, so that the onAppear doesn't reset the period to today's period once it has been changed
    }
    @StateObject var selectedPeriod = SelectedPeriod() // the period selected - added to the environment further down
    
    var body: some View {
        
        
//        PeriodListView() // to fix crashes on startup when the database has emptied and re-synced from iCloud, leave only this, and comment out the rest of the body

        /* */
        if periods.count > 0 {  // to protect against crashes when opening BudgetView when there are no periods yet
            
            TabView {
                
                BudgetView()
                    .tabItem {
                        Label("Budget", systemImage: "dollarsign.circle.fill")
                    }
                
                //            BalanceListView()
                //                .tabItem {
                //                    Label("Balances", systemImage: "dollarsign.circle.fill")
                //                }
                
                AccountListView()
                    .tabItem {
                        Label("Accounts", systemImage: "banknote")
                    }
                
                NavigationView { // NavigationView added here so that I don't have two of them when calling TransactionListView from other places
                    TransactionListView(payee: nil, account: nil, category: nil)
                }
                .tabItem {
                    Label("Transactions", systemImage: "list.triangle")
                }
                
                PayeeListView()
                    .tabItem {
                        Label("Payees", systemImage: "house")
                    }
                
                DebtorListView()
                    .tabItem {
                        Label("Expenses", systemImage: "banknote")
                    }
                
//                PeriodListView()
//                    .tabItem {
//                        Label("Periods", systemImage: "questionmark.folder.fill")
//                    }
                //            BudgetListView()
                //                .tabItem {
                //                    Label("Budgets", systemImage: "questionmark.folder.fill")
                //                }
                //            CategoryGroupListView()
                //                .tabItem {
                //                    Label("Category groups", systemImage: "questionmark.folder.fill")
                //                }
            }
            .environmentObject(periodBalances) // put the balances in the environment, so that they are available in all views that declare them
            .environmentObject(selectedPeriod) // put the selected period in the environment, so that they it is available in all views that declare it
//            .preferredColorScheme(.dark) // force the app to start in dark mode, even if the device is configured to light mode
            .preferredColorScheme(.light) // force the app to start in lighy mode, even if the device is configured to dark mode
        }
        
        else { // if there are no periods yet, show the setup screen
            VStack {
                Image(systemName: "dollarsign.circle")
                    .resizable()
                    .frame(width: 35, height: 35)
                Text("Welcome to Next Expense")
                    .font(.title)
                Text("Tap here to CREATE PERIODS AND TEST CATEGORIES")
                    .font(.headline)
            }
            .onTapGesture {
                createPeriods()
                createTutorialCategories()
            }
            .preferredColorScheme(.dark) // force the app to start in dark mode, even if the device is configured to light mode
        }
         /* */
    }
    
    
    private func createPeriods() {
        if(periods.count == 0) { // create periods if there are none
            print("Creating periods")
            var components = DateComponents()
            var startDate = Date()
            
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter
            }()
            
            for year in 2000...2070 {
                components.year = year
                for month in 1...12 {
                    components.month = month
                    components.day = 1
                    components.hour = 0
                    components.minute = 0
                    startDate = Calendar.current.date(from: components) ?? Date() // set the start date to the first day of the month
                    
                    let period = Period(context: viewContext)
                    period.id = UUID()
                    period.startdate = startDate
                    period.year = Int16(year)
                    period.month = Int16(month)
                    period.monthString = dateFormatter.string(from: startDate)
                    PersistenceController.shared.save() // save the item
                }
            }
        }
    }
    
    private func createTutorialCategories() { // create a few categories and groups
        // Category groups:
        let categoryGroup1 = CategoryGroup(context: viewContext)
        categoryGroup1.id = UUID()
        categoryGroup1.name = "Income"
        categoryGroup1.order = 0
        
        let categoryGroup2 = CategoryGroup(context: viewContext)
        categoryGroup2.id = UUID()
        categoryGroup2.name = "Daily expenses"
        categoryGroup2.order = 1
        
        let categoryGroup3 = CategoryGroup(context: viewContext)
        categoryGroup3.id = UUID()
        categoryGroup3.name = "Bills"
        categoryGroup3.order = 2
        
        // Categories in each group:
        let category1 = Category(context: viewContext)
        category1.id = UUID()
        category1.name = "Salary"
        category1.type = "Income"
        category1.categorygroup = categoryGroup1
        category1.order = 0
        
        let category2 = Category(context: viewContext)
        category2.id = UUID()
        category2.name = "Groceries"
        category2.type = "Expense"
        category2.categorygroup = categoryGroup2
        category2.order = 1
        
        let category3 = Category(context: viewContext)
        category3.id = UUID()
        category3.name = "Going out"
        category3.type = "Expense"
        category3.categorygroup = categoryGroup2
        category3.order = 2
        
        let category4 = Category(context: viewContext)
        category4.id = UUID()
        category4.name = "Rent"
        category4.type = "Expense"
        category4.categorygroup = categoryGroup3
        category4.order = 3
        
        let category5 = Category(context: viewContext)
        category5.id = UUID()
        category5.name = "Utilities"
        category5.type = "Expense"
        category5.categorygroup = categoryGroup3
        category5.order = 4
        
        PersistenceController.shared.save() // save the items
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
