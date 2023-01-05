//
//  AccountListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AccountListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to call AddTransactionView with a default category

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    
    @State private var addAccountView = false // determines whether that view is displayed or not
    
    @State private var addTransactionView = false // determines whether that view is displayed or not
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(accounts) { account in
                        NavigationLink {
                            AccountDetailView(account: account)
                        } label : {
                            AccountView(account: account)
                        }
                    }
                    .onMove(perform: moveItem)
                }
                .sheet(isPresented: $addAccountView) {
                    AddAccountView()
                }
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(account: accounts[0], category: categories[0])
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            addAccountView.toggle() // show the view where I can add a new element
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
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
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = accounts[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                accounts[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            accounts[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = accounts[destination].order + 1
            let newOrder = accounts[destination].order
            while startIndex <= endIndex {
                accounts[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            accounts[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
}

struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListView()
    }
}
