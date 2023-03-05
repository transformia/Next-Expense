//
//  TransactionView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-03-01.
//

import SwiftUI

struct TransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to call AddTransactionView with a default account
    
    let transaction: Transaction
    let account: Account? // if the TransactionListView is called from an account, this will contain that account
    
    @State private var showingTransactionDetailView = false
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    if(transaction.recurring) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    Text(transaction.date ?? Date(), formatter: dateFormatter)
                        .font(.callout)
                    if transaction.transfer {
                        Text("Transfer")
                            .font(.callout)
                    }
                    else {
                        Text(transaction.payee?.name ?? "")
                            .font(.callout)
                    }
                    Spacer()
                }
                
                HStack {
                    if transaction.transfer {
                        Text("\(transaction.account?.name ?? "") to \(transaction.toaccount?.name ?? "")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    else {
                        Text(transaction.account?.name ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer() // align it to the left
                }
                
                HStack {
                    Text(transaction.category?.name ?? "")
                        .font(.caption)
                        .foregroundColor(Calendar.current.startOfDay(for: transaction.date ?? Date()) > Date() ? .gray : .blue)
                    Spacer() // align it to the left
                }
                
                HStack {
                    Text(transaction.memo ?? "")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer() // align it to the left
                }
            }
            VStack(alignment: .trailing) {
                //                                                Spacer()
                //                                                Spacer()
                if(account == nil || transaction.account == account) { // from the transaction view (account == nil), or from the account sending a transfer
                    Text(Double(transaction.amount) / 100, format: .currency(code: transaction.currency ?? "EUR"))
                        .font(.callout)
                        .foregroundColor(transaction.income || (account == nil && transaction.account?.type == "External" && transaction.toaccount?.type == "Budget") ? .green : .primary) // color the amount in green if it is an income, or if I am viewing a transfer from an external account to a budget account, and am viewing it from the transaction list (i.e. account = nil)
                }
                else if (transaction.transfer && transaction.toaccount == account) { // from the account receiving a transfer
                    Text(Double(transaction.amount) / 100, format: .currency(code: transaction.currency ?? "EUR"))
                        .font(.callout)
                        .foregroundColor(.green)
                    //                                                    .foregroundColor(!transaction.income || (transaction.account?.type == "External" && transaction.toaccount?.type == "Budget") ? .green : .primary) // reversed for the account that receives the transfer
                }
                
                //                                                Spacer()
                //
                //                                                Text(transaction.category?.name ?? "")
                //                                                    .font(.caption)
                //                                                    .foregroundColor(Calendar.current.startOfDay(for: transaction.date ?? Date()) > Date() ? .gray : .blue)
                
            }
        }
        .foregroundColor(Calendar.current.startOfDay(for: transaction.date ?? Date()) > Date() ? .gray : nil)
        .onTapGesture {
            showingTransactionDetailView.toggle()
        }
        .sheet(isPresented: $showingTransactionDetailView) {
            TransactionDetailView(transaction: transaction)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
}

struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView(transaction: Transaction(), account: Account())
    }
}
