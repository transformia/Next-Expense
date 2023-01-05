//
//  CategoryGroupView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-10-14.
//

import SwiftUI

struct CategoryGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext

//    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Category.order, ascending: true)],
//        animation: .default)
//    private var categories: FetchedResults<Category>
    
    let categoryGroup: CategoryGroup
    
    var body: some View {
        VStack {
            Text(categoryGroup.name ?? "")
//            List {
//                ForEach(categories) { category in
//                    if(category.categorygroups?.count ?? 0 >= 1) { // if this category has at least 1 category group
//                        if(category.categorygroups?.contains(categoryGroup) != false) { // if this category is part of this category group
//                            Text(category.name ?? "")
//                        }
//                    }
//                }
//            }
        }
    }
}

//struct CategoryGroupView_Previews: PreviewProvider {
//    static var previews: some View {
//        CategoryGroupView()
//    }
//}
