//
//  PeriodView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-02-25.
//

import SwiftUI

struct PeriodView: View {
    
    let period: Period
    
    @State private var transactionCount = 0
    
    var body: some View {
        HStack {
            Text(period.monthString ?? "None")
            Text(yearFormatter.string(from: period.year as NSNumber) ?? "None")
//            Text("\(transactionCount)")
//                .onAppear {
//                    transactionCount = period.countTransactions()
//                }
        }
    }
    
    private let yearFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
}

struct PeriodView_Previews: PreviewProvider {
    static var previews: some View {
        PeriodView(period: Period())
    }
}
