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
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: false)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to process recurring transactions
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    @State private var addTransactionView = false // determines whether the view for adding transactions is displayed or not
    
    @State private var showFutureTransactions = false // determines whether transactions dated in the future are displayed or not
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment - for the category balance animation
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment - to be able to show an animation when a category balance changes
    
    // Filters with which to call this view:
    let payee: Payee?
    let account: Account?
    let category: Category?
    
    
    var body: some View {
        ZStack { // to be able to show an animation on top when a category balances changes
            VStack {
                
                // Show button to create recurring transactions that are due:
                if(countRecurringTransactions() > 0) {
                    Button {
                        processRecurringTransactions()
                    } label: {
                        Text("Process recurring: \(countRecurringTransactions())")
                    }
                    .padding()
                }
                List {
                    ForEach(periods) { period in
                        if (
                            (showFutureTransactions && period.transactions?.filter({(category == nil || ($0 as! Transaction).category == category) && (account == nil || ($0 as! Transaction).account == account)}).count ?? 0 > 0) // if future transactions are shown, and there are transactions in the period, either with the selected account or category, or with no selection of account or category
                            || (period.transactions?.filter({Calendar.current.startOfDay(for: ($0 as! Transaction).date ?? Date()) <= Date() && (category == nil || ($0 as! Transaction).category == category) && (account == nil || ($0 as! Transaction).account == account)}).count ?? 0 > 0) // or if there are non-future transactions in the period, either with the selected account or category, or with no selection of account or category
                        ) {
                            
                            PeriodTransactionsView(period: period)
                            
                            if period.showtransactions {
                                ForEach(transactions) { transaction in
                                    if transaction.period == period { // if the transaction is in this period
                                        if(category == nil || transaction.category == category) { // if there is no filter, or the transaction matches the filter
                                            if(account == nil || transaction.account == account || transaction.toaccount == account) { // if there is no filter, or the transaction matches the filter
                                                if(payee == nil || transaction.payee == payee) { // if there is no filter, or the transaction matches the filter
                                                    if showFutureTransactions || Calendar.current.startOfDay(for: transaction.date ?? Date()) <= Date() { // if I want to show future transactions, or if the start of the day of the transaction date is in the past
                                                        TransactionView(transaction: transaction, account: account)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    //                            ForEach(transactions) { transaction in
                    //                                if(category == nil || transaction.category == category) { // if there is no filter, or the transaction matches the filter
                    //                                    if(account == nil || transaction.account == account || transaction.toaccount == account) { // if there is no filter, or the transaction matches the filter
                    //                                        if(payee == nil || transaction.payee == payee) { // if there is no filter, or the transaction matches the filter
                    //                                            if showFutureTransactions || Calendar.current.startOfDay(for: transaction.date ?? Date()) <= Date() { // if I want to show future transactions, or if the start of the day of the transaction date is in the past
                    //                                                TransactionView(transaction: transaction, account: account)
                    //                                            }
                    //                                        }
                    //                                    }
                    //                                }
                    //                            }
                }
                .listStyle(PlainListStyle())
                //                        .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20)) // reduce side padding of the list items
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(payee: nil, account: account ?? accounts[0], category: category ?? categories[0])
                }
                
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
            
            if account == nil && category == nil { // if this view wasn't called from an account or a category, i.e. if I'm looking at the full transaction view:
                if(periodBalances.showBalanceAnimation) { // show the update of the category balance for x seconds
                    if !periodBalances.balanceAfter { // showing the balance before the transaction
                        HStack {
                            Text(periodBalances.category.name ?? "")
                            Text(periodBalances.remainingBudgetBefore / 100, format: .currency(code: "EUR"))
                        }
                        .padding()
                        .foregroundColor(periodBalances.remainingBudgetBefore > 0 ? .black : .white)
                        .bold()
                        .background(periodBalances.remainingBudgetBefore > 0 ? .green : .red)
                        .clipShape(Capsule())
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.50) { // make it change after x seconds
                                periodBalances.balanceAfter = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.00) { // make it disappear after x seconds
                                periodBalances.showBalanceAnimation = false
                                periodBalances.balanceAfter = false
                            }
                        }
                    }
                    
                    else { // showing the balance after the transaction
                        HStack {
                            Text(periodBalances.category.name ?? "")
                            //                        Text(periodBalances.category.calcRemainingBudget(period: selectedPeriod.period) / 100, format: .currency(code: "EUR"))
                            Text(periodBalances.remainingBudgetAfter / 100, format: .currency(code: "EUR"))
                        }
                        .padding()
                        .foregroundColor(periodBalances.remainingBudgetAfter > 0 ? .black : .white)
                        .bold()
                        .background(periodBalances.remainingBudgetAfter > 0 ? .green : .red)
                        .clipShape(Capsule())
                    }
                }
            }
        }  // end of ZStack
    }
    
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
                withAnimation {
                    showFutureTransactions = true
                }
//                withAnimation {
//                    showDeferredHelpText1 = true
//                }
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) { // make the text disappear after x seconds
//                        showDeferredHelpText1 = false
//                }
            case true:
                withAnimation {
                    showFutureTransactions = false
                }
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
