//
//  ErrorListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-10-21.
//

import SwiftUI

struct ErrorListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    var body: some View {
        List {
            ForEach(transactions) { transaction in
                if !transaction.transfer && transaction.category == nil {
                    TransactionView(transaction: transaction, account: nil)
                }
            }
        }
    }
}

#Preview {
    ErrorListView()
}
