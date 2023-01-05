//
//  AddCategoryToGroupView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-17.
//

import SwiftUI

struct AddCategoryToGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category> // to be able to select a category from a picker
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    let categoryGroup: CategoryGroup
    
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationView { // so that the pickers work
            Form {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { (category: Category) in
                        Text(category.name ?? "")
                            .tag(category as Category?)
                    }
                }
                saveButton
            }
        }
    }
    
    var saveButton: some View {
        Button(action: {
            selectedCategory?.addToCategorygroups(categoryGroup)
            
            PersistenceController.shared.save() // save the item
            
            dismiss() // dismiss this view
        }, label: {
            Label("Save", systemImage: "opticaldiscdrive.fill")
        })
    }
}

//struct AddCategoryToGroupView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddCategoryToGroupView()
//    }
//}
