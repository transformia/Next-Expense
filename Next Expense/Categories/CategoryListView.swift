//
//  CategoryListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct CategoryListView: View {
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
    private var periods: FetchedResults<Period> // to be able to select the active period
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Budget.id, ascending: true)],
        animation: .default)
    private var budgets: FetchedResults<Budget> // to be able to calculate the budget per category
    
    @State private var addCategoryView = false // determines whether that view is displayed or not
    
    @State private var addTransactionView = false // determines whether that view is displayed or not
    
    @State private var period = Period() // period (month) selected in the picker
    
    class SelectedPeriod: ObservableObject {
        @Published var period = Period()
        @Published var periodStartDate = Date()
        @Published var periodChangedManually = false // detects whether the user has changed period manually, so that the onAppear doesn't reset the period to today's period once it has been changed
    }
    @StateObject var selectedPeriod = SelectedPeriod() // period visible from other views
    
    var body: some View {
        NavigationView {
            VStack {
                
                HStack {
                    previousPeriod
                    
                    Picker("Period", selection: $period) {
                        ForEach(periods, id: \.self) { period in
                            Text(period.startdate ?? Date(), formatter: dateFormatter)
//                            HStack {
//                                Text(period.monthString ?? "Jan")
//                                Text("\(period.year)")
//                            }
//                            Text("\(period.monthString ?? "Jan") \(period.year, formatter: dateFormatter)")
                        }
                    }
                    .onAppear {
                        if(!selectedPeriod.periodChangedManually) { // if the user hasn't modified the period manually yet
                            period = getTodaysPeriod() // set the period selected in the picker to today's period
                        }
                        selectedPeriod.period = period // set the period value visible from other view to the value chosen in the picker
                        selectedPeriod.periodStartDate = period.startdate ?? Date()
                    }
                    .onChange(of: period) { _ in
                        selectedPeriod.period = period // set the period value visible from other view to the value chosen in the picker
                        selectedPeriod.periodStartDate = period.startdate ?? Date()
                        selectedPeriod.periodChangedManually = true // make sure that the period doesnt reset to today's period automatically anymore
                    }
                    
                    nextPeriod
                }
                
                NavigationLink { // link containing the simplified P&L, leading to the ReportingView()
                    ReportingView(selectedPeriod: selectedPeriod)
                } label: {
                    MiniReportingView(selectedPeriod: selectedPeriod)
                }
                .buttonStyle(PlainButtonStyle()) // remove blue color from the link
                
                List {
                    ForEach(categories) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            CategoryView(category: category,selectedPeriod: selectedPeriod)
                        }
                    }
                    .onMove(perform: moveItem)
                }
                .sheet(isPresented: $addCategoryView) {
                    AddCategoryView()
                }
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(payee: nil, account: accounts[0], category: categories[0])
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            addCategoryView.toggle() // show the view where I can add a new element
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                
                Button {
                    if(categories.count > 0 && accounts.count > 0) {
                        addTransactionView.toggle() // show the view where I can add a new element
                    }
                    else {
                        print("You need to create at least one account and one category before you can create a transaction")
                    }
                } label: {
                    Image(systemName: "plus")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(.green)
                        .clipShape(Circle())
                }
                .padding(.bottom, 20.0)
            }
        }
    }
    
    private func getTodaysPeriod() -> Period { // get the period corresponding to today's date
        let year = Calendar.current.dateComponents([.year], from: Date()).year ?? 1900
        let month = Calendar.current.dateComponents([.month], from: Date()).month ?? 1
        
        for period in periods {
            if(period.year == year) {
                if(period.month == month) {
                    return period
                }
            }
        }
        return Period() // if no period is found, return a new one (because I need to return something in all cases)
    }
    
    var previousPeriod: some View {
        Button {
            var year = Calendar.current.dateComponents([.year], from: period.startdate ?? Date()).year ?? 1900
            var month = Calendar.current.dateComponents([.month], from: period.startdate ?? Date()).month ?? 1
            
            // Decrement the month, or the year and the month:
            if(month == 1) {
                year -= 1
                month = 12
            }
            else {
                month -= 1
            }
            
            for periodFound in periods {
                if(periodFound.year == year) {
                    if(periodFound.month == month) {
                        period = periodFound // set the period selected in the picker to the period that was found
                        print(period)
                    }
                }
            }
        } label: {
            Label("", systemImage: "arrowtriangle.left.fill")
        }
    }
    
    var nextPeriod: some View {
        Button {
            var year = Calendar.current.dateComponents([.year], from: period.startdate ?? Date()).year ?? 1900
            var month = Calendar.current.dateComponents([.month], from: period.startdate ?? Date()).month ?? 1
            
            // Increment the month, or the year and the month:
            if(month == 12) {
                year += 1
                month = 1
            }
            else {
                month += 1
            }
            
            for periodFound in periods {
                if(periodFound.year == year) {
                    if(periodFound.month == month) {
                        period = periodFound // set the period selected in the picker to the period that was found
                        print(period)
                    }
                }
            }
        } label: {
            Label("", systemImage: "arrowtriangle.right.fill")
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    private func moveItem(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = categories[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                categories[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            categories[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = categories[destination].order + 1
            let newOrder = categories[destination].order
            while startIndex <= endIndex {
                categories[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            categories[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
}

struct CategoryListView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryListView()
    }
}
