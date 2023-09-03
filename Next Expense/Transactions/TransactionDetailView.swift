//
//  TransactionDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.order, ascending: true)],
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
    
    let transaction: Transaction? // transaction to display - nil if this is a new transaction
    
    // Attributes that can be defaulted when calling this view to add a transaction:
    let payee: Payee?
    let account: Account?
    let category: Category?
    
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
    @State private var expenseSettled = false // tells us if this expense has been settled already
    @State private var debtorFilter = ""
    @State private var payeeFilter = ""
    @State private var currency = "EUR"
    @State private var memo = ""
    
    @State private var showingDeleteAlert = false
    @State private var showingNoAccountsAlert = false
    @State private var showingNoCategoriesAlert = false
    @State private var showingAccountAlert = false
    @State private var showingCategoryAlert = false
    @State private var showingAccountAndCategoryAlert = false
    @State private var showingToAccountAlert = false
    
    class Amount: ObservableObject { // to store the amount and the visibility of the numpad, and allow the numpad view to edit them
        @Published var intAmount = 0
        @Published var intAmountTo = 0
        @Published var editingAmountTo = false // true if editing the to amount, false if editing the amount
        @Published var showNumpad = false
        @Published var currency = "EUR"
    }
    
    @StateObject var amount = Amount()
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    // Variables determining whether the focus is on the payee or debtor or not:
    @FocusState private var payeeFocused: Bool
    @FocusState private var debtorFocused: Bool
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    // Define available recurrences:
    let recurrences = ["Monthly"]
    
    let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
    
    var body: some View {
        NavigationView { // so that the pickers work
            ZStack(alignment: .bottom) { // Stack the form, the numpad and the payee or debtor list
                VStack {
                    
                    HStack {
                        dismissViewButton
                        Spacer()
                        if transaction != nil { // if this is an existing transaction
                            deleteButton
                            Spacer()
                        }
                        saveButton
                    }
                    .padding([.top, .leading, .trailing])
                    
                    Form {
                        Group {
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .onAppear {
                                    if transaction == nil { // if this is a new transaction...
                                        
                                        if categories.count == 0 {
                                            showingNoCategoriesAlert = true
                                        }
                                        else if accounts.count == 0 {
                                            showingNoAccountsAlert = true
                                        }
                                        else {
//                                            payeeFocused = true // focus on the payee so that I can start typing a payee
                                            amount.showNumpad = true // show the numpad by default when creating a new transaction
                                            amount.currency = selectedAccount?.currency ?? "EUR"
                                            selectedPayee = payee // default to the provided payee if there is one, otherwise leave it blank
                                            payeeFilter = payee?.name ?? ""// default to the provided payee if there is one, otherwise leave it blank
                                            if payee != nil { // if a payee is provided, default the category and the account based on it
                                                selectedCategory = payee?.category
                                                selectedAccount = payee?.account
                                            }
                                            else { // if no payee is provided, default the category and account to the provided ones, or the first ones if none are provided
                                                selectedCategory = category ?? categories[0] // default to the provided value, or the first category
                                                //                                                print("Selecting category \(category?.name)")
                                                selectedAccount = account ?? accounts[0] // default to the provided value, or the first account, so that it doesn't default to nil
                                                //                                                print("Selecting account \(account?.name)")
                                            }
                                            income = category?.type == "Income" ? true : false
                                            if accounts.count > 1 {
                                                selectedToAccount = accounts[1] // set a default to account, so that it doesn't default to nil
                                            }
                                        }
                                    }
                                    else { // else if this is an existing transaction, load its values
                                        date = transaction?.date ?? Date()
                                        recurring = transaction?.recurring == true
                                        recurrence = transaction?.recurrence ?? "Monthly"
                                        income = transaction?.income == true
                                        transfer = transaction?.transfer == true
                                        amount.intAmount = Int(transaction?.amount ?? 0)
                                        amount.intAmountTo = Int(transaction?.amountto ?? 0)
                                        payeeFilter = transaction?.payee?.name ?? ""
                                        selectedPayee = transaction?.payee
                                        selectedCategory = transaction?.category
                                        selectedAccount = transaction?.account
                                        if transaction?.transfer == true {
                                            selectedToAccount = transaction?.toaccount
//                                            print("Setting the to account to \(selectedToAccount)")
                                        }
                                        expense = transaction?.expense == true
                                        expenseSettled = transaction?.expensesettled == true
                                        debtorFilter = transaction?.debtor?.name ?? ""
                                        selectedDebtor = transaction?.debtor
                                        memo = transaction?.memo ?? ""
                                    }
                                }
                                .alert("You need to create at least one account before you can create a transaction", isPresented: $showingNoAccountsAlert) {
                                    Button("OK", role: .cancel) { }
                                }
                                .alert("You need to create at least one category before you can create a transaction", isPresented: $showingNoCategoriesAlert) {
                                    Button("OK", role: .cancel) { }
                                }
                            
                            // Amount of the transaction:
                            HStack {
                                Text("Amount")
                                Spacer()
                                
                                Text(Double(amount.intAmount) / 100, format: .currency(code: currency))
                                    .bold()
                                    .foregroundColor(income || (transfer && selectedAccount?.type == "External" && selectedToAccount?.type == "Budget") ? .green : .primary) // green for an income, or for a transfer from an external account to a budget account
                                    .onTapGesture {
                                        //                                withAnimation {
                                        amount.editingAmountTo = false
                                        amount.showNumpad = true // display the custom numpad
                                        amount.currency = selectedAccount?.currency ?? "EUR"
                                        //                                }
                                        payeeFocused = false // in case the payee field is selected, remove focus from it so that the keyboard closes
                                    }
                                    .onChange(of: amount.showNumpad) { _ in
                                        if !amount.showNumpad && selectedPayee == nil && !transfer { // when I hide the numpad, focus on the payee to open the keyboard if there is no payee selected yet, and this is not a transfer
                                            payeeFocused = true
                                        }
                                    }
                                
                                Spacer()
                            }
                            
                            // Amount received by the to account if it has a different currency from the from account:
                            if transfer && selectedAccount?.currency != selectedToAccount?.currency {
                                HStack {
                                    Text("Amount received")
                                    Spacer()

                                    Text(Double(amount.intAmountTo) / 100, format: .currency(code: selectedToAccount?.currency ?? defaultCurrency))
                                        .bold()
                                        .foregroundColor(income || (transfer && selectedAccount?.type == "External" && selectedToAccount?.type == "Budget") ? .green : .primary) // green for an income, or for a transfer from an external account to a budget account
                                        .onTapGesture {
                                            //                                withAnimation {
                                            amount.editingAmountTo = true
                                            amount.showNumpad = true // display the custom numpad
                                            amount.currency = selectedToAccount?.currency ?? "EUR"
                                            //                                }
                                            payeeFocused = false // in case the payee field is selected, remove focus from it so that the keyboard closes
                                        }
                                        .onChange(of: amount.showNumpad) { _ in
                                            if !amount.showNumpad && selectedPayee == nil && !transfer { // when I hide the numpad, focus on the payee to open the keyboard if there is no payee selected yet, and this is not a transfer
                                                payeeFocused = true
                                            }
                                        }

                                    Spacer()
                                }
                            }
                        }
                        Group {
                            if(!transfer) {
                                if selectedPayee == nil { // if no payee is selected, show a text field to filter on them
                                    TextField("Payee", text: $payeeFilter)
                                        .focused($payeeFocused)
                                        .disableAutocorrection(true)
                                        .onSubmit { // if I press enter:
                                            if payeeFocused { // if the payee list is showing, select the first value visible
                                                // If there is at least one value visible, select the first one based on the filter:
                                                if payees.filter({payeeFilter == "" ? true: $0.name?.lowercased().starts(with: payeeFilter.lowercased()) ?? false}).count > 0 {
                                                    selectedPayee = payees.filter({payeeFilter == "" ? true: $0.name?.lowercased().starts(with: payeeFilter.lowercased()) ?? false})[0]
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
                                                        payee.order = payees.last?.order ?? 0 + 1
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
                                else { // if a payee is already selected, show it as text, and tap on it to remove it
                                    Text(payeeFilter)
                                        .onTapGesture {
                                            selectedPayee = nil
                                            payeeFilter = ""
                                            payeeFocused = true // show the keyboard again
                                        }
                                }
                            }
                            
                            if ( (!transfer && selectedAccount?.type == "Budget") || (transfer && selectedAccount?.type != selectedToAccount?.type)  ) { // show the category this is a normal transaction from a budget account, or a transfer between a budget and an external account
                                Picker("Category", selection: $selectedCategory) {
                                    ForEach(categories, id: \.self) { (category: Category) in
                                        Text(category.name ?? "")
                                            .tag(category as Category?)
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
                            .onChange(of: selectedAccount) { _ in
                                currency = selectedAccount?.currency ?? "EUR" // set the currency to the currency of the selected account
                                
                                // If I have selected the same account as the to account, change the to account to another account with the same currency, if there is one:
                                if selectedToAccount == selectedAccount {
                                    if accounts.count > 2 { // if there are at least 2 accounts
                                        if accounts.filter({$0.currency == selectedAccount?.currency})[0] != selectedAccount {
                                            selectedToAccount = accounts[0] // if the first account found is different from the from account, select it
                                        }
                                        else {
                                            selectedToAccount = accounts[1] // else select the second one
                                        }
                                    }
                                }
                            }
                            
                            if(transfer) {
                                Picker("To account", selection: $selectedToAccount) {
                                    ForEach(accounts, id: \.self) { (account: Account) in
//                                        if account.currency == selectedAccount?.currency && account != selectedAccount { // only show destination accounts with the same currency as the selected from account, and don't show the one that is selected in the from account
                                        if account != selectedAccount { // don't show the account that is selected in the from account
                                            Text(account.name ?? "")
                                                .tag(account as Account?)
                                        }
                                    }
                                }
                                .onAppear {
                                    // If there are at least 2 accounts, select a different one as the to account:
                                    if accounts.count > 1 {
//                                    // If there are at least 2 accounts with the same currency as the from account, select a different one as the to account:
//                                    if accounts.filter({$0.currency == selectedAccount?.currency}).count > 1 { // if there are at least 2 accounts with the same currency as the selected from account
                                        if selectedAccount == selectedToAccount { // if the from account and the to account are the same
                                            if accounts.filter({$0.currency == selectedAccount?.currency})[0] != selectedAccount {
                                                selectedToAccount = accounts.filter({$0.currency == selectedAccount?.currency})[0] // if the first account with the same currency is different from the from account, select it
                                            }
                                            else {
                                                selectedToAccount = accounts.filter({$0.currency == selectedAccount?.currency})[1] // else select the second one
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Group {
                                TextField("Memo", text: $memo)
                                
                                if !transfer {
                                    Toggle("Inflow", isOn: $income)
                                }
                                
                                Toggle("Transfer", isOn: $transfer)
                                    .onChange(of: transfer) { _ in
                                        if transfer {
                                            income = false
                                        }
                                    }
                                
                                if !transfer {
                                    Toggle("Expense", isOn: $expense)
                                }
                                
                                if expense {
                                    if selectedDebtor == nil { // if no debtor is selected, show a text field to filter on them
                                        TextField("Debtor", text: $debtorFilter)
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
                                                    if payees.filter({debtorFilter == "" ? true: $0.name?.lowercased().starts(with: debtorFilter.lowercased()) ?? false}).count > 0 {
                                                        selectedDebtor = payees.filter({debtorFilter == "" ? true: $0.name?.lowercased().starts(with: debtorFilter.lowercased()) ?? false})[0]
                                                        print("Selecting \(selectedDebtor?.name ?? "")")
                                                        debtorFilter = selectedDebtor?.name ?? "" // display the debtor in the filter field
                                                    }
                                                    else { // if there is no value matching the filter, create a new payee as long as the filter isn't empty, and select it as a debtor
                                                        if debtorFilter != "" {
                                                            print("Creating new payee \(debtorFilter)")
                                                            let payee = Payee(context: viewContext) // create a new payee
                                                            payee.id = UUID()
                                                            payee.name = debtorFilter
                                                            payee.order = payees.last?.order ?? 0 + 1
                                                            selectedDebtor = payee // select the new debtor
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                    else { // if a debtor is already selected, show it as text, and tap on it to remove it
                                        Text(debtorFilter)
                                            .onTapGesture {
                                                selectedDebtor = nil
                                                debtorFilter = ""
                                                debtorFocused = true // show the keyboard again
                                            }
                                    }
                                    
                                    Toggle("Settled", isOn: $expenseSettled)
                                }
                                
                                Toggle("Recurring", isOn: $recurring)
                                if(recurring) {
                                    Picker("Recurrence", selection: $recurrence) {
                                        ForEach(recurrences, id: \.self) {
                                            Text($0)
                                        }
                                    }
                                }
                            }
                            
                            HStack {
                                Spacer()
                                saveButtonLarge
                                Spacer()
                            }
                        }
                    }
                }
                
                // Element of the ZStack: Payee selector:
//                if(payeeFocused) { // if I am trying to select a payee
                if selectedPayee == nil && !transfer && !amount.showNumpad { // if no payee is selected yet, this is not a transfer, and the numpad isn't showing, show the payee selector:
                    
                    // If there is no payee matching the filter, show the option to create one:
//                    if payees.filter({payeeFilter == "" ? true: $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil}).count == 0 {
                    if payees.filter({payeeFilter == "" ? true: $0.name?.lowercased().starts(with: payeeFilter.lowercased()) ?? false}).count == 0 {
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
                                        payee.order = payees.last?.order ?? 0 + 1
                                        selectedPayee = payee // select the new payee
                                    }
                                }
                        }
                        .listStyle(PlainListStyle()) // removed padding and background
                        .frame(width: 346, height: 177)
                        .background(.gray)
                        .cornerRadius(8)
//                        .offset(x: 0, y: -550) // for iPhone 13 Pro
                        .offset(x: 0, y: -375) // for iPhone SE
                    }
                    
                    else { // else if there is at least one match, show the matches so that I can select one
                        
                        if payeeFilter == "" { // if the filter is blank, show my top payees by number of transactions
                            List(payees, id: \.self) { payee in
                                HStack {
                                    Text(payee.name ?? "")
                                    Spacer()
                                    Text(payee.category?.name ?? "")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
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
                            .frame(width: 346, height: 177)
                            .background(.gray)
                            .cornerRadius(8)
//                            .offset(x: 0, y: -550) // for iPhone 13 Pro
                            .offset(x: 0, y: -375) // for iPhone SE
                        }
                        else { // else if the filter is not blank, show the payee list filtered based on what is typed
                            List(payees.filter({
                                $0.name?.lowercased().starts(with: payeeFilter.lowercased()) ?? false // show payees that start with the filter string, case insensitive
//                                $0.name?.range(of: payeeFilter, options: .caseInsensitive) != nil // filter based on what is typed
                            }), id: \.self) { payee in
                                HStack {
                                    Text(payee.name ?? "")
                                    Spacer()
                                    Text(payee.category?.name ?? "")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .contentShape(Rectangle()) // make the whole HStack tappable
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
                            .frame(width: 346, height: 177)
                            .background(.gray)
                            .cornerRadius(8)
                            //                            .offset(x: 0, y: -550) // for iPhone 13 Pro
                            .offset(x: 0, y: -375) // for iPhone SE
                        }
                    }
                }
                
                // Element of the ZStack: Debtor selector:
                
                if(debtorFocused) { // if I am trying to select a debtor
                    
                    // If there is no payee matching the filter, show the option to create one:
//                    if payees.filter({debtorFilter == "" ? true: $0.name?.range(of: debtorFilter, options: .caseInsensitive) != nil}).count == 0 {
                    if payees.filter({debtorFilter == "" ? true: $0.name?.lowercased().starts(with: debtorFilter.lowercased()) ?? false}).count == 0 {
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
                                        payee.order = payees.last?.order ?? 0 + 1
                                        selectedDebtor = payee // select the new payee as a debtor
                                    }
                                }
                        }
                        .listStyle(PlainListStyle()) // removed padding and background
                        .frame(width: 280, height: 177)
                        .background(.gray)
                        .cornerRadius(8)
                        .offset(x: -32, y: -375)
                    }
                    
                    else { // else if there is at least one match, show the matches so that I can select one
                        List(payees.filter({
                            debtorFilter == "" ? true: $0.name?.lowercased().starts(with: debtorFilter.lowercased()) ?? false // filter based on what is typed
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
                        .background(.gray)
                        .cornerRadius(8)
                        .offset(x: -32, y: -375)
                    }
                }
                
                // Element of the ZStack: Numpad:
                
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
    
    var dismissViewButton: some View {
        Button {
            dismiss()
        } label : {
            Text("Cancel")
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label : {
            Label("", systemImage: "trash")
                .foregroundColor(.red)
//            Label("Delete", systemImage: "xmark.circle")
//                .foregroundColor(.red)
        }
        .alert(isPresented:$showingDeleteAlert) {
            Alert(
                title: Text("Are you sure you want to delete this transaction?"),
                message: Text("This cannot be undone"),
                primaryButton: .destructive(Text("Delete")) {
                    
                    // Back up the transaction info so that I can update the balances of its old category, accounts and period:
                    let oldPeriod = transaction?.period ?? selectedPeriod.period
                    let oldCategory = transaction?.category
                    let oldAccount = transaction?.account
                    let oldToAccount = transaction?.toaccount
                    let oldDate = transaction?.date ?? Date()
                    
                    // Delete the transaction:
                    viewContext.delete(transaction!)
                    
                    PersistenceController.shared.save() // save the change, otherwise the transaction amount still appears in the balances
                    
                    // Update the category balance if the transaction is in the selected period, and has a category:
                    if oldPeriod == selectedPeriod.period && oldCategory != nil {
                        oldCategory?.calcBalance(period: oldPeriod) // calculate the balance and store it in the category
                    }
                    
                    // Update the account balance for end of day today if the transaction isn't in the future:
                    if Calendar.current.startOfDay(for: oldDate) < Date() {
                        oldAccount?.calcBalance(toDate: Date())
                    }
                    
                    // Update the "to account" balance for end of day today if there is one, and the transaction isn't in the future:
                    if oldToAccount != nil && Calendar.current.startOfDay(for: oldDate) < Date() {
                        oldToAccount?.calcBalance(toDate: Date())
                    }
                    
                    
                    
                    // Update the category, account(s) and period balances after the deletion: -> app crashes when I run this!
//                    let newTransaction = Transaction()
//                    newTransaction.updateBalances(transactionPeriod: oldPeriod ?? Period(), selectedPeriod: selectedPeriod.period, category: oldCategory, account: oldAccount ?? Account(), toaccount: oldToAccount)
//                    newTransaction.updateBalances(transactionPeriod: oldPeriod ?? Period(), todayPeriod: getPeriod(date: Date()), category: oldCategory, account: oldAccount ?? Account(), toaccount: oldToAccount)
                    
                    // Update the period balances in the environment object:
                    updateTotalBalances()
//                    periodBalances.incomeActual = getPeriod(date: date).getBalance()?.incomeactual ?? 0.0
//                    periodBalances.expensesActual = getPeriod(date: date).getBalance()?.expensesactual ?? 0.0
                    
                    PersistenceController.shared.save() // save the change
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    var saveButton: some View {
        Button {
            saveTransaction()
        } label: {
            Text("Save")
        }
        .alert("Please select an account", isPresented: $showingAccountAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select a category", isPresented: $showingCategoryAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select an account and a category", isPresented: $showingAccountAndCategoryAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select two different accounts", isPresented: $showingToAccountAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    var saveButtonLarge: some View {
        Button {
            saveTransaction()
        } label: {
            Label("Save", systemImage: "externaldrive.fill")
        }
        .alert("Please select an account", isPresented: $showingAccountAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select a category", isPresented: $showingCategoryAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select an account and a category", isPresented: $showingAccountAndCategoryAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Please select two different accounts", isPresented: $showingToAccountAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    
    private func saveTransaction() { // create a new transaction if there isn't one already, populate it and save it
        // If this is a transfer: if the account and the to account are identical show an alert:
        if ( transfer && (selectedAccount == selectedToAccount) ) || ( transfer && selectedToAccount == nil ) {
            showingToAccountAlert = true
        }
        
        else if(selectedAccount == nil) { // if no valid account has been selected, show an alert
            showingAccountAlert = true
        }
        
        else if selectedCategory == nil && ( !expense && ( (!transfer && selectedAccount?.type == "Budget") || (transfer && selectedAccount?.type != selectedToAccount?.type) ) ) { // if no valid category has been selected, and this is a transaction that requires a category, show an alert
            showingCategoryAlert = true
        }
        
        else if selectedAccount == nil && selectedCategory == nil {
            showingAccountAndCategoryAlert = true
        }

        else { // if a valid account and category have been selected, populate and save the transaction
            // Change the default account and category of the payee, if one is selected:
            if(selectedPayee != nil) {
                selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
                selectedPayee?.account = selectedAccount // if a payee has been selected, change its default account to the one I used this time
            }
            
            // Before I create or update the transaction, save the current remaining budget for the transaction's period, so that it can be displayed after:
            if selectedCategory != nil {
//                selectedCategory!.calcRemainingBudget(selectedPeriod: getPeriod(date: date)) // update the remaining budget on the category based on the transaction's period (later restored to it initial value)
                periodBalances.remainingBudgetBefore = selectedCategory!.remainingbudget // get the remaining budget for the transaction's period
//                periodBalances.remainingBudgetBefore = selectedCategory!.budget + selectedCategory!.balance
            }
//            print(selectedCategory?.budget)
//            print(selectedCategory?.balance)
//            print(selectedCategory?.budget - selectedCategory?.balance)
//            print(periodBalances.remainingBudgetBefore)
//            periodBalances.remainingBudgetBefore = selectedCategory?.calcRemainingBudget(period: getPeriod(date: date)) ?? 0.0
            
            // If the transaction is new, recurring, and its date is in the past, create the recurring transaction one recurrence period in the future, and also create a non-recurring transaction on the selected date:
            if transaction == nil && recurring && date < Date() {
                let transaction = Transaction(context: viewContext)
                
                let nextRecurrenceDate = Calendar.current.date(byAdding: .month, value: 1, to: date) // increment the recurring transaction's date by one recurrence period
                let period = getPeriod(date: nextRecurrenceDate ?? Date())
                
                transaction.populate(account: selectedAccount ?? Account(), date: nextRecurrenceDate ?? Date(), period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, amountTo: amount.intAmountTo, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, expenseSettled: expenseSettled, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                
                // Update the category, account(s) and period balances based on the new transaction:
                transaction.updateBalances(transactionPeriod: getPeriod(date: date), selectedPeriod: selectedPeriod.period, category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
//                transaction.updateBalances(transactionPeriod: getPeriod(date: date), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
                
                // Create a non-recurring transaction on the selected date:
                let transaction2 = Transaction(context: viewContext)
                let period2 = getPeriod(date: date)
                
                transaction2.populate(account: selectedAccount ?? Account(), date: date, period: period2, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, amountTo: amount.intAmountTo, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, expenseSettled: expenseSettled, debtor: selectedDebtor, recurring: false, recurrence: "")
                
                // Update the category, account(s) and period balances based on the new transaction:
                transaction2.updateBalances(transactionPeriod: getPeriod(date: date), selectedPeriod: selectedPeriod.period, category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
//                transaction2.updateBalances(transactionPeriod: getPeriod(date: date), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
            }
            
            // Else if the transaction is not recurring, or it is due in the future, just create the transaction if it is new, and populate the transaction:
            else {
                if transaction == nil { // if this is a new transaction, create it and populate it
                    let transaction = Transaction(context: viewContext)
                    
                    let period = getPeriod(date: date)
                    
                    transaction.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, amountTo: amount.intAmountTo, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, expenseSettled: expenseSettled, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                    
                    // Update the category, account(s) and period balances based on the new transaction:
                    transaction.updateBalances(transactionPeriod: getPeriod(date: date), selectedPeriod: selectedPeriod.period, category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
//                    transaction.updateBalances(transactionPeriod: getPeriod(date: date), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
                }
                else { // else if this is an existing transaction, populate it
                    let period = getPeriod(date: date)
                    
                    transaction?.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, amountTo: amount.intAmountTo, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, expenseSettled: expenseSettled, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                    
                    // Update the category, account(s) and period balances based on the new transaction:
                    transaction?.updateBalances(transactionPeriod: getPeriod(date: date), selectedPeriod: selectedPeriod.period, category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
//                    transaction?.updateBalances(transactionPeriod: getPeriod(date: date), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
                }
            }
            
            // Save the information required to show the category balance animation, except for expense transactions, for income categories, for transactions on an external account, and for transfers between accounts of the same type:
            if !expense && !(selectedCategory?.type == "Income") && !(!transfer && selectedAccount?.type == "External") && !(transfer && selectedAccount?.type == selectedToAccount?.type) {
                periodBalances.category = selectedCategory ?? Category()
                periodBalances.showBalanceAnimation = true
            }
            
            // Save the remaining budget of the transaction's category in the transaction's period, so that it can be displayed after:
            if selectedCategory != nil {
//                selectedCategory!.calcRemainingBudget(selectedPeriod: getPeriod(date: date)) // update the remaining budget on the category based on the transaction's period (later restored to it initial value)
                
                periodBalances.remainingBudgetAfter = selectedCategory!.remainingbudget // get the remaining budget for the transaction's period after the transaction has been created
//                periodBalances.remainingBudgetAfter = selectedCategory!.budget + selectedCategory!.balance
                
//                if getPeriod(date: date) != selectedPeriod.period {
//                    selectedCategory!.calcRemainingBudget(selectedPeriod: selectedPeriod.period) // update the remaining budget on the category based on the selected period, to restore it to its initial value, if the selected period is different from the transaction's period
//                }
            }
//            periodBalances.remainingBudgetAfter = selectedCategory?.budget ?? 0.0 - (selectedCategory?.balance ?? 0.0)
//            periodBalances.remainingBudgetAfter = selectedCategory?.calcRemainingBudget(period: getPeriod(date: date)) ?? 0.0
            
            // Update the period balances in the environment object:
            updateTotalBalances()
            // Update the account totals in the environment object:
            updateAccountTotals()
            
//            periodBalances.incomeActual = getPeriod(date: date).getBalance()?.incomeactual ?? 0.0
//            periodBalances.expensesActual = getPeriod(date: date).getBalance()?.expensesactual ?? 0.0
            
            PersistenceController.shared.save() // save the new transactions, and the balance updates
            dismiss() // dismiss this view
        }
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, TransactionDetailView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
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
    
    private func updateTotalBalances() {
        print("Updating the total income and expenses for the period")
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
    }
    
    private func updateAccountTotals() {
        print("Updating totals for all accounts")
        // Calculate the total balances as of today, and store them in the environment variable:
        var amount = 0.0
        var budget = 0.0
        var external = 0.0
        var total = 0.0
        let period = getPeriod(date: Date())
        
        for account in accounts {
            if account.currency == defaultCurrency { // for accounts in the default currency
                amount = account.balance
//                amount = account.getBalance(period: period)?.accountbalance ?? 0.0
            }
            else { // for accounts in a different currency, add the amount converted to the default currency using the selected period's exchange rate, if there is one, otherwise add 0
                if let fxRate = period.getFxRate(currency1: defaultCurrency, currency2: account.currency ?? "") {
                    amount = account.balance / fxRate * 100.0
//                    amount = (account.getBalance(period: period)?.accountbalance ?? 0.0) / fxRate * 100.0
                }
            }
            
            total += amount // add the amount to the total balance
            
            // Also add the amount to one of the subtotals, for budget or for external accounts:
            if account.type == "Budget" {
                budget += amount
            }
            else if account.type == "External" {
                external += amount
            }
        }
        
        periodBalances.totalBalance = total
        periodBalances.totalBalanceBudget = budget
        periodBalances.totalBalanceExternal = external
    }
    
    /*
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
                // Change the default account and category of the payee, if one is selected:
                if(selectedPayee != nil) {
                    selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
                    selectedPayee?.account = selectedAccount // if a payee has been selected, change its default account to the one I used this time
                }
                
                // Before I create the transaction, save the current remaining budget for the transaction's period, so that it can be displayed after:
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
     */
}

//struct TransactionDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionDetailView()
//    }
//}
