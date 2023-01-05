//
//  NumpadKeyView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-19.
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
                .frame(width: 120, height: 50)
                .background(configuration.isPressed ? Color.gray : Color.black.opacity(0))
                .cornerRadius(10)
                .padding(0)
        }
    }
    
    var body: some View {
//        Text(specialKey == "" ? String(key) : (specialKey == "Backspace") ? "<" : "x")
//            .frame(width: 60, height: 60)
//            .background(.blue)
//            .font(.title)
//            .cornerRadius(10)
//            .onTapGesture {
//                let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
//                impactMed.impactOccurred()
//
//                if(specialKey == "") {
//                    amount.intAmount = amount.intAmount * 10 + Int(key)
//                }
//                else if(specialKey == "Backspace") {
//                    amount.intAmount = amount.intAmount / 10
//                }
//                else if(specialKey == "Done") {
//                    print("Dismiss the keyboard")
//                }
//            }
        
        Button(action: {
            let impactMed = UIImpactFeedbackGenerator(style: .medium) // haptic feedback
            impactMed.impactOccurred() // haptic feedback
            
            if(specialKey == "") {
                amount.intAmount = amount.intAmount * 10 + Int(key)
            }
            else if(specialKey == "Backspace") {
                amount.intAmount = amount.intAmount / 10
            }
            else if(specialKey == "Done") {
//                amount.moveFocusToPayee = true
                amount.intAmount = 0
            }
            
        }) {
            Text(specialKey == "" ? String(key) : (specialKey == "Backspace") ? "<" : "x")
                .font(.title)
        }
        .buttonStyle(KeyButtonStyle())
    }
}

//struct NumpadKeyView_Previews: PreviewProvider {
//    static var previews: some View {
//        NumpadKeyView()
//    }
//}
