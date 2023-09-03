//
//  AccountView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the account balance
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to select the active period
    
    let account: Account
    
    @State private var balance = 0.0
    
    var body: some View {
        HStack {
            Text(account.name ?? "")
                .padding(.leading, 25) // to align it with the Budget and External headings
            Spacer()
//            Text(balance / 100, format: .currency(code: account.currency ?? "EUR"))
//            Text((account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0) / 100, format: .currency(code: account.currency ?? "EUR"))
            Text(account.balance, format: .currency(code: account.currency ?? "EUR"))
                .font(.callout)
            /*
                .onAppear {
//                    balance = account.calcBalance(toDate: Date())
                    
                    let accountbalance = account.getBalance(period: getPeriod(date: Date()))
                    if accountbalance?.modifieddate ?? Date() < Calendar.current.startOfDay(for: Date()) { // if this period's account balance hasn't been updated yet today, update it
                        print("Account balance for \(account.name ?? "") hasn't been updated yet today")
                        accountbalance?.accountbalance = account.calcBalance(toDate: Date())
                        accountbalance?.modifieddate = Date()
                        PersistenceController.shared.save()
                    }
                    // For testing purposes: push the modified date into the past:
//                    accountbalance?.modifieddate = Calendar.current.date(byAdding: .day, value: -2, to: Date())
//                    PersistenceController.shared.save()
                }
             */
        }
//        .listRowBackground(Color.clear) // remove the grey background from the list items - WHY DOESN'T THIS WORK??
    }
    
    /*
    func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, CategoryListView...?
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
     */
}

//struct AccountView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountView()
//    }
//}
