//
//  BalanceListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-03-01.
//

import SwiftUI

struct BalanceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Balance.id, ascending: true)],
        animation: .default)
    private var balances: FetchedResults<Balance>
    
    var body: some View {
        List {
            ForEach(balances) { balance in
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(balance.period?.monthString ?? ""):")
                        Text((balance.category?.name ?? balance.account?.name ?? "Period"))
                    }
                    if balance.accountbalance != 0.0 {
                        HStack {
                            Text("Account balance:")
                            Text(balance.accountbalance / 100, format: .currency(code: balance.account?.currency ?? "EUR"))
                        }
                    }
                    if balance.categorybalance != 0.0 {
                        HStack {
                            Text("Category balance:")
                            Text(balance.categorybalance / 100, format: .currency(code: "EUR"))
                        }
                    }
                    if balance.incomeactual != 0.0 {
                        HStack {
                            Text("Income actual:")
                            Text(balance.incomeactual / 100, format: .currency(code: "EUR"))
                        }
                    }
                    if balance.expensesactual != 0.0 {
                        HStack {
                            Text("Expenses actual:")
                            Text(balance.expensesactual / 100, format: .currency(code: "EUR"))
                        }
                    }
                }
            }
        }
    }
}

struct BalanceListView_Previews: PreviewProvider {
    static var previews: some View {
        BalanceListView()
    }
}
