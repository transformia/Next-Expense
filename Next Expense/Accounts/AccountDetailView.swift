//
//  AccountDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AccountDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to call AddTransactionView with a default category, and to be able to assign a category to a reconciliation difference
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the reconciliation transaction
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let account: Account // element to display
    
    @State private var name = ""
    @State private var type = "Budget" // tells us the type of the category    
    
    @State private var addTransactionView = false // determines whether the view for adding elements is displayed or not
    
    // Define category types:
    let types = ["Budget", "External"]
    
//    @State private var balance = 0.0
    @StateObject var accountBalance = AddTransactionView.Amount()
    
    // Category selected for the reconciliation difference:
    @State private var selectedCategory: Category?
    
    @State private var showingDeleteAlert = false
//    @State private var showingReconciliationAlert = false
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // get the period balances from the environment
    
    @FocusState var isFocused: Bool // determines whether the focus is on the text field or not
    
    var body: some View {
        VStack {
            HStack {
                TextField("", text: $name)
                    .font(.title)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.center)
                    .onAppear {
                        name = account.name ?? ""
                    }
                if name != account.name { // if I have modified the name, show a button to save the change
                    Image(systemName: "opticaldiscdrive")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            account.name = name
                            PersistenceController.shared.save()
                            isFocused = false
                        }
                }
            }
            
            // Don't allow me to change this for now:
//            HStack {
//                Picker("Account type", selection: $type) {
//                    ForEach(types, id: \.self) {
//                        Text($0)
//                    }
//                }
//                .onAppear {
//                    type = account.type ?? ""
//                }
//                .onChange(of: type) { _ in
//                    account.type = type
//                    PersistenceController.shared.save()
//                }
//            }
            
            HStack {
                Text("Balance")
                    .font(.headline)
//                Text(Double(balance.intAmount) / 100, format: .currency(code: account.currency ?? "EUR"))
                Text((account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0) / 100, format: .currency(code: account.currency ?? "EUR"))
                    .font(.headline)
                    .foregroundColor(.blue)
                    .onAppear {
//                        balance.intAmount = Int(account.calcBalance(toDate: Date()))
                        accountBalance.intAmount = Int(account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0) // set the reconciliation balance to the account's balance
                    }
                    .onTapGesture {
                        accountBalance.showNumpad.toggle()
                    }
                    .onChange(of: account.getBalance(period: getPeriod(date: Date()))?.accountbalance) { _ in
                        accountBalance.intAmount = Int(account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0)
                    } // when the account balance changes because a transaction has been modified, also update the reconciliation balance so that it doesn't think that there is suddenly a reconciliation difference
            }
