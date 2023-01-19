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
    
    var body: some View {
        TabView {
            CategoryListView()
                .tabItem {
                    Label("Categories", systemImage: "dollarsign.circle.fill")
                }
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "banknote")
                }
            
            TransactionListView(payee: nil, account: nil, category: nil)
                .tabItem {
                    Label("Transactions", systemImage: "list.triangle")
                }
            
            PayeeListView()
                .tabItem {
                    Label("Payees", systemImage: "house")
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
        .onAppear {
            createPeriods()
        }
        .preferredColorScheme(.dark) // force the app to start in dark mode, even if the device is configured to light mode
    }
    
//    func clearAllTransactions() {
//        print("Clearing all transactions")
//        if(transactions.count > 0) {
//            for i in 0 ... transactions.count - 1 {
//                viewContext.delete(transactions[i])
//            }
//            PersistenceController.shared.save() // save the changes
//        }
//    }
        
    
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
            
            for year in 2020...2030 {
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
