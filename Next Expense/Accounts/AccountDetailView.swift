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
    
    @State private var addTransactionView = false // determines whether the view for adding elements is displayed or not
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let account: Account // element to display
    
    @State private var name = ""
    @State private var type = "Budget" // tells us the type of the category
    
    // Define category types:
    let types = ["Budget", "External"]
    
//    @State private var balance = 0.0
    @StateObject var balance = AddTransactionView.Amount()
    
    // Category selected for the reconciliation difference:
    @State private var selectedCategory: Category?
    
    @State private var showingDeleteAlert = false
//    @State private var showingReconciliationAlert = false
    
    // Variable determining whether the custom keypad is shown or not:
    @State private var showKeypad = false
    
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
                Text(Double(balance.intAmount) / 100, format: .currency(code: account.currency ?? "EUR"))
                    .font(.headline)
                    .foregroundColor(.blue)
                    .onAppear {
                        balance.intAmount = account.calcBalance(toDate: Date())
                    }
                    .onTapGesture {
                        showKeypad.toggle()
                    }
            }
            
            if(balance.intAmount != account.calcBalance(toDate: Date())) {
                HStack {
                    Text("Difference: ")
                    Text(((Double(balance.intAmount) - Double(account.calcBalance(toDate: Date()))) / 100), format: .currency(code: account.currency ?? "EUR"))
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { (category: Category) in
                            Text(category.name ?? "")
                                .tag(category as Category?)
                        }
                    }
                }
                HStack {
                    Button {
                        print("Reconciling with a difference of \(( Double(balance.intAmount) - Double(account.calcBalance(toDate: Date())) ) / 100)")
                        let transaction = Transaction(context: viewContext)
                        
                        transaction.id = UUID()
                        transaction.timestamp = Date()
                        transaction.date = Date()
                        transaction.period = getPeriod(date: Date())
                        //                    transaction.payee = selectedPayee
                        transaction.category = selectedCategory
                        transaction.amount = Int64(abs(balance.intAmount - account.calcBalance(toDate: Date()))) // save amount as an int, i.e. 2560 means 25,60€ for example
                        transaction.income = balance.intAmount - account.calcBalance(toDate: Date()) > 0 ? true : false // save the direction of the transaction, true for an positive value, false for a negative one
                        transaction.transfer = false // save the information that this is not a transfer
                        print("Amount: \(transaction.amount)")
                        transaction.currency = account.currency
                        transaction.memo = "Reconciliation difference"
                        transaction.account = account
                        
                    } label: {
                        Label("Reconcile", systemImage: "checkmark")
                    }
                    
                    Button {
                        balance.intAmount = account.calcBalance(toDate: Date())
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
        .sheet(isPresented: $showKeypad) {
            NumpadView(amount: balance)
                .presentationDetents([.height(280)])
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
