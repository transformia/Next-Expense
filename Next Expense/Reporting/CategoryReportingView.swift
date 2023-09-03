//
//  CategoryReportingView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-06-06.
//

import SwiftUI

struct CategoryReportingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to display the periods
    
    let category: Category
    
    @State private var totalBudget = 0.0
    @State private var totalBalance = 0.0
    
    @State private var defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
    
    var body: some View {
        VStack {
            
            HStack {
                Spacer()
                Text("Period")
                Spacer()
                Text("Budget")
                Spacer()
                Text("Actual")
                Spacer()
            }
            .bold()
            
            ForEach(periods) { period in
                if period.year == 2023 || period.year == 2022 {
                    HStack {
                        Spacer()
                        PeriodView(period: period)
                        Spacer()
                        Text(category.getBudget(period: period), format: .currency(code: defaultCurrency))
                        Spacer()
                        Text(category.calcBalance(period: period), format: .currency(code: defaultCurrency))
                        Spacer()
                    }
                }
            }
            
            HStack {
                Spacer()
                Text("Total")
                Spacer()
                Text(totalBudget, format: .currency(code: defaultCurrency))
                    .onAppear {
                        for period in periods {
                            totalBudget += category.getBudget(period: period)
                            totalBalance += category.calcBalance(period: period)
                        }
                    }
                Spacer()
                Text(totalBalance, format: .currency(code: defaultCurrency))
                Spacer()
            }
            .bold()
        }
    }
}

struct CategoryReportingView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryReportingView(category: Category())
    }
}
