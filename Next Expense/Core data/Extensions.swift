//
//  Extensions.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-24.
//

import Foundation

extension Account {
    
    func calcBalance(toDate: Date) -> Int {
        var balance = 0.0
        for transaction in self.transactions ?? [] {
            if((transaction as! Transaction).date ?? Date() <= toDate) { // if the transaction happened before the specified date
                balance += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount, depending on the direction of the transaction
            }
        }
        return Int(balance)
    }
}

extension Category {
    
    func calcBalance(period: Period) -> Double { // needs to be a double, in case it is negative?
        var amount = 0.0
        for transaction in self.transactions ?? [] {
            if((transaction as! Transaction).period == period) { // if the budget period is the selected period
                amount += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount, depending on the direction of the transaction
            }
        }
        return amount
    }
    
    
    func calcBudget(period: Period) -> Int {
        var amount = 0
        for budget in self.budgets ?? [] {
//            print("Budget start date for category \(self.name): \((budget as! Budget).date)")
//            print("Start date: \(startDate)")
            if((budget as! Budget).period == period) { // if the budget period is the selected period
//                print("Budget amount for \(self.name) is \((budget as! Budget).amount)")
                if((budget as! Budget).category == self) { // if the category matches
                    amount += Int((budget as! Budget).amount) // add the budget amount
                }
            }
        }
        return amount
    }
    
}
