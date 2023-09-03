//
//  CategoryGroupView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-14.
//

import SwiftUI

struct CategoryGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext

//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
//        animation: .default)
//    private var categories: FetchedResults<Category>
    
    let categoryGroup: CategoryGroup
    
    @State private var categoryGroupBudget = 0.0
    @State private var categoryGroupActual = 0.0
    @State private var categoryGroupRemain = 0.0
    @State private var showCategoryGroupBalances = false
    
    @State private var defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    
    var body: some View {
        HStack {
            Image(systemName: categoryGroup.showcategories ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                .resizable()
                .frame(width: 10, height: 10)
//                .onTapGesture {
//                    categoryGroup.showcategories.toggle()
//                    showCategoryGroupBalances.toggle()
//                    PersistenceController.shared.save()
//                }
            
            Text(categoryGroup.name ?? "")
                .font(.headline)
            
            Spacer()
            
            if showCategoryGroupBalances {
                Text(categoryGroupBudget, format: .currency(code: defaultCurrency))
                    .font(.caption)
                    .foregroundColor(.blue)
                    .onAppear {
                        updateCategoryGroupTotals()
                    }
                    .onChange(of: periodBalances.expensesActual) { _ in
                        updateCategoryGroupTotals()
                    }
                    .onChange(of: periodBalances.incomeActual) { _ in
                        updateCategoryGroupTotals()
                    }
                    .onChange(of: periodBalances.expensesBudget) { _ in
                        updateCategoryGroupTotals()
                    }
                    .onChange(of: periodBalances.incomeBudget) { _ in
                        updateCategoryGroupTotals()
                    }
                
                Spacer()
                
                Text(categoryGroupActual, format: .currency(code: defaultCurrency))
                    .font(.caption)
                
                Spacer()
                
//                if categoryGroup.categories?.count ?? 0 > 0 && categoryGroup.categories[0].type == "Expense" {
                    Text(categoryGroupRemain, format: .currency(code: defaultCurrency)) // remaining budget
                        .font(.caption)
                        .foregroundColor(categoryGroupRemain < 0 ? .red : .green)
//                }
            }
        }
        .onAppear {
            showCategoryGroupBalances = !categoryGroup.showcategories
        }
        .onTapGesture {
            categoryGroup.showcategories.toggle()
            showCategoryGroupBalances.toggle()
            PersistenceController.shared.save()
        }
    }
    
    private func updateCategoryGroupTotals() {
        print("Updating category group totals for \(categoryGroup.name ?? "")")
        categoryGroupBudget = 0.0
        categoryGroupActual = 0.0
        for category in categoryGroup.categories ?? [] {
            categoryGroupBudget += Double((category as! Category).budget)
//            categoryGroupBudget += Double((category as! Category).getBudget(period: selectedPeriod.period))
            categoryGroupActual += Double((category as! Category).balance)
//            categoryGroupActual += Double((category as! Category).getBalance(period: selectedPeriod.period)?.categorybalance ?? 0.0)
        }
        categoryGroupRemain = categoryGroupBudget + categoryGroupActual
    }
}

struct CategoryGroupView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryGroupView(categoryGroup: CategoryGroup())
    }
}
