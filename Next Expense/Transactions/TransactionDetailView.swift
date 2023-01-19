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
    
    // Variable determining whether the focus is on the payee or not:
    @FocusState private var payeeFocused: Bool
    
    // Define variables for the transactions's new attributes:
    @State private var date = Date()
    @State private var selectedPayee: Payee?
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedCategory: Category?
    @State private var income = false // tells us the sign of the transaction
    @State private var transfer = false // tells us if this is a transfer between accounts
//    @State private var amount = 0
    @State private var payeeFilter = ""
    @State private var currency = "EUR"
    @State private var memo = ""
    
    @State private var showingDeleteAlert = false
    
    // Variable determining whether the focus is on the amount text editor or not:
//    @FocusState private var isFocused: Bool
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        NavigationView { // so that the pickers work
            Form {
                Group {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .onAppear {
                            date = transaction.date ?? Date()
                        }
                    Toggle("Income", isOn: $income)
                        .onAppear {
                            income = transaction.income
                        }
//                    Toggle("Transfer", isOn: $transfer)
//                        .onAppear {
//                            transfer = transaction.transfer
//                        }
//                    TextField("Amount", value: $amount, formatter: NumberFormatter())
//                        .keyboardType(.numberPad)
//                        .onAppear {
//                            amount = Int(transaction.amount)
//                        }
//                        .focused($isFocused)
                    
//                    ZStack {
//                        TextField("Amount", value: $amount, formatter: NumberFormatter())
//                            .keyboardType(.numberPad)
//                            .focused($isFocused)
//                            .onAppear {
//                                amount = Int(transaction.amount)
//                            }
//                            .focused($isFocused)
//                        Text(Double(amount) / 100, format: .currency(code: currency))
//                            .foregroundColor(income ? .green : .primary)
//                    }
                    
                    Text(Double(amount.intAmount) / 100, format: .currency(code: "EUR")) // amount of the transaction
                        .foregroundColor(income ? .green : .primary)
                        .onAppear {
                            amount.intAmount = Int(transaction.amount)
                        }
                        .onTapGesture {
                            amount.showNumpad.toggle()
                            payeeFocused = false // in case the payee field is selected, remove focus from it so that the keyboard closes
                        }
                }
                Group {
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
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { (category: Category) in
                            Text(category.name ?? "")
                                .tag(category as Category?)
                        }
                    }
                    .onAppear {
                        selectedCategory = transaction.category
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
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) {
                            Text($0)
                        }
                    }
                    .onAppear {
                        currency = transaction.currency ?? "EUR"
                    }
                    TextField("Memo", text: $memo)
                        .onAppear {
                            memo = transaction.memo ?? ""
                        }
                    HStack {
                        saveButton
                        Spacer()
                        deleteButton
                    }
                    .padding()
                    .buttonStyle(BorderlessButtonStyle()) // to avoid that buttons inside the same HStack activate together
                }
            }
            .padding(.leading, 5.0) // padding on the Form?
//            .toolbar {
//                ToolbarItemGroup(placement: .keyboard) {
//                    Spacer()
//                    saveButton
//                    Spacer()
//                    Button("Done") {
//                        isFocused = false
//                    }
//                }
//            }
            
        }
        .sheet(isPresented: $amount.showNumpad) {
            NumpadView(amount: amount)
                .presentationDetents([.height(300)])
        }
    }
    
    var saveButton: some View {
        Button {
            if((payeeFilter != "" && selectedPayee == nil) || (payeeFilter != selectedPayee?.name && payeeFilter != "")) { // if a payee has been entered, but none has been selected, create a new payee. Also do that if the payee that has been typed isn't the one that was previously selected, so that I can create a new payee on an existing transaction
                let payee = Payee(context: viewContext)
                payee.id = UUID()
                payee.name = payeeFilter
                payee.category = selectedCategory
                selectedPayee = payee
            }
            
            else if(selectedPayee != nil) {
                selectedPayee?.category = selectedCategory // if a payee has been selected, change its default category to the one I used this time
            }
            
//            transaction.timestamp = Date() // don't change the timestamp, as it changes the order of the transactions
            transaction.date = date
            transaction.period = getPeriod(date: date)
            transaction.payee = selectedPayee
            transaction.category = selectedCategory
            transaction.amount = Int64(amount.intAmount) // save amount as an int, i.e. 2560 means 25,60€ for example
            transaction.income = income // save the direction of the transaction, true for an income, false for an expense
//            transaction.transfer = transfer // save the information of whether or not this is a transfer - not needed, as I can't change it
            transaction.currency = currency
            transaction.memo = memo
            transaction.account = selectedAccount
            
                
            PersistenceController.shared.save() // save the change
            dismiss()
        } label : {
            Label("Save", systemImage: "opticaldiscdrive.fill")
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteAlert = true
        } label : {
            Label("Delete", systemImage: "xmark.circle")
                .foregroundColor(.red)
        }
        .alert(isPresented:$showingDeleteAlert) {
            Alert(
                title: Text("Are you sure you want to delete this transaction?"),
                message: Text("This cannot be undone"),
                primaryButton: .destructive(Text("Delete")) {
                    viewContext.delete(transaction)
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
