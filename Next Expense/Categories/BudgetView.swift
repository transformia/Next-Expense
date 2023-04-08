//
//  BudgetView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-02-28.
//

import SwiftUI

struct BudgetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryGroup.order, ascending: true)],
        animation: .default)
    private var categoryGroups: FetchedResults<CategoryGroup>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to select the active period
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account>
    
    @State private var tutorialStep = 0 // step in the tutorial. 0 means that it is inactive
    
    @State private var addTransactionView = false // determines whether that view is displayed or not
    @State private var fxRateView = false // determines whether that view is displayed or not
    @State private var settingsView = false // determines whether that view is displayed or not
    @State private var addCategoryView = false // determines whether that view is displayed or not
    @State private var addCategoryGroupView = false // determines whether that view is displayed or not
    @State private var adminView = false // determines whether that view is displayed or not
    
    @State private var period = Period() // period (month) selected in the picker
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment - to be able to show an animation when a category balance changes
    
    var body: some View {
        ZStack { // to be able to show an animation on top when a category balances changes
            
            NavigationView {
                VStack {
                    // Period picker:
                    HStack {
                        previousPeriod
                        
                        Picker("Period", selection: $period) {
                            ForEach(periods, id: \.self) { period in
                                Text(period.startdate ?? Date(), formatter: dateFormatter)
                            }
                        }
                        .onAppear {
                            if(!selectedPeriod.periodChangedManually) { // if the user hasn't modified the period manually yet
                                period = getPeriod(date: Date()) // set the period selected in the picker to today's period
                            }
                            selectedPeriod.period = period // set the period value visible from other view to the value chosen in the picker
                            selectedPeriod.periodStartDate = period.startdate ?? Date()
                        }
                        .onChange(of: period) { _ in
                            selectedPeriod.period = period // set the period value visible from other view to the value chosen in the picker
                            selectedPeriod.periodStartDate = period.startdate ?? Date()
                            selectedPeriod.periodChangedManually = true // make sure that the period doesnt reset to today's period automatically anymore
                            
                            // Update the account, category and period balances:
                            updateBalances()
                            
                            // Create the balances that haven't been created yet for this period:
//                            createMissingBalances()
                        }
                        
                        nextPeriod
                    }
                
                    
                    List {
                        ForEach(categoryGroups) { categoryGroup in
                            HStack {
                                NavigationLink {
                                    CategoryGroupDetailView(categoryGroup: categoryGroup)
                                } label: {
                                    CategoryGroupView(categoryGroup: categoryGroup)
                                }
                            }
                            if categoryGroup.showcategories {
                                ForEach(categories) { category in
                                    if category.categorygroup == categoryGroup {
                                        NavigationLink {
                                            CategoryDetailView(category: category)
                                        } label: {
                                            CategoryView(category: category)
                                        }
                                    }
                                }
                                .onMove(perform: moveItem)
                            }
                        }
                        .onMove(perform: moveGroup)
                        
                        // Categories without a group, if there are any:
                        if categories.filter({$0.categorygroup == nil}).count > 0 {
                            Text("Ungrouped")
                                .font(.headline)
                            ForEach(categories) { category in
                                if category.categorygroup == nil {
                                    NavigationLink {
                                        CategoryDetailView(category: category)
                                    } label: {
                                        CategoryView(category: category)
                                    }
                                }
                            }
                            .onMove(perform: moveItem)
                        }
                        
                        
                        HStack {
                            Text("Total income")
                                .font(.headline)
                            Spacer()
                            Text(periodBalances.incomeBudget / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Text(periodBalances.incomeActual / 100, format: .currency(code: "EUR"))
                            //                        Text((getPeriod(date: Date()).getBalance()?.incomeactual ?? 0.0) / 100, format: .currency(code: "EUR"))
                            //                        Text((period.getBalance()?.incomeactual ?? 0.0) / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Total expenses")
                                .font(.headline)
                            Spacer()
                            Text(periodBalances.expensesBudget / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Text(periodBalances.expensesActual / 100, format: .currency(code: "EUR"))
                            //                        if selectedPeriod.period.getBalance() != nil {
                            //                            Text((selectedPeriod.period.getBalance()?.expensesactual ?? 0.0) / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                            //                        }
                        }
                        
                        HStack {
                            Text("Savings")
                                .font(.headline)
                            Spacer()
                            Text((periodBalances.incomeBudget - periodBalances.expensesBudget) / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Text((periodBalances.incomeActual - periodBalances.expensesActual) / 100, format: .currency(code: "EUR"))
                            //                        if selectedPeriod.period.getBalance() != nil {
                            //                            Text((selectedPeriod.period.getBalance()?.expensesactual ?? 0.0) / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                            //                        }
                        }
                        
                    } // end of List                    
                    .listStyle(PlainListStyle())
//                    .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20)) // reduce side padding of the list items
                    
                    
                    
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
                .navigationTitle("Budget")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $addCategoryView) {
                    AddCategoryView()
                }
                .sheet(isPresented: $addCategoryGroupView) {
                    AddCategoryGroupView()
                }
                .sheet(isPresented: $addTransactionView) {
                    AddTransactionView(payee: nil, account: accounts[0], category: categories[0])
                }
                .sheet(isPresented: $settingsView) {
                    SettingsView()
                }
                .sheet(isPresented: $fxRateView) {
                    FxRateView()
                }
                .sheet(isPresented: $adminView) {
                    AdminView()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        HStack {
                            Button {
                                adminView.toggle()
                            } label: {
                                Image(systemName: "key")
                            }
                            Button {
                                settingsView.toggle()
                            } label: {
                                Image(systemName: "gear")
                            }
                            Button {
                                fxRateView.toggle()
                            } label: {
                                Image(systemName: "dollarsign.arrow.circlepath")
                            }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button {
                                addCategoryView.toggle()
                            } label: {
                                Image(systemName: "plus")
                            }
                            
                            Button {
                                addCategoryGroupView.toggle()
                            } label: {
                                Image(systemName: "g.square")
                            }
                            
                            EditButton()
                        }
                    }
                }
            }
         
            if(periodBalances.showBalanceAnimation) { // show the update of the category balance for x seconds
                if !periodBalances.balanceAfter { // showing the balance before the transaction
                    HStack {
                        Text(periodBalances.category.name ?? "")
                        Text(periodBalances.remainingBudgetBefore / 100, format: .currency(code: "EUR"))
                    }
                    .padding()
                    .foregroundColor(periodBalances.remainingBudgetBefore > 0 ? .black : .white)
                    .bold()
                    .background(periodBalances.remainingBudgetBefore > 0 ? .green : .red)
                    .clipShape(Capsule())
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.50) { // make it change after x seconds
                            periodBalances.balanceAfter = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.00) { // make it disappear after x seconds
                            periodBalances.showBalanceAnimation = false
                            periodBalances.balanceAfter = false
                        }
                    }
                }
                
                else { // showing the balance after the transaction
                    HStack {
                        Text(periodBalances.category.name ?? "")
//                        Text(periodBalances.category.calcRemainingBudget(period: selectedPeriod.period) / 100, format: .currency(code: "EUR"))
                        Text(periodBalances.remainingBudgetAfter / 100, format: .currency(code: "EUR"))
                    }
                    .padding()
                    .foregroundColor(periodBalances.remainingBudgetAfter > 0 ? .black : .white)
                    .bold()
                    .background(periodBalances.remainingBudgetAfter > 0 ? .green : .red)
                    .clipShape(Capsule())
                }
            }
            
            
                
            if tutorialStep > 0 { // if I haven't created an account yet, show me the tutorial
                VStack {
                    
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 25, height: 25)
                        Text("Tutorial \(tutorialStep) / 3")
                            .font(.title)
                    }
                    switch tutorialStep {
                    case 1:
                        Text("This is the budget view, where you can track your income and expenses in each category")
//                            .font(.headline)
                            .onTapGesture {
                                withAnimation {
                                    tutorialStep += 1
                                }
                            }
                    case 2:
                        Text("You will be able to personalize this to your liking. But first, let's get started by creating your first account")
//                            .font(.headline)
                            .onTapGesture {
                                withAnimation {
                                    tutorialStep += 1
                                }
                            }
                    case 3:
                        Text("Tap on the Accounts button at the bottom to go to your account list")
//                            .font(.headline)
                            .onTapGesture {
                                withAnimation {
                                    tutorialStep = 0
                                }
                            }
                    default:
                        Text("Invalid tutorial state")
                    }
                    HStack {
                        Image(systemName: tutorialStep == 1 ? "circle.fill" : "circle")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .onTapGesture {
                                withAnimation {
                                    tutorialStep = 1
                                }
                            }
                        Image(systemName: tutorialStep == 2 ? "circle.fill" : "circle")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .onTapGesture {
                                withAnimation {
                                    tutorialStep = 2
                                }
                            }
                        Image(systemName: tutorialStep == 3 ? "circle.fill" : "circle")
                            .resizable()
                            .frame(width: 10, height: 10)
                            .onTapGesture {
                                withAnimation {
                                    tutorialStep = 3
                                }
                            }
                    }
                }
                .padding()
                .frame(width: 300, height: 175)
                .background(.black)
                .cornerRadius(10)
            }
            
        } // end of ZStack
        .onAppear {
            if accounts.count == 0 { // if there are no accounts yet, show the first step of the tutorial
                tutorialStep = 1
            }
        }
    }
    
    private func updateBalances() { // update the balance of each category for this period, of each account for today, and the period balances
        
        print("Updating category, account and period balances")
        
        // Category balances:
        for category in categories {
            if category.getBalance(period: selectedPeriod.period) == nil { // if there is no balance yet, create it
                let categorybalance = Balance(context: viewContext)
                categorybalance.populate(type: "categorybalance", amount: category.calcBalance(period: selectedPeriod.period).0 , period: selectedPeriod.period, account: nil, category: category)
                categorybalance.populate(type: "categorybalancetotal", amount: category.calcBalance(period: selectedPeriod.period).1 , period: selectedPeriod.period, account: nil, category: category)
            }
            else { // if there is already a balance, update it
                let categorybalance = category.getBalance(period: selectedPeriod.period)
                categorybalance?.populate(type: "categorybalance", amount: category.calcBalance(period: selectedPeriod.period).0 , period: selectedPeriod.period, account: nil, category: category)
                categorybalance?.populate(type: "categorybalancetotal", amount: category.calcBalance(period: selectedPeriod.period).1 , period: selectedPeriod.period, account: nil, category: category)
            }
        }
        
        // Account balances:
        var consideredDate: Date
        if selectedPeriod.period == getPeriod(date: Date()) {
            consideredDate = Date()
        }
        else {
            var components = DateComponents()
            components.year = Int(selectedPeriod.period.year)
            components.month = Int(selectedPeriod.period.month) + 1
            components.day = 1
            consideredDate = Calendar.current.startOfDay(for: Calendar.current.date(from: components) ?? Date())
        }
        
        for account in accounts {
            if account.getBalance(period: selectedPeriod.period) == nil { // if there is no balance yet, create it
                let accountbalance = Balance(context: viewContext)
                accountbalance.populate(type: "accountbalance", amount: account.calcBalance(toDate: consideredDate), period: selectedPeriod.period, account: account, category: nil)
            }
            else { // if there is already a balance, update it
                let accountbalance = account.getBalance(period: selectedPeriod.period)
                accountbalance?.populate(type: "accountbalance", amount: account.calcBalance(toDate: consideredDate), period: selectedPeriod.period, account: account, category: nil)
            }
        }
        // Period balances:
        let periodBalance = selectedPeriod.period.getBalance()
        if periodBalance == nil {  // if there is no balance yet, create it
            let periodBalance = Balance(context: viewContext)
            let (incomeactual, expensesactual) = selectedPeriod.period.calcBalances()
            periodBalance.populate(type: "incomeactual", amount: incomeactual, period: selectedPeriod.period, account: nil, category: nil)
            periodBalance.populate(type: "expensesactual", amount: expensesactual, period: selectedPeriod.period, account: nil, category: nil)            
        }
        else { // if there is already a balance, update it
            let periodBalance = selectedPeriod.period.getBalance()
            let (incomeactual, expensesactual) = selectedPeriod.period.calcBalances()
            periodBalance?.populate(type: "incomeactual", amount: incomeactual, period: selectedPeriod.period, account: nil, category: nil)
            periodBalance?.populate(type: "expensesactual", amount: expensesactual, period: selectedPeriod.period, account: nil, category: nil)
        }
        
        PersistenceController.shared.save() // save the new balances
        
        // Update the actual and budget balances in the environment object:
        let periodBalance2 = selectedPeriod.period.getBalance()
        periodBalances.incomeActual = periodBalance2?.incomeactual ?? 0.0
        periodBalances.expensesActual = periodBalance2?.expensesactual ?? 0.0
        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
    }
    
    /*
    private func createMissingBalances() {
        // Create the balances that haven't been created yet for this period:
        
        // Category balances:
        for category in categories {
            if category.getBalance(period: selectedPeriod.period) == nil {
                let categorybalance = Balance(context: viewContext)
                categorybalance.populate(type: "categorybalance", amount: category.calcBalance(period: selectedPeriod.period) , period: selectedPeriod.period, account: nil, category: category)
            }
        }
        
        // Account balances:
        var consideredDate: Date
        if selectedPeriod.period == getPeriod(date: Date()) {
            consideredDate = Date()
        }
        else {
            var components = DateComponents()
            components.year = Int(selectedPeriod.period.year)
            components.month = Int(selectedPeriod.period.month) + 1
            components.day = 1
            consideredDate = Calendar.current.startOfDay(for: Calendar.current.date(from: components) ?? Date())
        }
        
        for account in accounts {
            if account.getBalance(period: selectedPeriod.period) == nil {
                let accountbalance = Balance(context: viewContext)
                accountbalance.populate(type: "accountbalance", amount: account.calcBalance(toDate: consideredDate), period: selectedPeriod.period, account: account, category: nil)
            }
        }
        // Period balance:
        let incomeexpensesactual = selectedPeriod.period.getBalance()
        if incomeexpensesactual == nil {
            let incomeexpensesactual = Balance(context: viewContext)
            let (incomeactual, expensesactual) = selectedPeriod.period.calcBalances()
            incomeexpensesactual.populate(type: "incomeactual", amount: incomeactual, period: selectedPeriod.period, account: nil, category: nil)
            incomeexpensesactual.populate(type: "expensesactual", amount: expensesactual, period: selectedPeriod.period, account: nil, category: nil)
        }
        
        PersistenceController.shared.save() // save the new balances
        
        // Update the actual and budget balances in the environment object:
        let periodBalance = selectedPeriod.period.getBalance()
        periodBalances.incomeActual = periodBalance?.incomeactual ?? 0.0
        periodBalances.expensesActual = periodBalance?.expensesactual ?? 0.0
        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
    }
    */
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, BudgetView, ...?
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
//                        print(period)
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
//                        print(period)
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
    
    private func moveGroup(at sets:IndexSet, destination: Int) {
        let itemToMove = sets.first!
        
        // If the item is moving down:
        if itemToMove < destination {
            var startIndex = itemToMove + 1
            let endIndex = destination - 1
            var startOrder = categoryGroups[itemToMove].order
            // Change the order of all tasks between the task to move and the destination:
            while startIndex <= endIndex {
                categoryGroups[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            categoryGroups[itemToMove].order = startOrder // set the moved task's order to its final value
        }
        
        // Else if the item is moving up:
        else if itemToMove > destination {
            var startIndex = destination
            let endIndex = itemToMove - 1
            var startOrder = categoryGroups[destination].order + 1
            let newOrder = categoryGroups[destination].order
            while startIndex <= endIndex {
                categoryGroups[startIndex].order = startOrder
                startOrder += 1
                startIndex += 1
            }
            categoryGroups[itemToMove].order = newOrder // set the moved task's order to its final value
        }
        
        PersistenceController.shared.save() // save the item
    }
    
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
    }
}
