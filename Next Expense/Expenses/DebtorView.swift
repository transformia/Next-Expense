//
//  DebtorView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-02-24.
//

import SwiftUI

struct DebtorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to select an account from a picker
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the transaction
    
    let payee: Payee
    
    @StateObject var settleAmount = TransactionDetailView.Amount() // stores the amount to settle, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
    
    // Define variables for the new transactions's attributes:
    @State private var date = Date()
    @State private var selectedAccount: Account?
    
    
    var body: some View {
        
        VStack {
            HStack {
                
                Text(payee.name ?? "")
                
                Text(payee.calcDebtBalance(period: getPeriod(date: date)) / 100, format: .currency(code: "EUR"))
                
                Image(systemName: "equal.circle.fill") // tap to set the settle amount to the amount of the balance
                    .foregroundColor(.blue)
                    .onTapGesture {
                        settleAmount.intAmount = Int(payee.calcDebtBalance(period: getPeriod(date: date)))
                    }
                Text(Double(settleAmount.intAmount) / 100, format: .currency(code: selectedAccount?.currency ?? UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"))
//                Text(Double(settleAmount.intAmount) / 100, format: .currency(code: UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"))
                    .onTapGesture {
                        settleAmount.showNumpad.toggle()
                    }
            }
            /*
            // If I have entered an amount, show the other required fields:
            if settleAmount.intAmount != 0 {
             */
            // If I have entered the same amount as the debt amount (converted or not), show the other required fields - IN THE FUTURE, ALSO ALLOW PARTIAL SETTLEMENTS, BUT THEN I WILL NEED TO DO SOMETHING WITH THE DIFFERENCE
            if settleAmount.intAmount == Int(payee.calcDebtBalance(period: getPeriod(date: Date()))) || settleAmount.intAmount == Int(payee.calcDebtBalance(period: getPeriod(date: Date())) / (getPeriod(date: date).getFxRate(currency1: selectedAccount?.currency ?? "", currency2: UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR") ?? 1) * 100.0) {
                HStack {
                    DatePicker("", selection: $date, displayedComponents: .date)
                    Picker("", selection: $selectedAccount) {
                        ForEach(accounts, id: \.self) { (account: Account) in
                            Text(account.name ?? "")
                                .tag(account as Account?)
                        }
                    }
                    .onAppear {
                        selectedAccount = accounts[0]
                    }
                    .onChange(of: selectedAccount) { _ in // if I switch to an account that does not have the default currency, calculate the amount by taking the current debt amount and converting it into the new account's currency
                        let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
                        if selectedAccount?.currency != defaultCurrency {
                            if let fxRate = getPeriod(date: date).getFxRate(currency1: selectedAccount?.currency ?? "", currency2: defaultCurrency) {
                                settleAmount.intAmount = Int(payee.calcDebtBalance(period: getPeriod(date: Date())) / fxRate * 100.0)
                            }
                            
                        }
                        else { // else if the currency of the account is the default currency, restore the amount to the debt amount
                            settleAmount.intAmount = Int(payee.calcDebtBalance(period: getPeriod(date: date)))
                        }
                    }
                    if selectedAccount != nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .onTapGesture {
                                // Create a settlement transaction:
                                let transaction = Transaction(context: viewContext)
                                
                                let period = getPeriod(date: date)
                                
                                transaction.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: payee, category: nil, memo: "Debt reimbursement", amount: settleAmount.intAmount, amountTo: 0, currency: (selectedAccount?.currency ?? UserDefaults.standard.string(forKey: "DefaultCurrency")) ?? "EUR", income: true, transfer: false, toAccount: nil, expense: true, expenseSettled: true, debtor: payee, recurring: false, recurrence: "")
                                
                                // Settle all of the debts of this debtor:
                                for transaction in payee.debttranssactions ?? [] {
                                    (transaction as! Transaction).expensesettled = true
                                }
                                
                                PersistenceController.shared.save()
                                
                                // Clear the settle amount:
                                settleAmount.intAmount = 0
                            }
                    }
                }
            }
        }
        .sheet(isPresented: $settleAmount.showNumpad) {
            NumpadView(amount: settleAmount)
                .presentationDetents([.height(300)])
        }
    }
    
    func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
        let year = Calendar.current.dateComponents([.year], from: date).year ?? 1900
        let month = Calendar.current.dateComponents([.month], from: date).month ?? 1
        
        for period in periods {
            if(period.year == year) {
                if(period.month == month) {
                    return period
                }
            }
        }
        return Period() // if no period is found, return a new one
    }
}

struct DebtorView_Previews: PreviewProvider {
    static var previews: some View {
        DebtorView(payee: Payee())
    }
}
