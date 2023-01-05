//
//  CategoryGroupDetailView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-17.
//

import SwiftUI

struct CategoryGroupDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    let categoryGroup: CategoryGroup
    
    @State private var name = ""
    
    @State private var addCategoryToGroupView = false // determines whether that view is displayed or not
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
    
    var body: some View {
        VStack {
            TextField("Category group", text: $name)
                .onAppear {
                    name = categoryGroup.name ?? ""
                }
            List {
                ForEach(categories) { category in
                    if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                        if(category.categorygroups?.contains(categoryGroup) != false) { // if this category is part of this category group
                            Text(category.name ?? "")
                        }
                    }
                }
            }
            
            HStack {
                saveButton
                deleteButton
            }
            .padding()
            .buttonStyle(BorderlessButtonStyle()) // to avoid that buttons inside the same HStack activate together
        }
        .sheet(isPresented: $addCategoryToGroupView) {
            AddCategoryToGroupView(categoryGroup: categoryGroup)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addCategoryToGroupView.toggle() // show the view where I can add a new element
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    var saveButton: some View {
        Button {
            categoryGroup.name = name
                
            PersistenceController.shared.save() // save the change
            dismiss()
        } label : {
            Label("Save", systemImage: "opticaldiscdrive.fill")
        }
    }
    
    var deleteButton: some View {
        Button(role: .destructive) {
            withAnimation {
                viewContext.delete(categoryGroup)
                PersistenceController.shared.save() // save the change
                dismiss()
            }
        } label : {
            Label("Delete category group", systemImage: "xmark.circle")
        }
    }
}

//struct CategoryGroupDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryGroupDetailView()
//    }
//}
