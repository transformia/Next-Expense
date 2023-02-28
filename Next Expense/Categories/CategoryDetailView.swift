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
    
    @State private var showingDeleteAlert = false
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let category: Category // element to display
    
    @State private var name = ""
    @State private var type = "Expense" // tells us the type of the category
    
    // Define category types:
    let types = ["Income", "Expense", "Investment"]
    
    @FocusState var isFocused: Bool // determines whether the focus is on the text field or not
    
    var body: some View {
        VStack {
            HStack {
                TextField("", text: $name)
                    .font(.title)
                    .focused($isFocused)
                    .multilineTextAlignment(.center)
                    .onAppear {
                        name = category.name ?? ""
                    }
                if name != category.name { // if I have modified the name, show a button to save the change
                    Image(systemName: "opticaldiscdrive")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            category.name = name
                            PersistenceController.shared.save()
                            isFocused = false
                        }
                }
            }
                
            Picker("Category type", selection: $type) {
                ForEach(types, id: \.self) {
                    Text($0)
                }
            }
            .onAppear {
                type = category.type ?? ""
            }
            .onChange(of: type) { _ in
                category.type = type
                PersistenceController.shared.save()
            }
//                HStack {
//                    saveButton
//                    Spacer()
//                    deleteButton
//                }
//                .padding()
//                .buttonStyle(BorderlessButtonStyle()) // to avoid that buttons inside the same HStack activate together
            
            
            // Show button to delete the category if it has no transactions:
            if transactions.filter({$0.category == category}).count == 0 {
                Button(role: .destructive) {
                    print("Deleting category \(category.name ?? "")")
                    viewContext.delete(category)
                    PersistenceController.shared.save() // save the change
                    dismiss()
                } label: {
                    Label("Delete category", systemImage: "trash")
                }
                .padding()
            }
            
            TransactionListView(payee: nil, account: nil, category: category)
            .sheet(isPresented: $addTransactionView) {
                AddTransactionView(payee: nil, account: accounts[0], category: category)
            }
        }
    }
    
//    var saveButton: some View {
//        Button {
//            category.name = name
//            category.type = type
//
//            PersistenceController.shared.save() // save the change
//            dismiss()
//        } label : {
//            Label("Save", systemImage: "opticaldiscdrive.fill")
//        }
//    }
    
//    var deleteButton: some View {
//        Button(role: .destructive) {
//            showingDeleteAlert = true
//        } label : {
//            Label("Delete", systemImage: "xmark.circle")
//                .foregroundColor(.red)
//        }
//        .alert(isPresented: $showingDeleteAlert) {
//            Alert(
//                title: Text("Are you sure you want to delete this category?"),
//                message: Text("This cannot be undone"),
//                primaryButton: .destructive(Text("Delete")) {
//                    withAnimation {
//                        viewContext.delete(category)
//                        PersistenceController.shared.save() // save the change
//                        dismiss()
//                    }
//                },
//                secondaryButton: .cancel()
//            )
//        }
//        .buttonStyle(BorderlessButtonStyle()) // to avoid that buttons inside the same HStack activate together
//    }
}

//struct CategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryDetailView()
//    }
//}
