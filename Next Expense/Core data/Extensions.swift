//
//  Extensions.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-24.
//

import Foundation

extension Transaction {
    
    func populate(account: Account, date: Date, period: Period, payee: Payee?, category: Category?, memo: String, amount: Int, amountTo: Int, currency: String, income: Bool, transfer: Bool, toAccount: Account?, expense: Bool, expenseSettled: Bool, debtor: Payee?, recurring: Bool, recurrence: String) {
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
        
        if ( !expense && ( (!transfer && account.type == "Budget") || (transfer && account.type != toAccount?.type) ) ) { // save the category if this is not an expense, and is a normal transaction from a budget account, or a transfer between a budget and an external account
            self.category = category
        }
        else { // else if this is an expense, or a normal transaction from an External account, or a transfer between two accounts that are both budget or both external accounts, set the category to nil
            self.category = nil
        }
        self.memo = memo
        self.amount = Int64(amount) // save amount as an int, i.e. 2560 means 25,60€ for example
        self.amountto = Int64(amountTo) // save amount of the transfer receiving account, for when the receiving account's currency is different from the transaction currency
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
        self.expensesettled = expenseSettled
        if expense {
            self.debtor = debtor
        }
        else {
            self.debtor = nil
        }
        self.recurring = recurring
        self.recurrence = recurrence
    }
    
