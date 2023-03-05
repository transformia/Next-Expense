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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryGroup.id, ascending: true)],
        animation: .default)
    private var categoryGroups: FetchedResults<CategoryGroup> // to be able to select a category group
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    // Define variables for the new category's attributes:
    @State private var name = ""
    @State private var type = "Expense" // tells us the type of the category
    @State private var categoryGroup: CategoryGroup?
    
    // Define category types:
    let types = ["Income", "Expense", "Investment"]
    
    var body: some View {
        VStack {
            Form {
                TextField("Category name", text: $name)
                Picker("Category type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                Picker("Category group", selection: $categoryGroup) {
                    ForEach(categoryGroups, id: \.self) { (categoryGroup: CategoryGroup) in
                        Text(categoryGroup.name ?? "")
                            .tag(categoryGroup as CategoryGroup?)
                    }
                }
                .onAppear {
                    if categoryGroups.count > 0 {
                        categoryGroup = categoryGroups[0]
                    }
                }
            }
            createCategoryButton
        }
    }
    
    var createCategoryButton: some View {
        Button(action: {
            let category = Category(context: viewContext)
            
            category.id = UUID()
            category.name = name
            category.type = type
            category.categorygroup = categoryGroup
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
