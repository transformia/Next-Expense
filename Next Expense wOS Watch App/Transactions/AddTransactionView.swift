//
//  AddTransactionView.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2022-10-12.
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
    
    // Define variables for the new transactions's attributes:
    @State private var date = Date()
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var income = false
    @State private var amount = 0
    @State private var currency = "EUR"
    @State private var memo = ""
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        Form {
            
            Toggle("Income", isOn: $income)
            
            TextField("Amount", value: $amount, formatter: NumberFormatter())
            
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { (category: Category) in
                    Text(category.name ?? "")
                        .tag(category as Category?)
                }
            }
            .onAppear {
                selectedCategory = categories[0] // default to the provided value
            }
            
            Picker("Account", selection: $selectedAccount) {
                ForEach(accounts, id: \.self) { (account: Account) in
                    Text(account.name ?? "")
                        .tag(account as Account?)
                }
            }
            .onAppear {
                selectedAccount = accounts[0] // default to the provided value
            }
            
            createTransactionButton
        }
    }
    
    var createTransactionButton: some View {
        Button(action: {
            if(amount != 0) { // do nothing if the amount is 0
                let transaction = Transaction(context: viewContext)
                
                transaction.id = UUID()
                transaction.timestamp = Date()
                transaction.date = date
                transaction.category = selectedCategory
                transaction.amount = Int64(amount) // save amount as an int, i.e. 2560 means 25,60€ for example
                transaction.income = income // save the direction of the transaction, true for an income, false for an expense
                print("Amount: \(transaction.amount)")
                transaction.currency = currency
                transaction.memo = memo
                transaction.account = selectedAccount
                
                PersistenceController.shared.save() // save the item
                
                amount = 0 // clear the amount after saving
            }
            
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView()
    }
}
