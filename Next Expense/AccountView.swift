//
//  AccountView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the account balance
    
    let account: Account
    
    @State private var balance = 0.0
    
    var body: some View {
        HStack {
            Text(account.name ?? "")
            Text(balance / 100, format: .currency(code: account.currency ?? "EUR"))
                .onAppear {
                    balance = 0
                    for transaction in transactions {
                        if(transaction.account == account) { // if the account matches
                            balance += transaction.income ? Double(transaction.amount) : -Double(transaction.amount) // add or substract the amount, depending on the direction of the transaction
                        }
                    }
                }
        }
    }
}

//struct AccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountView()
//    }
//}