    // Update the balances of the transaction's account, to account (for today's date) and category (for the selected period)
    func updateBalances(transactionPeriod: Period, selectedPeriod: Period, category: Category?, account: Account, toaccount: Account?) {
        print("Updating balances based on new or modified transaction: category \(category?.name ?? ""), account \(account.name ?? ""), to account \(toaccount?.name ?? "")")
        
        // Update the category balance and the remaining budget if the transaction is in the selected period, and has a category:
        if transactionPeriod == selectedPeriod && category != nil {
            category?.calcBalance(period: transactionPeriod) // calculate the balance and store it in the category
            category?.calcRemainingBudget(selectedPeriod: transactionPeriod) // calculate the remaining budget and store it in the category
        }
        // Update the account balance for end of day today if the transaction isn't in the future:
        if Calendar.current.startOfDay(for: self.date ?? Date()) < Date() {
            account.calcBalance(toDate: Date())
        }
        
        // Update the "to account" balance for end of day today if there is one, and the transaction isn't in the future:
        if toaccount != nil && Calendar.current.startOfDay(for: self.date ?? Date()) < Date() {
            toaccount?.calcBalance(toDate: Date())
        }
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
        
        // If this is a transfer with a to account that has a different currency than the transaction currency, look at the to account currency and the to amount:
        
        if self.transfer && self.currency != self.toaccount?.currency {
            
            if self.toaccount?.currency == defaultCurrency { // if the to account is in the default currency, return the to amount with the correct sign
                return positiveAmount ? Double(self.amountto) : -Double(self.amountto)
            }
            else { // if the to account is in another currency, check if there is an fx rate for the transaction's period. Return the to amount with the correct sign after dividing by the exchange rate. If no exchange rate is found, return 0
                if let fxRate = self.period?.getFxRate(currency1: defaultCurrency, currency2: self.toaccount?.currency ?? "") {
                    return positiveAmount ? Double(self.amountto) / fxRate * 100.0 : -Double(self.amountto) / fxRate * 100.0
                }
                else {
                    return 0.0
                }
            }
            
        }
        
        // Else if this is not a transfer, or if it is a transfer between two accounts with the same currency, look at the transaction currency and the regular amount:
        
        if self.currency == defaultCurrency { // if the transaction is in the default currency, return the amount with the correct sign
            // If this is a transfer with a to account that has a different currency than the transaction currency, return the to amount:
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
    
    // Get the amount of an expense transaction converted into the default currency, negative if it is an inflow and positive if it is an outflow
    func getExpenseAmount(period: Period) -> Double {
        let positiveAmount = !self.income // the signed is reversed for expenses
        
        // Determine if an exchange rate needs to be applied:
        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
        
        if self.currency == defaultCurrency { // if the transaction is in the default currency, return the amount with the correct sign
            return positiveAmount ? Double(self.amount) : -Double(self.amount)
        }
        else { // if the transaction is in another currency, check if there is an fx rate for the period provided. Return the amount with the correct sign after dividing by the exchange rate. If no exchange rate is found, return 0
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
    
    func calcBalance(toDate: Date) { // sum up all transactions on the account, based on both the Account and the ToAccount field
//        print("Calculating balance for account \(self.name ?? "")")
        var balance = 0.0
        for transaction in self.transactions ?? [] {
            if(Calendar.current.startOfDay(for: (transaction as! Transaction).date ?? Date()) <= toDate) { // if the transaction happened on or before the specified date
                balance += (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount, depending on the direction of the transaction
            }
        }
        // Substract the transactions received to this account through transfers:
        for transaction in self.transfertransactions ?? [] {
            if(Calendar.current.startOfDay(for: (transaction as! Transaction).date ?? Date()) <= toDate) { // if the transaction happened on or before the specified date
                // If the currency of the to account is different from the currency of the transaction, use the amountTo instead of the amount:
                if (transaction as! Transaction).currency != (transaction as! Transaction).toaccount?.currency {
                    balance -= (transaction as! Transaction).income ? Double((transaction as! Transaction).amountto) : -Double((transaction as! Transaction).amountto) // add or substract the amount, depending on the direction of the transaction
                }
                else {
                    balance -= (transaction as! Transaction).income ? Double((transaction as! Transaction).amount) : -Double((transaction as! Transaction).amount) // add or substract the amount, depending on the direction of the transaction
                }
            }
        }
        print("New balance of account \(self.name ?? ""): \(round(balance) / 100)")
        
        // Save the balance to the account:
        self.balance = round(balance) / 100
    }
}

extension Category {
    
    func calcBalance(period: Period) -> Double { // needs to be doubles, in case something is negative
        print("Calculating balances of category \(self.name ?? "")")
        var amountToday = 0.0 // balance as of end of day today
        var amountTotal = 0.0 // balance for the whole period, including future transactions
        
        for transaction in period.transactions ?? [] { // there will be less transactions in a period than in a category, so this should be faster than going through the category
            if((transaction as! Transaction).category == self) { // if the transaction is in this category
                if(Calendar.current.startOfDay(for: (transaction as! Transaction).date ?? Date()) <= Calendar.current.startOfDay(for: Date())) { // if the transaction happened on or before today, add it to the period balance as of today for this category
                    amountToday += (transaction as! Transaction).getAmount()
                }
                amountTotal += (transaction as! Transaction).getAmount() // whatever its date is, add it to the total period balance for this category
            }
        }
        
        print("New balance of category \(self.name ?? ""): \(round(amountToday) / 100) today, \(round(amountTotal) / 100) for the whole period")
        self.balance = round(amountToday) / 100
        self.balanceperiod = round(amountTotal) / 100
        
        return self.balanceperiod
    }
    
    
    func getBudget(period: Period) -> Double { // get the budget for a category and period, and save it to the category
//        print("Getting budget for category \(self.name ?? "")")
        var amount = 0
        for budget in period.budgets ?? [] {
//            print("Budget start date for category \(self.name): \((budget as! Budget).date)")
//            print("Start date: \(startDate)")
            if((budget as! Budget).category == self) { // if the budget category is this category
//                print("Budget amount for \(self.name) is \((budget as! Budget).amount)")
                amount += Int((budget as! Budget).amount) // add the budget amount
            }
        }
        self.budget = Double(amount) / 100
        return self.budget
    }
    
    func calcRemainingBudget(selectedPeriod: Period) -> Double {
        print("Calculating remaining balance of category \(self.name ?? "")")
        var budgetAmountInt: Int64 = 0
        var transactionAmountDoubleNoDecimals: Double = 0.0
        // Sum all of the budget amounts whose period start date is earlier or equal to the selected period's start date
        for budget in self.budgets ?? [] {
            if (budget as! Budget).period?.startdate ?? Date() <= selectedPeriod.startdate ?? Date() {
                budgetAmountInt += (budget as! Budget).amount
            }
        }
        
        // Sum all of the (signed) transaction amounts whose period start date is on or before the selected period's start date, and whose date is on of before today:
            // NOTE: THIS MEANS THAT I AM EXCLUDING FUTURE TRANSACTIONS FOR CURRENT AND FUTURE PERIODS - WHICH IS WHY I ADD BACK THE BALANCE OF THE FUTURE TRANSACTIONS WHEN DETERMINING THE COLOR OF THE AMOUNT ON THE CATEGORY
        
        for transaction in self.transactions ?? [] {
            if((transaction as! Transaction).period?.startdate ?? Date() <= selectedPeriod.startdate ?? Date()) {
                if Calendar.current.startOfDay(for: (transaction as! Transaction).date ?? Date()) <= Calendar.current.startOfDay(for: Date()) {
                    transactionAmountDoubleNoDecimals += (transaction as! Transaction).getAmount()
                }
            }
        }
        
        self.remainingbudget = Double(budgetAmountInt) / 100 + round(transactionAmountDoubleNoDecimals) / 100 // save the remaining budget to the category. Rounding it to avoid having anything after the 2nd decimal
        
        print("Total budgeted amount: \(Double(budgetAmountInt) / 100)")
        print("Total spent amount: \(round(transactionAmountDoubleNoDecimals) / 100)")
        
        return Double(budgetAmountInt) / 100 + round(transactionAmountDoubleNoDecimals) / 100 // return the remaining budget, for the places where I need to use it
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
    
    func calcBudgets() -> (Double, Double) {
        print("Calculating total budgets of period \(self.monthString ?? "")")
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
    func calcDebtBalance(period: Period) -> Double {
        print("Calculating balance of debtor \(self.name ?? "")")
        var balance = 0.0
        for transaction in self.debttranssactions?.filter({!($0 as! Transaction).expensesettled}) ?? [] {
            balance += (transaction as! Transaction).getExpenseAmount(period: period)
        }
        return balance
    }
}
