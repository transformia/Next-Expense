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
    
    @Environment(\.dismiss) private var dismiss // used for dismissing this view
        
    let categoryGroup: CategoryGroup
    
    @State private var name = ""
    
    @State private var addCategoryToGroupView = false // determines whether that view is displayed or not
    
    @FocusState var isFocused: Bool // determines whether the focus is on the text field or not
    
    var body: some View {
        VStack {
            HStack {
                TextField("Category group", text: $name)
                    .font(.title)
                    .focused($isFocused)
                    .multilineTextAlignment(.center)
                    .onAppear {
                        name = categoryGroup.name ?? ""
                    }
                if name != categoryGroup.name { // if I have modified the name, show a button to save the change
                    Image(systemName: "opticaldiscdrive")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            categoryGroup.name = name
                            PersistenceController.shared.save()
                            isFocused = false
                        }
                }
            }
            
            List {
                ForEach(categories) { category in
                    if category.categorygroup == categoryGroup {
                        Text(category.name ?? "")
                            .swipeActions(edge: .trailing) {
                                Button {
                                    withAnimation {
                                        category.categorygroup = nil
                                    }
                                    PersistenceController.shared.save() // save the changes
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
                    }
                }
            }
            
            deleteButton
            
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
