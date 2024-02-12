//
//  RefRow.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct RefRow: View {
    let refItemId: String
    let newRefsType: String
    
    @StateObject private var itemId = SimpleItemStoreSubscriber(initialValue: nil as String?)
    @StateObject private var viewId = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
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
                ItemRow(itemId: itemId, preferItemViewId: viewId.value, refType: newRefsType) {
                    RefMenu(refItemId: refItemId)
                }
            }
            else {
                Text("Can't find toItemId")
            }
        }
        .onAppear(perform: onAppear)
    }
}

fileprivate struct RefMenu: View {
    let refItemId: String
    
    var body: some View {
        Button {
            ItemStore.shared.deleteItem(itemId: refItemId)
        } label: {
            Text("Disconnect")
        }
    }
}

#Preview {
    RefRow(refItemId: "", newRefsType: "")
}
