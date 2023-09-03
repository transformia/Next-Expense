//
//  DebtorTransView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-05-26.
//

import SwiftUI

struct DebtorTransView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    let payee: Payee
    
    
    var body: some View {
        List {
            // Open transactions:
            Section(header: Text("Open transactions")) {
                ForEach(transactions) { transaction in
                    if transaction.debtor == payee && !transaction.expensesettled {
                        TransactionView(transaction: transaction, account: nil)
                    }
                }
            }
            
            // Settled transactions:
            Section(header: Text("Settled transactions")) {                
                ForEach(transactions) { transaction in
                    if transaction.debtor == payee && transaction.expensesettled {
                        TransactionView(transaction: transaction, account: nil)
                    }
                }
            }
        }
    }
}

struct DebtorTransView_Previews: PreviewProvider {
    static var previews: some View {
        DebtorTransView(payee: Payee())
    }
}
