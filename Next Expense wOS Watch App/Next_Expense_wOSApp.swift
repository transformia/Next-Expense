//
//  Next_Expense_wOSApp.swift
//  Next Expense wOS Watch App
//
//  Created by Michael Frisk on 2022-10-12.
//

import SwiftUI

@main
struct Next_Expense_wOS_Watch_AppApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
