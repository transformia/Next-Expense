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
    
    @State private var balance = 0
    
    var body: some View {
        HStack {
            Text(account.name ?? "")
            Spacer()
            Text(Double(balance) / 100, format: .currency(code: account.currency ?? "EUR"))
                .onAppear {
                    balance = account.calcBalance(toDate: Date())
                }
        }
    }
}

//struct AccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountView()
//    }
//}
