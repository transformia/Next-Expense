//
//  PeriodTransactionsView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-03-05.
//

import SwiftUI

struct PeriodTransactionsView: View {
    
    let period: Period
    
    var body: some View {
        HStack {
            Image(systemName: period.showtransactions ? "arrowtriangle.down.fill" : "arrowtriangle.right.fill")
                .resizable()
                .frame(width: 10, height: 10)
            
            Text(period.startdate ?? Date(), formatter: dateFormatter)
        }
        .onTapGesture {
            period.showtransactions.toggle()
            PersistenceController.shared.save()
        }
    }
    
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

struct PeriodTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        PeriodTransactionsView(period: Period())
    }
}
