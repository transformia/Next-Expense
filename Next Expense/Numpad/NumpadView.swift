//
//  NumpadView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-19.
//

import SwiftUI

struct NumpadView: View {
    
    @ObservedObject var amount: AddTransactionView.Amount // the amount being edited
    
    var body: some View {
        VStack {
            
            Text(Double(amount.intAmount) / 100, format: .currency(code: "EUR")) // amount budgeted
            
            VStack {
                HStack {
                    NumpadKeyView(amount: amount, key: 1, specialKey: "")
                    NumpadKeyView(amount: amount, key: 2, specialKey: "")
                    NumpadKeyView(amount: amount, key: 3, specialKey: "")
                }
                HStack {
                    NumpadKeyView(amount: amount, key: 4, specialKey: "")
                    NumpadKeyView(amount: amount, key: 5, specialKey: "")
                    NumpadKeyView(amount: amount, key: 6, specialKey: "")
                }
                HStack {
                    NumpadKeyView(amount: amount, key: 7, specialKey: "")
                    NumpadKeyView(amount: amount, key: 8, specialKey: "")
                    NumpadKeyView(amount: amount, key: 9, specialKey: "")
                }
                HStack {
                    NumpadKeyView(amount: amount, key: 0, specialKey: "Backspace")
                    NumpadKeyView(amount: amount, key: 0, specialKey: "")
                    NumpadKeyView(amount: amount, key: 0, specialKey: "Done")
                    
                    
                }
            }
        }
    }
}

//struct NumpadView_Previews: PreviewProvider {
//    static var previews: some View {
//        NumpadView()
//    }
//}
