//
//  ContentView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to create periods if none exist yet (only on the first launch of the app
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the balances in the PeriodBalances class - delete this if that didn't work
    
    class PeriodBalances: ObservableObject {
        @Published var incomeBudget = 0.0 // total budget on all categories with type "Income"
        @Published var incomeActual = 0.0 // total actual on all categories with type "Income"
        @Published var expensesBudget = 0.0 // total budget on all categories with type "Expense"
        @Published var expensesActual = 0.0 // total actual on all categories with type "Expense"
        @Published var totalBalance = 0.0 // total balances of all accounts
        @Published var showBalanceAnimation = false // determines whether the category balance change animation is shown the next time I open one of the views its defined in, or not
        @Published var balanceAfter = false // determines which balance is being shown - the one before or the one after the transaction was created
        @Published var category = Category() // category for which the animation will be shown
        @Published var remainingBudgetBefore = 0.0 // remaining balance of that category before the latest change
        
        var budgetAvailable: Double {
            return expensesBudget - expensesActual
        }
    }
    @StateObject var periodBalances = PeriodBalances() // create the period balances - added to the environment further down
    
    class SelectedPeriod: ObservableObject {
        @Published var period = Period()
        @Published var periodStartDate = Date()
        @Published var periodChangedManually = false // detects whether the user has changed period manually, so that the onAppear doesn't reset the period to today's period once it has been changed
    }
    @StateObject var selectedPeriod = SelectedPeriod() // the period selected - added to the environment further down
    
    var body: some View {
        TabView {
            CategoryListView()
                .tabItem {
                    Label("Budget", systemImage: "dollarsign.circle.fill")
                }
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "banknote")
                }
            
            TransactionListView(payee: nil, account: nil, category: nil)
            .tabItem {
                Label("Transactions", systemImage: "list.triangle")
            }
            
//            PayeeListView()
//                .tabItem {
//                    Label("Payees", systemImage: "house")
//                }
            
            DebtorListView()
                .tabItem {
                    Label("Expenses", systemImage: "banknote")
                }
            
            CSVExportView()
                .tabItem {
                    Label("Export", systemImage: "list.triangle")
                }
            
//            AdminView()
//                .tabItem {
//                    Label("Admin", systemImage: "key")
//                }
            
//            PeriodListView()
//                .tabItem {
//                    Label("Periods", systemImage: "questionmark.folder.fill")
//                }
//            BudgetListView()
//                .tabItem {
//                    Label("Budgets", systemImage: "questionmark.folder.fill")
//                }
//            CategoryGroupListView()
//                .tabItem {
//                    Label("Category groups", systemImage: "questionmark.folder.fill")
//                }
        }
        .environmentObject(periodBalances) // put the balances in the environment, so that they are available in all views that declare them
        .environmentObject(selectedPeriod) // put the selected period in the environment, so that they it is available in all views that declare it
//        .onAppear {
//            createPeriods()
//        }
        .preferredColorScheme(.dark) // force the app to start in dark mode, even if the device is configured to light mode
    }   
    
    func createPeriods() {
        if(periods.count == 0) { // create periods if there are none
            print("Creating periods")
            var components = DateComponents()
            var startDate = Date()
            
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter
            }()
            
            for year in 2020...2025 {
                components.year = year
                for month in 1...12 {
                    components.month = month
                    components.day = 1
                    components.hour = 0
                    components.minute = 0
                    startDate = Calendar.current.date(from: components) ?? Date() // set the start date to the first day of the month
                    
                    let period = Period(context: viewContext)
                    period.id = UUID()
                    period.startdate = startDate
                    period.year = Int16(year)
                    period.month = Int16(month)
                    period.monthString = dateFormatter.string(from: startDate)
                    PersistenceController.shared.save() // save the item
                }
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
