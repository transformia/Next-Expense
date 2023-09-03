//
//  PayeeDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-01-05.
//

import SwiftUI

struct PayeeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to display a picker on the categories
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to display a picker on the accounts
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Payee.order, ascending: true)],
        animation: .default)
    private var payees: FetchedResults<Payee> // to be able to select a payee to move the transactions of a deleted payee to
    
    let payee: Payee // element to display
    
    @State private var name = ""
    @State private var category: Category?
    @State private var account: Account?
    
    @State private var addTransactionView = false // determines whether the view for adding elements is displayed or not
    
    @State private var showingDeleteAlert = false
    @State private var showingDeletePayeePicker = false
    
    @State private var selectedPayee: Payee? // payee to move the transactions to when deleting a payee
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    var body: some View {
        VStack {
            // Show button to delete the payee:
            
            HStack {
                if !showingDeletePayeePicker {
                    Button(role: .destructive) {
                        if payee.transactions?.count == 0 {
                            print("Deleting payee \(payee.name ?? "")")
                            viewContext.delete(payee)
                            PersistenceController.shared.save() // save the change
                            dismiss()
                        }
                        else {
                            showingDeletePayeePicker = true
                        }
                    } label: {
                        //                    Label("Delete payee", systemImage: "trash")
                        Label("", systemImage: "trash")
                    }
                }
                
                if showingDeletePayeePicker {
                    Picker("Payee", selection: $selectedPayee) {
                        ForEach(payees, id: \.self) { (payee: Payee) in
                            Text(payee.name ?? "")
                                .tag(payee as Payee?)
                        }
                    }
                    
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Label("", systemImage: "checkmark")
                    }
                    .tint(.red)
                    .alert(isPresented: $showingDeleteAlert) {
                        Alert(
                            title: Text("Are you sure that you want to delete this payee and move its transactions to \(selectedPayee?.name ?? "")?"),
                            message: Text("This cannot be undone"),
                            primaryButton: .destructive(Text("Delete")) {
                                // Move the payee's transactions to the selected payee:
                                
                                for transaction in payee.transactions ?? [] {
                                    (transaction as! Transaction).payee = selectedPayee
                                }
                                
                                // Delete the payee:
                                viewContext.delete(payee)
                                
                                PersistenceController.shared.save() // save the change
                                
                                dismiss()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
//            .padding()
            
            Form {
                TextField("Payee", text: $name)
                    .autocorrectionDisabled()
                    .onAppear {
                        name = payee.name ?? ""
                    }
                    .onChange(of: name) { _ in
                        payee.name = name
                        PersistenceController.shared.save()
                    }
                
                Picker("Default category", selection: $category) {
                    ForEach(categories, id: \.self) { (category: Category) in
                        Text(category.name ?? "")
                            .tag(category as Category?)
                    }
                }
                .onAppear {
                    category = payee.category ?? categories[0]
                }
                .onChange(of: category) { _ in
                    payee.category = category
                    PersistenceController.shared.save()
                }
                
                Picker("Default account", selection: $account) {
                    ForEach(accounts, id: \.self) { (account: Account) in
                        Text(account.name ?? "")
                            .tag(account as Account?)
                    }
                }
                .onAppear {
                    account = payee.account ?? accounts[0]
                }
                .onChange(of: account) { _ in
                    payee.account = account
                    PersistenceController.shared.save()
                }
                
//                saveButton
            }
            
            TransactionListView(payee: payee, account: nil, category: nil)
                .sheet(isPresented: $addTransactionView) {
                    TransactionDetailView(transaction: nil, payee: payee, account: nil, category: nil)
                }
            
        }
    }
    
//    var saveButton: some View {
//        Button {
//            payee.name = name
//            payee.category = category
//            payee.account = account
//
//            PersistenceController.shared.save() // save the change
//            dismiss()
//        } label : {
//            Label("Save", systemImage: "opticaldiscdrive.fill")
//        }
//    }
}

//struct PayeeDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PayeeDetailView()
//    }
//}
