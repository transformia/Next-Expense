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
    
    var body: some View {
        VStack {
            Text(category.name ?? "")
            
            List {
                ForEach(transactions) { transaction in
                    if(transaction.category == category) { // if the transaction matches this category
                        NavigationLink {
                            TransactionDetailView(transaction: transaction)
                        } label : {
                            HStack {
                                Text(transaction.account?.name ?? "")
                                Text(transaction.category?.name ?? "")
                                Text(Double(transaction.amount) / 100, format: .currency(code: transaction.currency ?? "EUR"))
                                    .foregroundColor(transaction.income ? .green : .primary)
                                Text(transaction.memo ?? "")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $addTransactionView) {
                AddTransactionView(defaultAccount: accounts[0], defaultCategory: category)
            }
            
            deleteButton
            
            
            Button {
                addTransactionView.toggle() // show the view where I can add a new element
            } label: {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.green)
                    .clipShape(Circle())
            }
            .padding(.bottom, 20.0)
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            withAnimation {
                viewContext.delete(category)
                PersistenceController.shared.save() // save the change
                dismiss()
            }
        } label : {
            Label("Delete category", systemImage: "xmark.circle")
        }
    }
}

//struct CategoryDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryDetailView()
//    }
//}
