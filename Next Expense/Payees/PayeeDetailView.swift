//
//  PayeeDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-01-05.
//

import SwiftUI

struct PayeeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to display a picker on the categories
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to display a picker on the accounts
    
    let payee: Payee // element to display
    
    @State private var name = ""
    @State private var category: Category?
    @State private var account: Account?
    
    @State private var addTransactionView = false // determines whether the view for adding elements is displayed or not
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    var body: some View {
        VStack {
            Form {
                TextField("Payee", text: $name)
                    .onAppear {
                        name = payee.name ?? ""
                    }
                
                Picker("Default category", selection: $category) {
                    ForEach(categories, id: \.self) { (category: Category) in
                        Text(category.name ?? "")
                            .tag(category as Category?)
                    }
                }
                .onAppear {
                    category = payee.category ?? categories[0]
                }
                
                Picker("Default account", selection: $account) {
                    ForEach(accounts, id: \.self) { (account: Account) in
                        Text(account.name ?? "")
                            .tag(account as Account?)
                    }
                }
                .onAppear {
                    account = payee.account ?? accounts[0]
                }
                
                saveButton
            }
            
            TransactionListView(payee: payee, account: nil, category: nil)
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(payee: payee, account: accounts[0], category: categories[0])
                }
            
        }
    }
    
    var saveButton: some View {
        Button {
            payee.name = name
            payee.category = category
            payee.account = account
                
            PersistenceController.shared.save() // save the change
            dismiss()
        } label : {
            Label("Save", systemImage: "opticaldiscdrive.fill")
        }
    }
}

//struct PayeeDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PayeeDetailView()
//    }
//}
