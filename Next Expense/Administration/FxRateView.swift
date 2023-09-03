//
//  FxRateView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-02-23.
//

import SwiftUI

struct FxRateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FxRate.startdate, ascending: false)],
        animation: .default)
    private var fxrates: FetchedResults<FxRate>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to be able to choose a period for the exchange rate
    
    @State private var currency1 = "EUR"
    @State private var currency2 = "SEK"
    @State private var period = Period() // period (month) selected in the picker
    
    @StateObject var rateAmount = TransactionDetailView.Amount() // stores the rate amount, and the visibility of the numpad as seen from NumpadView / NumpadKeyView
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        VStack {
            VStack {
                
                Picker("Period", selection: $period) {
                    ForEach(periods, id: \.self) { period in
                        Text(period.startdate ?? Date(), formatter: dateFormatter)
                    }
                }
                .onAppear {
                    period = getPeriod(date: Date())
                }
                
                HStack {
                    Picker("From", selection: $currency1) {
                        ForEach(currencies, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Text("\(Double(rateAmount.intAmount) / 100, specifier: "%.2f")") // exchange rate
                        .onTapGesture {
                            rateAmount.showNumpad.toggle()
                        }
                    
                    Picker("To", selection: $currency2) {
                        ForEach(currencies, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    // If I've selected two different currencies, entered a rate, and there is not rate for that period and currency pair yet, show a button to save the rate:
                    if currency1 != currency2 && rateAmount.intAmount != 0 && fxrates.filter({$0.startdate == period.startdate &&
                        ($0.currency1 == currency1 && $0.currency2 == currency2
                         ||
                         $0.currency1 == currency2 && $0.currency2 == currency1)
                    }).count == 0 {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .onTapGesture {
                                let fxRate = FxRate(context: viewContext)
                                fxRate.id = UUID()
                                fxRate.startdate = period.startdate // to be able to sort them by period
                                fxRate.period = period
                                fxRate.currency1 = currency1
                                fxRate.currency2 = currency2
                                fxRate.rate = Int16(rateAmount.intAmount)
                                PersistenceController.shared.save()
                                rateAmount.intAmount = 0
                            }
                    }
                }
            }
            .sheet(isPresented: $rateAmount.showNumpad) {
                NumpadView(amount: rateAmount)
                    .presentationDetents([.height(300)])
            }
            
            
            List {
                ForEach(fxrates) { fxrate in
                    HStack {
                        Text(fxrate.period?.startdate ?? Date(), formatter: dateFormatter)
                        Spacer()
                        Text("1 \(fxrate.currency1 ?? "")  =")
                        Spacer()
                        Text("\(Double(fxrate.rate) / 100, specifier: "%.2f")")
                        Text(fxrate.currency2 ?? "")
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }
                }
                .onDelete(perform: deleteRate)
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
    
    private func deleteRate(at offsets: IndexSet) {
        for index in offsets {
            let fxRate = fxrates[index]
            viewContext.delete(fxRate)
        }
        
        PersistenceController.shared.save() // save the changes
    }
    
    private func getPeriod(date: Date) -> Period { // get the period corresponding to the chosen date. Exists in AccountDetailView, AddTransactionView, MiniReportingView, ReportingView, FxRateView, CSVExportView, DebtorView, ...?
        let year = Calendar.current.dateComponents([.year], from: date).year ?? 1900
        let month = Calendar.current.dateComponents([.month], from: date).month ?? 1
        
        for period in periods {
            if(period.year == year) {
                if(period.month == month) {
                    return period
                }
            }
        }
        return Period() // if no period is found, return a new one
    }
}

struct FxRateView_Previews: PreviewProvider {
    static var previews: some View {
        FxRateView()
    }
}
