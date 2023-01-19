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
    
    @State private var addTransactionView = false // determines whether the view for adding transactions is displayed or not
    
    
    // Filters with which to call this view:
    let payee: Payee?
    let account: Account?
    let category: Category?
    
    
    var body: some View {
        VStack {
            NavigationView {
                List {
                    ForEach(transactions) { transaction in
                        if(category == nil || transaction.category == category) { // if there is no filter, or the transaction matches the filter
                            if(account == nil || transaction.account == account) { // if there is no filter, or the transaction matches the filter
                                if(payee == nil || transaction.payee == payee) { // if there is no filter, or the transaction matches the filter
                                    NavigationLink {
                                        TransactionDetailView(transaction: transaction)
                                    } label : {
                                        HStack {
                                            VStack {
                                                HStack {
                                                    if(transaction.recurring) {
                                                        Image(systemName: "arrow.counterclockwise")
                                                    }
                                                    Text(transaction.date ?? Date(), formatter: dateFormatter)
                                                        .font(.callout)
                                                    //                                                Text("\(transaction.period?.monthString ?? "Jan") \(transaction.period?.year ?? 1900)")
                                                    
                                                    Text(transaction.payee?.name ?? "")
                                                        .font(.callout)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text(transaction.account?.name ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                    Spacer()
                                                    Text(transaction.category?.name ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(.blue)
                                                    Spacer()
                                                }
                                                HStack {
                                                    Text(transaction.memo ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            Text(Double(transaction.amount) / 100, format: .currency(code: transaction.currency ?? "EUR"))
                                                .foregroundColor(transaction.income ? .green : .primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(payee: nil, account: account ?? accounts[0], category: category ?? categories[0])
                }
            }
            
//            Button(role: .destructive) {
//                clearAllTransactions()
//            } label : {
//                Label("Clear all transactions", systemImage: "xmark.circle")
//                    .foregroundColor(.red)
//            }
            
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

//struct TransactionListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListView()
//    }
//}
