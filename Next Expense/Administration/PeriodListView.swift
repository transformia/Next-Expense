//
//  PeriodListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-18.
//

import SwiftUI

struct PeriodListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to display the periods
    
    var body: some View {
        VStack {
//            Button( action: {
//                clearPeriods()
//            }, label: {
//                Text("Clear all periods")
//            })
            List {
                ForEach(periods) { period in
                    PeriodView(period: period)
                }
                .onDelete(perform: deletePeriod)
            }
        }
        .toolbar {
            ToolbarItem {
                EditButton()
            }
        }
    }
    
    private func deletePeriod(at offsets: IndexSet) {
        for index in offsets {
            let period = periods[index]
            if period.transactions?.count == 0 {
                viewContext.delete(period)
            }
            else {
                print("This period has transactions. It cannot be deleted")
            }
        }
        
        PersistenceController.shared.save() // save the changes
    }
    
    private func clearPeriods() {
        print("Clearing all periods")
        if(periods.count > 0) {
            for i in 0 ... periods.count - 1 {
                viewContext.delete(periods[i])
            }
            PersistenceController.shared.save() // save the changes
        }
    }
}

struct PeriodListView_Previews: PreviewProvider {
    static var previews: some View {
        PeriodListView()
    }
}