//            HStack {
//                if showKeypad { // show the balance to reconcile to
//                    Text("Reconciliation balance")
//                        .font(.headline)
//
//                    Text(Double(balance.intAmount) / 100, format: .currency(code: account.currency ?? "EUR"))
//                        .font(.headline)
//                        .foregroundColor(.green)
//                }
//            }
            
            if(Double(accountBalance.intAmount) != (account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0)) {
//            if(balance.intAmount != Int(account.calcBalance(toDate: Date()))) {
                HStack {
                    Text("Reconciliation balance")
                        .font(.headline)
                    
                    Text(Double(accountBalance.intAmount) / 100, format: .currency(code: account.currency ?? "EUR"))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                HStack {
                    Text("Difference: ")
                    Text(((Double(accountBalance.intAmount) - (account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0)) / 100), format: .currency(code: account.currency ?? "EUR"))
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { (category: Category) in
                            Text(category.name ?? "")
                                .tag(category as Category?)
                        }
                    }
                    .onAppear {
                        selectedCategory = categories[0]
                    }
                }
                HStack {
                    Button {
                        print("Reconciling with a difference of \(( Double(accountBalance.intAmount) - Double(account.calcBalance(toDate: Date())) ) / 100)")
                        let transaction = Transaction(context: viewContext)
                        
//                        transaction.id = UUID()
//                        transaction.timestamp = Date()
//                        transaction.date = Date()
//                        transaction.period = getPeriod(date: Date())
//                        //                    transaction.payee = selectedPayee
//                        transaction.category = selectedCategory
//                        transaction.amount = Int64(abs(accountBalance.intAmount - Int(account.calcBalance(toDate: Date())))) // save amount as an int, i.e. 2560 means 25,60€ for example
//                        transaction.income = Double(accountBalance.intAmount) - account.calcBalance(toDate: Date()) > 0 ? true : false // save the direction of the transaction, true for an positive value, false for a negative one
//                        transaction.transfer = false // save the information that this is not a transfer
//                        print("Amount: \(transaction.amount)")
//                        transaction.currency = account.currency
//                        transaction.memo = "Reconciliation difference"
//                        transaction.account = account
                        
                        transaction.populate(account: account, date: Date(), period: getPeriod(date: Date()), payee: nil, category: selectedCategory, memo: "Reconciliation difference", amount: Int(abs((Double(accountBalance.intAmount) - (account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0)))), currency: account.currency ?? "EUR", income: Double(accountBalance.intAmount) - (account.getBalance(period: getPeriod(date: Date()))?.accountbalance ?? 0.0) > 0 ? true : false, transfer: false, toAccount: nil, expense: false, debtor: nil, recurring: false, recurrence: "")
                        
                        // Update the category, account(s) and period balances based on the new transaction:
                        transaction.updateBalances(transactionPeriod: transaction.period ?? Period(), todayPeriod: getPeriod(date: Date()), category: selectedCategory, account: account, toaccount: nil)
                        
                        // Update the period balances in the environment object:
                        periodBalances.incomeActual = getPeriod(date: Date()).getBalance()?.incomeactual ?? 0.0
                        periodBalances.expensesActual = getPeriod(date: Date()).getBalance()?.expensesactual ?? 0.0
                        
                        PersistenceController.shared.save() // save the reconciliation transaction and the balance updates
                        
                    } label: {
                        Label("Reconcile", systemImage: "checkmark")
                    }
                    
                    Button {
                        accountBalance.intAmount = Int(account.calcBalance(toDate: Date()))
                    } label: {
                        Label("Cancel", systemImage: "x.circle")
                    }
                    .tint(.green)
                }
            }
            
            // Show button to delete the account if it has no transactions:
            if transactions.filter({$0.account == account}).count == 0 {
                Button(role: .destructive) {
                    print("Deleting account \(account.name ?? "")")
                    viewContext.delete(account)
                    PersistenceController.shared.save() // save the change
                    dismiss()
                } label: {
                    Label("Delete account", systemImage: "trash")
                }
                .padding()
            }
            
//                .onTapGesture {
//                    showingReconciliationAlert = true
//                }
//                .confirmationDialog("Is your account balance correct?", isPresented:$showingReconciliationAlert, titleVisibility: .visible) {
//                    Button("Yes") {
//                        print("Reconciling without difference")
////                        dismiss()
//                    }
//                    Button("No") {
//                        print("Canceling")
////                        dismiss()
//                    }
//                }
            
//            Spacer()
            
//            deleteButton
                        
            TransactionListView(payee: nil, account: account, category: nil)
            .sheet(isPresented: $addTransactionView) {
                AddTransactionView(payee: nil, account: account, category: categories[0])
            }
            
