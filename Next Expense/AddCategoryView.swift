//
//  AddCategoryView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-09-23.
//

import SwiftUI

struct AddCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to find the next available order int
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    // Define variables for the new category's attributes:
    @State private var name = ""
    
    var body: some View {
        VStack {
            Form {
                TextField("Category name", text: $name)
            }
            createCategoryButton
        }
    }
    
    var createCategoryButton: some View {
        Button(action: {
            let category = Category(context: viewContext)
            
            category.id = UUID()
            category.name = name
            category.order = (categories.last?.order ?? 0) + 1
            
            PersistenceController.shared.save() // save the item
            
            dismiss() // dismiss this view
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
    }
}

struct AddCategoryView_Previews: PreviewProvider {
    static var previews: some View {
        AddCategoryView()
    }
}
