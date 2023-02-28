//
//  Extensions.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-24.
//

import Foundation

extension Transaction {
    
    func populate(account: Account, date: Date, period: Period, payee: Payee?, category: Category?, memo: String, amount: Int, currency: String, income: Bool, transfer: Bool, toAccount: Account?, expense: Bool, debtor: Payee?, recurring: Bool, recurrence: String) {
        //    func populate(date: Date, period: Period, recurring: Bool, recurrence: String, income: Bool, amount: Int, currency: String, payee: Payee?, category: Category?, account: Account, transfer: Bool, toAccount: Account?, expense: Bool, debtor: Payee?, memo: String) {
        if self.id == nil { // if this is a new transaction, create a UUID for it, and set its timestamp
            //            print("Creating a UUID for the transaction")
            self.id = UUID()
            self.timestamp = Date() // only set the timestamp when I create the transaction, not when I update it, as it changes the order of the transactions
        }
        
        self.account = account
        self.date = date
        self.period = period
        
        if(!transfer) { // save the payee if this is not a transfer
            self.payee = payee
        }
        else { // else if this is a transfer, set the payee to nil
            self.payee = nil
        }
        
        if ( (!transfer && account.type == "Budget") || (transfer && account.type != toAccount?.type) ) { // save the category if this is a normal transaction from a budget account, or a transfer between a budget and an external account
            self.category = category
        }
        else { // else if this is a normal transaction from an External account, or a a transfer between two accounts that are both budget or both external accounts, set the category to nil
            self.category = nil
        }
        self.memo = memo
        self.amount = Int64(amount) // save amount as an int, i.e. 2560 means 25,60€ for example
        self.currency = currency
        if !transfer {
            self.income = income // save the direction of the transaction, true for an income, false for an expense, always false for a transfer
        }
        else {
            self.income = false // always false for a transfer, to avoid confusion
        }
        self.transfer = transfer // save the information of whether or not this is a transfer
        if(transfer) {
            self.toaccount = toAccount
        }
        else {
            self.toaccount = nil
        }
        self.expense = expense
        if expense {
            self.debtor = debtor
        }
        else {
            self.debtor = nil
        }
        self.recurring = recurring
        self.recurrence = recurrence
    }
    
    
    
    // Get the amount of the transaction converted into the default currency, positive if it is an inflow and negative if it is an outflow. If it is an expense transaction to a debtor, return 0. If it is a transfer between two accounts of the same type, return 0
    func getAmount() -> Double {
        let positiveAmount: Bool
        
        if self.expense { // expenses to debtors should not be counted
            return 0.0
        }
        
        else if self.transfer {
            if self.account?.type == self.toaccount?.type { // if the 2 accounts have the same type, return 0
                return 0.0 // transfers between 2 budget accounts or 2 external accounts should not be counted
            }
            else if self.account?.type == "Budget" { // else if the from account is of type Budget
                positiveAmount = false // this is a transfer out of the budget, so it should be negative
            }
            else { // else, i.e. if the from account is of type External
                positiveAmount = true // this is a transfer into the budget, so it should be positive
            }
        }
        
        else { // if this is not an expense to a debtor and not a transfer
            positiveAmount = self.income // return a positive amount for an income, and a negative amount for an expense
        }
        
        // Determine if an exchange rate needs to be applied:
        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
        
        if self.currency == defaultCurrency { // if the transaction is in the default currency, return the amount with the correct sign
            return positiveAmount ? Double(self.amount) : -Double(self.amount)
        }
        else { // if the transaction is in another currency, check if there is an fx rate for the transaction's period. Return the amount with the correct sign after dividing by the exchange rate. If no exchange rate is found, return 0
            if let fxRate = self.period?.getFxRate(currency1: defaultCurrency, currency2: self.currency ?? "") {
                return positiveAmount ? Double(self.amount) / fxRate * 100.0 : -Double(self.amount) / fxRate * 100.0
            }
            else {
                return 0.0
            }
        }
    }
}

extension Account {
    
    func calcBalance(toDate: Date) -> Int { // sum up all transactions on the account, based on both the Account and the ToAccount field
        var balance = 0.0
        for transaction in self.transactions ?? [] {
            if((transaction as! Transaction).date ?? Date() <= toDate) { // if the transaction happened before the specified date
                balance += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount, depending on the direction of the transaction
            }
        }
        // Substract the transactions received to this account through transfers:
        for transaction in self.transfertransactions ?? [] {
            if((transaction as! Transaction).date ?? Date() <= toDate) { // if the transaction happened before the specified date
                balance -= (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount, depending on the direction of the transaction
            }
        }
        return Int(balance)
    }
}

extension Category {
    
