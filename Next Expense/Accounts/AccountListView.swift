//
//  AccountListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AccountListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to call AddTransactionView with a default category

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the transaction, to calculate the total balance on the correct date
    
    @State private var addAccountView = false // determines whether that view is displayed or not
    
    @State private var addTransactionView = false // determines whether that view is displayed or not
    
    @State private var showBudgetAccounts = true
    @State private var showExternalAccounts = true
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment - for the category balance animation
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment - to be able to show an animation when a category balance changes
    
    let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
    
    var body: some View {
        ZStack { // to be able to show an animation on top when a category balances changes
            
            NavigationView {
                VStack {
                    List {
                        
                        HStack {
                            Image(systemName: showBudgetAccounts ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                                .resizable()
                                .frame(width: 10, height: 10)
                            Text("Budget")
                                .font(.headline)
                            Spacer()
                            Text(periodBalances.totalBalanceBudget, format: .currency(code: defaultCurrency))
                                .font(.callout)
                        }
                        .onTapGesture {
                            withAnimation {
                                showBudgetAccounts.toggle()
                            }
                        }
                        .onChange(of: periodBalances.expensesActual) { _ in
                            updateAccountTotals()
                        }
                        .onChange(of: periodBalances.incomeActual) { _ in
                            updateAccountTotals()
                        }
                        
                        if showBudgetAccounts {
                            ForEach(accounts) { account in
                                if account.type == "Budget" {
                                    NavigationLink {
                                        AccountDetailView(account: account)
                                    } label : {
                                        AccountView(account: account)
                                    }
                                }
                            }
                            .onMove(perform: moveItem)
                        }
                        
                        HStack {
                            Image(systemName: showExternalAccounts ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                                .resizable()
                                .frame(width: 10, height: 10)
                            Text("External")
                                .font(.headline)
                            Spacer()
                            Text(periodBalances.totalBalanceExternal, format: .currency(code: defaultCurrency))
                                .font(.callout)
                        }
                        .onTapGesture {
                            withAnimation {
                                showExternalAccounts.toggle()
                            }
                        }
                        
                        if showExternalAccounts {
                            ForEach(accounts) { account in
                                if account.type == "External" {
                                    NavigationLink {
                                        AccountDetailView(account: account)
                                    } label : {
                                        AccountView(account: account)
                                    }
                                }
                            }
                            .onMove(perform: moveItem)
                        }
                        
                        HStack {
                            Text("Total balance")
                                .font(.headline)
                            Spacer()
                            Text(periodBalances.totalBalance, format: .currency(code: defaultCurrency))
                                .font(.callout)
                        }
                        
                    }
                    .listStyle(PlainListStyle())
//                    .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20)) // reduce side padding of the list items
                    .sheet(isPresented: $addAccountView) {
                        AddAccountView()
                    }
                    .sheet(isPresented: $addTransactionView) {
                        TransactionDetailView(transaction: nil, payee: nil, account: nil, category: nil)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            HStack {
                                Button {
                                    addAccountView.toggle() // show the view where I can add a new element
                                } label: {
                                    Image(systemName: "plus")
                                }
                                
                                EditButton()
                            }
                        }
                    }
                    
                    Button {
//                        if(categories.count > 0 && accounts.count > 0) {
                            addTransactionView.toggle() // show the view where I can add a new element
//                        }
//                        else {
//                            print("You need to create at least one account and one category before you can create a transaction")
//                        }
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(.green)
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 20.0)
                }
                .onAppear {
                    updateAccountTotals()
                }
                .navigationTitle("Accounts")
                .navigationBarTitleDisplayMode(.inline)
            }
            
            
            // Show the balance before and after the transaction:
            CategoryBalanceBubble()
            
            
        } // end of ZStack
    }
    
    private func updateAccountTotals() {
        print("Updating totals for all accounts")
        // Calculate the total balances as of today, and store them in the environment variable:
        var amount = 0.0
        var budget = 0.0
        var external = 0.0
        var total = 0.0
        let period = getPeriod(date: Date())
        
        for account in accounts {
            if account.currency == defaultCurrency { // for accounts in the default currency
                amount = account.balance
//                amount = account.getBalance(period: period)?.accountbalance ?? 0.0
            }
            else { // for accounts in a different currency, add the amount converted to the default currency using the selected period's exchange rate, if there is one, otherwise add 0
                if let fxRate = period.getFxRate(currency1: defaultCurrency, currency2: account.currency ?? "") {
                    amount = account.balance / fxRate * 100.0
//                    amount = (account.getBalance(period: period)?.accountbalance ?? 0.0) / fxRate * 100.0
                }
            }
            
            total += amount // add the amount to the total balance
            
            // Also add the amount to one of the subtotals, for budget or for external accounts:
            if account.type == "Budget" {
                budget += amount
            }
            else if account.type == "External" {
                external += amount
            }
        }
        
        periodBalances.totalBalance = total
        periodBalances.totalBalanceBudget = budget
        periodBalances.totalBalanceExternal = external
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
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
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = accounts[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                accounts[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            accounts[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = accounts[destination].order + 1
            let newOrder = accounts[destination].order
            while startIndex <= endIndex {
                accounts[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            accounts[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
}

struct AccountListView_Previews: PreviewProvider {
    static var previews: some View {
        AccountListView()
    }
}
