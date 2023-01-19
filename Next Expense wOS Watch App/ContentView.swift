//
//  ContentView.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2022-10-12.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to call AddTransactionView with a default account
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to create periods if none exist yet (only on the first launch of the app
    
    var body: some View {
        
        TabView {
            PayeeList()
            AddTransactionView()
            TransactionListView()
        }
        .tabViewStyle(.page)
        .onAppear {
            createDefaults()
            createPeriods()
        }
    }
    
    // NECESSARY FOR THE SIMULATOR TO WORK:
    func createDefaults() { // Create a default account and category on startup if there aren't any
        if(categories.count == 0) {
            let category = Category(context: viewContext)
            
            category.id = UUID()
            category.name = "Default"
            category.type = "Expense"
            category.order = 0
            
            PersistenceController.shared.save() // save the item
        }
        if(accounts.count == 0) {
            let account = Account(context: viewContext)
            
            account.id = UUID()
            account.name = "Default"
            account.currency = "EUR"
            account.order = 1
            
            PersistenceController.shared.save() // save the item
        }
    }
    
    
    // NECESSARY FOR THE SIMULATOR TO WORK, BUT APART FROM THAT, I COULD JUST FORCE THE USER TO RUN THE IPHONE APP FIRST INSTEAD. OR KEEP THIS AS A SAFEGUARD?:
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
