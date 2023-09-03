//
//  NumpadKeyView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-19.
//

import SwiftUI

struct NumpadKeyView: View {

    @ObservedObject var amount: TransactionDetailView.Amount // the amount being edited
    
    let key: Int
    let specialKey: String
    
    struct KeyButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .padding()
                .foregroundColor(.white)
                .frame(width: 80, height: 50)
//                .background(configuration.isPressed ? Color.gray : Color.blue)
                .background(configuration.isPressed ? Color.gray : Color.black.opacity(0.1))
//                .background(configuration.isPressed ? Color.gray : Color.black.opacity(0))
                .cornerRadius(10)
                .padding(0)
        }
    }
    
    var body: some View {
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            
            if amount.editingAmountTo {
                switch(specialKey) {
                case "":
                    if(amount.intAmountTo < 100000000000) { // stop accepting new digits when the amount is above one billion
                        amount.intAmountTo = amount.intAmountTo * 10 + Int(key)
                    }
                case "Backspace":
                    amount.intAmountTo = amount.intAmountTo / 10
                case "Clear":
                    amount.intAmountTo = 0
                case "Done":
                    amount.showNumpad = false
                case "-":
                    print("Minus")
                case "+":
                    print("Plus")
                case "=":
                    print("Equal")
                default:
                    print("Undefined")
                }
            }
            else {
                switch(specialKey) {
                case "":
                    if(amount.intAmount < 100000000000) { // stop accepting new digits when the amount is above one billion
                        amount.intAmount = amount.intAmount * 10 + Int(key)
                    }
                case "Backspace":
                    amount.intAmount = amount.intAmount / 10
                case "Clear":
                    amount.intAmount = 0
                case "Done":
                    amount.showNumpad = false
                case "-":
                    print("Minus")
                case "+":
                    print("Plus")
                case "=":
                    print("Equal")
                default:
                    print("Undefined")
                }
            }
        }) {
            switch(specialKey) {
            case "":
                Text(String(key))
                    .font(.title)
            case "Backspace":
                Image(systemName: "delete.backward")
                    .foregroundColor(.cyan)
            case "Clear":
                Image(systemName: "xmark")
                    .foregroundColor(.cyan)
            case "Done":
                Image(systemName: "checkmark")
                    .font(.title)
                    .foregroundColor(.green)
            case "-":
                Text("-")
                    .font(.title)
                    .foregroundColor(.cyan)
            case "+":
                Text("+")
                    .font(.title)
                    .foregroundColor(.cyan)
            case "=":
                Text("=")
                    .font(.title)
                    .foregroundColor(.cyan)
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
