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
    
    let category: Category
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    
//    @State private var categoryBalance = 0.0
    
    @StateObject var categoryBudget = AddTransactionView.Amount() // stores the budgeted amount, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
    
    @State private var defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
        
    var body: some View {
        HStack {
            Text(category.name ?? "")
                .font(.subheadline)
            
            Spacer()
            
            Text(Double(categoryBudget.intAmount) / 100, format: .currency(code: defaultCurrency)) // amount budgeted
                .onAppear {
                    categoryBudget.intAmount = category.getBudget(period: selectedPeriod.period)
                }
                .onChange(of: selectedPeriod.period) { _ in
                    categoryBudget.intAmount = category.getBudget(period: selectedPeriod.period) // recalculate the monthly budget balances when I switch periods
                }
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
            
            Text((category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 0.0) / 100, format: .currency(code: defaultCurrency)) // amount spent
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
                Text((Double(categoryBudget.intAmount) + (category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00)) / 100, format: .currency(code: defaultCurrency)) // remaining budget
                    .font(.caption)
                    .foregroundColor((Double(categoryBudget.intAmount) + (category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00)) < 0 ? .red : .green)
            }
        }
        .sheet(isPresented: $categoryBudget.showNumpad) {
            NumpadView(amount: categoryBudget)
                .presentationDetents([.height(300)])
        }
        .swipeActions(edge: .trailing) {
            budgetToSpent
        }
    }
    
    var budgetToSpent: some View {
        Button {
            categoryBudget.intAmount = Int(-(category.getBalance(period: selectedPeriod.period)?.categorybalance ?? 00))
            saveBudget()
        } label: {
            Label("Spent", systemImage: "equal")
        }
        .tint(.blue)
    }
    
    private func saveBudget() {
        if(category.budgets?.count ?? 0 > 0) { // if there is already a budget for this category and period, update it
            for budget in category.budgets ?? [] {
                if((budget as! Budget).period == selectedPeriod.period) {
                    print("Budget already exists, and has changed. Updating it to \(Double(categoryBudget.intAmount) / 100)")
                    (budget as! Budget).amount = Int64(categoryBudget.intAmount) // update the budget
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
        
        PersistenceController.shared.save() // save the changes
        
        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets() // calculate the period budget balances and save them in the environment object
    }
}

//struct CategoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryView()
//    }
//}
