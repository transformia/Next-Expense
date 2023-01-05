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
    
    let category: Category
    
    @ObservedObject var selectedPeriod: CategoryListView.SelectedPeriod // the period selected in CategoryListView
    
    @State private var categoryBalance = 0.0
    
    @StateObject var categoryBudget = AddTransactionView.Amount()
    
    // Variable determining whether the custom keypad is shown or not:
    @State private var showKeypad = false
        
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
                }
                .onTapGesture {
                    showKeypad.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text(Double(categoryBalance) / 100, format: .currency(code: "EUR")) // amount spent
                .onAppear {
//                    categoryBalance = category.income ? category.calcBalance(period: selectedPeriod.period) : -category.calcBalance(period: selectedPeriod.period) // category balance for income, opposite of category balance for expenses, to make everything positive
                    categoryBalance = category.calcBalance(period: selectedPeriod.period)
                }
                .onChange(of: selectedPeriod.period) { _ in
//                    categoryBalance = category.income ? category.calcBalance(period: selectedPeriod.period) : -category.calcBalance(period: selectedPeriod.period)
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
        .sheet(isPresented: $showKeypad) {
            NumpadView(amount: categoryBudget)
                .presentationDetents([.height(280)])
        }
    }
    
    private func saveBudget() {
        if(category.budgets?.count ?? 0 > 0) { // if there is already a budget for this category and period, update it
            for budget in category.budgets ?? [] {
                if((budget as! Budget).period == selectedPeriod.period) {
                    print("Budget already exists. Updating it to \(categoryBudget)")
                    (budget as! Budget).amount = Int64(categoryBudget.intAmount) // update the budget
                    PersistenceController.shared.save() // save the changes
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
