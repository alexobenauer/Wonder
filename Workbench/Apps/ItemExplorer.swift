//
//  ItemExplorer.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/1/24.
//

import SwiftUI

struct ItemExplorer: View {
    @StateObject private var sub = SimpleItemStoreSubscriber(getValue: {
        var result: [String] = []
        
        // maintain sort order
        for fact in ItemStore.shared.fetchFacts() {
            if !result.contains(fact.itemId) {
                result.append(fact.itemId)
            }
        }
        
        return result
    })
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(sub.value, id: \.self) { itemId in
                    GenericItemView(itemId: itemId)
                }
                
                HStack {
                    Spacer()
                }
            }
            .padding()
        }
    }
}

#Preview {
    ItemExplorer()
}
