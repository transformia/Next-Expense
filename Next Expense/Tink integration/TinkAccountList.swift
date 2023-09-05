//
//  TinkAccountList.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-08-30.
//

import SwiftUI

struct TinkAccountList: View {
    
    let account: Account
    let accountInfo: [(name: String, id: String, type: String, balance: Int)]
    
    @ObservedObject var balance: TransactionDetailView.Amount // the reconciliation balance
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    var body: some View {
        List(accountInfo, id: \.id) { info in
            VStack {
                HStack {
                    Text(info.name)
                    Spacer()
                    Text(Double(info.balance) / 100, format: .currency(code: account.currency ?? "EUR"))
                        .font(.headline)
                }
                
                HStack {
                    Text(info.type)
                    Spacer()
                }
                
//                Text(info.id)
//                    .font(.caption)
            }
            .onTapGesture {
                account.externalid = info.id
                
                balance.intAmount = info.balance
                
                PersistenceController.shared.save()
                
                dismiss()
            }
        }
    }
}

//struct TinkAccountList_Previews: PreviewProvider {
//    static var previews: some View {
//        TinkAccountList(account: Account(), accountInfo: [("Account name", "accountid", "accounttype")])
//    }
//}
