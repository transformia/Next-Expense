//
//  CategoryView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct CategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the category balance
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.id, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget> // to be able to calculate the total budgets for the period
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to find the previous period
    
    let category: Category
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    
//    @State private var categoryBalance = 0.0
    
    @StateObject var categoryBudget = TransactionDetailView.Amount() // stores the budgeted amount, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
    
    @State private var showCategoryReportingView = false
    
    @State private var defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
        
    var body: some View {
        HStack {
            Text(category.name ?? "")
                .font(.subheadline)
            
            Spacer()
            
            Text(category.budget, format: .currency(code: defaultCurrency)) // amount budgeted
//            Text(Double(category.getBudget(period: selectedPeriod.period)) / 100, format: .currency(code: defaultCurrency)) // amount budgeted
                .onAppear {
                    categoryBudget.intAmount = Int(category.budget * 100)
//                    categoryBudget.intAmount = category.getBudget(period: selectedPeriod.period)
                }
                .onChange(of: selectedPeriod.period) { _ in
                    category.getBudget(period: selectedPeriod.period) // recalculate the monthly budget balances when I switch periods
//                    category.budget = Double(category.getBudget(period: selectedPeriod.period) / 100) // recalculate the monthly budget balances when I switch periods
                    PersistenceController.shared.save()
//                    categoryBudget.intAmount = category.getBudget(period: selectedPeriod.period) // recalculate the monthly budget balances when I switch periods
                }
            
//            Text(Double(categoryBudget.intAmount) / 100, format: .currency(code: defaultCurrency)) // amount budgeted
//                .onAppear {
//                    categoryBudget.intAmount = category.getBudget(period: selectedPeriod.period)
//                }
//                .onChange(of: selectedPeriod.period) { _ in
//                    categoryBudget.intAmount = category.getBudget(period: selectedPeriod.period) // recalculate the monthly budget balances when I switch periods
//                }
//                .onChange(of: categoryBudget.intAmount) { _ in
//                    saveBudget()
//                    // Calculate the period budgets - done in MiniReportingView and CategoryView:
//                    (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
//                }
                .onTapGesture {
                    categoryBudget.showNumpad.toggle()
                }
                .onChange(of: categoryBudget.showNumpad) { _ in
                    if categoryBudget.showNumpad == false { // save the category budget when I close the numpad
                        saveBudget()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            // NO NEED FOR THIS ANYMORE, THE BUDGET IS SAVED WHEN I CLOSE THE NUMPAD:
//            if category.getBudget(period: selectedPeriod.period) != categoryBudget.intAmount { // if the category budget has been modified, show a button to save the new category budget
//                Image(systemName: "checkmark")
//                    .foregroundColor(.green)
//                    .onTapGesture {
//                        let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
//                        impactMed.impactOccurred() // haptic feedback
//                        categoryBudget.showNumpad = false // hide the numpad
//                        saveBudget() // save the new budget
//                        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets() // calculate the period budget balances and save them in the environment object
//                    }
//            }
            
            Text(category.balance, format: .currency(code: defaultCurrency)) // amount spent
//            Text((category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 0.0) / 100, format: .currency(code: defaultCurrency)) // amount spent
//                .onAppear {
////                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
//                    categoryBalance = category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 0.0
//                }
//                .onChange(of: periodBalances.expensesActual) { _ in
////                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
////                    categoryBalance = category.getBalance(period: selectedPeriod.period)?.categorybalance
//                }
//                .onChange(of: selectedPeriod.period) { _ in
////                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
//                    categoryBalance = category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 0.0
//                }
                .font(.caption)
            
            Spacer()
            
            if(category.type == "Expense") { // show the remaining budget - but only for expense categories, not for income categories
                Text(category.remainingbudget, format: .currency(code: defaultCurrency)) // remaining budget, after substracting this period's total balance and adding back this period's realized (i.e. non-future) balance
//                Text(category.budget + category.balance, format: .currency(code: defaultCurrency)) // remaining budget
//                Text((Double(category.getBudget(period: selectedPeriod.period)) + (category.balance)) / 100, format: .currency(code: defaultCurrency)) // remaining budget
//                Text((Double(category.getBudget(period: selectedPeriod.period)) + (category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00)) / 100, format: .currency(code: defaultCurrency)) // remaining budget
//                Text((Double(categoryBudget.intAmount) + (category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00)) / 100, format: .currency(code: defaultCurrency)) // remaining budget
                    .font(.caption)
//                    .foregroundColor((Double(categoryBudget.intAmount) + (category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00)) < 0 ? .red : .green)
//                    .foregroundColor((Double(categoryBudget.intAmount) + (category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00)) < 0 ? .red : (Double(categoryBudget.intAmount) + (category.getBalance(period: selectedPeriod.period)?.categorybalancetotal ?? 00)) < 0 ? .yellow : .green)
//                    .foregroundColor(category.budget + category.balance >= 0 ? .green : category.budget + category.balance >= 0 ? .yellow : .red)
                    .foregroundColor(category.remainingbudget - category.balance + category.balanceperiod >= 0 ? .green : category.remainingbudget - category.balanceperiod + category.balance >= 0 ? .yellow : .red)
            } // green if the remaining budget including the full period's transactions is positive, yellow if it's only positive as of today, but not when you consider the whole period, and red if it is strictly negative as of today
        }
        .sheet(isPresented: $categoryBudget.showNumpad) {
            NumpadView(amount: categoryBudget)
                .presentationDetents([.height(300)])
        }
        .sheet(isPresented: $showCategoryReportingView, onDismiss: {
            // When dismissing the reporting view, recalculate the selected period's balances:
            category.calcBalance(period: selectedPeriod.period)
            category.getBudget(period: selectedPeriod.period)
            category.calcRemainingBudget(selectedPeriod: selectedPeriod.period)
        }) {
            CategoryReportingView(category: category)
        }
        .swipeActions(edge: .leading) {
            Button {
                showCategoryReportingView = true
            } label: {
                Label("Report", systemImage: "stethoscope")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
//            budgetToSpent
            budgetToSpentIncludingFuture
            budgetToLastMonth
        }
    }
    
//    var budgetToSpent: some View {
//        Button {
//            categoryBudget.intAmount = Int(-(category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00))
//            saveBudget()
//        } label: {
//            Label("Spent", systemImage: "equal")
//        }
//        .tint(.blue)
//    }
    
    var budgetToSpentIncludingFuture: some View {
        Button {
            if category.type == "Expense" {
                categoryBudget.intAmount = Int( -category.balanceperiod * 100 - category.calcRemainingBudget(selectedPeriod: previousPeriod() ?? selectedPeriod.period) * 100 ) // amount spent in the selected period minus budget remaining in the previous period
//                categoryBudget.intAmount = Int(-(category.balanceperiod) * 100)
            }
            else if category.type == "Income" {
                categoryBudget.intAmount = Int((category.balanceperiod) * 100)
            }
            saveBudget()
        } label: {
            Label("Spent", systemImage: "equal")
        }
        .tint(.green)
    }
    
    var budgetToLastMonth: some View {
        Button {
            category.getBudget(period: previousPeriod() ?? Period()) // update the budget on the category
            
            categoryBudget.intAmount = Int(category.budget * 100)
            
            saveBudget()
        } label: {
            Label("Last month", systemImage: "arrow.left.circle.fill")
        }
        .tint(.blue)
    }
    
    private func saveBudget() {
        
        // Save the new budget to the category:
        category.budget = Double(categoryBudget.intAmount) / 100
        
        // Save the new budget in the Budget entity:
        if(category.budgets?.count ?? 0 > 0) { // if there is already a budget for this category and period, update it
            for budget in category.budgets ?? [] {
                if((budget as! Budget).period == selectedPeriod.period) {
                    print("Budget already exists, and has changed. Updating it to \(Double(categoryBudget.intAmount) / 100)")
                    (budget as! Budget).amount = Int64(categoryBudget.intAmount) // update the budget
                    
                    // Update the remaining budget:
                    category.calcRemainingBudget(selectedPeriod: selectedPeriod.period)
                    
                    PersistenceController.shared.save() // save the changes
                    
                    (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets() // calculate the period budget balances and save them in the environment object
                    
                    
                    return // exit the function if the budget has been found
                }
            }
        }
        
        let newBudget = Budget(context: viewContext) // if I haven't returned yet, create a new budget
        newBudget.id = UUID()
        newBudget.period = selectedPeriod.period
        newBudget.amount = Int64(categoryBudget.intAmount)
        newBudget.category = category
        
        // Update the remaining budget:
        category.calcRemainingBudget(selectedPeriod: selectedPeriod.period)
        
        PersistenceController.shared.save() // save the changes
        
        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets() // calculate the period budget balances and save them in the environment object
    }
    
    private func previousPeriod() -> Period? {
        var year = Calendar.current.dateComponents([.year], from: selectedPeriod.period.startdate ?? Date()).year ?? 1900
        var month = Calendar.current.dateComponents([.month], from: selectedPeriod.period.startdate ?? Date()).month ?? 1
        
        // Decrement the month, or the year and the month:
        if(month == 1) {
            year -= 1
            month = 12
        }
        else {
            month -= 1
        }
        
        for periodFound in periods {
            if(periodFound.year == year) {
                if(periodFound.month == month) {
                    return periodFound // return the period that was found
                }
            }
        }
        
        return nil // if no previous period is found, return nil
    }
}

//struct CategoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryView()
//    }
//}
