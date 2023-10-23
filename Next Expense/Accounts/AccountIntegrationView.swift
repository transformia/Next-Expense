//
//  AccountIntegrationView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-10-18.
//

import SwiftUI

struct AccountIntegrationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to import only transactions corresponding to this account
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to find the payee corresponding to a string
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to check if a transaction already exists
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the new transactions
    
    let account: Account
    
    @Environment(\.openURL) var openURL
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var country = "ES" // tell Tink which market to use in the link
    @State private var bank = "handelsbanken-bankid" // tell Tink which bank to use in the link
    @State private var bankLogin = "" // tell Tink which login to use in the link
    
    @State private var showAccountList = false
    
    @State private var accountInfo: [(String, String, String, Int)] = []
    
    @StateObject var accountBalance = TransactionDetailView.Amount()
    
    // For one-time access to Tink:
    @State private var tinkCode = ""
    @State private var tinkAccessToken = ""
    
    @State private var lastRefreshDate = Date(timeIntervalSinceReferenceDate: 0)
    @State private var countSameId = 0
    @State private var countDuplicates = 0
    @State private var countCreated = 0
    @State private var countOldTransactions = 0
    
    
    var body: some View {
        
        VStack {
//            Text("Tink id: " + (account.externalid ?? ""))
            
            
            /* Tink one-time access buttons: */
            
            
            Form {
                
                Picker("Country", selection: $country) {
                    Text("Spain")
                        .tag("ES")
                    Text("Sweden")
                        .tag("SE")
                }
                .onAppear {
                    country = account.country ?? "ES"
                }
                .onChange(of: country) { _ in
                    account.country = country
                    PersistenceController.shared.save()
                }
                
                Picker("Bank", selection: $bank) {
                    Text("Handelsbanken")
                        .tag("handelsbanken-bankid")
                    Text("BBVA")
                        .tag("es-bbva-password")
                    Text("Other")
                        .tag("none")
                }
                .onAppear {
                    bank = account.bank ?? "none"
                }
                .onChange(of: bank) { _ in
                    account.bank = bank
                    PersistenceController.shared.save()
                }
                
                if bank != "none" {
                    TextField("Login", text: $bankLogin)
                        .onAppear {
                            bankLogin = account.banklogin ?? ""
                        }
                        .onChange(of: bankLogin) { _ in
                            account.banklogin = bankLogin
                            PersistenceController.shared.save()
                        }
                }
            }
            
            Button {
                openTinkLink()
            } label: {
                Label("Open Tink link", systemImage: "key")
            }
            .onOpenURL { incomingURL in
                handleTinkLinkCallback(incomingURL: incomingURL)
            }
            .padding()
            
            
            Button {
                getAccountInfo()
            } label: {
                Label("Refresh data", systemImage: "arrow.clockwise")
            }
            .sheet(isPresented: $showAccountList) {
                TinkAccountList(account: account, accountInfo: accountInfo, balance: accountBalance)
            }
            .onOpenURL { incomingURL in
                handleTinkLinkCallback(incomingURL: incomingURL)
            }
            .padding()
            
            
            //            Text("Tink code: \(tinkCode)")
            
            
            /* Included in handleTinkLinkCallback():
             Button {
             getTinkAccessToken()
             } label: {
             Label("Exchange code for access token", systemImage: "key")
             }*/
            
            
            /* Included in getAccountInfo:
             Button {
             TinkService.shared.getTransactions() { success, tinkTransactions in
             //                            print(tinkTransactions)
             createTransactions(tinkTransactions: tinkTransactions)
             }
             } label: {
             Label("Get transactions", systemImage: "key")
             }*/
            
            HStack {
                Text("Last refresh:")
                Text(lastRefreshDate, formatter: dateTimeFormatter)
                    .onAppear {
                        lastRefreshDate = account.lastrefreshdate ?? Date(timeIntervalSinceReferenceDate: 0)
                    }
            }
            .padding(.horizontal)
            
            HStack {
                Text("Account balance: ")
                Text(Double(accountBalance.intAmount) / 100, format: .currency(code: account.currency ?? "EUR"))
            }
            
            Text("\(countCreated) new, \(countOldTransactions) too old, \(countSameId) already imported, \(countDuplicates) identical")
                .padding(.horizontal)
            
            /*HStack {
             Text("Created:")
             Text("\(countCreated)")
             }
             .padding(.horizontal)
             
             HStack {
             Text("Duplicate id:")
             Text("\(countSameId)")
             }
             .padding(.horizontal)
             
             HStack {
             Text("Duplicate without id:")
             Text("\(countDuplicates)")
             }
             .padding(.horizontal)*/
            
            
            //            Button {
            //                getAccountList()
            //            } label: {
            //                Label("Get account list", systemImage: "dollarsign")
            //            }
            //            .sheet(isPresented: $showAccountList) {
            //                TinkAccountList(account: account, accountInfo: accountInfo, balance: accountBalance)
            //            }
            
            //            if account.externalid != nil {
            //                Button {
            //                    getAccountBalance()
            //                } label: {
            //                    Label("Get balance", systemImage: "dollarsign")
            //                }
            //            }
            
            
            /*Group {
             
             /* Continuous access buttons: */
             
             
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
             
             Button {
             getAccountInfo()
             } label: {
             Label("Reconcile account", systemImage: "dollarsign")
             }
             .sheet(isPresented: $showAccountList) {
             TinkAccountList(account: account, accountInfo: accountInfo, balance: accountBalance)
             }
             }*/
            
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
    
    
    
    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d hh:mm:ss"
        return formatter
    }()

    private let dateFormatterTink: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Find the account based on the external id, if it exists:
    private func matchAccount(externalId: String)  -> Account? {
        return accounts.first { $0.externalid == externalId }
    }
    
    // One-time access functions:
    
    private func openTinkLink() {
        // Guide: https://docs.tink.com/resources/transactions/connect-to-a-bank-account
        
        // Sandbox - Transactions:
//        openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=408dcac9914442a1b875da8e10f7a487&redirect_uri=nextexpenseapp%3A%2F%2F&market=SE&locale=en_US")!)
        
        // Real world Sweden - Transactions - also gives access to accounts??:
//        openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=SE&locale=en_US")!)
        
        // Real world Spain - Transactions:
//        openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=ES&locale=en_US")!)
        
        // Real world - selected country and bank:
        if bank != "none" {
            openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=\(country)&locale=en_US&input_provider=\(bank)&input_username=\(bankLogin)")!)
        }
        else {
            openURL(URL(string: "https://link.tink.com/1.0/transactions/connect-accounts/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=\(account.country ?? "ES")&locale=en_US")!)
        }
        
        // Real world Sweden - Handelsbanken - Account check:
//        openURL(URL(string: "https://link.tink.com/1.0/account-check/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=nextexpenseapp%3A%2F%2F&market=SE&locale=en_US&input_provider=handelsbanken-bankid&input_username=198406227432")!)
        
        
        // Demo bank Sweden - account check?? - doesn't work:
//        openURL(URL(string: "https://link.tink.com/1.0/account-check/?client_id=dd0e0e14037347a8b9a003b869c4de87&redirect_uri=https%3A%2F%2Fconsole.tink.com%2Fcallback&market=SE&locale=en_US&input_provider=se-demobank-password&input_username=u27678322")!)
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
        
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("Code not found")
            return
        }
        
        print("Code obtained: \(code)")
        tinkCode = code
        
        // Exchange the code obtained in the callback url for an access token:
        getTinkAccessToken()
    }
    
    private func getTinkAccessToken() { // exchange the code obtained in the callback url for an access token
//        let clientID = "408dcac9914442a1b875da8e10f7a487" // sandbox
//        let clientSecret = "79a3313907fd46a193f9b0a196b14bfa" // sandbox
        let clientID = "dd0e0e14037347a8b9a003b869c4de87" // production
        let clientSecret = "4b4393da30d34e7c98f5966c13be504d" // production
                
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
                        UserDefaults.standard.set(tinkAccessToken, forKey: "UserAccessToken")
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
    
    
    // Send the user access token, get the list of accounts, display it. Tap on an account to get its balance and its id, store the id on the account, and put the balance in the account reconciliation balance:
    private func getAccountInfo() {
        print("Fetching account list")
        let url = URL(string: "https://api.tink.com/data/v2/accounts")!
        
//        let header = ["Authorization": "Bearer \(tinkAccessToken)"]
        let header = ["Authorization": "Bearer \(UserDefaults.standard.string(forKey: "UserAccessToken") ?? tinkAccessToken)"]
        
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
//                    print("Data:")
//                    print(jsonData)
                    
                    // Check if I am authenticated, otherwise open the authentication link:
                    if let code = jsonData["code"] as? Int {
                        print("Error code:")
                        print(code)
                        openTinkLink()
                    }
                    
                    else if let accounts = jsonData["accounts"] as? [[String: Any]] {
//                        print("Account list:")
//                        print(accounts)
                        
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
//                        print("Account info:")
//                        print(accountInfo)
                        
                        // If account information is found in Tink that matches this account's external id, get the transactions and the balance
                        if let thisAccountInfo = accountInfo.first(where: {$0.1 == account.externalid}) {
                            
                            // Get the latest transactions:
                            getTransactions()
                            
                             
                            // Get the account balance and put it in the Reconciliation balance, and save it on the account:
                            print("Setting reconciled balance to \(thisAccountInfo.3)")
                            accountBalance.intAmount = thisAccountInfo.3 // getting this error from this line of code: "Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates."
                            account.reconciledbalance = Double(thisAccountInfo.3)
                            PersistenceController.shared.save() // save the change
                            
                             
                            /* Replaced to avoid error "Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates."
                             
                             TinkService.shared.getTransactions() { success, tinkTransactions in
            //                            print(tinkTransactions)
                                createTransactions(tinkTransactions: tinkTransactions)
                                
                                // Get the account balance and put it in the Reconciliation balance, and save it on the account:
//                                print("Setting reconciled balance to \(thisAccountInfo.3)")
                                accountBalance.intAmount = thisAccountInfo.3
                                account.reconciledbalance = Double(thisAccountInfo.3)
                                PersistenceController.shared.save() // save the change
                            }*/
                            
                        }
                        // Else show the account list so that I can link an account to this one:
                        else {
                            print("This account's id wasn't found: \(account.externalid ?? "")")
                            showAccountList = true
                        }
                        
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
    
    private func getTransactions() {
        print("Fetching transactions")
        
        let url = URL(string: "https://api.tink.com/data/v2/transactions")!
        
        let header = ["Authorization": "Bearer \(UserDefaults.standard.string(forKey: "UserAccessToken") ?? tinkAccessToken)"]
        
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
                    
                    /* COMMENTING THIS OUT FOR NOW SO THAT I DON'T CREATE TRANSACTIONS
                     if let tinkTransactions = jsonData["transactions"] as? [[String: Any]] {
                        createTransactions(tinkTransactions: tinkTransactions)
                    } else {
                        print("No transaction info found")
                    }*/
                } else {
                    print("Error decoding JSON")
                }
            } catch {
                print("Error decoding JSON:", error)
            }
            
        }.resume()
    }
    
    private func createTransactions(tinkTransactions: [[String: Any]]) {
        countCreated = 0
        countDuplicates = 0
        countSameId = 0
        countOldTransactions = 0
        
        for tinkTransaction in tinkTransactions {
            
            /*// For now, only import the n latest transactions:
            if countCreated + countDuplicates + countSameId >= 3 {
                print("Stopped after \(countCreated + countDuplicates + countSameId) transactions")
                return
            }*/
            
            // Get the account from the external account id:
            guard let externalId = tinkTransaction["accountId"] as? String,
                  let account = matchAccount(externalId: externalId) else {
                // Skip this transaction if the account isn't found
                print("Account not found. Skipping")
                continue
            }
                
//            print("Transaction:")
//            print(tinkTransaction)
            
            // Fails in the case of Handelsbanken, because they do not send a provider transactionid:
             // Get the provider transaction id:
            guard let identifiers = tinkTransaction["identifiers"] as? [String: Any],
                  let providerTransactionId = identifiers["providerTransactionId"] as? String else {
                // Skip this transaction if it doesn't have a provider transaction id
                print("Provider transaction id not found")
//                print("Transaction:")
//                print(tinkTransaction)
                continue
            }
            
            
            /* If I want to support banks that don't sent a provider id, like Handelsbanken:
            // Get the provider transaction id:
            let identifiers = tinkTransaction["identifiers"] as? [String: Any]
            
            let providerTransactionId = identifiers?["providerTransactionId"] as? String
                
            
            // Check if a transaction with the same provider id already exists on that account (except if there is no provider id):
            if providerTransactionId != nil && transactions.filter({$0.account == account && $0.externalid == providerTransactionId}).count > 0 {
//                print("Transaction with id \(providerTransactionId) has already been imported. Skipping it")
                countSameId += 1
                continue
            }*/
            
            // Get the date:
            guard let dates = tinkTransaction["dates"] as? [String: Any],
                  let dateString = dates["booked"] as? String,
                  let date = dateFormatterTink.date(from: dateString) else {
                // Skip this transaction if date information is missing or invalid
                print("Date not found. Skipping")
                continue
            }
            
            // Skip this transaction if it is older than the last refresh date minus 7 days, or older than 7 days if there is no last refresh date:
            if date < Calendar.current.date(byAdding: .day, value: -7, to: lastRefreshDate) ?? Date() || ( lastRefreshDate == Date(timeIntervalSinceReferenceDate: 0) && date < Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() ) {
//                print("Transaction more than 3 days older than the last refresh date. Skipping")
                countOldTransactions += 1
                continue
            }
            
            // Get the currency and amount:
            guard let amountNode = tinkTransaction["amount"] as? [String: Any],
                  let currencyCode = amountNode["currencyCode"] as? String,
                  let value = amountNode["value"] as? [String: Any],
                  let unscaledValue = value["unscaledValue"] as? String,
                  let amount = Int(unscaledValue) else {
                // Skip this transaction if amount information is missing or invalid
                print("Amount or currency not found. Skipping")
                continue
            }
            
            // Determine if it is an inflow or an outflow, and remove the sign of the amount:
            let income = amount > 0
            let intAmount = abs(amount)
            
            // Get the descriptions:
            guard let descriptions = tinkTransaction["descriptions"] as? [String: Any],
                  let displayDescription = descriptions["display"] as? String,
                  let originalDescription = descriptions["original"] as? String else {
                // Skip this transaction if it doesn't have descriptions
                print("Descriptions not found. Skipping")
                continue
            }
            
            // Determine the payee:
            var payee: Payee? = nil
            
            for existingPayee in payees {
                if(existingPayee.name == displayDescription || existingPayee.name == originalDescription) {
                    payee = existingPayee
                    break
                }
            }
            
            if payee == nil { // if not payee was found, create it
                print("Creating payee ", displayDescription)
                let newPayee = Payee(context: viewContext)
                newPayee.id = UUID()
                newPayee.name = displayDescription
                newPayee.account = account
                payee = newPayee
                PersistenceController.shared.save() // save the new payee, so that another transaction can use it - otherwise it will get created more than once if more than one transaction has it
            }
            
            // Check if a transaction with the same date, sign, payee and amount already exists on the account (in case it was created manually):
            if transactions.filter({$0.account == account && Calendar.current.startOfDay(for: $0.date ?? Date())  == Calendar.current.startOfDay(for: date) && $0.payee == payee && $0.amount == intAmount && $0.income == income}).count > 0 {
//                print("Transaction on account ", account.name ?? "", " on date ", date, " on payee ", displayDescription, " of amount ", intAmount, " already exists. Skipping it")
                countDuplicates += 1
                continue
            }
            
            // Get the status:
            guard let status = tinkTransaction["status"] as? String else {
                // Skip this transaction if it doesn't have a status
                print("Status not found. Skipping")
                continue
            }
            
            // LATER: ALSO GET THE MERCHANT CATEGORY CODE AND NAME, IF THEY ARE PRESENT?
            
            
            
            // Create the transaction
            countCreated += 1
            print("Creating a transaction: ", providerTransactionId ?? "no_id", account.name ?? "", date, currencyCode, intAmount, displayDescription, originalDescription, status)
            let transaction = Transaction(context: viewContext)
            transaction.populate(account: account, date: date, period: getPeriod(date: date), payee: payee, category: payee?.category, memo: originalDescription, amount: intAmount, amountTo: 0, currency: currencyCode, income: income, transfer: false, toAccount: nil, expense: false, expenseSettled: false, debtor: nil, recurring: false, recurrence: "", externalId: providerTransactionId ?? "no_id", posted: false)
            
            // Update the category, account(s) and period balances based on the new transaction:
            transaction.updateBalances(transactionPeriod: transaction.period ?? Period(), selectedPeriod: selectedPeriod.period, category: payee?.category, account: account, toaccount: nil)
        }
        
        print("Transactions that already exist with the same id: \(countSameId)")
        print("Transactions that seem to be duplicates: \(countDuplicates)")
        print("Transactions created: \(countCreated)")
        print("Transactions too old: \(countOldTransactions)")
        
        lastRefreshDate = Date()
        account.lastrefreshdate = lastRefreshDate
        
        PersistenceController.shared.save() // save the new transactions
    }
    
}

//#Preview {
//    AccountIntegrationView()
//}
