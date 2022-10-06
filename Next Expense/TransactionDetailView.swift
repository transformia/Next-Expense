//
//  TransactionDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct TransactionDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let transaction: Transaction // transaction to display
    
    var body: some View {
        VStack {
            Text(transaction.account?.name ?? "")
        }
        
        deleteButton
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            withAnimation {
                viewContext.delete(transaction)
                PersistenceController.shared.save() // save the change
                dismiss()
            }
        } label : {
            Label("Delete", systemImage: "xmark.circle")
        }
    }
}

//struct TransactionDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionDetailsView()
//    }
//}
