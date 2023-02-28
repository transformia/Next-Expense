//
//  AdminView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-01-18.
//

import SwiftUI

struct AdminView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to work with transactions
    
    @State private var transactionCount = 0
    
    var body: some View {
        VStack {
            HStack {
                Text("Transactions with amount 0:")
                Text("\(transactionCount)")
                    .onAppear {
                        transactionCount = countTransactions()
                    }
            }
            
            Button {
                clearTransactions()
                
            } label: {
                Label("Clear transactions", systemImage: "xmark.circle.fill")
            }
            
//            Button {
//                clearAllTransactions()
//                
//            } label: {
//                Label("Clear ALL transactions", systemImage: "xmark.circle.fill")
//            }
        }
    }
    
    private func countTransactions() -> Int {
        return transactions.filter { $0.amount == 0 }.count
    }
    
    private func clearTransactions() {
        for transaction in transactions {
            if(transaction.amount == 0) {
//                print(transaction.payee?.name ?? "")
                viewContext.delete(transaction)
                PersistenceController.shared.save() // save the change
            }
        }
    }
    
    func clearAllTransactions() {
        print("Clearing all transactions")
        if(transactions.count > 0) {
            for i in 0 ... transactions.count - 1 {
                viewContext.delete(transactions[i])
            }
            PersistenceController.shared.save() // save the changes
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
    }
}
