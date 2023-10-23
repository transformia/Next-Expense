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
    private var periods: FetchedResults<Period> // to determine the period of the transaction (getPeriod() function)
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let transaction: Transaction // transaction to display
    
    @StateObject var amount = AddTransactionView.Amount() // stores the transaction amount, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    
    // Variable determining whether the focus is on the payee or not:
    @FocusState private var payeeFocused: Bool
    
    // Define variables for the transactions's new attributes:
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
//    @State private var amount = 0
    @State private var payeeFilter = ""
    @State private var currency = "EUR"
    @State private var memo = ""
    
    @State private var showingDeleteAlert = false
    @State private var showingToAccountAlert = false
    
    // Variable determining whether the focus is on the amount text editor or not:
//    @FocusState private var isFocused: Bool
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    // Define available recurrences:
    let recurrences = ["Monthly"]
    
    var body: some View {
        NavigationView { // so that the pickers work
            VStack {
                HStack {
                    dismissViewButton
                    Spacer()
                    deleteButton
                    Spacer()
                    saveButton
                }
                .padding([.top, .leading, .trailing])
                
                
                Form {
                    Group {
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .onAppear {
                                date = transaction.date ?? Date()
                            }
                        Toggle("Recurring", isOn: $recurring)
                            .onAppear {
                                recurring = transaction.recurring
                            }
                        if(recurring) {
                            Picker("Recurrence", selection: $recurrence) {
                                ForEach(recurrences, id: \.self) {
                                    Text($0)
                                }
                            }
                            .onAppear {
                                recurrence = transaction.recurrence ?? "Monthly"
                            }
                        }
                        if !transfer {
                            Toggle("Inflow", isOn: $income)
                                .onAppear {
                                    income = transaction.income
                                }
                        }
                        Toggle("Transfer", isOn: $transfer)
                            .onAppear {
                                transfer = transaction.transfer
                            }
                        
                        Text(Double(amount.intAmount) / 100, format: .currency(code: currency)) // amount of the transaction
                            .foregroundColor(income || (transfer && selectedAccount?.type == "External" && selectedToAccount?.type == "Budget") ? .green : .primary) // green for an income, or for a transfer from an external account to a budget account
                            .onAppear {
                                amount.intAmount = Int(transaction.amount)
                            }
                            .onTapGesture {
                                amount.showNumpad.toggle()
                                payeeFocused = false // in case the payee field is selected, remove focus from it so that the keyboard closes
                            }
                    }
                    Group {
                        if(!transfer) {
                            TextField("Payee", text: $payeeFilter)
                                .onAppear {
                                    payeeFilter = transaction.payee?.name ?? ""
                                    selectedPayee = transaction.payee
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
                                            payeeFilter = payee.name ?? "" // display the payee in the filter field
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
                                selectedCategory = transaction.category
                            }
                        }
                        
                        Picker("Account", selection: $selectedAccount) {
                            ForEach(accounts, id: \.self) { (account: Account) in
                                Text(account.name ?? "")
                                    .tag(account as Account?)
                            }
                        }
                        .onAppear {
                            selectedAccount = transaction.account
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
                                selectedToAccount = transaction.toaccount
                            }
                            // NOT NEEDED BECAUSE I CANNOT SELECT A TO ACCOUNT WITH A DIFFERENT CURRENCY, NOR THE SAME AS THE FROM ACCOUNT:
                            //                        .onChange(of: selectedToAccount) { _ in
                            //                            // If I have selected the same account as the from account, or the accounts now have different currencies, change the from account to another account with the same currency, if there is one:
                            //                            if selectedToAccount == selectedAccount || selectedToAccount?.currency != selectedAccount?.currency {
                            //                                if accounts.filter({$0.currency == selectedToAccount?.currency}).count > 1 { // if there are at least 2 accounts with the same currency as the selected to account
                            //                                    if accounts.filter({$0.currency == selectedToAccount?.currency})[0] != selectedToAccount {
                            //                                        selectedAccount = accounts.filter({$0.currency == selectedToAccount?.currency})[0] // if the first account with the same currency is different from the to account, select it
                            //                                    }
                            //                                    else {
                            //                                        selectedAccount = accounts.filter({$0.currency == selectedToAccount?.currency})[1] // else select the second one
                            //                                    }
                            //                                }
                            //                            }
                            //                        }
                        }
                        //                    Picker("Currency", selection: $currency) {
                        //                        ForEach(currencies, id: \.self) {
                        //                            Text($0)
                        //                        }
                        //                    }
                        //                    .onAppear {
                        //                        currency = transaction.currency ?? "EUR"
                        //                    }
                        
                        if !transfer {
                            Toggle("Expense", isOn: $expense)
                                .onAppear {
                                    expense = transaction.expense
                                }
                        }
                        
                        if expense {
                            TextField("Debtor", text: $debtorFilter)
                                .onAppear {
                                    debtorFilter = transaction.debtor?.name ?? ""
                                    selectedDebtor = transaction.debtor
                                }
                            //                            .focused($debtorFocused)
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
                                            //                                        debtorFocused = false // hide the keyboard
                                        }
                                }
                            }
                        }                        
                        
                        
                        TextField("Memo", text: $memo)
                            .onAppear {
                                memo = transaction.memo ?? ""
                            }
                    }
                }
                .padding(.leading, 5.0) // padding on the Form?
            }
        }
        .sheet(isPresented: $amount.showNumpad) {
            NumpadView(amount: amount)
                .presentationDetents([.height(300)])
        }
    }
    
    var dismissViewButton: some View {
        Button {
            dismiss()
        } label : {
            Text("Cancel")
        }
    }
    
    var saveButton: some View {
        Button {
            
            // If the account and the to account are identical, or the two accounts have different currencies, show an alert:
            if transfer && (selectedAccount == selectedToAccount || selectedAccount?.currency != selectedToAccount?.currency) {
                showingToAccountAlert = true
            }
            
            else { // is the accounts are different and have the same currency, save the change
                
                // Create a new payee if necessary:
                if((payeeFilter != "" && selectedPayee == nil) || (payeeFilter != selectedPayee?.name && payeeFilter != "")) { // if a payee has been entered, but none has been selected, create a new payee. Also do that if the payee that has been typed isn't the one that was previously selected, so that I can create a new payee on an existing transaction
                    let payee = Payee(context: viewContext)
                    payee.id = UUID()
                    payee.name = payeeFilter
                    payee.category = selectedCategory
                    selectedPayee = payee
                }
                
                // Else change the default account and category of the payee:
                else if(selectedPayee != nil) {
                    selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
                }
                
                // Create a new payee for the debtor if necessary:
                if((debtorFilter != "" && selectedDebtor == nil) || (debtorFilter != selectedDebtor?.name && debtorFilter != "")) { // if a debtor has been entered, but none has been selected, create a new payee. Also do that if I selected a debtor, then changed my mind and typed a completely new one
                    let payee = Payee(context: viewContext)
                    payee.id = UUID()
                    payee.name = debtorFilter
                    selectedDebtor = payee
                }
                
                let period = getPeriod(date: date)
                
                // Back up the transaction info so that I can update the balances of its old category, accounts and period:
                let oldPeriod = transaction.period
                let oldCategory = transaction.category
                let oldAccount = transaction.account
                let oldToAccount = transaction.toaccount
                
                // Update the transaction:
                transaction.populate(account: selectedAccount ?? Account(), date: date, period: period, payee: selectedPayee, category: selectedCategory, memo: memo, amount: amount.intAmount, currency: currency, income: income, transfer: transfer, toAccount: selectedToAccount, expense: expense, debtor: selectedDebtor, recurring: recurring, recurrence: recurrence)
                
                // Update the category, account(s) and period balances based on the new transaction:
                transaction.updateBalances(transactionPeriod: period, todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: selectedAccount ?? Account(), toaccount: selectedToAccount)
                
                // Update the same balances based on the category, accounts and period of how the transaction used to look:
                transaction.updateBalances(transactionPeriod: oldPeriod ?? Period(), todayPeriod: getPeriod(date: Date()), category: oldCategory, account: oldAccount ?? Account(), toaccount: oldToAccount)
                
                // Update the period balances in the environment object:
                periodBalances.incomeActual = getPeriod(date: date).getBalance()?.incomeactual ?? 0.0
                periodBalances.expensesActual = getPeriod(date: date).getBalance()?.expensesactual ?? 0.0
                
                PersistenceController.shared.save() // save the changes
                dismiss()
            }
        } label : {
//            Label("Save", systemImage: "opticaldiscdrive.fill")
            Text("Save")
        }
        .alert("Please select two different accounts with the same currency", isPresented: $showingToAccountAlert) {
            Button("OK", role: .cancel) { }
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
                    let oldPeriod = transaction.period
                    let oldCategory = transaction.category
                    let oldAccount = transaction.account
                    let oldToAccount = transaction.toaccount
                    
                    // Delete the transaction:
                    viewContext.delete(transaction)
                    
                    PersistenceController.shared.save() // save the change, otherwise the transaction amount still appears in the balances
                    
                    // Update the category, account(s) and period balances after the deletion:
                    let newTransaction = Transaction()
                    newTransaction.updateBalances(transactionPeriod: oldPeriod ?? Period(), todayPeriod: getPeriod(date: Date()), category: oldCategory, account: oldAccount ?? Account(), toaccount: oldToAccount)
                    
                    // Update the period balances in the environment object:
                    periodBalances.incomeActual = getPeriod(date: date).getBalance()?.incomeactual ?? 0.0
                    periodBalances.expensesActual = getPeriod(date: date).getBalance()?.expensesactual ?? 0.0
                    
                    PersistenceController.shared.save() // save the change
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date
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

//struct TransactionDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionDetailsView()
//    }
//}
