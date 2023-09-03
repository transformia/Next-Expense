//
//  DebtorListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-02-24.
//

import SwiftUI

struct DebtorListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.order, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the current date
    
    var body: some View {
        NavigationView {
            List {
                ForEach(payees) { payee in
                    if payee.debttranssactions?.count ?? 0 > 0 { // if the payee has debt transations
                        if payee.calcDebtBalance(period: getPeriod(date: Date())) != 0 { // if the debt isn't 0 today
                            NavigationLink {
                                DebtorTransView(payee: payee)
                            } label: {
                                DebtorView(payee: payee)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, DebtorListView, BudgetView, ...?
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

struct DebtorListView_Previews: PreviewProvider {
    static var previews: some View {
        DebtorListView()
    }
}
