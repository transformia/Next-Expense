//
//  AccountDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AccountDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to call AddTransactionView with a default category, and to be able to assign a category to a reconciliation difference
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the reconciliation transaction
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let account: Account // element to display
    
    @State private var name = ""
    @State private var type = "Budget" // tells us the type of the category    
    
    @State private var addTransactionView = false // determines whether the view for adding elements is displayed or not
    
    // Define category types:
    let types = ["Budget", "External"]
    
//    @State private var balance = 0.0
    @StateObject var accountBalance = TransactionDetailView.Amount()
    
    // Category selected for the reconciliation difference:
    @State private var selectedCategory: Category?
    
    @State private var showingDeleteAlert = false
//    @State private var showingReconciliationAlert = false
    
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    
    @FocusState var isFocused: Bool // determines whether the focus is on the text field or not
    
    @Environment(\.openURL) var openURL
    
//    @State private var clientAccessToken = ""
//    @State private var userAccessToken = ""
    
    @State private var accountInfo: [(String, String, String, Int)] = []
    @State private var showAccountList = false
    
    var body: some View {
        VStack {
            HStack {
                TextField("", text: $name)
                    .font(.title)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .onAppear {
                        name = account.name ?? ""
                    }
                if name != account.name { // if I have modified the name, show a button to save the change
                    Image(systemName: "opticaldiscdrive")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            account.name = name
                            PersistenceController.shared.save()
                            isFocused = false
                        }
                }
            }
            
            // Don't allow me to change this for now:
//            HStack {
//                Picker("Account type", selection: $type) {
//                    ForEach(types, id: \.self) {
//                        Text($0)
//                    }
//                }
//                .onAppear {
//                    type = account.type ?? ""
//                }
//                .onChange(of: type) { _ in
//                    account.type = type
//                    PersistenceController.shared.save()
//                }
//            }
            
            HStack {
                Text("Balance")
                    .font(.headline)
                Text(account.balance, format: .currency(code: account.currency ?? "EUR"))
                    .font(.headline)
                    .foregroundColor(.blue)
                    .onAppear {
                        accountBalance.intAmount = Int(account.balance * 100) // set the reconciliation balance to the account's balance
                    }
                    .onTapGesture {
                        accountBalance.showNumpad.toggle()
                    }
                    .onChange(of: account.balance) { _ in
                        accountBalance.intAmount = Int(account.balance * 100)
                    } // when the account balance changes because a transaction has been modified, also update the reconciliation balance so that it doesn't think that there is suddenly a reconciliation difference
            }
            
//            Text("Tink account id: " + (account.externalid ?? ""))
            
            Group {
                
                Button {
                    TinkService.shared.newUser() { success, tinkLinkURL in
                        print("Tink Link generated")
//                        print(tinkLinkURL ?? "")
                    }
                } label: {
                    Label("Create user", systemImage: "key")
                }
                
                Button {
                    TinkService.shared.giveAccess() { success, tinkLinkURL in
                        if success {
                            //                        print(tinkLinkURL ?? "")
                            openURL(URL(string: tinkLinkURL!)!)
                        }
                        else {
                            print("Tink link wan't generated")
                        }
                    }
                } label: {
                    Label("Grant user access", systemImage: "key")
                }
                .onOpenURL { incomingURL in
                    handleTinkLinkCallback(incomingURL: incomingURL)
                }
                
                Button {
                    TinkService.shared.authorizeApp(scope: "authorization:grant") { success, clientAccessToken in
                        if success {
                            TinkService.shared.getUserAccessToken()
                        }
                    }
                } label: {
                    Label("Get client then user access token", systemImage: "key")
                }
                
                /*Button {
                    TinkService.shared.authorizeApp(scope: "authorization:grant") { success, clientAccessToken in
//                        print(clientAccessToken ?? "")
                    }
                } label: {
                    Label("Get client access token", systemImage: "key")
                }
                
                Button {
                    TinkService.shared.getUserAccessToken()
                } label: {
                    Label("Get user access token", systemImage: "key")
                }*/
                
                Button {
                    linkAccount()
                } label: {
                    Label("Link account", systemImage: "key")
                }
                .sheet(isPresented: $showAccountList) {
                    TinkAccountList(account: account, accountInfo: accountInfo, balance: accountBalance)
                }
            }
            
            /*Group {
                
                Button {
                    authorizeApp(scope: "user:create")
                } label: {
                    Label("Authorize app", systemImage: "key")
                }
                
                Button {
                    createUser()
                } label: {
                    Label("Create user", systemImage: "key")
                }
                
                Button {
                    authorizeApp(scope: "authorization:grant")
                } label: {
                    Label("Authorize app", systemImage: "key")
                }
                
                Button {
                    grantUserAccess()
                } label: {
                    Label("Grant user access", systemImage: "key")
                }
                .onOpenURL { incomingURL in
                    handleTinkLinkCallback(incomingURL: incomingURL)
                }
                
                Button {
                    getUserAccessCode()
                } label: {
                    Label("Get user access code then tokens", systemImage: "key")
                }
                
                Button {
                    getAccountList()
                } label: {
                    Label("Link account", systemImage: "key")
                }
                .sheet(isPresented: $showAccountList) {
                    TinkAccountList(account: account, accountInfo: accountInfo, balance: accountBalance)
                }
                
                Button {
                    getAccountBalance()
                } label: {
                    Label("Get account balance", systemImage: "key")
                }
            }*/
            
            /*Button {
                openTinkLink()
            } label: {
                Label("Authenticate with Tink", systemImage: "key")
            }
            .onOpenURL { incomingURL in
                handleTinkLinkCallback(incomingURL: incomingURL)
            }
            
            
//            Text("Tink code: \(tinkCode)")
            
            
            Button {
                getTinkAccessToken()
            } label: {
                Label("Exchange code for access token", systemImage: "key")
            }
                
            
            Button {
                getAccountList()
            } label: {
                Label("Get account list", systemImage: "dollarsign")
            }
            .sheet(isPresented: $showAccountList) {
                TinkAccountList(account: account, accountInfo: accountInfo, balance: accountBalance)
            }
            
//            if account.externalid != nil {
//                Button {
//                    getAccountBalance()
//                } label: {
//                    Label("Get balance", systemImage: "dollarsign")
//                }
//            }*/
            
            
            if(Double(accountBalance.intAmount) / 100 != account.balance) {
                HStack {
                    Text("Reconciliation balance")
                        .font(.headline)
                    
                    Text(Double(accountBalance.intAmount) / 100, format: .currency(code: account.currency ?? "EUR"))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                HStack {
                    Text("Difference: ")
                    Text(((Double(accountBalance.intAmount) / 100 - account.balance)), format: .currency(code: account.currency ?? "EUR"))
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { (category: Category) in
                            Text(category.name ?? "")
                                .tag(category as Category?)
                        }
                    }
                    .onAppear {
                        selectedCategory = categories[0]
                    }
                }
                HStack {
                    Button {
                        print("Reconciling with a difference of \(( Double(accountBalance.intAmount) / 100 - account.balance ))")
                        let transaction = Transaction(context: viewContext)
                            
                        transaction.populate(account: account, date: Date(), period: getPeriod(date: Date()), payee: nil, category: selectedCategory, memo: "Reconciliation difference", amount: Int(abs((Double(accountBalance.intAmount) - account.balance * 100))), amountTo: 0, currency: account.currency ?? "EUR", income: Double(accountBalance.intAmount) - account.balance * 100 > 0 ? true : false, transfer: false, toAccount: nil, expense: false, expenseSettled: false, debtor: nil, recurring: false, recurrence: "")
                        
                        // Update the category, account(s) and period balances based on the new transaction:
                        transaction.updateBalances(transactionPeriod: transaction.period ?? Period(), selectedPeriod: selectedPeriod.period, category: selectedCategory, account: account, toaccount: nil)
//                        transaction.updateBalances(transactionPeriod: transaction.period ?? Period(), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: account, toaccount: nil)
                        
                        PersistenceController.shared.save() // save the reconciliation transaction and the balance updates
                        
                    } label: {
                        Label("Reconcile", systemImage: "checkmark")
                    }
                    
                    Button {
                        accountBalance.intAmount = Int(account.balance * 100)
//                        accountBalance.intAmount = Int(account.calcBalance(toDate: Date()))
                    } label: {
                        Label("Cancel", systemImage: "x.circle")
                    }
                    .tint(.green)
                }
            }
            
            // Show button to delete the account if it has no transactions:
            if transactions.filter({$0.account == account || $0.toaccount == account}).count == 0 {
                Button(role: .destructive) {
                    print("Deleting account \(account.name ?? "")")
                    viewContext.delete(account)
                    PersistenceController.shared.save() // save the change
                    dismiss()
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
                .padding()
            }
            
//                .onTapGesture {
//                    showingReconciliationAlert = true
//                }
//                .confirmationDialog("Is your account balance correct?", isPresented:$showingReconciliationAlert, titleVisibility: .visible) {
//                    Button("Yes") {
//                        print("Reconciling without difference")
////                        dismiss()
//                    }
//                    Button("No") {
//                        print("Canceling")
////                        dismiss()
//                    }
//                }
            
//            Spacer()
            
//            deleteButton
                        
            TransactionListView(payee: nil, account: account, category: nil)
            .sheet(isPresented: $addTransactionView) {
                TransactionDetailView(transaction: nil, payee: nil, account: account, category: nil)
            }
            
//            deleteButton
        }
        .sheet(isPresented: $accountBalance.showNumpad) {
            NumpadView(amount: accountBalance)
                .presentationDetents([.height(300)])
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            withAnimation {
                showingDeleteAlert = true
            }
        } label : {
            Label("Delete account", systemImage: "xmark.circle")
        }
        .alert(isPresented:$showingDeleteAlert) {
            Alert(
                title: Text("Are you sure you want to delete this account?"),
                message: Text("This cannot be undone"),
                primaryButton: .destructive(Text("Delete")) {
                    viewContext.delete(account)
                    PersistenceController.shared.save() // save the change
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
        let year = Calendar.current.dateComponents([.year], from: date).year ?? 1900
        let month = Calendar.current.dateComponents([.month], from: date).month ?? 1
        
        for period in periods {
            if(period.year == year) {
                if(period.month == month) {
                    return period
                }
            }
        }
        return Period() // if no period is found, return a new one
    }
    
    private func handleTinkLinkCallback(incomingURL: URL) {
        print("App was opened via URL: \(incomingURL)")
        guard incomingURL.scheme == "nextexpenseapp" else {
            print("Invalid URL scheme")
            return
        }
        guard let components = URLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            print("Invalid URL")
            return
        }
        
        guard let state = components.queryItems?.first(where: { $0.name == "state" })?.value else {
            print("State not found")
            return
        }
        
        if state == "MyStateCode" {
            print("User access granted")
        }
        else {
            print("Invalid state code")
            return
        }
    }
    
    /*
    private func authorizeApp(scope: String) {
        print("Authorizing the app")
        
        let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
        let clientSecret = "79a3313907fd46a193f9b0a196b14bfa" // sandbox
//        let clientID = "dd0e0e14037347a8b9a003b869c4de87" // production
//        let clientSecret = "4b4393da30d34e7c98f5966c13be504d" // production
        
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
                        tinkAccessToken = accessToken
                    } else {
                        print("Error: Access token not found in JSON")
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
    
    
    private func createUser() {
        print("Creating a user")
        
        let url = URL(string: "https://api.tink.com/api/v1/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody: [String: Any] = [
            "external_user_id": "user_123_abc",
            "market": "GB",
            "locale": "en_US"
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            print("Error encoding JSON:", error)
            return
        }
        
        request.addValue("Bearer \(tinkAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
                    if let externalUserId = jsonData["external_user_id"] as? String, let userId = jsonData["user_id"] as? String {
                        print("User created:", externalUserId)
                        print("Tink user id", userId)
                    } else {
                        print("Error: User was not created")
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
    
    private func grantUserAccess() {
        print("Granting access to user")
        
        let actor_client_id = "df05e4b379934cd09963197cc855bfe9"
        let externalUserID = "user_123_abc"
        let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
        
        let url = URL(string: "https://api.tink.com/api/v1/oauth/authorization-grant/delegate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
//        let requestBody: [String: Any] = [
////            "actor_client_id" : actor_client_id,
////            "user_id": "user_123_abc",
////            "id_hint": "John%20Doe",
//            "scope": "authorization:read,authorization:grant,credentials:refresh,credentials:read,credentials:write,providers:read,user:read"
//        ]
        
        let requestBody = "external_user_id=\(externalUserID)&id_hint=Michael%20Frisk&actor_client_id=\(actor_client_id)&scope=credentials:read,credentials:refresh,credentials:write,providers:read,user:read,authorization:read"
                
        request.httpBody = requestBody.data(using: .utf8)
        
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
//            request.httpBody = jsonData
//        } catch {
//            print("Error encoding JSON:", error)
//            return
//        }
        
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
                        
                        let tinkLinkURL = "https://link.tink.com/1.0/transactions/connect-accounts?client_id=\(clientID)&state=MyStateCode&redirect_uri=nextexpenseapp%3A%2F%2F&authorization_code=\(code)&market=GB&locale=en_US"
                        
                        print(tinkLinkURL)
                        
                        openURL(URL(string: tinkLinkURL)!)
                        
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
    
    // Send the external user id and the tink access token, and get a code. Then run getUserAccessTokens() to exchange the code for a user access token
    private func getUserAccessCode() {
        print("Getting user access code")
        
        let externalUserID = "user_123_abc"
        
        let url = URL(string: "https://api.tink.com/api/v1/oauth/authorization-grant")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let requestBody = "external_user_id=\(externalUserID)&scope=accounts:read,balances:read,transactions:read,provider-consents:read"
        
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
                        getUserAccessTokens(code: code)
                                            
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
        
    // Exchange the code for a user access token:
    private func getUserAccessTokens(code: String) {
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
    }*/
    
    // Send the user access token, get the list of accounts, display it. Tap on an account to get its balance and its id, store the id on the account, and put the balance in the account reconciliation balance:
    private func linkAccount() {
        print("Fetching account list")
        let url = URL(string: "https://api.tink.com/data/v2/accounts")!
        
        let header = ["Authorization": "Bearer \(TinkService.shared.userAccessToken)"]
        
//        print("User access token:")
//        print(TinkService.shared.userAccessToken)
        
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
                    print("Data:")
                    print(jsonData)
                    
                    if let accounts = jsonData["accounts"] as? [[String: Any]] {
                        print("Account list:")
                        print(accounts)
                        
                        accountInfo = accounts.compactMap { account in
                            guard
                                let name = account["name"] as? String,
                                let id = account["id"] as? String,
                                let type = account["type"] as? String,
                                let balances = account["balances"] as? [String: Any],
                                let booked = balances["booked"] as? [String: Any],
                                let amount = booked["amount"] as? [String: Any],
                                let unscaledValueString = amount["value"] as? [String: Any],
                                let unscaledValue = unscaledValueString["unscaledValue"] as? String,
                                let balance = Int(unscaledValue)
                            else {
                                return nil
                            }
                            return (name: name, id: id, type: type, balance: balance)
                        }
                        print("Account info:")
                        print(accountInfo)
                        
                        showAccountList = true
                        
                    } else {
                        print("No account information found")
                    }
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error decoding JSON:", error)
            }
            
        }.resume()
    }
    
    // Send the account id and the user access token, and get the account balance?:
    private func getAccountBalance() {
        if account.externalid != nil {
            print("Getting account balance")
            let url = URL(string: "https://api.tink.com/data/v2/accounts/\(account.externalid ?? "")/balances")!
            
            let header = ["Authorization": "Bearer \(TinkService.shared.userAccessToken)"]
            
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
                        print("Data:")
                        print(jsonData)
                        
                        /*if let accounts = jsonData["accounts"] as? [[String: Any]] {
                            print("Account list:")
                            print(accounts)
                            
                            accountInfo = accounts.compactMap { account in
                                if let name = account["name"] as? String,
                                   let id = account["id"] as? String,
                                let type = account["type"] as? String {
                                    return (name: name, id: id, type: type)
                                }
                                return nil
                            }
                            
                            print(accountInfo)
                            
                            showAccountList = true
                            
                        } else {
                            print("No account balance found")
                        }*/
                    } else {
                        print("Error decoding JSON")
                    }
                } catch {
                    print("Error decoding JSON:", error)
                }
                
            }.resume()
        }
    }
    
    /*private func openTinkLink() {
        // Guide: https://docs.tink.com/resources/transactions/connect-to-a-bank-account
        
        // Sandbox - Transactions:
        openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=408dcac9914442a1b875da8e10f7a487&redirect_uri=nextexpenseapp%3A%2F%2F&market=SE&locale=en_US")!)
        
        // Real world Sweden - Transactions - also gives access to accounts??:
//        openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=SE&locale=en_US")!)
        
        // Real world Sweden - Handelsbanken - Account check:
//        openURL(URL(string: "https://link.tink.com/1.0/account-check/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=SE&locale=en_US&input_provider=handelsbanken-bankid&input_username=198406227432")!)
        
        
        // Demo bank Sweden - account check?? - doesn't work:
//        openURL(URL(string: "https://link.tink.com/1.0/account-check/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=https%3A%2F%2Fconsole.tink.com%2Fcallback&market=SE&locale=en_US&input_provider=se-demobank-password&input_username=u27678322")!)
    }
    
    private func getTinkAccessToken() { // exchange the code obtained in the callback url for an access token
        let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
        let clientSecret = "79a3313907fd46a193f9b0a196b14bfa" // sandbox
//        let clientID = "dd0e0e14037347a8b9a003b869c4de87" // production
//        let clientSecret = "4b4393da30d34e7c98f5966c13be504d" // production
                
        let url = URL(string: "https://api.tink.com/api/v1/oauth/token")!
        
        let data = NSMutableData(data: "code=\(tinkCode)".data(using: .utf8)!)
        data.append("&client_id=\(clientID)".data(using: .utf8)!)
        data.append("&client_secret=\(clientSecret)".data(using: .utf8)!)
        data.append("&grant_type=authorization_code".data(using: .utf8)!)
        
        let header = ["Content-Type": "application/x-www-form-urlencoded"]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = header
        request.httpBody = data as Data
        
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
                        tinkAccessToken = accessToken
                    } else {
                        print("Error: Access token not found in JSON")
                        print(jsonData)
                    }
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error decoding JSON:", error)
            }
            
        }.resume()
    }*/
}

//struct AccountDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountDetailView()
//    }
//}
