//
//  AddTransactionView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to select an account from a picker
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to select a category from a picker
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    // Attributes that can be defaulted when calling this view:
    let defaultAccount: Account
    let defaultCategory: Category
    
    // Define variables for the new transactions's attributes:
    @State private var date = Date()
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var income = false
    @State private var amount = 0
    @State private var currency = "EUR"
    @State private var memo = ""
    
    // Variable determining whether the focus is on the amount field or not:
    @FocusState private var amountFocused: Bool
    
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        NavigationView { // so that the pickers work
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Toggle("Income", isOn: $income)
                TextField("Amount", value: $amount, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .focused($amountFocused)
                    .onAppear { // after the view has appeared, and with a delay to ensure that the view has loaded: put the focus on the amount field
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { // focus on the text editor after N seconds
                            amountFocused = true
                        }
                    }
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { (category: Category) in
                        Text(category.name ?? "")
                            .tag(category as Category?)
                    }
                }
                .onAppear {
                    selectedCategory = defaultCategory // default to the provided value
                }
                Picker("Account", selection: $selectedAccount) {
                    ForEach(accounts, id: \.self) { (account: Account) in
                        Text(account.name ?? "")
                            .tag(account as Account?)
                    }
                }
                .onAppear {
                    selectedAccount = defaultAccount // default to the provided value
                }
                .onChange(of: selectedAccount) { _ in
                    currency = selectedAccount?.currency ?? "EUR" // set the currency to the currency of the selected account
                }
                Picker("Currency", selection: $currency) {
                    ForEach(currencies, id: \.self) {
                        Text($0)
                    }
                }
                .onAppear {
                    currency = selectedAccount?.currency ?? "EUR" // set the currency to the currency of the selected account
                }
                TextField("Memo", text: $memo)
                createTransactionButton
            }
        }
    }
    
    var createTransactionButton: some View {
        Button(action: {
            let transaction = Transaction(context: viewContext)
            
            transaction.id = UUID()
            transaction.timestamp = Date()
            transaction.date = date
            transaction.category = selectedCategory
//            transaction.amount = income ? NSDecimalNumber(decimal: amount) : NSDecimalNumber(decimal: -amount) // save incomes as positive, expenses as negative
            transaction.amount = Int64(amount) // save amount as an int, i.e. 2560 means 25,60€ for example
            transaction.income = income // save the direction of the transaction, true for an income, false for an expense
            print("Amount: \(transaction.amount)")
            transaction.currency = currency
            transaction.memo = memo
            transaction.account = selectedAccount
            
            PersistenceController.shared.save() // save the item
            
            dismiss() // dismiss this view
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
    }
}

//struct AddTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddTransactionView()
//    }
//}
