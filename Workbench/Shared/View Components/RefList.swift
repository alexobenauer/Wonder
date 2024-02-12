//
//  ItemList.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/22/24.
//

import SwiftUI

struct RefList: View {
    let fromItemId: String
    let refType: String
    let sortOrder: SortOrder
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: [String]())
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(sub.value, id: \.self) { refItemId in
                RefRow(refItemId: refItemId, newRefsType: refType)
            }
            
            HStack {
                Spacer()
            }
        }
        .onAppear {
            sub.initialize {
                let rids = ItemStore.shared.getRelationshipIds(fromItemId: fromItemId, referenceType: refType)
                
                return sortOrder == .reverse ? rids : rids.reversed()
            }
        }
    }
}

#Preview {
    RefList(fromItemId: "", refType: "content", sortOrder: .forward)
}
