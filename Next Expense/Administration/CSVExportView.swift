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
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.id, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget> // to be able to display budgets
    
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
    
    var body: some View {
        VStack {
            HStack {
                Button(action: { document.message = getTransactions() }, label: {
                    Text("Get transactions")
                })
                Button(action: { document.message = getBudgets() }, label: {
                    Text("Get budgets")
                })
                Button(action: { putTransactions(message: document.message) }, label: {
                    Text("Create transactions")
                })
                Button(action: { putBudgets(message: document.message) }, label: {
                    Text("Create budgets")
                })
            }
            GroupBox(label: Text("Transactions:")) {
                TextEditor(text: $document.message)
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
                print("Getting file URL")
                guard let selectedFile: URL = try result.get().first else { return }
                print("Getting message")
//                guard let message = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                let message = try String(contentsOf: selectedFile, encoding: .utf8)
//                let message = try? String(contentsOf: selectedFile)
                print("Assigning message to object") // fails just above this line on physical iPhone. Succeeds in simulator
                document.message = message
            } catch {
                // Handle failure.
                print("Failed to import data")
            }
        }
    }
    
    private func getTransactions() -> String { // get all transactions and put them in the message field
        var message = "\"Account\"\t\"Date\"\t\"Payee\"\t\"Category\"\t\"Memo\"\t\"Amount\"\t\"Income\"\t\"Transfer\"\t\"Currency\""
        for transaction in transactions {
            message += "\n\"\(transaction.account?.name ?? "")\"\t"
            message += "\"\(transaction.date ?? Date())\"\t"
            message += "\"\(transaction.payee?.name ?? "")\"\t"
            message += "\"\(transaction.category?.name ?? "")\"\t"
            message += "\"\(transaction.memo ?? "")\"\t"
            message += "\"\(String(Double(transaction.amount) / 100))\"\t"
            message += "\"\(transaction.income)\"\t"
            message += "\"\(transaction.transfer)\"\t"
            message += "\"\(transaction.currency ?? "EUR")\""
        }
        return message
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
    
    private func putTransactions(message: String) { // write all imported transactions to the app
        let transactions = message.components(separatedBy: .newlines) // split the message into an array containing each of its lines
        for i in 1 ... transactions.count - 1 {
            let charsToBeDeleted = CharacterSet(charactersIn: "\"")
            let accountName = transactions[i].components(separatedBy: "\t")[0].trimmingCharacters(in: charsToBeDeleted)
            let dateFull = transactions[i].components(separatedBy: "\t")[1].trimmingCharacters(in: charsToBeDeleted)
            let payeeName = transactions[i].components(separatedBy: "\t")[2].trimmingCharacters(in: charsToBeDeleted)
            let categoryName = transactions[i].components(separatedBy: "\t")[3].trimmingCharacters(in: charsToBeDeleted)
            
            let memo = transactions[i].components(separatedBy: "\t")[4].trimmingCharacters(in: charsToBeDeleted)
            let amount = transactions[i].components(separatedBy: "\t")[5].trimmingCharacters(in: charsToBeDeleted)
            let income = transactions[i].components(separatedBy: "\t")[6].trimmingCharacters(in: charsToBeDeleted) == "false" ? false : true
            let transfer = transactions[i].components(separatedBy: "\t")[7].trimmingCharacters(in: charsToBeDeleted) == "false" ? false : true
            let currency = transactions[i].components(separatedBy: "\t")[8].trimmingCharacters(in: charsToBeDeleted)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy HH:mm:ss Z"
            let date = dateFormatter.date(from: dateFull)
            
            let account = getAccount(accountName: accountName, currency: currency)
            let category = getCategory(categoryName: categoryName, income: income)
            let payee = getPayee(payeeName: payeeName, category: category)
            
            
            let transaction = Transaction(context: viewContext)
            transaction.id = UUID()
            transaction.timestamp = Date()
            transaction.date = date
            transaction.period = getPeriod(date: date ?? Date())
            transaction.payee = payee
            transaction.category = category
            transaction.amount = Int64(amount) ?? 0
            transaction.income = income
            transaction.transfer = transfer
            transaction.currency = currency
            transaction.memo = memo
            transaction.account = account
        }
    }
    
    private func putBudgets(message: String) { // write all imported budgets to the app
        
    }
    
    private func getAccount(accountName: String, currency: String) -> Account { // get the account corresponding to the account name string
        
        for account in accounts {
            if(account.name == accountName && account.currency == currency) {
                return account
            }
        }
        let account = Account(context: viewContext) // if no account is found, create a new one, and return it
        account.id = UUID()
        account.name = accountName
        account.currency = currency
        account.order = (accounts.last?.order ?? 0) + 1
        
        PersistenceController.shared.save() // save the item
        
        return account
    }
    
    private func getCategory(categoryName: String, income: Bool) -> Category { // get the category corresponding to the category name string
        
        for category in categories {
            if(category.name == categoryName) {
                return category
            }
        }
        let category = Category(context: viewContext) // if no category is found, create a new one, and return it
        category.id = UUID()
        category.name = categoryName
        category.type = "Expense"
        category.order = (categories.last?.order ?? 0) + 1
        
        PersistenceController.shared.save() // save the item
        
        return category
    }
    
    private func getPayee(payeeName: String, category: Category) -> Payee { // get the payee corresponding to the payee name string
        
        for payee in payees {
            if(payee.name == payeeName) {
                return payee
            }
        }
        
        let payee = Payee(context: viewContext) // if no payee is found, create a new one, and return it
        payee.id = UUID()
        payee.name = payeeName
        payee.category = category
//        payee.account = account
        
        PersistenceController.shared.save() // save the item
        
        return payee
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date
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
