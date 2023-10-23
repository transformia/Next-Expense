//
//  AdminView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-01-18.
//

import SwiftUI

struct AdminView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryGroup.id, ascending: true)],
        animation: .default)
    private var categoryGroups: FetchedResults<CategoryGroup>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.order, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee>
    
    @State private var transactionCount = 0
    
    @State private var showingClearTransactionsAlert = false
    @State private var showingClearPeriodsAlert = false
    @State private var showingClearCategoriesAlert = false
    @State private var showingClearPayeesAlert = false
    
    var body: some View {
        VStack {
            
            Button {
                showingClearPeriodsAlert = true
            } label: {
                Label("Delete all periods", systemImage: "xmark.circle.fill")
            }
            .alert(isPresented:$showingClearPeriodsAlert) {
                Alert(
                    title: Text("Are you sure you want to delete all periods?"),
                    message: Text("This cannot be undone"),
                    primaryButton: .destructive(Text("Delete")) {
                        clearPeriods()
                    },
                    secondaryButton: .cancel()
                )
            }
            .padding()
            
            Button {
                showingClearCategoriesAlert = true
            } label: {
                Label("Delete all categories and groups", systemImage: "xmark.circle.fill")
            }
            .alert(isPresented:$showingClearCategoriesAlert) {
                Alert(
                    title: Text("Are you sure you want to delete all categories and groups?"),
                    message: Text("This cannot be undone"),
                    primaryButton: .destructive(Text("Delete")) {
                        clearCategories()
                    },
                    secondaryButton: .cancel()
                )
            }
            .padding()
            
            
//            HStack {
//                Text("Transactions with amount 0:")
//                Text("\(transactionCount)")
//                    .onAppear {
//                        transactionCount = countTransactions()
//                    }
//            }
//
//            Button {
//                clearTransactions()
//
//            } label: {
//                Label("Clear transactions", systemImage: "xmark.circle.fill")
//            }
            
            Button {
                showingClearPayeesAlert = true
                
            } label: {
                Label("Clear ALL payees", systemImage: "xmark.circle.fill")
            }
            .alert(isPresented:$showingClearPayeesAlert) {
                Alert(
                    title: Text("Are you sure you want to delete all payees?"),
                    message: Text("This cannot be undone"),
                    primaryButton: .destructive(Text("Delete")) {
                        clearAllPayees()
                    },
                    secondaryButton: .cancel()
                )
            }
            .padding()
            
            Button {
                showingClearTransactionsAlert = true
                
            } label: {
                Label("Clear ALL transactions", systemImage: "xmark.circle.fill")
            }
            .alert(isPresented:$showingClearTransactionsAlert) {
                Alert(
                    title: Text("Are you sure you want to delete all transactions?"),
                    message: Text("This cannot be undone"),
                    primaryButton: .destructive(Text("Delete")) {
                        clearAllTransactions()
                    },
                    secondaryButton: .cancel()
                )
            }
            .padding()
        }
    }
    
    
    private func clearPeriods() {
        for period in periods {
            viewContext.delete(period)
        }
        PersistenceController.shared.save() // save the changes
    }
    
    private func clearCategories() {
        for category in categories {
            viewContext.delete(category)
        }
        for categoryGroup in categoryGroups {
            viewContext.delete(categoryGroup)
        }
        PersistenceController.shared.save() // save the changes
    }
    
    private func countTransactions() -> Int {
        return transactions.filter { $0.amount == 0 }.count
    }
    
    private func clearTransactions() {
        for transaction in transactions {
            if(transaction.amount == 0) {
//                print(transaction.payee?.name ?? "")
                viewContext.delete(transaction)
                PersistenceController.shared.save() // save the change
            }
        }
    }
    
    func clearAllTransactions() {
        print("Clearing all transactions")
        if(transactions.count > 0) {
            for i in 0 ... transactions.count - 1 {
                viewContext.delete(transactions[i])
            }
            PersistenceController.shared.save() // save the changes
        }
    }
    
    func clearAllPayees() {
        print("Clearing all payees")
        if(payees.count > 0) {
            for i in 0 ... payees.count - 1 {
                viewContext.delete(payees[i])
            }
            PersistenceController.shared.save() // save the changes
        }
    }
}

struct AdminView_Previews: PreviewProvider {
    static var previews: some View {
        AdminView()
    }
}
