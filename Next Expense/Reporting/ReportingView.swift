//
//  ReportingView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-14.
//


/*
import SwiftUI

struct ReportingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryGroup.order, ascending: true)],
//        animation: .default)
//    private var categoryGroups: FetchedResults<CategoryGroup>
//
//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
//        animation: .default)
//    private var categories: FetchedResults<Category>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Period.startdate, ascending: true)],
        animation: .default)
    private var periods: FetchedResults<Period> // to determine the period of the transaction, to calculate the total balance on the correct date
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Account.order, ascending: true)],
        animation: .default)
    private var accounts: FetchedResults<Account> // to be able to calculate the total balance using the extension on Account
    
    @State private var addCategoryGroupView = false // determines whether that view is displayed or not
    
    @EnvironmentObject var selectedPeriod: ContentView.SelectedPeriod // get the selected period from the environment
    
    @EnvironmentObject var periodBalances: ContentView.PeriodBalances // the balances of the selected period
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    
                    VStack(alignment: .leading) {
                        Text("")
                        Text("Income")
                        Text("Expenses")
                        Text("Savings")
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Budget")
                        
                        Text(periodBalances.incomeBudget / 100, format: .currency(code: "EUR"))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
                                }
                            }
                            .onChange(of: selectedPeriod.period) { _ in
    //                            (periodBalances.incomeBudget, periodBalances.expensesBudget) = monthlyBudgets()
                                // Calculate the period budgets - done in MiniReportingView and CategoryView:
                                (periodBalances.incomeBudget, periodBalances.expensesBudget) = selectedPeriod.period.calcBudgets()
    //                            periodBalances.expensesBudget = monthlyBudgets().1
                            }
                        
                        Text(periodBalances.expensesBudget / 100, format: .currency(code: "EUR"))
                        
                        Text((periodBalances.incomeBudget - periodBalances.expensesBudget) / 100, format: .currency(code: "EUR"))
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("Actual")
                        
                        Text(periodBalances.incomeActual / 100, format: .currency(code: "EUR"))
//                            .onAppear {
//                                (periodBalances.incomeActual, periodBalances.expensesActual) = selectedPeriod.period.calcBalances()
//                            }
//                            .onChange(of: selectedPeriod.period) { _ in
//                                // Calculate the period balances - done in MiniReportingView and AddTransactionView:
//                                (periodBalances.incomeActual, periodBalances.expensesActual) = selectedPeriod.period.calcBalances()
//                            }
                        
                        Text(periodBalances.expensesActual / 100, format: .currency(code: "EUR"))
                        
                        Text((periodBalances.incomeActual - periodBalances.expensesActual) / 100, format: .currency(code: "EUR"))
                    }
                    
                    Spacer()
                }
                
                VStack {
                    HStack {
                        Text("Budget balance")
                        Text(periodBalances.totalBalance / 100, format: .currency(code: "EUR"))
    //                        .onAppear { // not needed, because the period always changes when the view appears?
    //                            periodBalances.totalBalance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
    //                        }
                        /*
                            .onChange(of: selectedPeriod.period) { _ in
    //                            periodBalances.totalBalance = totalBalance(periodStartDate: selectedPeriod.periodStartDate)
                                
                                // Calculate the total balance - done in MiniReportingView and AddTransactionView:
                                periodBalances.totalBalance = 0.0
                                let defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
                                // Set the date to today if the current period is selected, or the end of the period if a past or future period is selected:
                                var consideredDate: Date
                                if selectedPeriod.period == getPeriod(date: Date()) {
                                    consideredDate = Date()
                                }
                                else {
                                    var components = DateComponents()
                                    components.year = Int(selectedPeriod.period.year)
                                    components.month = Int(selectedPeriod.period.month) + 1
                                    components.day = 1
                                    consideredDate = Calendar.current.startOfDay(for: Calendar.current.date(from: components) ?? Date())
                                }
                                
//                                print("Calculating total balance as of \(consideredDate)")
//                                for account in accounts {
//                                    if account.type == "Budget" { // ignore external accounts
//                                        if account.currency == defaultCurrency { // for accounts in the default currency
//                                            periodBalances.totalBalance += Double(account.calcBalance(toDate: consideredDate))
//                                        }
//                                        else { // for accounts in a different currency, add the amount converted to the default currency using the selected period's exchange rate, if there is one, otherwise add 0
//                                            if let fxRate = selectedPeriod.period.getFxRate(currency1: defaultCurrency, currency2: account.currency ?? "") {
//                                                periodBalances.totalBalance += Double(account.calcBalance(toDate: consideredDate)) / fxRate * 100.0
//                                            }
//                                        }
//                                    }
//                                }
                            }
                        */
                    }
                    HStack {
                        Text("Budget available")
                        
                        Text(periodBalances.budgetAvailable / 100, format: .currency(code: "EUR")) // calculated in the periodBalances struct
                    }
                }
            }
            .padding()
            
            
            
            
            // Old code where I tried to make a P&L - move this to another view?:
            /*
            VStack {
                if(categoryGroups.count >= 3) {
                    NavigationLink {
                        CategoryGroupDetailView(categoryGroup: categoryGroups[0])
                    } label: {
                        CategoryGroupView(categoryGroup: categoryGroups[0])
                    }
                    List {
                        ForEach(categories) { category in
                            if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                                if(category.categorygroups?.contains(categoryGroups[0]) != false) { // if this category is part of this category group
                                    CategoryView(category: category)
                                }
                            }
                        }
                    }
                    
                    NavigationLink {
                        CategoryGroupDetailView(categoryGroup: categoryGroups[1])
                    } label: {
                        CategoryGroupView(categoryGroup: categoryGroups[1])
                    }
                    List {
                        ForEach(categories) { category in
                            if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                                if(category.categorygroups?.contains(categoryGroups[1]) != false) { // if this category is part of this category group
                                    CategoryView(category: category)
                                }
                            }
                        }
                    }
                    
                    NavigationLink {
                        CategoryGroupDetailView(categoryGroup: categoryGroups[2])
                    } label: {
                        CategoryGroupView(categoryGroup: categoryGroups[2])
                    }
                    List {
                        ForEach(categories) { category in
                            if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                                if(category.categorygroups?.contains(categoryGroups[2]) != false) { // if this category is part of this category group
                                    CategoryView(category: category)
                                }
                            }
                        }
                    }
                }
                
//                List {
//                    ForEach(categoryGroups) { categoryGroup in
//                        NavigationLink {
//                            CategoryGroupDetailView(categoryGroup: categoryGroup)
//                        } label: {
//                            CategoryGroupView(categoryGroup: categoryGroup)
//                                .frame(height: 150)
//                        }
//                    }
//                }
            }
            .sheet(isPresented: $addCategoryGroupView) {
                AddCategoryGroupView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addCategoryGroupView.toggle() // show the view where I can add a new element
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            */
        }
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

//struct ReportingView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReportingView()
//    }
//}


*/
