//
//  TransactionListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct TransactionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to call AddTransactionView with a default account
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to call AddTransactionView with a default category
    
    @State private var addView = false // determines whether the view for adding elements is displayed or not
    
    var body: some View {
        VStack {
            NavigationView {
                List {
                    ForEach(transactions) { transaction in
                        NavigationLink {
                            TransactionDetailView(transaction: transaction)
                        } label : {
                            HStack {
                                Text(transaction.date ?? Date(), formatter: dateFormatter)
                                Text(transaction.account?.name ?? "")
                                Text(transaction.category?.name ?? "")
                                Text(Double(transaction.amount) / 100, format: .currency(code: transaction.currency ?? "EUR"))
                                    .foregroundColor(transaction.income ? .green : .primary)
                                Text(transaction.memo ?? "")
                            }
                        }
                    }
                }
                .sheet(isPresented: $addView) {
                    AddTransactionView(defaultAccount: accounts[0], defaultCategory: categories[0])
                }
            }
            
//            Button(role: .destructive) {
//                clearAllTransactions()
//            } label : {
//                Label("Clear all transactions", systemImage: "xmark.circle")
//                    .foregroundColor(.red)
//            }
            
            Button {
                addView.toggle() // show the view where I can add a new element
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
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
//        formatter.dateStyle = .medium
        return formatter
    }()
    
//    private func clearAllTransactions() { // TEMPORARY - delete all transactions
//        print("Clearing all transactions")
//        if(transactions.count > 0) {
//            for i in 0 ... transactions.count - 1 {
//                viewContext.delete(transactions[i])
//            }
//            PersistenceController.shared.save() // save the item
//        }
//    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView()
    }
}
