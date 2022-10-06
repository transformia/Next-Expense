//
//  ContentView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    var body: some View {
        TabView {
            CategoryListView()
                .tabItem {
                    Label("Categories", systemImage: "dollarsign.circle.fill")
                }
            AccountListView()
                .tabItem {
                    Label("Accounts", systemImage: "banknote")
                }
            
            TransactionListView()
                .tabItem {
                    Label("Transactions", systemImage: "list.triangle")
                }
        }
    }
    
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//    }
//}
