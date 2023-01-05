//
//  ReportingView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-14.
//

import SwiftUI

struct ReportingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryGroup.order, ascending: true)],
        animation: .default)
    private var categoryGroups: FetchedResults<CategoryGroup>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
        animation: .default)
    private var categories: FetchedResults<Category>
    
    @State private var addCategoryGroupView = false // determines whether that view is displayed or not
    
    @ObservedObject var selectedPeriod: CategoryListView.SelectedPeriod // the period selected in CategoryListView
    
    var body: some View {
        NavigationView {
            VStack {
                if(categoryGroups.count >= 3) {
                    NavigationLink {
                        CategoryGroupDetailView(categoryGroup: categoryGroups[0])
                    } label: {
                        CategoryGroupView(categoryGroup: categoryGroups[0])
                    }
                    List {
                        ForEach(categories) { category in
                            if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                                if(category.categorygroups?.contains(categoryGroups[0]) != false) { // if this category is part of this category group
                                    CategoryView(category: category,selectedPeriod: selectedPeriod)
                                }
                            }
                        }
                    }
                    
                    NavigationLink {
                        CategoryGroupDetailView(categoryGroup: categoryGroups[1])
                    } label: {
                        CategoryGroupView(categoryGroup: categoryGroups[1])
                    }
                    List {
                        ForEach(categories) { category in
                            if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                                if(category.categorygroups?.contains(categoryGroups[1]) != false) { // if this category is part of this category group
                                    CategoryView(category: category,selectedPeriod: selectedPeriod)
                                }
                            }
                        }
                    }
                    
                    NavigationLink {
                        CategoryGroupDetailView(categoryGroup: categoryGroups[2])
                    } label: {
                        CategoryGroupView(categoryGroup: categoryGroups[2])
                    }
                    List {
                        ForEach(categories) { category in
                            if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
                                if(category.categorygroups?.contains(categoryGroups[2]) != false) { // if this category is part of this category group
                                    CategoryView(category: category,selectedPeriod: selectedPeriod)
                                }
                            }
                        }
                    }
                }
                
//                List {
//                    ForEach(categoryGroups) { categoryGroup in
//                        NavigationLink {
//                            CategoryGroupDetailView(categoryGroup: categoryGroup)
//                        } label: {
//                            CategoryGroupView(categoryGroup: categoryGroup)
//                                .frame(height: 150)
//                        }
//                    }
//                }
            }
            .sheet(isPresented: $addCategoryGroupView) {
                AddCategoryGroupView()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        addCategoryGroupView.toggle() // show the view where I can add a new element
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

//struct ReportingView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReportingView()
//    }
//}
