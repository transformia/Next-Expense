//
//  AddTransactionView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.name, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to select a payee
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to select an account from a picker
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to select a category from a picker
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the transaction
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to calculate the total balance
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    // Attributes that can be defaulted when calling this view:
    let payee: Payee?
    let account: Account
    let category: Category
    
    // Define variables for the new transactions's attributes:
    @State private var date = Date()
    @State private var recurring = false
    @State private var recurrence = ""
    @State private var selectedPayee: Payee?
    @State private var selectedDebtor: Payee?
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedCategory: Category?
    @State private var income = false // tells us the sign of the transaction
    @State private var transfer = false // tells us if this is a transfer between accounts
    @State private var expense = false // tells us if this is an expense that someone will pay back to us later on
    @State private var debtorFilter = ""
    @State private var payeeFilter = ""
    @State private var currency = "EUR"
    @State private var memo = ""
    
    @State private var showingAccountAlert = false
    @State private var showingCategoryAlert = false
    @State private var showingAccountAndCategoryAlert = false
    @State private var showingToAccountAlert = false
    
    class Amount: ObservableObject { // to store the amount and the visibility of the numpad, and allow the numpad view to edit them
        @Published var intAmount = 0
        @Published var showNumpad = false
    }
    
    @StateObject var amount = Amount()
    
