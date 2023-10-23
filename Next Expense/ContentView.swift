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
        @Published var totalBalanceBudget = 0.0 // total balances of all budget accounts
        @Published var totalBalanceExternal = 0.0 // total balances of all external accounts
        @Published var totalBalance = 0.0 // total balances of all accounts
        @Published var showBalanceAnimation = false // determines whether the category balance change animation is shown the next time I open one of the views its defined in, or not
        @Published var balanceAfter = false // determines which balance is being shown - the one before or the one after the transaction was created
        @Published var category = Category() // category for which the animation will be shown
        @Published var remainingBudgetBefore = 0.0 // remaining balance of that category before the latest change
        @Published var remainingBudgetAfter = 0.0 // remaining balance of that category after the latest change
        
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
        
        
//        PeriodListView() // to fix crashes on startup when the database has emptied and re-synced from iCloud, leave only this, and comment out the rest of the body

        /* */
        if periods.count > 0 {  // to protect against crashes when opening BudgetView when there are no periods yet
            
            TabView {
                
                BudgetView()
                    .tabItem {
                        Label("Budget", systemImage: "dollarsign.circle.fill")
                    }
                
                //            BalanceListView()
                //                .tabItem {
                //                    Label("Balances", systemImage: "dollarsign.circle.fill")
                //                }
                
                AccountListView()
                    .tabItem {
                        Label("Accounts", systemImage: "banknote")
                    }
                
                NavigationView { // NavigationView added here so that I don't have two of them when calling TransactionListView from other places
                    TransactionListView(payee: nil, account: nil, category: nil)
                }
                .tabItem {
                    Label("Transactions", systemImage: "list.triangle")
                }
                
                PayeeListView()
                    .tabItem {
                        Label("Payees", systemImage: "house")
                    }
                
                DebtorListView()
                    .tabItem {
                        Label("Expenses", systemImage: "banknote")
                    }
                
                RecurringTransactionsView()
                    .tabItem {
                        Label("Recurring", systemImage: "arrow.triangle.2.circlepath.circle")
                    }
                
//                PeriodListView()
//                    .tabItem {
//                        Label("Periods", systemImage: "questionmark.folder.fill")
//                    }
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
//            .preferredColorScheme(.dark) // force the app to start in dark mode, even if the device is configured to light mode
            .preferredColorScheme(.light) // force the app to start in lighy mode, even if the device is configured to dark mode
        }
        
        else { // if there are no periods yet, show the setup screen
            VStack {
                Image(systemName: "dollarsign.circle")
                    .resizable()
                    .frame(width: 35, height: 35)
                Text("Welcome to Next Expense")
                    .font(.title)
                Text("Tap here to CREATE PERIODS AND TEST CATEGORIES")
                    .font(.headline)
            }
            .onTapGesture {
                createPeriods()
                createTutorialCategories()
            }
            .preferredColorScheme(.dark) // force the app to start in dark mode, even if the device is configured to light mode
        }
         /* */
    }
    
    
    private func createPeriods() {
        if(periods.count == 0) { // create periods if there are none
            print("Creating periods")
            var components = DateComponents()
            var startDate = Date()
            
            let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return formatter
            }()
            
            for year in 2000...2070 {
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
    
    private func createTutorialCategories() { // create a few categories and groups
        // Category groups:
        let categoryGroup1 = CategoryGroup(context: viewContext)
        categoryGroup1.id = UUID()
        categoryGroup1.name = "Income"
        categoryGroup1.order = 0
        
        let categoryGroup2 = CategoryGroup(context: viewContext)
        categoryGroup2.id = UUID()
        categoryGroup2.name = "Daily expenses"
        categoryGroup2.order = 1
        
        let categoryGroup3 = CategoryGroup(context: viewContext)
        categoryGroup3.id = UUID()
        categoryGroup3.name = "Bills"
        categoryGroup3.order = 2
        
        // Categories in each group:
        let category1 = Category(context: viewContext)
        category1.id = UUID()
        category1.name = "Salary"
        category1.type = "Income"
        category1.categorygroup = categoryGroup1
        category1.order = 0
        
        let category2 = Category(context: viewContext)
        category2.id = UUID()
        category2.name = "Groceries"
        category2.type = "Expense"
        category2.categorygroup = categoryGroup2
        category2.order = 1
        
        let category3 = Category(context: viewContext)
        category3.id = UUID()
        category3.name = "Going out"
        category3.type = "Expense"
        category3.categorygroup = categoryGroup2
        category3.order = 2
        
        let category4 = Category(context: viewContext)
        category4.id = UUID()
        category4.name = "Rent"
        category4.type = "Expense"
        category4.categorygroup = categoryGroup3
        category4.order = 3
        
        let category5 = Category(context: viewContext)
        category5.id = UUID()
        category5.name = "Utilities"
        category5.type = "Expense"
        category5.categorygroup = categoryGroup3
        category5.order = 4
        
        PersistenceController.shared.save() // save the items
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
