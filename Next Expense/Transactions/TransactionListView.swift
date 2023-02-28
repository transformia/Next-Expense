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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to process recurring transactions
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var addTransactionView = false // determines whether the view for adding transactions is displayed or not
    
    @State private var showFutureTransactions = false // determines whether transactions dated in the future are displayed or not
    
    // Filters with which to call this view:
    let payee: Payee?
    let account: Account?
    let category: Category?
    
    
    var body: some View {
        NavigationView {
            VStack {
                
                // Show button to create recurring transactions that are due:
                if(countRecurringTransactions() > 0) {
                    Button {
                        processRecurringTransactions()
                    } label: {
                        Text("Process recurring: \(countRecurringTransactions())")
                    }
                    .padding()
                    //                Text("Process recurring: \(countRecurringTransactions())")
                    //                    .frame(width: 500, height: 20)
                    //                    .background(.blue)
                    //                    .padding()
                    //                    .onTapGesture {
                    //                        processRecurringTransactions()
                    //                    }
                }
                
//                // Show button to delete the account if it has not transactions:
//                if account != nil && transactions.filter({$0.account == account}).count == 0 {
//                    Button(role: .destructive) {
//                        print("Deleting account \(account?.name ?? "")")
//                        let accountToDelete = account ?? Account()
//                        viewContext.delete(accountToDelete)
//                        PersistenceController.shared.save() // save the change
//                        dismiss()
//                    } label: {
//                        Label("Delete account", systemImage: "trash")
//                    }
//                    .padding()
//                }
                
                NavigationView {
                    List {
                        ForEach(transactions) { transaction in
                            if(category == nil || transaction.category == category) { // if there is no filter, or the transaction matches the filter
                                if(account == nil || transaction.account == account || transaction.toaccount == account) { // if there is no filter, or the transaction matches the filter
                                    if(payee == nil || transaction.payee == payee) { // if there is no filter, or the transaction matches the filter
                                        if showFutureTransactions || Calendar.current.startOfDay(for: transaction.date ?? Date()) <= Date() { // if I want to show future transactions, or if the start of the day of the transaction date is in the past
                                            // Display the date if it is different from the previous transaction's date (if there is a previous transaction):
                                            //                                    if {
                                            //                                        Text(transaction.date ?? Date(), formatter: dateFormatter)
                                            //                                    }
                                            // Display the transaction:
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
                                                            if transaction.transfer {
                                                                Text("Transfer")
                                                                    .font(.callout)
                                                            }
                                                            else {
                                                                Text(transaction.payee?.name ?? "")
                                                                    .font(.callout)
                                                            }
                                                            Spacer()
                                                            //                                                    Text(transaction.category?.name ?? "")
                                                            //                                                        .font(.caption)
                                                            //                                                        .foregroundColor(Calendar.current.startOfDay(for: transaction.date ?? Date()) > Date() ? .gray : .blue)
                                                            //                                                    Spacer()
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
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: -10, bottom: 0, trailing: -10)) // reduce side padding of the list items
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
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    showFutureTransactionsButton
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
    
    private func processRecurringTransactions() {
        for transaction in transactions {
            if(transaction.recurring) {
                if(Calendar.current.startOfDay(for: transaction.date ?? Date()) <= Date()) {
                    
                    // Create a non-recurring transaction from the recurring transaction:
                    let transaction2 = Transaction(context: viewContext)

                    transaction2.id = UUID()
                    transaction2.timestamp = Date()
                    transaction2.date = transaction.date
                    transaction2.period = getPeriod(date: transaction.date ?? Date())
                    transaction2.payee = transaction.payee
                    transaction2.category = transaction.category
                    transaction2.amount = transaction.amount
                    transaction2.income = transaction.income
                    transaction2.transfer = transaction.transfer
                    transaction2.currency = transaction.currency
                    transaction2.memo = transaction.memo
                    transaction2.account = transaction.account
                    transaction2.toaccount = transaction.toaccount
                    
                    
                    // Increment the recurring transaction's date and update its period:
                    transaction.date = Calendar.current.date(byAdding: .month, value: 1, to: transaction.date ?? Date())
                    transaction.period = getPeriod(date: transaction.date ?? Date())
                    
                    PersistenceController.shared.save() // save the item
                }
            }
        }
    }
    
    var showFutureTransactionsButton: some View {
        Button {
            switch(showFutureTransactions) { // toggle between the 2 options
            case false:
                showFutureTransactions = true
//                withAnimation {
//                    showDeferredHelpText1 = true
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) { // make the text disappear after x seconds
//                        showDeferredHelpText1 = false
//                }
            case true:
                showFutureTransactions = false
//                withAnimation {
//                    showDeferredHelpText2 = true
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) { // make the text disappear after x seconds
//                        showDeferredHelpText2 = false
//                }
            }
        } label: {
            switch(showFutureTransactions) {
            case false:
                Label("", systemImage: "eye.slash")
            case true:
                Label("", systemImage: "eye.fill")
            }
        }
    }
    
    private func countRecurringTransactions() -> Int {
        var count = 0
        for transaction in transactions {
            if(transaction.recurring) {
                if(Calendar.current.startOfDay(for: transaction.date ?? Date()) <= Date()) {
                    count += 1
                }
            }
        }
        return count
    }
    
    func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date
        let year = Calendar.current.dateComponents([.year], from: date).year ?? 1900
        let month = Calendar.current.dateComponents([.month], from: date).month ?? 1
        
        for period in periods {
            if(period.year == year) {
                if(period.month == month) {
                    return period
                }
            }
        }
        return Period() // if no period is found, return a new one
    }
    
}

//struct TransactionListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionListView()
//    }
//}