//    @ObservedObject var refreshBalances: CategoryListView.RefreshBalances // the object containing the bool that toggles when the balances should be refreshed
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    // Variables determining whether the focus is on the payee or debtor or not:
    @FocusState private var payeeFocused: Bool
    @FocusState private var debtorFocused: Bool
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    // Define available recurrences:
    let recurrences = ["Monthly"]
    
    var body: some View {
        NavigationView { // so that the pickers work
            ZStack(alignment: .bottom) { // Stack the form and the numpad
                Form {
                    Group {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                        
                        Toggle("Recurring", isOn: $recurring)
                        if(recurring) {
                            Picker("Recurrence", selection: $recurrence) {
                                ForEach(recurrences, id: \.self) {
                                    Text($0)
                                }
                            }
                        }
                        
                        Toggle("Transfer", isOn: $transfer)
                            .onChange(of: transfer) { _ in
                                if transfer {
                                    income = false
                                }
                            }
                        
                        if !transfer {
                            Toggle("Expense", isOn: $expense)
                            Toggle("Inflow", isOn: $income)
                        }
                        
                        Text(Double(amount.intAmount) / 100, format: .currency(code: currency))
//                            .foregroundColor(income ? .green : .primary)
                            .foregroundColor(income || (selectedAccount?.type == "External" && selectedToAccount?.type == "Budget") ? .green : .primary) // green for an income, or for a transfer from an external account to a budget account
                            .onTapGesture {
//                                withAnimation {
                                amount.showNumpad = true // display the custom numpad
//                                }
                                payeeFocused = false // in case the payee field is selected, remove focus from it so that the keyboard closes
                            }
                            .onAppear {
                                amount.showNumpad = true // show the numpad by default when creating a new transaction
                            }
                    }
                    Group {
                        if(!transfer) {
                            TextField("Payee", text: $payeeFilter)
                                .onAppear {
                                    selectedPayee = payee // default to the provided value
                                    payeeFilter = payee?.name ?? ""
                                }
                                .focused($payeeFocused)
                                .onTapGesture {
                                    //                                    withAnimation {
                                    amount.showNumpad = false // hide the custom numpad, so I don't need to tap twice to get to the payee
                                    //                                    }
                                }
                            if((payeeFilter != "" && selectedPayee == nil) || (payeeFilter != selectedPayee?.name && payeeFilter != "")) { // display the list of matching payees when I start typing in the text field, until I have selected one. Also do that if I'm trying to modify the payee
                                List(payees.filter({
                                    payeeFilter == "" ? true: $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil // filter based on what is typed
                                }), id: \.self) { payee in
                                    Text(payee.name ?? "")
                                        .onTapGesture {
                                            print("Selected \(payee.name ?? "")")
                                            selectedPayee = payee // select this payee
                                            selectedCategory = payee.category // set the category to this payee's default category
                                            selectedAccount = payee.account // set the account to this payee's default account
                                            payeeFilter = payee.name ?? "" // display the payee in the filter field
                                            payeeFocused = false // hide the keyboard
                                        }
                                }
                            }
                        }
                            
                        if expense {
                            TextField("Debtor", text: $debtorFilter)
                            //                                    .onAppear {
                            //                                        selectedPayee = payee // default to the provided value
                            //                                        payeeFilter = payee?.name ?? ""
                            //                                    }
                                .focused($debtorFocused)
                                .onTapGesture {
                                    //                                    withAnimation {
                                    amount.showNumpad = false // hide the custom numpad, so I don't need to tap twice to get to the debtor
                                    //                                    }
                                }
                            if((debtorFilter != "" && selectedDebtor == nil) || (debtorFilter != selectedDebtor?.name && debtorFilter != "")) { // display the list of matching payees when I start typing in the text field, until I have selected one. Also do that if I'm trying to modify the payee
                                List(payees.filter({
                                    debtorFilter == "" ? true: $0.name?.range(of: debtorFilter, options: .caseInsensitive) != nil // filter based on what is typed
                                }), id: \.self) { payee in
                                    Text(payee.name ?? "")
                                        .onTapGesture {
                                            print("Selected debtor \(payee.name ?? "")")
                                            selectedDebtor = payee // select this payee
                                            //                                                selectedCategory = payee.category // set the category to this payee's default category
                                            //                                                selectedAccount = payee.account // set the account to this payee's default account
                                            debtorFilter = payee.name ?? "" // display the payee in the filter field
                                            debtorFocused = false // hide the keyboard
                                        }
                                }
                            }
                        }
                        
                        if ( (!transfer && selectedAccount?.type == "Budget") || (transfer && selectedAccount?.type != selectedToAccount?.type) ) { // show the category if this is a normal transaction from a budget account, or a transfer between a budget and an external account
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { (category: Category) in
                                    Text(category.name ?? "")
                                        .tag(category as Category?)
                                }
                            }
                            .onAppear {
                                selectedCategory = category // default to the provided value
                                if !transfer {
                                    income = category.type == "Income" ? true : false
                                }
                            }
                            .onChange(of: selectedCategory) { _ in
                                if !transfer {
                                    income = selectedCategory?.type == "Income" ? true : false
                                }
                            }
                        }
                            
                        Picker("Account", selection: $selectedAccount) {
                            ForEach(accounts, id: \.self) { (account: Account) in
                                Text(account.name ?? "")
                                    .tag(account as Account?)
                            }
                        }
                        .onAppear {
                            selectedAccount = account // default to the provided value
                        }
                        .onChange(of: selectedAccount) { _ in
                            currency = selectedAccount?.currency ?? "EUR" // set the currency to the currency of the selected account
                            
                            // If I have selected the same account as the to account, or the accounts now have different currencies, change the to account to another account with the same currency, if there is one:
                            if selectedToAccount == selectedAccount || selectedToAccount?.currency != selectedAccount?.currency {
                                if accounts.filter({$0.currency == selectedAccount?.currency}).count > 2 { // if there are at least 2 accounts with the same currency as the selected from account
                                    if accounts.filter({$0.currency == selectedAccount?.currency})[0] != selectedAccount {
                                        selectedToAccount = accounts.filter({$0.currency == selectedAccount?.currency})[0] // if the first account with the same currency is different from the from account, select it
                                    }
                                    else {
                                        selectedToAccount = accounts.filter({$0.currency == selectedAccount?.currency})[1] // else select the second one
                                    }
                                }
                            }
                        }
                        
                        if(transfer) {
                            Picker("To account", selection: $selectedToAccount) {
                                ForEach(accounts, id: \.self) { (account: Account) in
                                    if account.currency == selectedAccount?.currency && account != selectedAccount { // only show destination accounts with the same currency as the selected from account, and don't show the one that is selected in the from account
                                        Text(account.name ?? "")
                                            .tag(account as Account?)
                                    }
                                }
                            }
                            .onAppear {
                                // If there are at least 2 accounts with the same currency as the from account, select a different one as the to account:
                                if accounts.filter({$0.currency == selectedAccount?.currency}).count > 1 { // if there are at least 2 accounts with the same currency as the selected from account
                                    if accounts.filter({$0.currency == selectedAccount?.currency})[0] != selectedAccount {
                                        selectedToAccount = accounts.filter({$0.currency == selectedAccount?.currency})[0] // if the first account with the same currency is different from the from account, select it
                                    }
                                    else {
                                        selectedToAccount = accounts.filter({$0.currency == selectedAccount?.currency})[1] // else select the second one
                                    }
                                }
                            }
                            // NOT NEEDED BECAUSE I CANNOT SELECT A TO ACCOUNT WITH A DIFFERENT CURRENCY, NOR THE SAME AS THE FROM ACCOUNT:
//                            .onChange(of: selectedToAccount) { _ in
//                                // If I have selected the same account as the from account, or the accounts now have different currencies, change the from account to another account with the same currency, if there is one:
//                                if selectedToAccount == selectedAccount || selectedToAccount?.currency != selectedAccount?.currency {
//                                    if accounts.filter({$0.currency == selectedToAccount?.currency}).count > 1 { // if there are at least 2 accounts with the same currency as the selected to account
//                                        if accounts.filter({$0.currency == selectedToAccount?.currency})[0] != selectedToAccount {
//                                            selectedAccount = accounts.filter({$0.currency == selectedToAccount?.currency})[0] // if the first account with the same currency is different from the to account, select it
//                                        }
//                                        else {
//                                            selectedAccount = accounts.filter({$0.currency == selectedToAccount?.currency})[1] // else select the second one
//                                        }
//                                    }
//                                }
//                            }
                        }
                        
//                        Picker("Currency", selection: $currency) {
//                            ForEach(currencies, id: \.self) {
//                                Text($0)
//                            }
//                        }
//                        .onAppear {
//                            currency = selectedAccount?.currency ?? "EUR" // set the currency to the currency of the selected account
//                        }
                        
                        TextField("Memo", text: $memo)
                        createTransactionButton
                    }
                    //                if(amount.isFocused) { // if the amount field has the focus, display the numpad
                    //                    NumpadView(amount: amount)
                    //                }
                }
                //            .toolbar {
                //                ToolbarItemGroup(placement: .keyboard) {
                //                    Spacer()
                //                    createTransactionButton
                //                    Spacer()
                //                    Button("Done") {
                //                        amount.isFocused = false
                //                    }
                //                }
                //            }
                
                if(amount.showNumpad) {
                    NumpadView(amount: amount)
                        .frame(height: 300, alignment: .bottom)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
//                        .transition(.move(edge: .bottom))
                }
                
            } // end of ZStack
            .ignoresSafeArea()
        }
