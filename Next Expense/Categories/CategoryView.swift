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
    
    @State private var categoryBalance = 0.0
    
    @StateObject var categoryBudget = AddTransactionView.Amount() // stores the budgeted amount, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
        
    var body: some View {
        HStack {
            Text(category.name ?? "")
                .font(.subheadline)
            
            Spacer()
            
            Text(Double(categoryBudget.intAmount) / 100, format: .currency(code: "EUR")) // amount budgeted
                .onAppear {
                    categoryBudget.intAmount = category.calcBudget(period: selectedPeriod.period)
                }
                .onChange(of: selectedPeriod.period) { _ in
                    categoryBudget.intAmount = category.calcBudget(period: selectedPeriod.period)
                }
                .onChange(of: categoryBudget.intAmount) { _ in
                    saveBudget()
                    // Calculate the period budgets - done in MiniReportingView and CategoryView:
                    (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
//                    periodBalances.incomeBudget = monthlyBudgets().0
//                    periodBalances.expensesBudget = monthlyBudgets().1
                }
                .onTapGesture {
                    categoryBudget.showNumpad.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text(Double(categoryBalance) / 100, format: .currency(code: "EUR")) // amount spent
                .onAppear {
                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
                }
                .onChange(of: periodBalances.expensesActual) { _ in
                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
                }
                .onChange(of: selectedPeriod.period) { _ in
                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
                }
                .font(.caption)
            
            Spacer()
            
            if(category.type == "Expense") { // only show the remaining budget for expense categories
                Text((Double(categoryBudget.intAmount) + Double(categoryBalance)) / 100, format: .currency(code: "EUR")) // remaining budget
                    .font(.caption)
                    .foregroundColor((Double(categoryBudget.intAmount) + Double(categoryBalance)) < 0 ? .red : .green)
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
            categoryBudget.intAmount = Int(-categoryBalance)
        } label: {
            Label("Spent", systemImage: "equal")
        }
        .tint(.blue)
    }
    
    private func saveBudget() {
        if(category.budgets?.count ?? 0 > 0) { // if there is already a budget for this category and period, update it
            for budget in category.budgets ?? [] {
                if((budget as! Budget).period == selectedPeriod.period) {
                    if (budget as! Budget).amount != Int64(categoryBudget.intAmount) {
                        print("Budget already exists, and has changed. Updating it to \(Double(categoryBudget.intAmount) / 100)")
                        (budget as! Budget).amount = Int64(categoryBudget.intAmount) // update the budget
                        PersistenceController.shared.save() // save the changes
                    }
                    else {
                        print("Budget already exists, but is unchanged")
                    }
                    return
                }
            }
        }
        
        
        let newBudget = Budget(context: viewContext) // if I haven't returned yet, create a new budget
        newBudget.id = UUID()
        newBudget.period = selectedPeriod.period
        newBudget.amount = Int64(categoryBudget.intAmount)
        newBudget.category = category
        
        PersistenceController.shared.save() // save the changes
    }
}

//struct CategoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryView()
//    }
//}
