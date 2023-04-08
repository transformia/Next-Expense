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
            ZStack(alignment: .bottom) { // Stack the form, the numpad and the payee or debtor list
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
                            Toggle("Inflow", isOn: $income)
                        }
                        
                        Text(Double(amount.intAmount) / 100, format: .currency(code: currency))
                        //                            .foregroundColor(income ? .green : .primary)
                            .foregroundColor(income || (transfer && selectedAccount?.type == "External" && selectedToAccount?.type == "Budget") ? .green : .primary) // green for an income, or for a transfer from an external account to a budget account
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
                                .focused($payeeFocused)
                                .disableAutocorrection(true)
                                .onAppear {
                                    selectedPayee = payee // default to the provided value
                                    payeeFilter = payee?.name ?? ""
                                }
                                .onSubmit { // if I press enter:
                                    if payeeFocused { // if the payee list is showing, select the first value visible
                                        // If there is at least one value visible, select the first one:
                                        if payees.filter({payeeFilter == "" ? true: $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil}).count > 0 {
                                            selectedPayee = payees.filter({payeeFilter == "" ? true: $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil})[0]
                                            print("Selecting \(selectedPayee?.name ?? "")")
                                            payeeFilter = selectedPayee?.name ?? "" // display the payee in the filter field
                                            selectedCategory = selectedPayee?.category // set the category to this payee's default category
                                            selectedAccount = selectedPayee?.account // set the account to this payee's default account
//                                            payeeFocused = false // close the keyboard
                                        }
                                        
                                        else { // if there is no value matching the filter, create a new payee as long as the filter isn't empty, and select it as a payee
                                            if payeeFilter != "" {
                                                print("Creating new payee \(payeeFilter)")
                                                let payee = Payee(context: viewContext) // create a new payee
                                                payee.id = UUID()
                                                payee.name = payeeFilter
                                                selectedPayee = payee // select the new payee
                                            }
                                        }
                                    }
                                }
                                .onTapGesture {
                                    //                                    withAnimation {
                                    amount.showNumpad = false // hide the custom numpad, so I don't need to tap twice to get to the payee
                                    //                                    }
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
                        
                        if !transfer {
                            Toggle("Expense", isOn: $expense)
                        }
                        
                        if expense {
                            TextField("Debtor", text: $debtorFilter)
                            //                                    .onAppear {
                            //                                        selectedPayee = payee // default to the provided value
                            //                                        payeeFilter = payee?.name ?? ""
                            //                                    }
                                .focused($debtorFocused)
                                .disableAutocorrection(true)
                                .onTapGesture {
                                    //                                    withAnimation {
                                    amount.showNumpad = false // hide the custom numpad, so I don't need to tap twice to get to the debtor
                                    //                                    }
                                }
                                .onSubmit { // if I press enter:
                                    if debtorFocused { // if the debtor list is showing, select the first value visible
                                        // If there is at least one value visible, select the first one:
                                        if payees.filter({debtorFilter == "" ? true: $0.name?.range(of: debtorFilter, options: .caseInsensitive) != nil}).count > 0 {
                                            selectedDebtor = payees.filter({debtorFilter == "" ? true: $0.name?.range(of: debtorFilter, options: .caseInsensitive) != nil})[0]
                                            print("Selecting \(selectedDebtor?.name ?? "")")
                                            debtorFilter = selectedDebtor?.name ?? "" // display the debtor in the filter field
                                        }
                                        else { // if there is no value matching the filter, create a new payee as long as the filter isn't empty, and select it as a debtor
                                            if debtorFilter != "" {
                                                print("Creating new payee \(debtorFilter)")
                                                let payee = Payee(context: viewContext) // create a new payee
                                                payee.id = UUID()
                                                payee.name = debtorFilter
                                                selectedDebtor = payee // select the new debtor
                                            }
                                        }
                                    }
                                }
                        }
                        
                        TextField("Memo", text: $memo)
                        createTransactionButton
                    }
                }
                
                
                // Second element of the ZStack:
                if(payeeFocused) { // if I am trying to select a payee
                    
                    // If there is no payee matching the filter, show the option to create one:
                    if payees.filter({payeeFilter == "" ? true: $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil}).count == 0 {
                        List {
                            Text("New: \(payeeFilter)")
                                .listRowBackground(Color.clear) // remove the grey background from the list items
                                .onTapGesture {
                                    payeeFocused = false // hide the keyboard
                                    if payeeFilter != "" { // create a new payee as long as the filter isn't empty
                                        print("Creating new payee \(payeeFilter)")
                                        let payee = Payee(context: viewContext) // create a new payee
                                        payee.id = UUID()
                                        payee.name = payeeFilter
                                        selectedPayee = payee // select the new payee
                                    }
                                }
                        }
                        .listStyle(PlainListStyle()) // removed padding and background
                        .frame(width: 280, height: 177)
                        .background(.black)
                        .cornerRadius(8)
                        .offset(x: -32, y: -550)
                    }
                    
                    else { // else if there is at least one match, show the matches so that I can select one
                        List(payees.filter({
                            payeeFilter == "" ? true: $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil // filter based on what is typed
                        }), id: \.self) { payee in
                            Text(payee.name ?? "")
                                .listRowBackground(Color.clear) // remove the grey background from the list items
                                .onTapGesture {
                                    print("Selected \(payee.name ?? "")")
                                    selectedPayee = payee // select this payee
                                    selectedCategory = payee.category // set the category to this payee's default category
                                    selectedAccount = payee.account // set the account to this payee's default account
                                    payeeFilter = payee.name ?? "" // display the payee in the filter field
                                    payeeFocused = false // hide the keyboard
                                }
                        }
                        .listStyle(PlainListStyle()) // removed padding and background
                        .frame(width: 280, height: 177)
                        .background(.black)
                        .cornerRadius(8)
                        .offset(x: -32, y: -550)
                    }
                }
                
                // Third element of the ZStack:
                
                
                if(debtorFocused) { // if I am trying to select a debtor
                    
                    // If there is no payee matching the filter, show the option to create one:
                    if payees.filter({debtorFilter == "" ? true: $0.name?.range(of: debtorFilter, options: .caseInsensitive) != nil}).count == 0 {
                        List {
                            Text("New: \(debtorFilter)")
                                .listRowBackground(Color.clear) // remove the grey background from the list items
                                .onTapGesture {
                                    debtorFocused = false // hide the keyboard
                                    if debtorFilter != "" { // create a new debtor as long as the filter isn't empty
                                        print("Creating new payee \(debtorFilter)")
                                        let payee = Payee(context: viewContext) // create a new payee
                                        payee.id = UUID()
                                        payee.name = debtorFilter
                                        selectedDebtor = payee // select the new payee as a debtor
                                    }
                                }
                        }
                        .listStyle(PlainListStyle()) // removed padding and background
                        .frame(width: 280, height: 177)
                        .background(.black)
                        .cornerRadius(8)
                        .offset(x: -32, y: -375)
                    }
                    
                    else { // else if there is at least one match, show the matches so that I can select one
                        List(payees.filter({
                            debtorFilter == "" ? true: $0.name?.range(of: debtorFilter, options: .caseInsensitive) != nil // filter based on what is typed
                        }), id: \.self) { payee in
                            Text(payee.name ?? "")
                                .listRowBackground(Color.clear) // remove the grey background from the list items
                                .onTapGesture {
                                    print("Selected \(payee.name ?? "")")
                                    selectedDebtor = payee // select this payee
                                    debtorFilter = payee.name ?? "" // display the payee in the debtor filter field
                                    debtorFocused = false // hide the keyboard
                                }
                        }
                        .listStyle(PlainListStyle()) // removed padding and background
                        .frame(width: 280, height: 177)
                        .background(.black)
                        .cornerRadius(8)
                        .offset(x: -32, y: -375)
                    }
                }
                
                // Fourth element of the ZStack:
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
            
            // If this is a transfer: if the account and the to account are identical, or the two accounts have different currencies, show an alert:
            if transfer && (selectedAccount == selectedToAccount || selectedAccount?.currency != selectedToAccount?.currency) {
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
                
                // DONE WHEN SELECTING THE PAYEE INSTEAD:
//                // Create a new payee if necessary:
//                if((payeeFilter != "" && selectedPayee == nil) || (payeeFilter != selectedPayee?.name && payeeFilter != "")) { // if a payee has been entered, but none has been selected, create a new payee. Also do that if I selected a payee, then changed my mind and typed a completely new one
//                    let payee = Payee(context: viewContext)
//                    payee.id = UUID()
//                    payee.name = payeeFilter
//                    payee.category = selectedCategory
//                    payee.account = selectedAccount
//                    selectedPayee = payee
//                }
                
                // Change the default account and category of the payee, if one is selected:
                if(selectedPayee != nil) {
                    selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
                    selectedPayee?.account = selectedAccount // if a payee has been selected, change its default account to the one I used this time
                }
                
                // DONE WHEN SELECTING THE DEBTOR INSTEAD:
//                // Create a new payee for the debtor if necessary:
//                if((debtorFilter != "" && selectedDebtor == nil) || (debtorFilter != selectedDebtor?.name && debtorFilter != "")) { // if a debtor has been entered, but none has been selected, create a new payee. Also do that if I selected a debtor, then changed my mind and typed a completely new one
//                    let payee = Payee(context: viewContext)
//                    payee.id = UUID()
//                    payee.name = debtorFilter
//                    selectedDebtor = payee
//                }
                
                // Before I create the transaction, save the current remaining budget for the transaction's period, so that it can be displayed after:
//                periodBalances.remainingBudgetBefore = selectedCategory?.calcRemainingBudget(period: selectedPeriod.period) ?? 0.0
                periodBalances.remainingBudgetBefore = selectedCategory?.calcRemainingBudget(period: getPeriod(date: date)) ?? 0.0
                
                // Create and populate the transaction:
                let transaction = Transaction(context: viewContext)
                
                // If the transaction is recurring, and its date is in the past, create the recurring transaction one recurrence period in the future, and also create a non-recurring transaction on the selected date:
                if(recurring && date < Date()) {
                    let nextRecurrenceDate = Calendar.current.date(byAdding: .month, value: 1, to: date) // increment the recurring transaction's date by one recurrence period
                    let period = getPeriod(date: nextRecurrenceDate ?? Date())
                    
                    transaction.populate(account: selectedAccount ?? Account(), date: nextRecurrenceDate ?? Date(), period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                    
                    // Create a non-recurring transaction on the selected date:
                    let transaction2 = Transaction(context: viewContext)
                    let period2 = getPeriod(date: date)
                    
                    transaction2.populate(account: selectedAccount ?? Account(), date: date, period: period2, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: false, recurrence: "")
                }
                
                // Else if the transaction is not recurring, or it is due in the future, just create the transaction:
                else {
                    let period = getPeriod(date: date)
                    
                    transaction.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                }                
                // Save the information required to show the category balance animation, except for income categories, for transactions on an external account, and for transfers between accounts of the same type:
                if !(selectedCategory?.type == "Income") && !(!transfer && selectedAccount?.type == "External") && !(transfer && selectedAccount?.type == selectedToAccount?.type) {
                    periodBalances.category = selectedCategory ?? Category()
                    periodBalances.showBalanceAnimation = true
                }
                
                // Save the remaining budget of the transaction's category in the transation's period, so that it can be displayed after:
                periodBalances.remainingBudgetAfter = selectedCategory?.calcRemainingBudget(period: getPeriod(date: date)) ?? 0.0
                
                // Update the category, account(s) and period balances based on the new transaction:
                transaction.updateBalances(transactionPeriod: getPeriod(date: date), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
                
                // Update the period balances in the environment object:
                periodBalances.incomeActual = getPeriod(date: date).getBalance()?.incomeactual ?? 0.0
                periodBalances.expensesActual = getPeriod(date: date).getBalance()?.expensesactual ?? 0.0
                
                PersistenceController.shared.save() // save the new transactions, and the balance updates
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
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
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
