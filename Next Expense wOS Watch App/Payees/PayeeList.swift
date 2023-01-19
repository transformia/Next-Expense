//
//  PayeeList.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2023-01-17.
//

import SwiftUI

struct PayeeList: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to select a payee
    
    @State private var addTransactionView = false // determines whether that view is displayed or not
    
    @State private var selectedPayee: Payee? // payee that I tap on
    
    var body: some View {
        List {
            ForEach(payees) { payee in
                Text(payee.name ?? "")
//                    .onTapGesture {
//                        selectedPayee = self
//                        addTransactionView.toggle() // show the view where I can add a new element
//                    }
            }
        }
//        .sheet(isPresented: $addTransactionView) {
//            AddTransactionView(payee: selectedPayee)
//        }
    }
}

//struct PayeeList_Previews: PreviewProvider {
//    static var previews: some View {
//        PayeeList()
//    }
//}
