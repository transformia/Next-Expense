//
//  AddTransactionView.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2022-10-12.
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
    
    // Define variables for the new transactions's attributes:
    @State private var date = Date()
    @State private var selectedPayee: Payee?
    @State private var selectedAccount: Account?
    @State private var selectedCategory: Category?
    @State private var income = false
//    @State private var amount = 0
    @State private var payeeFilter = ""
    @State private var currency = "EUR"
    @State private var memo = ""
    
    @State private var showingAlert = false
    
    class Amount: ObservableObject {
        @Published var intAmount = 0
        @Published var showNumpad = true
    }
    
    @StateObject var amount = Amount()
    
//    // Variable determining whether the custom numpad is shown or not:
//    @State private var showNumpad = true
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        ZStack(alignment: .bottom) { // Stack the form and the numpad
            
            Form {
                
                Toggle("Income", isOn: $income)
                
                TextField("Payee", text: $payeeFilter)
                //                .focused($payeeFocused)
                
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
                                //                            payeeFocused = false // hide the keyboard
                            }
                    }
                }
                
//                TextField("Amount", value: $amount, formatter: NumberFormatter())
                
                Text(Double(amount.intAmount) / 100, format: .currency(code: currency))
                    .foregroundColor(income ? .green : .primary)
                    .onTapGesture {
//                                withAnimation {
                        amount.showNumpad = true // display the custom numpad
//                                }
//                        payeeFocused = false // in case the payee field is selected, remove focus from it so that the keyboard closes
                    }
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { (category: Category) in
                        Text(category.name ?? "")
                            .tag(category as Category?)
                    }
                }
//                .onAppear {
//                    selectedCategory = categories[0] // default to the provided value
//                }
                
                Picker("Account", selection: $selectedAccount) {
                    ForEach(accounts, id: \.self) { (account: Account) in
                        Text(account.name ?? "")
                            .tag(account as Account?)
                    }
                }
//                .onAppear {
//                    selectedAccount = accounts[0] // default to the provided value
//                }
                
                createTransactionButton
            }
            
            if(amount.showNumpad) {
                NumpadView(amount: amount)
                    .frame(width: 1000, height: 1000)
                    .background(.black)
                    .cornerRadius(10)
//                        .transition(.move(edge: .bottom))
            }
            
        }
    }
    
    var createTransactionButton: some View {
        Button(action: {
            if(amount.intAmount != 0) { // do nothing if the amount is 0
                
                if(selectedAccount == nil || selectedCategory == nil) { // if no valid account and category have been selected, show an alert
                    showingAlert = true
                }
                
                else {
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
                    transaction.period = getPeriod(date: date)
                    transaction.payee = selectedPayee
                    transaction.category = selectedCategory
                    transaction.amount = Int64(amount.intAmount) // save amount as an int, i.e. 2560 means 25,60€ for example
                    transaction.income = income // save the direction of the transaction, true for an income, false for an expense
                    print("Amount: \(transaction.amount)")
                    transaction.currency = currency
                    transaction.memo = memo
                    transaction.account = selectedAccount
                    
                    PersistenceController.shared.save() // save the item
                    
                    amount.intAmount = 0 // clear the amount after saving
                    payeeFilter = "" // clear the payee after saving
                }
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
                    print("Period found")
                    return period
                }
            }
        }
        print("Period NOT found")
        return Period() // if no period is found, return a new one
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView()
    }
}
