//
//  RecurringTransactionsView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-09-10.
//

import SwiftUI

struct RecurringTransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: false), NSSortDescriptor(keyPath: \Transaction.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<Transaction> // to be able to display transactions
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to display totals per category
    
    let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
    
    var body: some View {
        VStack {
            
//            HStack {
//                Text("Monthly income")
//                    .bold()
//                Spacer()
//                Text(-calcRecurring(income: true, recurrence: "Yearly") / 100, format: .currency(code: defaultCurrency))
//            }
            
            
            VStack {
                
                ForEach(categories) { category in
                    if -calcRecurring(category: category, income: false, recurrence: "Monthly") - calcRecurring(category: category, income: false, recurrence: "Yearly") > 0 {
                        HStack {
                            Text(category.name ?? "")
                            Spacer()
                            Text((-calcRecurring(category: category, income: false, recurrence: "Yearly") / 12 - calcRecurring(category: category, income: false, recurrence: "Monthly")) / 100, format: .currency(code: defaultCurrency))
                        }
                    }
                }
                
                HStack {
                    Text("Yearly expenses")
                        .bold()
                    Spacer()
                    Text(-calcRecurring(category: nil, income: false, recurrence: "Yearly") / 100, format: .currency(code: defaultCurrency))
                }
                
                HStack {
                    Text("Monthly expenses")
                        .bold()
                    Spacer()
                    Text(-calcRecurring(category: nil, income: false, recurrence: "Monthly") / 100, format: .currency(code: defaultCurrency))
                }
                
                HStack {
                    Text("Total expenses per month")
                        .bold()
                    Spacer()
                    Text((-calcRecurring(category: nil, income: false, recurrence: "Yearly") / 12 - calcRecurring(category: nil, income: false, recurrence: "Monthly")) / 100, format: .currency(code: defaultCurrency))
                }
            }
            .padding()
            
            List {
                ForEach(transactions.filter({$0.recurring && !$0.transfer && $0.account?.type == "Budget"})) { transaction in
                    TransactionView(transaction: transaction, account: nil)
                }
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private func calcRecurring(category: Category?, income: Bool, recurrence: String) -> Double {
        var amount = 0.0
        for transaction in transactions.filter({ ($0.category == category || category == nil ) && $0.recurring && !$0.transfer && $0.income == income && $0.account?.type == "Budget"}) {
            if transaction.recurrence == recurrence {
                amount += transaction.getAmount()
                print(transaction.getAmount())
            }
        }
        return amount
    }
}

struct RecurringTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        RecurringTransactionsView()
    }
}
