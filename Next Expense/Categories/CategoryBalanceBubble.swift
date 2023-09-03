//
//  CategoryBalanceBubble.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-05-25.
//

import SwiftUI

struct CategoryBalanceBubble: View {
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment - to be able to show an animation when a category balance changes
    
    
    var body: some View {
        if(periodBalances.showBalanceAnimation) { // show the update of the category balance for x seconds
            if !periodBalances.balanceAfter { // showing the balance before the transaction
                HStack {
                    Text(periodBalances.category.name ?? "")
                    Text(periodBalances.remainingBudgetBefore, format: .currency(code: "EUR"))
//                        Text(periodBalances.remainingBudgetBefore / 100, format: .currency(code: "EUR"))
                }
                .padding()
                .foregroundColor(periodBalances.remainingBudgetBefore >= 0 ? .black : .white)
                .bold()
                .background(periodBalances.remainingBudgetBefore >= 0 ? .green : .red)
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
                    Text(periodBalances.remainingBudgetAfter, format: .currency(code: "EUR"))
//                        Text(periodBalances.remainingBudgetAfter / 100, format: .currency(code: "EUR"))
//                        Text(periodBalances.category.calcRemainingBudget(period: selectedPeriod.period) / 100, format: .currency(code: "EUR"))
                }
                .padding()
                .foregroundColor(periodBalances.remainingBudgetAfter >= 0 ? .black : .white)
                .bold()
                .background(periodBalances.remainingBudgetAfter >= 0 ? .green : .red)
                .clipShape(Capsule())
            }
        }
    }
}

struct CategoryBalanceBubble_Previews: PreviewProvider {
    static var previews: some View {
        CategoryBalanceBubble()
    }
}
