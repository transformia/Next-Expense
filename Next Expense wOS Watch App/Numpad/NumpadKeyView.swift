//
//  NumpadKeyView.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2023-01-17.
//

import SwiftUI

struct NumpadKeyView: View {
    
    @ObservedObject var amount: AddTransactionView.Amount // the amount being edited
    
    let key: Int
    let specialKey: String
    
    struct KeyButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .padding()
                .foregroundColor(.white)
                .frame(width: 60, height: 30)
//                .background(configuration.isPressed ? Color.gray : Color.blue)
                .background(configuration.isPressed ? Color.gray : Color.black.opacity(0.1))
//                .background(configuration.isPressed ? Color.gray : Color.black.opacity(0))
                .cornerRadius(10)
                .padding(0)
        }
    }
    
    
    var body: some View {
        Button(action: {
            switch(specialKey) {
            case "":
                if(amount.intAmount < 100000000) { // stop accepting new digits when the amount is above one billion (less on Apple watch, otherwise doesn't compile for some reason)
                    amount.intAmount = amount.intAmount * 10 + Int(key)
                }
            case "Backspace":
                amount.intAmount = amount.intAmount / 10
            case "Done":
                amount.showNumpad = false
            default:
                print("Undefined")
            }
        }) {
            switch(specialKey) {
            case "":
                Text(String(key))
                    .font(.title)
            case "Backspace":
                Image(systemName: "delete.backward")
                    .foregroundColor(.cyan)
            case "Done":
                Image(systemName: "checkmark")
                    .font(.title)
                    .foregroundColor(.green)
            default:
                Text("")
                    .font(.title)
            }
        }
        .buttonStyle(KeyButtonStyle())
    }
}

//struct NumpadKeyView_Previews: PreviewProvider {
//    static var previews: some View {
//        NumpadKeyView()
//    }
//}
