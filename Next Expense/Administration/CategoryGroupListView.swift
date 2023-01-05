//
//  CategoryGroupListView.swift
//  Next Expense
//
//  Created by Michael Frisk on 2022-11-03.
//

import SwiftUI

struct CategoryGroupListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.id, ascending: true)],
        animation: .default)
    private var groups: FetchedResults<CategoryGroup> // to be able to display the category groups
    
    var body: some View {
        List {
            ForEach(groups) { group in
                NavigationLink {
                    HStack {
                        CategoryGroupDetailView(categoryGroup: group)
                    }
                } label : {
                    Text("\(group.order)")
                    Text(group.name ?? "")
                }
            }
//            .onMove(perform: moveItem)
        }
    }
}

struct CategoryGroupListView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryGroupListView()
    }
}