    func calcBalance(period: Period) -> Double { // needs to be a double, in case it is negative?
        var amount = 0.0
//        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
        
        for transaction in self.transactions ?? [] {
            if((transaction as! Transaction).period == period) { // if the budget period is the selected period
                amount += (transaction as! Transaction).getAmount()
//                if !(transaction as! Transaction).expense { // if the transaction is not an expense transaction to a debtor
//                    if (transaction as! Transaction).currency == defaultCurrency { // if the transaction is in the default currency
//                        amount += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount depending on the direction of the transaction
//                    }
//                    else { // else if the transaction is in another currency
//                        if let fxRate = period.getFxRate(currency1: defaultCurrency, currency2: (transaction as! Transaction).currency ?? "") {
//                            amount += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) / fxRate * 100.0 : -Double((transaction as! Transaction).amount) / fxRate * 100.0 // add or substract the converted amount depending on the direction of the transaction
//                        }
//                    }
//                }
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
    
    func calcRemainingBudget(period: Period) -> Double {
        return Double(calcBudget(period: period)) + calcBalance(period: period)
    }
    
}

extension Period {
    
    func countTransactions() -> Int { // useful to delete duplicate periods that were generated by mistake. Might not be useful later on
        var count = 0
        for _ in self.transactions ?? [] {
            count += 1
        }
        return count
    }
    
    func getFxRate(currency1: String, currency2: String) -> Double? {
        print("Getting the exchange rate from \(currency1) to \(currency2) for \(self.monthString ?? "")")
        for fxRate in self.fxrates ?? [] {
            if (fxRate as! FxRate).currency1 == currency1 && (fxRate as! FxRate).currency2 == currency2 { // if the exchange rate is found, return it
                print("Found a rate of \((fxRate as! FxRate).rate)")
                return Double((fxRate as! FxRate).rate)
            }
            else if (fxRate as! FxRate).currency1 == currency2 && (fxRate as! FxRate).currency2 == currency1 { // if the reverse exchange rate is found, return its reverse
                print("Found a rate of \((fxRate as! FxRate).rate). Returning \(10000 / Double((fxRate as! FxRate).rate))")
                return 10000 / Double((fxRate as! FxRate).rate)
            }
        }
        
        return nil
    }
    
    func calcBalances() -> (Double, Double) {
        print("Calculating balances of period \(self.monthString ?? "")")
        var monthlyInc = 0.0 // sum of all incomes on income categories, minus sum of all expenses on income categories (in case that's a thing? Maybe for exchanging SEK to EUR for example, I would reduce my SEK income and increase my EUR income)
        var monthlyExp = 0.0 // sum of all expenses on expense categories, minus sum of all incomes on expense categories (to include reimbursements from other people)
//        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"

        for transaction in self.transactions ?? [] {
//            if((transaction as! Transaction).transfer == false) { // if this is not a transfer between accounts
//                if !(transaction as! Transaction).expense { // if the transaction is not an expense transaction to a debtor
                    //                print(transaction.amount)
            
            if((transaction as! Transaction).category?.type == "Income") { // if the category is an income category, add the amount to the monthly income
                monthlyInc += (transaction as! Transaction).getAmount()
            }
            else if((transaction as! Transaction).category?.type == "Expense") {  // if the category is an expense category, substract the amount from the monthly expenses
                monthlyExp -= (transaction as! Transaction).getAmount()
            }
            
            
            
//                    if (transaction as! Transaction).currency == defaultCurrency { // if the transaction is in the default currency
//                        if((transaction as! Transaction).category?.type == "Income") { // if the category is an income category, add or substract the amount to the monthly income
//                            monthlyInc += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                        }
//                        else if((transaction as! Transaction).category?.type == "Expense") {  // if the category is an expense category, add or substract the amount to the monthly expenses
//                            monthlyExp += (transaction as! Transaction).income ? -Double((transaction as! Transaction).amount) : Double((transaction as! Transaction).amount) // substract or add the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                        }
//                    }
//                    else { // else if the transaction is in another currency
//                        if let fxRate = self.getFxRate(currency1: defaultCurrency, currency2: (transaction as! Transaction).currency ?? "") {
//                            if((transaction as! Transaction).category?.type == "Income") { // if the category is an income category, add or substract the converted amount to the monthly income
//                                monthlyInc += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) / fxRate * 100.0 : -Double((transaction as! Transaction).amount) / fxRate * 100.0 // add or substract the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                            }
//                            else if((transaction as! Transaction).category?.type == "Expense") {  // if the category is an expense category, add or substract the converted amount to the monthly expenses
//                                monthlyExp += (transaction as! Transaction).income ? -Double((transaction as! Transaction).amount) / fxRate * 100.0 : Double((transaction as! Transaction).amount) / fxRate * 100.0 // substract or add the amount depending on the direction of the transaction, using Double so that it can be divided by 100 when displaying it
//                            }
//                        }
//                    }
//                }
//            }
        }

        return (monthlyInc, monthlyExp)
    }
    
    func calcBudgets() -> (Double, Double) {
        print("Calculating budgets of period \(self.monthString ?? "")")
        var monthlyIncomeBudget = 0.0
        var monthlyExpenseBudget = 0.0
        for budget in self.budgets ?? [] {
            if((budget as! Budget).period == self) { // if the budget is from the selected period
                if((budget as! Budget).category?.type == "Income") { // if this is an income category's budget
                    monthlyIncomeBudget += Double((budget as! Budget).amount) // using Double so that it can be divided by 100 when displaying it
                }
                else if((budget as! Budget).category?.type == "Expense") { // if this is an expense category's budget
                    monthlyExpenseBudget += Double((budget as! Budget).amount) // using Double so that it can be divided by 100 when displaying it
                }
            }
        }
        
        return (monthlyIncomeBudget, monthlyExpenseBudget)
    }
}

extension Payee {
    func calcDebtBalance() -> Double {
        print("Calculating balance of debtor \(self.name ?? "")")
        var balance = 0.0
        for transaction in self.debttranssactions ?? [] {
            balance += (transaction as! Transaction).income ? -Double((transaction as! Transaction).amount) : Double((transaction as! Transaction).amount)
        }
        return balance
    }
}
