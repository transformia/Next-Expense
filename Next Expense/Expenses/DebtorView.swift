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
    
    @StateObject var settleAmount = AddTransactionView.Amount() // stores the amount to settle, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
    
    // Define variables for the new transactions's attributes:
    @State private var date = Date()
    @State private var selectedAccount: Account?
    
    
    var body: some View {
        
        VStack {
            HStack {
                
                Text(payee.name ?? "")
                
                Text(payee.calcDebtBalance() / 100, format: .currency(code: "EUR"))
                
                Image(systemName: "equal.circle.fill") // tap to set the settle amount to the amount of the balance
                    .foregroundColor(.blue)
                    .onTapGesture {
                        settleAmount.intAmount = Int(payee.calcDebtBalance())
                    }
                
                Text(Double(settleAmount.intAmount) / 100, format: .currency(code: UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"))
                    .onTapGesture {
                        settleAmount.showNumpad.toggle()
                    }
            }
            
            // If I have entered an amount, show the other required fields:
            if settleAmount.intAmount != 0 {
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
                    if selectedAccount != nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .onTapGesture {
                                let transaction = Transaction(context: viewContext)
                                
                                let period = getPeriod(date: date)
                                
                                transaction.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: payee, category: nil, memo: "Debt reimbursement", amount: settleAmount.intAmount, currency: (selectedAccount?.currency ?? UserDefaults.standard.string(forKey: "DefaultCurrency")) ?? "EUR", income: true, transfer: false, toAccount: nil, expense: true, debtor: payee, recurring: false, recurrence: "")
                                
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
