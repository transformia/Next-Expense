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
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedCategory: Category?
    @State private var income = false // tells us the sign of the transaction
    @State private var transfer = false // tells us if this is a transfer between accounts
    @State private var payeeFilter = ""
    @State private var currency = "EUR"
    @State private var memo = ""
    
    @State private var showingAlert = false
    
    class Amount: ObservableObject { // to store the amount and the visibility of the numpad, and allow the numpad view to edit them
        @Published var intAmount = 0
        @Published var showNumpad = false
    }
    
    @StateObject var amount = Amount()
    
    // Variable determining whether the focus is on the payee or not:
    @FocusState private var payeeFocused: Bool
    
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
                        Toggle("Income", isOn: $income)
                        Toggle("Transfer", isOn: $transfer)
                        
                        Text(Double(amount.intAmount) / 100, format: .currency(code: currency))
                            .foregroundColor(income ? .green : .primary)
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
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { (category: Category) in
                                    Text(category.name ?? "")
                                        .tag(category as Category?)
                                }
                            }
                            .onAppear {
                                selectedCategory = category // default to the provided value
                                income = category.type == "Income" ? true : false
                            }
                            .onChange(of: selectedCategory) { _ in
                                income = selectedCategory?.type == "Income" ? true : false
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
                        }
                        
                        if(transfer) {
                            Picker("To account", selection: $selectedToAccount) {
                                ForEach(accounts, id: \.self) { (account: Account) in
                                    Text(account.name ?? "")
                                        .tag(account as Account?)
                                }
                            }
                            .onAppear {
                                selectedToAccount = account // default to the provided value
                            }
                        }
                        
                        Picker("Currency", selection: $currency) {
                            ForEach(currencies, id: \.self) {
                                Text($0)
                            }
                        }
                        .onAppear {
                            currency = selectedAccount?.currency ?? "EUR" // set the currency to the currency of the selected account
                        }
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
            
            if(selectedAccount == nil || selectedCategory == nil) { // if no valid account and category have been selected, show an alert
                showingAlert = true
            }
            
            else { // if a valid account and category have been selected, create and save the transaction
                if((payeeFilter != "" && selectedPayee == nil) || (payeeFilter != selectedPayee?.name && payeeFilter != "")) { // if a payee has been entered, but none has been selected, create a new payee. Also do that if I selected a payee, then changed my mind and typed a completely new one
                    let payee = Payee(context: viewContext)
                    payee.id = UUID()
                    payee.name = payeeFilter
                    payee.category = selectedCategory
                    payee.account = selectedAccount
                    selectedPayee = payee
                }
                
                else if(selectedPayee != nil) {
                    selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
                    selectedPayee?.account = selectedAccount // if a payee has been selected, change its default account to the one I used this time
                }
                
                let transaction = Transaction(context: viewContext)
                
                transaction.id = UUID()
                transaction.timestamp = Date()
                transaction.date = date
                transaction.recurring = recurring
                transaction.recurrence = recurrence
                transaction.period = getPeriod(date: date)
                transaction.payee = selectedPayee
                transaction.category = selectedCategory
                //            transaction.amount = Int64(amount_old) // save amount as an int, i.e. 2560 means 25,60€ for example
                transaction.amount = Int64(amount.intAmount) // save amount as an int, i.e. 2560 means 25,60€ for example
                transaction.income = income // save the direction of the transaction, true for an income, false for an expense
                transaction.transfer = transfer // save the information of whether or not this is a transfer
                //            print("Amount: \(transaction.amount)")
                transaction.currency = currency
                transaction.memo = memo
                transaction.account = selectedAccount
                
                if(transfer) { // if this is a transfer, create a second transaction
                    transaction.category = nil // remove the category from the first transaction
                    
                    let transaction2 = Transaction(context: viewContext)
                    
                    transaction2.id = UUID()
                    transaction2.timestamp = Date()
                    transaction2.date = date
                    transaction2.recurring = recurring
                    transaction2.recurrence = recurrence
                    transaction2.period = getPeriod(date: date)
                    transaction2.category = nil // remove the category
                    //                transaction2.amount = Int64(amount_old) // save amount as an int, i.e. 2560 means 25,60€ for example
                    transaction2.amount = Int64(amount.intAmount) // save amount as an int, i.e. 2560 means 25,60€ for example
                    transaction2.income = !income // save the direction of the transaction, true for an income, false for an expense. Reversed for this transaction
                    transaction2.transfer = transfer // save the information of whether or not this is a transfer
                    transaction2.currency = currency
                    transaction2.memo = memo
                    transaction2.account = selectedToAccount
                }
                
                PersistenceController.shared.save() // save the item
                
                dismiss() // dismiss this view
            }
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
        .alert("Category or account missing", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
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

//struct AddTransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddTransactionView()
//    }
//}
