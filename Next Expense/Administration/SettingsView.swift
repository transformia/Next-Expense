//
//  SettingsView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2023-02-23.
//

import SwiftUI

struct SettingsView: View {
    
    @State private var defaultCurrency = ""
    @State private var showCSVExportView = false
    
    // Define available currencies:
    let currencies = ["EUR", "SEK"]
    
    var body: some View {
        Form {
            Picker("Default currency", selection: $defaultCurrency) {
                ForEach(currencies, id: \.self) {
                    Text($0)
                }
            }
            .onAppear {
                defaultCurrency = UserDefaults.standard.string(forKey: "DefaultCurrency") ?? "EUR"
            }
            .onChange(of: defaultCurrency) { _ in
                UserDefaults.standard.set(defaultCurrency, forKey: "DefaultCurrency")
            }
            
            Text("Import or export data")
                .onTapGesture {
                    showCSVExportView.toggle()
                }
        }
        .sheet(isPresented: $showCSVExportView) {
            CSVExportView()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
