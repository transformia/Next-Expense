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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to find the payee corresponding to a string
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to check if a transaction already exists when importing transactions
    
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
    
    
    @State private var lastImportTime = Date(timeIntervalSinceReferenceDate: 0)
    @State private var countSameId = 0
    @State private var countDuplicates = 0
    @State private var countCreated = 0
    
    var body: some View {
        ZStack { // to be able to show an animation on top when a category balances changes
            
            NavigationView {
                VStack {
                    
                    
                    
                    /* Tink buttons for continuous access - only possible once I have a lot of users, after negotiation with Tink
                    Button {
                        TinkService.shared.authorizeApp(scope: "authorization:grant") { success, clientAccessToken in
                            if success {
                                TinkService.shared.getUserAccessToken()
                            }
                        }
                    } label: {
                        Label("Get client then user access token", systemImage: "key")
                    }
                    
                    Button {
                        TinkService.shared.getTransactions() { success, tinkTransactions in
//                            print(tinkTransactions)
//                            print(tinkTransactions[0])
                            
                            createTransactions(tinkTransactions: tinkTransactions)
                        }
                    } label: {
                        Label("Get transactions", systemImage: "key")
                    }
                    
                    HStack {
                        Text("Last import:")
                        Text(lastImportTime, formatter: dateTimeFormatter)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Created:")
                        Text("\(countCreated)")
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Duplicate id:")
                        Text("\(countSameId)")
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Duplicate without id:")
                        Text("\(countDuplicates)")
                    }
                    .padding(.horizontal)
                    */
                    
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
                            
                            // Update the category balances:
                            updateCategoryBalances()
                            
                            // Update the period total balances:
                            updateTotalBalances()
                            
                            // Create the balances that haven't been created yet for this period:
//                            createMissingBalances()
                        }
                        
                        nextPeriod
                    }
                
                    
                    List {
                        
                        HStack {
                            Text("Savings")
                                .font(.headline)
                            Spacer()
                            Text((periodBalances.incomeBudget - periodBalances.expensesBudget) / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Text((periodBalances.incomeActual - periodBalances.expensesActual) / 100, format: .currency(code: "EUR"))
                                .font(.caption)
                        }
                        
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
//                        if(categories.count > 0 && accounts.count > 0) {
                            addTransactionView.toggle() // show the view where I can add a new element
//                        }
//                        else {
//                            print("You need to create at least one account and one category before you can create a transaction")
//                        }
                    } label: {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                            .padding(8)
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
                    TransactionDetailView(transaction: nil, payee: nil, account: nil, category: nil)
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
         
            // Show the balance before and after the transaction:
            CategoryBalanceBubble()
            
            
                
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
    
    private func updateCategoryBalances() { // calculate the category's budget and balance for the selected period, and save it on the category
        print("Updating category balances for the selected period")
        
        for category in categories {
            category.calcBalance(period: selectedPeriod.period) // calculate the total of the selected period's transactions, and save it on the category
            category.getBudget(period: selectedPeriod.period) // fetch the budgeted amount for the selected period
            category.calcRemainingBudget(selectedPeriod: selectedPeriod.period) // calculate the total amount budgeted minus the total amount spent on this category, as of the end of the selected period if the period is fully in the past, otherwise as of today
        }
    }
    
    private func updateTotalBalances() {
        print("Updating the total income and expense actuals and budgets for the period")
        
        
        // Update the total actuals in the environment object:
        periodBalances.incomeActual = 0.0
        periodBalances.expensesActual = 0.0
        for category in categories {
            if category.type == "Income" {
                periodBalances.incomeActual += category.balance * 100
            }
            else if category.type == "Expense" {
                periodBalances.expensesActual -= category.balance * 100
            }
        }
        
        // Update the total budgets in the environment object:
        (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
    }
    
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
    
    private let dateFormatterTink: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
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
    
    // Find the account based on the external id, if it exists:
    private func matchAccount(externalId: String)  -> Account? {
        return accounts.first { $0.externalid == externalId }
    }
    
    private func createTransactions(tinkTransactions: [[String: Any]]) {
        lastImportTime = Date()
        countCreated = 0
        countDuplicates = 0
        countSameId = 0
        
        for tinkTransaction in tinkTransactions {
            
            // Get the account from the external account id:
            guard let externalId = tinkTransaction["accountId"] as? String,
                  let account = matchAccount(externalId: externalId) else {
                // Skip this transaction if the account isn't found
                print("Account not found. Skipping")
                continue
            }
                
//                                print(tinkTransaction)
            
            // Get the provider transaction id:
            guard let identifiers = tinkTransaction["identifiers"] as? [String: Any],
                  let providerTransactionId = identifiers["providerTransactionId"] as? String else {
                // Skip this transaction if it doesn't have a provider transaction id
                print("Provider transaction id not found. Skipping")
                continue
            }
            
            // Check if a transaction with the same provider id already exists on that account:
            if transactions.filter({$0.account == account && $0.externalid == providerTransactionId}).count > 0 {
//                print("Transaction with id \(providerTransactionId) has already been imported. Skipping it")
                countSameId += 1
                continue
            }
            
            // Get the date:
            guard let dates = tinkTransaction["dates"] as? [String: Any],
                  let dateString = dates["booked"] as? String,
                  let date = dateFormatterTink.date(from: dateString) else {
                // Skip this transaction if date information is missing or invalid
                print("Date not found. Skipping")
                continue
            }
            
            // Get the currency and amount:
            guard let amountNode = tinkTransaction["amount"] as? [String: Any],
                  let currencyCode = amountNode["currencyCode"] as? String,
                  let value = amountNode["value"] as? [String: Any],
                  let unscaledValue = value["unscaledValue"] as? String,
                  let amount = Int(unscaledValue) else {
                // Skip this transaction if amount information is missing or invalid
                print("Amount or currency not found. Skipping")
                continue
            }
            
            // Determine if it is an inflow or an outflow, and remove the sign of the amount:
            let income = amount > 0
            let intAmount = abs(amount)
            
            // Get the descriptions:
            guard let descriptions = tinkTransaction["descriptions"] as? [String: Any],
                  let displayDescription = descriptions["display"] as? String,
                  let originalDescription = descriptions["original"] as? String else {
                // Skip this transaction if it doesn't have descriptions
                print("Descriptions not found. Skipping")
                continue
            }
            
            // Determine the payee:
            var payee: Payee? = nil
            
            for existingPayee in payees {
                if(existingPayee.name == displayDescription || existingPayee.name == originalDescription) {
                    payee = existingPayee
                    break
                }
            }
            
            if payee == nil { // if not payee was found, create it
                print("Creating payee ", displayDescription)
                let newPayee = Payee(context: viewContext)
                newPayee.id = UUID()
                newPayee.name = displayDescription
                newPayee.account = account
                payee = newPayee
                PersistenceController.shared.save() // save the new payee, so that another transaction can use it - otherwise it will get created more than once if more than one transaction has it
            }
            
            // Check if a transaction with the same date, sign, payee and amount already exists on the account (in case it was created manually):
            if transactions.filter({$0.account == account && Calendar.current.startOfDay(for: $0.date ?? Date())  == Calendar.current.startOfDay(for: date) && $0.payee == payee && $0.amount == intAmount && $0.income == income}).count > 0 {
//                print("Transaction on account ", account.name ?? "", " on date ", date, " on payee ", displayDescription, " of amount ", intAmount, " already exists. Skipping it")
                countDuplicates += 1
                continue
            }
            
            // Get the status:
            guard let status = tinkTransaction["status"] as? String else {
                // Skip this transaction if it doesn't have a status
                print("Status not found. Skipping")
                continue
            }
            
            // LATER: ALSO GET THE MERCHANT CATEGORY CODE AND NAME, IF THEY ARE PRESENT?
            
            
            
            // Create the transaction
            countCreated += 1
            print("Creating a transaction: ", providerTransactionId, account.name ?? "", date, currencyCode, intAmount, displayDescription, originalDescription, status)
            let transaction = Transaction(context: viewContext)
            transaction.populate(account: account, date: date, period: getPeriod(date: date), payee: payee, category: payee?.category, memo: originalDescription, amount: intAmount, amountTo: 0, currency: currencyCode, income: income, transfer: false, toAccount: nil, expense: false, expenseSettled: false, debtor: nil, recurring: false, recurrence: "", externalId: providerTransactionId, posted: false)
            
            // Update the category, account(s) and period balances based on the new transaction:
            transaction.updateBalances(transactionPeriod: transaction.period ?? Period(), selectedPeriod: selectedPeriod.period, category: payee?.category, account: account, toaccount: nil)
        }
        
        print("Transactions that already exist with the same id: \(countSameId)")
        print("Transactions that seem to be duplicates: \(countDuplicates)")
        print("Transactions created: \(countCreated)")
        PersistenceController.shared.save() // save the new transactions
    }
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
    }
}
