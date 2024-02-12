//
//  RefView.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/5/24.
//

import SwiftUI

struct RefView: View {
    let refItemId: String
    
    @StateObject private var itemId = SimpleItemStoreSubscriber(initialValue: nil as String?)
    @StateObject private var viewId = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
    @State private var isMenuOpen = false
    
    func onAppear() {
        itemId.initialize {
            ItemStore.shared.fetchFacts(itemId: refItemId, attribute: "toItemId").first?.typedValue?.stringValue
        }
        
        viewId.initialize {
            ItemStore.shared.fetchFacts(itemId: refItemId, attribute: "itemViewId").first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        VStack {
            if let itemId = itemId.value {
                ItemView(itemId: itemId, selectedItemViewId: viewId.value)
            }
        }
        .onAppear(perform: onAppear)
    }
}

#Preview {
    RefView(refItemId: "")
}
