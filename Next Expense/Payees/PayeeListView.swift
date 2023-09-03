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
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.order, ascending: true)],
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
                
                Button {
                    var order = 0
                    for payee in payees.sorted(by: { $0.transactions?.count ?? 0 > $1.transactions?.count ?? 0 }) {
                        payee.order = Int64(order)
                        order += 1
                    }
                    PersistenceController.shared.save()
                } label: {
                    Text("Sort by volume of transactions")
                }
                
                List {
                    ForEach(payees) { payee in
                        NavigationLink {
                            PayeeDetailView(payee: payee)
                        } label: {
                            HStack {
                                Text(payee.name ?? "")
//                                Text("\(payee.order)")
                                Spacer()
                                Text("\(payee.transactions?.count ?? 0)")
                            }
                        }
                    }
                    .onMove(perform: moveItem)
                }
                .listStyle(PlainListStyle())
                .sheet(isPresented: $addTransactionView) {
                    TransactionDetailView(transaction: nil, payee: nil, account: nil, category: nil)
                }
                
                Button {
//                    if(categories.count > 0 && accounts.count > 0) {
                        addTransactionView.toggle() // show the view where I can add a new element
//                    }
//                    else {
//                        print("You need to create at least one account and one category before you can create a transaction")
//                    }
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.green)
                        .clipShape(Circle())
                }
                .padding(.bottom, 20.0)
            }
            .navigationTitle("Payees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = payees[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                payees[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            payees[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = payees[destination].order + 1
            let newOrder = payees[destination].order
            while startIndex <= endIndex {
                payees[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            payees[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
}

struct PayeeListView_Previews: PreviewProvider {
    static var previews: some View {
        PayeeListView()
    }
}
