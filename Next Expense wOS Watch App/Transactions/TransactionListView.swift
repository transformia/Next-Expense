//
//  TransactionListView.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2022-10-12.
//

import SwiftUI

struct TransactionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    var body: some View {
        List {
            ForEach(transactions) { transaction in
                NavigationLink {
                    Text(transaction.memo ?? "Hello")
                } label : {
                    HStack {
                        VStack {
                            HStack {
                                Text(transaction.date ?? Date(), formatter: dateFormatter)
                                    .font(.callout)
                                
                                Spacer()
                                
                                Text(Double(transaction.amount) / 100, format: .currency(code: transaction.currency ?? "EUR"))
                                    .foregroundColor(transaction.income ? .green : .primary)
                            }
                            HStack {
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
                    }
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
//        formatter.dateStyle = .medium
        return formatter
    }()
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView()
    }
}