//            deleteButton
        }
        .sheet(isPresented: $accountBalance.showNumpad) {
            NumpadView(amount: accountBalance)
                .presentationDetents([.height(300)])
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            withAnimation {
                showingDeleteAlert = true
            }
        } label : {
            Label("Delete account", systemImage: "xmark.circle")
        }
        .alert(isPresented:$showingDeleteAlert) {
            Alert(
                title: Text("Are you sure you want to delete this account?"),
                message: Text("This cannot be undone"),
                primaryButton: .destructive(Text("Delete")) {
                    viewContext.delete(account)
                    PersistenceController.shared.save() // save the change
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    /*
    private func updateBalances() { // update the category, account(s) and period balances. Exists in AddTransactionView and TransactionDetailView, and a special variant of it is in AccountDetailView
        
        // Note: this doesn't save the changes, so PersistenceController.shared.save() needs to be run after it
        
        
        // Update the balance of the transaction's category, if the transaction has a category:
        if selectedCategory != nil {
            let categorybalance = selectedCategory?.getBalance(period: getPeriod(date: Date()))
            if categorybalance != nil { // if the balance already exists, recalculate it
                categorybalance?.categorybalance = selectedCategory?.calcBalance(period: getPeriod(date: Date())) ?? 0.0
                categorybalance?.modifieddate = Date()
            }
            else  { // if the balance doesn't exist yet, create it and calculate it
                let categorybalance = Balance(context: viewContext)
                categorybalance.populate(type: "categorybalance", amount: selectedCategory?.calcBalance(period: getPeriod(date: Date())) ?? 0.0, period: getPeriod(date: Date()), account: nil, category: selectedCategory)
            }
        }
        
        // Update the balance of the transaction's account(s) as of END OF DAY TODAY:
        let consideredDate = Date() // calcBalance compares this with start of day of the transation, so this is the same as saying end of day today
        
//        // Set the date to today if the current period is selected, or the end of the period if a past or future period is selected:
//        var consideredDate: Date
//        if selectedPeriod.period == getPeriod(date: Date()) {
//            consideredDate = Date()
//        }
//        else {
//            var components = DateComponents()
//            components.year = Int(selectedPeriod.period.year)
//            components.month = Int(selectedPeriod.period.month) + 1
//            components.day = 1
//            consideredDate = Calendar.current.startOfDay(for: Calendar.current.date(from: components) ?? Date())
//        }
        
        let accountbalance = account.getBalance(period: getPeriod(date: Date()))
        if accountbalance != nil { // if the balance already exists, recalculate it
            accountbalance?.accountbalance = account.calcBalance(toDate: consideredDate)
            accountbalance?.modifieddate = Date()
            
        }
        else  { // if the balance doesn't exist yet, create it and calculate it
            let accountbalance = Balance(context: viewContext)
            accountbalance.populate(type: "accountbalance", amount: account.calcBalance(toDate: consideredDate), period: getPeriod(date: Date()), account: account, category: nil)
        }
        
//        if transfer { // if this is a transfer, do the same for the to account
//            let toaccountbalance = selectedToAccount?.getBalance(period: selectedPeriod.period)
//            if toaccountbalance != nil { // if the balance already exists, recalculate it
//                toaccountbalance?.accountbalance = selectedToAccount?.calcBalance(toDate: consideredDate) ?? 0.0
//                toaccountbalance?.modifieddate = Date()
//
//            }
//            else  { // if the balance doesn't exist yet, create it and calculate it
//                let toaccountbalance = Balance(context: viewContext)
//                toaccountbalance.populate(type: "accountbalance", amount: selectedToAccount?.calcBalance(toDate: consideredDate) ?? 0.0, period: selectedPeriod.period, account: selectedToAccount, category: nil)
//            }
//        }
        
        
        // Update the period balance for either income or expenses:
        
        let incomeexpensesactual = getPeriod(date: Date()).getBalance()
        if incomeexpensesactual != nil {
            if selectedCategory?.type == "Income" {
                incomeexpensesactual?.incomeactual = getPeriod(date: Date()).calcBalances().0
            }
            else if selectedCategory?.type == "Expense" {
                incomeexpensesactual?.expensesactual = getPeriod(date: Date()).calcBalances().1
            }
            incomeexpensesactual?.modifieddate = Date()
        }
        
        else { // if the balance doesn't exist yet, create it and calculate both the actual income and expenses
            let incomeexpensesactual = Balance(context: viewContext)
            let (incomeactual, expensesactual) = getPeriod(date: Date()).calcBalances()
            incomeexpensesactual.populate(type: "incomeactual", amount: incomeactual, period: getPeriod(date: Date()), account: nil, category: nil)
            incomeexpensesactual.populate(type: "expensesactual", amount: expensesactual, period: getPeriod(date: Date()), account: nil, category: nil)
        }
    }
    */
    
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

//struct AccountDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        AccountDetailView()
//    }
//}
