//
//  BudgetListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-19.
//

import SwiftUI

struct BudgetListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.id, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget> // to be able to display budgets
    
    var body: some View {
        VStack {
            Button( action: {
                clearBudgets()
            }, label: {
                Text("Clear all budgets")
            })
            
            List {
                ForEach(budgets) { budget in
                    HStack {
                        Text(budget.category?.name ?? "")
                        Text(budget.date ?? Date(), formatter: dateFormatter)
                        Text(Double(budget.amount) / 100, format: .currency(code: "EUR"))
                    }
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    private func clearBudgets() {
        print("Clearing all budgets")
        if(budgets.count > 0) {
            for i in 0 ... budgets.count - 1 {
                viewContext.delete(budgets[i])
            }
            PersistenceController.shared.save() // save the changes
        }
    }
}

struct BudgetListView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetListView()
    }
}
