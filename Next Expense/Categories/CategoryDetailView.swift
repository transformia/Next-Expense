//
//  CategoryDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to call AddTransactionView with a default account
    
    @State private var addTransactionView = false // determines whether the view for adding elements is displayed or not
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let category: Category // element to display
    
    @State private var name = ""
    @State private var type = "Expense" // tells us the type of the category
    
    // Define category types:
    let types = ["Income", "Expense", "Investment"]
    
    var body: some View {
        VStack {
            Form {
                TextField("Category", text: $name)
                    .onAppear {
                        name = category.name ?? ""
                    }
                Picker("Category type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                .onAppear {
                    type = category.type ?? "Expense"
                }
                HStack {
                    saveButton
                    //                deleteButton
                }
//                .padding()
//                .buttonStyle(BorderlessButtonStyle()) // to avoid that buttons inside the same HStack activate together
            }
            
            TransactionListView(account: nil, category: category)
            .sheet(isPresented: $addTransactionView) {
                AddTransactionView(account: accounts[0], category: category)
            }
        }
    }
    
    var saveButton: some View {
        Button {
            category.name = name
            category.type = type
                
            PersistenceController.shared.save() // save the change
            dismiss()
        } label : {
            Label("Save", systemImage: "opticaldiscdrive.fill")
        }
    }
    
//    var deleteButton: some View {
//        Button(role: .destructive) {
//            withAnimation {
//                viewContext.delete(category)
//                PersistenceController.shared.save() // save the change
//                dismiss()
//            }
//        } label : {
//            Label("Delete category", systemImage: "xmark.circle")
//        }
//    }
}

//struct CategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryDetailView()
//    }
//}
