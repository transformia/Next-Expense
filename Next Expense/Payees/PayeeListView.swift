//
//  PayeeListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-01-05.
//

import SwiftUI

struct PayeeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to display the payees
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to check if I have categories when I want to add a transaction
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to check if I have accounts when I want to add a transaction
    
    @State private var addTransactionView = false // determines whether that view is displayed or not
    
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(payees) { payee in
                        NavigationLink {
                            PayeeDetailView(payee: payee)
                        } label: {
                            Text(payee.name ?? "")
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(payee: nil, account: accounts[0], category: categories[0])
                }
                
                Button {
                    if(categories.count > 0 && accounts.count > 0) {
                        addTransactionView.toggle() // show the view where I can add a new element
                    }
                    else {
                        print("You need to create at least one account and one category before you can create a transaction")
                    }
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(.green)
                        .clipShape(Circle())
                }
                .padding(.bottom, 20.0)
            }
        }
    }
}

struct PayeeListView_Previews: PreviewProvider {
    static var previews: some View {
        PayeeListView()
    }
}
