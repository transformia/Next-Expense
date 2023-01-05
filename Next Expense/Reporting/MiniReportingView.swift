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
    
    @ObservedObject var selectedPeriod: CategoryListView.SelectedPeriod // the period selected in CategoryListView
    
    @State private var monthlyIncome = 0.0
    @State private var monthlyExpenses = 0.0
    @State private var monthlyIncomeBudget = 0.0
    @State private var monthlyExpenseBudget = 0.0
    @State private var balance = 0.0
    @State private var budgeted = 0.0
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    Text("Income")
                    Text(monthlyIncomeBudget / 100, format: .currency(code: "EUR"))
                        .onAppear {
                            monthlyIncomeBudget = monthlyBudgets().0
                            monthlyExpenseBudget = monthlyBudgets().1
                        }
                        .onChange(of: selectedPeriod.period) { _ in
                            monthlyIncomeBudget = monthlyBudgets().0
                            monthlyExpenseBudget = monthlyBudgets().1
                        }
                    Text(monthlyIncome / 100, format: .currency(code: "EUR"))
                        .onAppear {
                            monthlyIncome = monthlyBalances().0
                            monthlyExpenses = monthlyBalances().1
                        }
                        .onChange(of: selectedPeriod.period) { _ in
                            monthlyIncome = monthlyBalances().0
                            monthlyExpenses = monthlyBalances().1
                        }
                }
                Spacer()
                VStack {
                    Text("Expenses")
                    Text(monthlyExpenseBudget / 100, format: .currency(code: "EUR"))
                    Text(monthlyExpenses / 100, format: .currency(code: "EUR"))
                }
                Spacer()
                VStack {
                    Text("Savings")
                    Text((monthlyIncomeBudget - monthlyExpenseBudget) / 100, format: .currency(code: "EUR"))
                    Text((monthlyIncome - monthlyExpenses) / 100, format: .currency(code: "EUR"))
                }
                Spacer()
            }
            
            VStack {
                HStack {
                    Text("Total balance")
                    Text(balance / 100, format: .currency(code: "EUR"))
                        .onAppear {
                            balance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
                        }
                        .onChange(of: selectedPeriod.period) { _ in
                            balance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
                        }
                }
                HStack {
                    Text("Budget available")
                    Text(budgetedExpenses() / 100, format: .currency(code: "EUR"))
                    Text(monthlyBalances().1 / 100, format: .currency(code: "EUR"))
                    Text(budgeted / 100, format: .currency(code: "EUR"))
                        .onAppear {
                            budgeted = budgetedExpenses() - monthlyBalances().1
                        }
                        .onChange(of: selectedPeriod.period) { _ in
                            budgeted = budgetedExpenses() - monthlyBalances().1
                        }
                }
            }
        }
    }
    
    private func totalBalance(periodStartDate: Date) -> Double { // total balance of all accounts as of the provided period
        var totalBalance = 0.0
        for transaction in transactions {
            if(transaction.period?.startdate ?? Date() <= periodStartDate) { // if the transaction date is in or before the current period
                if(transaction.income) {
                    totalBalance += Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
                }
                else {
                    totalBalance -= Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
                }
            }
        }
        return totalBalance
    }
    
    private func budgetedExpenses() -> Double {
        var budgetedExpenses = 0.0
        
        for budget in budgets { // add the remaining budget amounts from this month
            if(budget.period == selectedPeriod.period) {
                if(budget.category?.type == "Expense") { // only get expense budget
                    budgetedExpenses += Double(budget.amount)
                }
            }
        }
        return budgetedExpenses
    }
    
    private func monthlyBalances() -> (Double, Double) {
        var monthlyInc = 0.0
        var monthlyExp = 0.0
        for transaction in transactions {
            if(transaction.transfer == false) { // if this is not a transfer between accounts
                if(transaction.period == selectedPeriod.period) { // if the transaction is from the selected period
                    //                print(transaction.amount)
                    if(transaction.income) { // if this is an income
                        if(transaction.category?.type != "Investment") { // if the category is an income or expense category
                            monthlyInc += Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
                        }
                    }
                    else { // if this is an expense
                        if(transaction.category?.type != "Investment") { // if the category is an income or expense category
                            monthlyExp += Double(transaction.amount) // using Double so that it can be divided by 100 when displaying it
                        }
                    }
                }
            }
        }
        
        return (monthlyInc, monthlyExp)
    }
    
    private func monthlyBudgets() -> (Double, Double) {
        monthlyIncomeBudget = 0.0
        monthlyExpenseBudget = 0.0
        for budget in budgets {
            if(budget.period == selectedPeriod.period) { // if the budget is from the selected period
                if(budget.category?.type == "Income") { // if this is an income category's budget
                    monthlyIncomeBudget += Double(budget.amount) // using Double so that it can be divided by 100 when displaying it
                }
                else if(budget.category?.type == "Expense") { // if this is an expense category's budget
                    monthlyExpenseBudget += Double(budget.amount) // using Double so that it can be divided by 100 when displaying it
                }
            }
        }
        
        return (monthlyIncomeBudget, monthlyExpenseBudget)
    }
}

//struct MiniReportingView_Previews: PreviewProvider {
//    static var previews: some View {
//        MiniReportingView()
//    }
//}
