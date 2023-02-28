//
//  CSVExportView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-11-05.
//

import SwiftUI
import UniformTypeIdentifiers

struct CSVExportView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to export transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.id, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget> // to be able to export budgets
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FxRate.startdate, ascending: false)],
        animation: .default)
    private var fxrates: FetchedResults<FxRate> // to be able to export fx rates
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to find the category corresponding to a string

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to find the account corresponding to a string
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to find the payee corresponding to a string
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the imported transaction
    
    struct MessageDocument: FileDocument {
        
        static var readableContentTypes: [UTType] { [.plainText] }
        
        var message: String
        
        init(message: String) {
            self.message = message
        }
        
        init(configuration: ReadConfiguration) throws {
            guard let data = configuration.file.regularFileContents,
                  let string = String(data: data, encoding: .utf8)
            else {
                throw CocoaError(.fileReadCorruptFile)
            }
            message = string
        }
        
        func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            return FileWrapper(regularFileWithContents: message.data(using: .utf8)!)
        }
        
    }
    
    @State private var document: MessageDocument = MessageDocument(message: "")
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    
    // Variable determining whether the focus is on the text editor or not:
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { document.message = getTransactions() }, label: {
                    Text("Get transactions")
                })
                Button(action: { document.message = getBudgets() }, label: {
                    Text("Get budgets")
                })
                Button(action: { document.message = getFxRates() }, label: {
                    Text("Get exchange rates")
                })
            }
            HStack {
                Button(action: { putTransactions(message: document.message) }, label: {
                    Text("Create transactions")
                })
                Button(action: { putBudgets(message: document.message) }, label: {
                    Text("Create budgets")
                })
                Button(action: { putFxRates(message: document.message) }, label: {
                    Text("Create exchange rates")
                })
            }
            GroupBox(label:
                        HStack {
                Text("Data:")
                if isFocused {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .onTapGesture {
                            isFocused = false
                        }
                }
            }) {
                TextEditor(text: $document.message)
                    .focused($isFocused)
            }
            GroupBox {
                HStack {
                    Spacer()
                    
                    Button(action: { isImporting = true }, label: {
                        Text("Import")
                    })
                    
                    Spacer()
                    
                    Button(action: { isExporting = true }, label: {
                        Text("Export")
                    })
                    
                    Spacer()
                    
                    Button(action: { document.message = "" }, label: {
                        Text("Clear")
                    })
                    
                    Spacer()
                }
            }
        }
        .padding()
        .fileExporter(isPresented: $isExporting, document: document, contentType: .plainText, defaultFilename: "Data") { result in
            if case .success = result {
                // Handle success.
            } else {
                // Handle failure.
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.plainText], allowsMultipleSelection: false) { result in
            do {
                print("Getting file")
                guard let selectedFile: URL = try result.get().first else { return }
                if selectedFile.startAccessingSecurityScopedResource() { // make the resource referenced by the url accessible to the process
                    //                guard let message = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                    print("Reading message")
                    let message = try? String(contentsOf: selectedFile, encoding: .macOSRoman) // supports special characters å ä ö as saved by Excel for mac
//                    let message = try String(contentsOf: selectedFile)
                    
                    selectedFile.stopAccessingSecurityScopedResource() // remove access to the resource
                    print("Assigning message to object")
                    document.message = message ?? "Failed to create a string from the document contents"
                }
                
            } catch {
                // Handle failure.
                print("Failed to import data")
            }
        }
    }
    
    private func getTransactions() -> String { // get all transactions and put them in the message field
        var message = "\"Account\"\t\"Date\"\t\"Payee\"\t\"Category\"\t\"Memo\"\t\"Amount\"\t\"Currency\"\t\"Income\"\t\"Transfer\"\t\"ToAccount\"\t\"Expense\"\t\"Debtor\"\t\"Recurring\"\t\"Recurrence\""
        for transaction in transactions {
            message += "\n\"\(transaction.account?.name ?? "")\"\t"
            message += "\"\(transaction.date ?? Date())\"\t"
            message += "\"\(transaction.payee?.name ?? "")\"\t"
            message += "\"\(transaction.category?.name ?? "")\"\t"
            message += "\"\(transaction.memo ?? "")\"\t"
            message += "\"\(String(transaction.amount))\"\t"
            message += "\"\(transaction.currency ?? "EUR")\"\t"
            message += "\"\(transaction.income)\"\t"
            message += "\"\(transaction.transfer)\"\t"
            message += "\"\(transaction.toaccount?.name ?? "")\"\t"
            message += "\"\(transaction.expense)\"\t"
            message += "\"\(transaction.debtor?.name ?? "")\"\t"
            message += "\"\(transaction.recurring)\"\t"
            message += "\"\(transaction.recurrence ?? "Monthly")\""
        }
        return message
    }
    
    private func putTransactions(message: String) { // write all imported transactions to the app
        let transactions = message.components(separatedBy: .newlines) // split the message into an array containing each of its lines
//        print(transactions)
        for i in 1 ... transactions.count - 1 {
            guard transactions[i].components(separatedBy: "\t").count == 14 else {
                print("Line \(i) contains \(transactions[i].components(separatedBy: "\t").count) field(s)")
                print("Skipping line \(i)")
                continue // skip this line
            }
            print("Line \(i) contains \(transactions[i].components(separatedBy: "\t").count) field(s). Creating a transaction")
            
            let charsToBeDeleted = CharacterSet(charactersIn: "\"")
            let accountName = transactions[i].components(separatedBy: "\t")[0].trimmingCharacters(in: charsToBeDeleted)
//            print("Account: \(accountName)")
            let dateFull = transactions[i].components(separatedBy: "\t")[1].trimmingCharacters(in: charsToBeDeleted)
//            print("Date: \(dateFull)")
            let payeeName = transactions[i].components(separatedBy: "\t")[2].trimmingCharacters(in: charsToBeDeleted)
            let categoryName = transactions[i].components(separatedBy: "\t")[3].trimmingCharacters(in: charsToBeDeleted)
            let memo = transactions[i].components(separatedBy: "\t")[4].trimmingCharacters(in: charsToBeDeleted)
            let amount = transactions[i].components(separatedBy: "\t")[5].trimmingCharacters(in: charsToBeDeleted)
            let currency = transactions[i].components(separatedBy: "\t")[6].trimmingCharacters(in: charsToBeDeleted)
            let income = transactions[i].components(separatedBy: "\t")[7].trimmingCharacters(in: charsToBeDeleted) == "false" ? false : true
            let transfer = transactions[i].components(separatedBy: "\t")[8].trimmingCharacters(in: charsToBeDeleted) == "false" ? false : true
            let toAccountName = transactions[i].components(separatedBy: "\t")[9].trimmingCharacters(in: charsToBeDeleted)
            let expense = transactions[i].components(separatedBy: "\t")[10].trimmingCharacters(in: charsToBeDeleted) == "false" ? false : true
            let debtorName = transactions[i].components(separatedBy: "\t")[11].trimmingCharacters(in: charsToBeDeleted)
            let recurring = transactions[i].components(separatedBy: "\t")[12].trimmingCharacters(in: charsToBeDeleted) == "false" ? false : true
            let recurrence = transactions[i].components(separatedBy: "\t")[13].trimmingCharacters(in: charsToBeDeleted)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            var date = dateFormatter.date(from: dateFull)
            
            if date != nil {
                print("Date converted to \(String(describing: date))")
            }
            else { // try another date format
                dateFormatter.dateFormat = "yyyy-MM-dd"
                date = dateFormatter.date(from: dateFull)
                if date != nil {
                    print("Date converted to \(String(describing: date))")
                }
                else {
                    print("Failed to convert the date using the two date formatters")
                    continue
                }
            }
            
            let account = getAccount(accountName: accountName, currency: currency)
            let category = getCategory(categoryName: categoryName, income: income)
            let payee = getPayee(payeeName: payeeName, account: account, category: category)
            let toAccount = getAccount(accountName: toAccountName, currency: currency)
            let debtor = getPayee(payeeName: debtorName, account: nil, category: nil)
            
            
            print("Creating a new transaction on \(payee?.name ?? "") on \(String(describing: date))")
            
            // Create the transaction:
            let transaction = Transaction(context: viewContext)
            let period = getPeriod(date: date ?? Date())
                
            transaction.populate(account: account ?? Account(), date: date ?? Date(), period: period, payee: payee, category: category, memo: memo, amount: Int(amount) ?? 0, currency: currency, income: income, transfer: transfer, toAccount: toAccount, expense: expense, debtor: debtor, recurring: recurring, recurrence: recurrence)
            
//            transaction.id = UUID()
//            transaction.timestamp = Date()
//            transaction.date = date
//            transaction.period = getPeriod(date: date ?? Date())
//            transaction.payee = payee
//            if !transfer {
//                transaction.category = category
//            }
//            transaction.memo = memo
//            transaction.amount = Int64(amount) ?? 0
//            transaction.income = income
//            transaction.transfer = transfer
//            transaction.currency = currency
//            transaction.recurring = recurring
//            transaction.recurrence = recurrence

//            transaction.account = account
//            if transfer {
//                let toAccount = getAccount(accountName: toAccountName, currency: currency)
//                transaction.toaccount = toAccount
//            }
        }
//        PersistenceController.shared.save() // save the changes
    }
    
    private func getBudgets() -> String { // get all budgets and put them in the message field
        var message = "\"Year\"\t\"Month\"\t\"Category\"\t\"Amount\""
        for budget in budgets {
            message += "\n\"\(budget.period?.year ?? 1900)\"\t"
            message += "\"\(budget.period?.month ?? 1)\"\t"
            message += "\"\(budget.category?.name ?? "")\"\t"
            message += "\"\(String(Double(budget.amount) / 100))\""
        }
        return message
    }
    
    private func putBudgets(message: String) { // write all imported budgets to the app
        
//        PersistenceController.shared.save() // save the changes
    }
    
    private func getFxRates() -> String { // get all exchange rates and put them in the message field
        var message = "\"Year\"\t\"Month\"\t\"Currency1\"\t\"Currency2\"\t\"Rate\""
        for fxrate in fxrates {
            message += "\n\"\(fxrate.period?.year ?? 1900)\"\t"
            message += "\"\(fxrate.period?.month ?? 1)\"\t"
            message += "\"\(fxrate.currency1 ?? "")\"\t"
            message += "\"\(fxrate.currency2 ?? "")\"\t"
            message += "\"\(fxrate.rate)\""
        }
        return message
    }
    
    private func putFxRates(message: String) { // write all exchange rates to the app
        let fxrates = message.components(separatedBy: .newlines) // split the message into an array containing each of its lines
        for i in 1 ... fxrates.count - 1 {
            guard fxrates[i].components(separatedBy: "\t").count == 5 else {
                print("Line \(i) contains \(fxrates[i].components(separatedBy: "\t").count) field(s)")
                print("Skipping line \(i)")
                continue // skip this line
            }
            
            let charsToBeDeleted = CharacterSet(charactersIn: "\"")
            let year = fxrates[i].components(separatedBy: "\t")[0].trimmingCharacters(in: charsToBeDeleted)
            print(year)
            let month = fxrates[i].components(separatedBy: "\t")[1].trimmingCharacters(in: charsToBeDeleted)
            print(month)
            let currency1 = fxrates[i].components(separatedBy: "\t")[2].trimmingCharacters(in: charsToBeDeleted)
            print(currency1)
            let currency2 = fxrates[i].components(separatedBy: "\t")[3].trimmingCharacters(in: charsToBeDeleted)
            print(currency2)
            let rate = fxrates[i].components(separatedBy: "\t")[4].trimmingCharacters(in: charsToBeDeleted)
            
            var components = DateComponents()
            components.year = Int(year)
            components.month = Int(month)
            components.day = 1
            let date = Calendar.current.date(from: components)
            
            print("Creating a new exchange rate from \(currency1) to \(currency2) of \(rate)")
            let fxRate = FxRate(context: viewContext)
            fxRate.id = UUID()
            fxRate.period = getPeriod(date: date ?? Date())
            fxRate.startdate = fxRate.period?.startdate // to be able to sort them by period
            fxRate.currency1 = currency1
            fxRate.currency2 = currency2
            fxRate.rate = Int16(rate) ?? 0
        }
        //        PersistenceController.shared.save() // save the changes
    }
    
    private func getAccount(accountName: String, currency: String) -> Account? { // get the account corresponding to the account name string
        
        for account in accounts {
            if(account.name == accountName && account.currency == currency) {
                return account
            }
        }
        if accountName != "" { // to avoid creating a blank account when importing a transaction without a category
            let account = Account(context: viewContext) // if no account is found, create a new one, and return it
            account.id = UUID()
            account.name = accountName
            account.currency = currency
            account.order = (accounts.last?.order ?? 0) + 1
            
//            PersistenceController.shared.save() // save the item
            
            return account
        }
        else {
            return nil
        }
    }
    
    private func getCategory(categoryName: String, income: Bool) -> Category? { // get the category corresponding to the category name string
        
        for category in categories {
            if(category.name == categoryName) {
                return category
            }
        }
        if categoryName != "" { // to avoid creating a blank category when importing a transaction without a category
            let category = Category(context: viewContext) // if no category is found, create a new one, and return it
            category.id = UUID()
            category.name = categoryName
            category.type = "Expense"
            category.order = (categories.last?.order ?? 0) + 1
            
//            PersistenceController.shared.save() // save the item
            
            return category
        }
        else {
            return nil
        }
    }
    
    private func getPayee(payeeName: String, account: Account?, category: Category?) -> Payee? { // get the payee corresponding to the payee name string, and update its default account and category
        
        for payee in payees {
            if(payee.name == payeeName) {
                return payee
            }
        }
        
        if payeeName != "" { // to avoid creating a blank payee when importing a transaction without a payee
            let payee = Payee(context: viewContext) // if no payee is found, create a new one, and return it
            payee.id = UUID()
            payee.name = payeeName
            payee.category = category
            payee.account = account
            
//            PersistenceController.shared.save() // save the item
            
            return payee
        }
        else {
            return nil
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
}

struct CSVExportView_Previews: PreviewProvider {
    static var previews: some View {
        CSVExportView()
    }
}
