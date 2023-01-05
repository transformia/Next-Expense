//
//  AddCategoryGroupView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-14.
//

import SwiftUI

struct AddCategoryGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryGroup.id, ascending: true)],
        animation: .default)
    private var categoryGroups: FetchedResults<CategoryGroup> // to be able to find the next available order int
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    // Define variables for the new category group's attributes:
    @State private var name = ""
    
    var body: some View {
        VStack {
            Form {
                TextField("Category group name", text: $name)
            }
            createCategoryGroupButton
        }
    }
    
    var createCategoryGroupButton: some View {
        Button(action: {
            let categoryGroup = CategoryGroup(context: viewContext)
            
            categoryGroup.id = UUID()
            categoryGroup.name = name
            categoryGroup.order = (categoryGroups.last?.order ?? 0) + 1
            
            PersistenceController.shared.save() // save the item
            
            dismiss() // dismiss this view
        }, label: {
            Label("Create", systemImage: "opticaldiscdrive.fill")
        })
    }
}

struct AddCategoryGroupView_Previews: PreviewProvider {
    static var previews: some View {
        AddCategoryGroupView()
    }
}
