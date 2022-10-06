//
//  AddAccountView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AddAccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to find the next available order int
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    // Define variables for the new account's attributes:
    @State private var name = ""
    @State private var currency = "EUR"
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        NavigationView { // so that the pickers work
            Form {
                TextField("Account name", text: $name)
                Picker("Currency", selection: $currency) {
                    ForEach(currencies, id: \.self) {
                        Text($0)
                    }
                }
                createAccountButton
            }
        }
    }
    
    var createAccountButton: some View {
        Button(action: {
            let account = Account(context: viewContext)
            
            account.id = UUID()
            account.name = name
            account.currency = currency
            account.order = (accounts.last?.order ?? 0) + 1
            
            PersistenceController.shared.save() // save the item
            
            dismiss() // dismiss this view
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
    }
}

struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddAccountView()
    }
}
