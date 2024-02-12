//
//  RefCanvas.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/4/24.
//

import SwiftUI

struct RefCanvas: View {
    let fromItemId: String
    let refType: String
    let defaultNewItemType: String
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: [String]())
    
    func onAppear() {
        sub.initialize {
            ItemStore.shared.getRelationshipIds(fromItemId: fromItemId, referenceType: refType)
        }
    }
    
    func addItem() {
        ItemStore.shared.createItem(
            type: defaultNewItemType,
            referenceFrom: fromItemId,
            referenceType: refType,
            resource: nil
        )
    }
    
    var body: some View {
        ZStack {
            Image("dot")
                .resizable(resizingMode: .tile)
                .opacity(0.25)
            
            ForEach(sub.value, id: \.self) { refItemId in
                RefPositionedNode(refItemId: refItemId)
            }
        }
        .onTapGesture(count: 2) {
            addItem()
        }
        .onAppear(perform: onAppear)
    }
}

#Preview {
    RefCanvas(fromItemId: "", refType: "", defaultNewItemType: "")
}
