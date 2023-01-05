//
//  ContentView.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2022-10-12.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        
        TabView {
            AddTransactionView()
//            TransactionListView()
        }
        .tabViewStyle(.page)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
