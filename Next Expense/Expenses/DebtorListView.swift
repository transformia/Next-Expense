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
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(payees) { payee in
                    if payee.debttranssactions?.count ?? 0 > 0 { // if the payee has debt transations
                        if payee.calcDebtBalance() != 0 { // if the debt isn't 0
                            DebtorView(payee: payee)
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DebtorListView_Previews: PreviewProvider {
    static var previews: some View {
        DebtorListView()
    }
}
