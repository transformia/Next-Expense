//
//  MiniReportingView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-11-03.
//

import SwiftUI

struct MiniReportingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the total income and expenses, and their balance per category
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.id, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget> // to be able to calculate the budget per category
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to calculate the total balance using the extension on Account
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the transaction, to calculate the total balance on the correct date
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // the balances of the selected period
    
    var body: some View {
        VStack {
            HStack {
                Text("Balance:")
                Text(periodBalances.totalBalance / 100, format: .currency(code: "EUR"))
                //                        .onAppear { // not needed, because the period always changes when the view appears?
                //                            periodBalances.totalBalance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
                //                        }
                    .onChange(of: selectedPeriod.period) { _ in
                        //                            periodBalances.totalBalance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
                        
                        // Calculate the total balance - done in MiniReportingView and AddTransactionView:
                        periodBalances.totalBalance = 0.0
                        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
                        // Set the date to today if the current period is selected, or the end of the period if a past or future period is selected:
                        var consideredDate: Date
                        if selectedPeriod.period == getPeriod(date: Date()) {
                            consideredDate = Date()
                        }
                        else {
                            var components = DateComponents()
                            components.year = Int(selectedPeriod.period.year)
                            components.month = Int(selectedPeriod.period.month) + 1
                            components.day = 1
                            consideredDate = Calendar.current.startOfDay(for: Calendar.current.date(from: components) ?? Date())
                        }
                        
                        print("Calculating total balance as of \(consideredDate)")
                        for account in accounts {
                            if account.type == "Budget" { // ignore external accounts
                                if account.currency == defaultCurrency { // for accounts in the default currency
                                    periodBalances.totalBalance += Double(account.calcBalance(toDate: consideredDate))
                                }
                                else { // for accounts in a different currency, add the amount converted to the default currency using the selected period's exchange rate, if there is one, otherwise add 0
                                    if let fxRate = selectedPeriod.period.getFxRate(currency1: defaultCurrency, currency2: account.currency ?? "") {
                                        periodBalances.totalBalance += Double(account.calcBalance(toDate: consideredDate)) / fxRate * 100.0
                                    }
                                }
                            }
                        }
                    }
            }
            HStack {
                Text("Budgeted savings:")
                Text((periodBalances.incomeBudget - periodBalances.expensesBudget) / 100, format: .currency(code: "EUR"))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
                        }
                    }
                    .onChange(of: selectedPeriod.period) { _ in
                        // Calculate the period budgets - done in MiniReportingView and CategoryView:
                        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
                    }
            }
        }
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
    
//    private func totalBalance(periodStartDate: Date) -> Double { // total balance of all accounts as of the provided period. Also in AddTransactionView
//        var totalBalance = 0.0
//        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
//        for transaction in transactions {
//            if(!transaction.transfer) { // exclude transfers, as they have no impact on the balance
//                if(transaction.period?.startdate ?? Date() <= periodStartDate) { // if the transaction date is in or before the current period
//                    if transaction.currency == defaultCurrency { // if the transaction is in the default currency
//                        totalBalance += transaction.income ? Double(transaction.amount) : -Double(transaction.amount) // add or substract the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                    }
//                }
//            }
//        }
//        return totalBalance
//    }
    
//    private func monthlyBalances() -> (Double, Double) { // also exists in AddTransactionView
//        var monthlyInc = 0.0 // sum of all incomes on income categories, minus sum of all expenses on income categories (in case that's a thing?!)
//        var monthlyExp = 0.0 // sum of all expenses on expense categories, minus sum of all incomes on expense categories (to include reimbursements from other people)
//        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
//
//        for transaction in transactions {
//            if(transaction.transfer == false) { // if this is not a transfer between accounts
//                if(transaction.period == selectedPeriod.period) { // if the transaction is from the selected period
//                    //                print(transaction.amount)
//
//                    if transaction.currency == defaultCurrency { // if the transaction is in the default currency
//                        if(transaction.category?.type == "Income") { // if the category is an income category, add or substract the amount to the monthly income
//                            monthlyInc += transaction.income ? Double(transaction.amount) : -Double(transaction.amount) // add or substract the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                        }
//                        else if(transaction.category?.type == "Expense") {  // if the category is an expense category, add or substract the amount to the monthly expenses
//                            monthlyExp += transaction.income ? -Double(transaction.amount) : Double(transaction.amount) // substract or add the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                        }
//                    }
//
//                    // Old code, now simplified into the one above:
////                    if(transaction.income) { // if this is an income
////                        if(transaction.category?.type == "Income") { // if the category is an income category
////                            if transaction.currency == defaultCurrency { // if the transaction is in the default currency
////                                monthlyInc += Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
////                            }
////                        }
////                        else if(transaction.category?.type == "Expense") { // if the category is an expense category
////                            if transaction.currency == defaultCurrency { // if the transaction is in the default currency
////                                monthlyExp -= Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
////                            }
////                        }
////                    }
////                    else { // if this is an expense
////                        if(transaction.category?.type == "Expense") { // if the category is an expense category
////                            if transaction.currency == defaultCurrency { // if the transaction is in the default currency
////                                monthlyExp += Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
////                            }
////                        }
////                        else if(transaction.category?.type == "Income") { // if the category is an income category
////                            if transaction.currency == defaultCurrency { // if the transaction is in the default currency
////                                monthlyInc -= Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
////                            }
////                        }
////                    }
//                }
//            }
//        }
//
//        return (monthlyInc, monthlyExp)
//    }
    
//    private func monthlyBudgets() -> (Double, Double) { // also in CategoryView
//        var monthlyIncomeBudget = 0.0
//        var monthlyExpenseBudget = 0.0
//        for budget in budgets {
//            if(budget.period == selectedPeriod.period) { // if the budget is from the selected period
//                if(budget.category?.type == "Income") { // if this is an income category's budget
//                    monthlyIncomeBudget += Double(budget.amount) // using Double so that it can be divided by 100 when displaying it
//                }
//                else if(budget.category?.type == "Expense") { // if this is an expense category's budget
//                    monthlyExpenseBudget += Double(budget.amount) // using Double so that it can be divided by 100 when displaying it
//                }
//            }
//        }
//
//        return (monthlyIncomeBudget, monthlyExpenseBudget)
//    }
}

//struct MiniReportingView_Previews: PreviewProvider {
//    static var previews: some View {
//        MiniReportingView()
//    }
//}