//        .sheet(isPresented: $showNumpad) {
//            NumpadView(amount: amount)
//                .presentationDetents([.height(280)])
//        }
    }
    
    var createTransactionButton: some View {
        Button(action: {
            
            // If the account and the to account are identical, or the two accounts have different currencies, show an alert:
            if selectedAccount == selectedToAccount || selectedAccount?.currency != selectedToAccount?.currency {
                showingToAccountAlert = true
            }
            
            else if(selectedAccount == nil) { // if no valid account has been selected, show an alert
                showingAccountAlert = true
            }
            
            else if selectedCategory == nil && ( (!transfer && selectedAccount?.type == "Budget") || (transfer && selectedAccount?.type != selectedToAccount?.type) ) { // if no valid category has been selected, and this is a transaction that requires a category, show an alert
                showingCategoryAlert = true
            }
            
            else if selectedAccount == nil && selectedCategory == nil {
                showingAccountAndCategoryAlert = true
            }
            
            else { // if a valid account and category have been selected, create and save the transaction
                
                // Create a new payee if necessary:
                if((payeeFilter != "" && selectedPayee == nil) || (payeeFilter != selectedPayee?.name && payeeFilter != "")) { // if a payee has been entered, but none has been selected, create a new payee. Also do that if I selected a payee, then changed my mind and typed a completely new one
                    let payee = Payee(context: viewContext)
                    payee.id = UUID()
                    payee.name = payeeFilter
                    payee.category = selectedCategory
                    payee.account = selectedAccount
                    selectedPayee = payee
                }
                
                // Else change the default account and category of the payee:
                else if(selectedPayee != nil) {
                    selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
                    selectedPayee?.account = selectedAccount // if a payee has been selected, change its default account to the one I used this time
                }
                
                // Create a new payee for the debtor if necessary:
                if((debtorFilter != "" && selectedDebtor == nil) || (debtorFilter != selectedDebtor?.name && debtorFilter != "")) { // if a debtor has been entered, but none has been selected, create a new payee. Also do that if I selected a debtor, then changed my mind and typed a completely new one
                    let payee = Payee(context: viewContext)
                    payee.id = UUID()
                    payee.name = debtorFilter
                    selectedDebtor = payee
                }
                
                // Before I create the transaction, save the current remaining budget so that it can be displayed after:
                periodBalances.remainingBudgetBefore = selectedCategory?.calcRemainingBudget(period: selectedPeriod.period) ?? 0.0
                
                // Create and populate the transaction:
                let transaction = Transaction(context: viewContext)
                
                // If the transaction is recurring, and its date is in the past, create the recurring transaction one recurrence period in the future, and also create a non-recurring transaction on the selected date:
                if(recurring && date < Date()) {
                    let nextRecurrenceDate = Calendar.current.date(byAdding: .month, value: 1, to: date) // increment the recurring transaction's date by one recurrence period
                    let period = getPeriod(date: nextRecurrenceDate ?? Date())
                    
//                    transaction.populate(date: nextRecurrenceDate ?? Date(), period: period, recurring: recurring, recurrence: recurrence, income: income, amount: amount.intAmount, currency: currency, payee: selectedPayee, category: selectedCategory, account: selectedAccount ?? Account(), transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, memo: memo)
                    
                    transaction.populate(account: selectedAccount ?? Account(), date: nextRecurrenceDate ?? Date(), period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                    
                    // Create a non-recurring transaction on the selected date:
                    let transaction2 = Transaction(context: viewContext)
                    let period2 = getPeriod(date: date)
                    
//                    transaction2.populate(date: date, period: period2, recurring: false, recurrence: "", income: income, amount: amount.intAmount, currency: currency, payee: selectedPayee, category: selectedCategory, account: selectedAccount ?? Account(), transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, memo: memo)
                    
                    transaction2.populate(account: selectedAccount ?? Account(), date: date, period: period2, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: false, recurrence: "")
                }
                
                // Else if the transaction is not recurring, or it is due in the future, just create the transaction:
                else {
                    let period = getPeriod(date: date)
                    
                    transaction.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                    
//                    transaction.populate(date: date, period: period, recurring: recurring, recurrence: recurrence, income: income, amount: amount.intAmount, currency: currency, payee: selectedPayee, category: selectedCategory, account: selectedAccount ?? Account(), transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, memo: memo)
                }
                
                
                
                
                /*
                transaction.id = UUID()
                transaction.timestamp = Date()
                if(recurring && date < Date()) {
                    transaction.date = Calendar.current.date(byAdding: .month, value: 1, to: transaction.date ?? Date()) // increment the recurring transaction's date
                    transaction.period = getPeriod(date: transaction.date ?? Date())
                }
                else {
                    transaction.date = date
                    transaction.period = getPeriod(date: date)
                }
                transaction.recurring = recurring
                transaction.recurrence = recurrence
                transaction.payee = selectedPayee
                if(!transfer) { // so that I don't get any category on transfers
                    transaction.category = selectedCategory
                }
                transaction.expense = expense
                if expense {
                    transaction.debtor = selectedDebtor
                }
                transaction.amount = Int64(amount.intAmount) // save amount as an int, i.e. 2560 means 25,60€ for example
                transaction.income = income // save the direction of the transaction, true for an income, false for an expense
                transaction.transfer = transfer // save the information of whether or not this is a transfer
                transaction.currency = currency
                transaction.memo = memo
                transaction.account = selectedAccount
                if(transfer) {
                    transaction.toaccount = selectedToAccount
                }
                
                if(recurring) { // if this is a recurring transaction
                    if(date < Date()) { // if the recurring transaction has a date today or in the past
                        
                        // Create a non-recurring transaction on the selected date:
                        let transaction2 = Transaction(context: viewContext)

                        transaction2.id = UUID()
                        transaction2.timestamp = Date()
                        transaction2.date = date
                        transaction2.period = getPeriod(date: date)
                        transaction2.payee = selectedPayee
                        if(!transfer) { // so that I don't get any category on transfers
                            transaction2.category = selectedCategory
                        }
                        transaction2.expense = expense
                        if expense {
                            transaction2.debtor = selectedDebtor
                        }
                        transaction2.amount = Int64(amount.intAmount) // save amount as an int, i.e. 2560 means 25,60€ for example
                        transaction2.income = income // save the direction of the transaction, true for an income, false for an expense
                        transaction2.transfer = transfer // save the information of whether or not this is a transfer
                        transaction2.currency = currency
                        transaction2.memo = memo
                        transaction2.account = selectedAccount
                        if(transfer) {
                            transaction2.toaccount = selectedToAccount
                        }
                    }
                }
                */
                
                PersistenceController.shared.save() // save the item
                
                // Calculate the period balances - done in MiniReportingView and AddTransactionView:
                (periodBalances.incomeActual, periodBalances.expensesActual) = selectedPeriod.period.calcBalances()
                
                // Calculate the total balance - done in MiniReportingView and AddTransactionView:
                periodBalances.totalBalance = 0.0
                let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
                // Set the date to today if the current period is selected, or the end of the period if a past or future period is selected:
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
                
                print("Calculating total balance as of \(consideredDate)")
                for account in accounts {
                    if account.type == "Budget" { // ignore external accounts
                        if account.currency == defaultCurrency {
                            periodBalances.totalBalance += Double(account.calcBalance(toDate: Date()))
                        }
                        else { // for accounts in a different currency, add the amount converted to the default currency using the selected period's exchange rate, if there is one, otherwise add 0
                            if let fxRate = selectedPeriod.period.getFxRate(currency1: defaultCurrency, currency2: account.currency ?? "") {
                                periodBalances.totalBalance += Double(account.calcBalance(toDate: consideredDate)) / fxRate * 100.0
                            }
                        }
                    }
                }
                
//                periodBalances.incomeActual = monthlyBalances().0
//                periodBalances.expensesActual = monthlyBalances().1
//                periodBalances.totalBalance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
                
                // Save the information required to show the category balance animation, except for income transactions, and for transfers between accounts of the same type:
                if !income && !(transfer && selectedAccount?.type == selectedToAccount?.type) {
                    periodBalances.category = selectedCategory ?? Category()
                    periodBalances.showBalanceAnimation = true
                }
                
                dismiss() // dismiss this view
            }
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
        .alert("Please select an account", isPresented: $showingAccountAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select a category", isPresented: $showingCategoryAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select an account and a category", isPresented: $showingAccountAndCategoryAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select two different accounts with the same currency", isPresented: $showingToAccountAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
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
}

//struct AddTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddTransactionView()
//    }
//}
