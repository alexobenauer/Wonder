//
//  ItemSelector.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/5/24.
//

import SwiftUI

struct ItemSelector: View {
    var itemTypes: [String] = []
    let select: (_ itemId: String) -> Void
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: [] as [String])
    
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    func onAppear() {
        if itemTypes.count > 0 {
            sub.initialize {
                var res: [String] = []
                
                for type in itemTypes {
                    res.append(contentsOf: ItemStore.shared.fetchFacts(attribute: "type", value: type).map({ $0.itemId }))
                }
                
                return res
            }
        }
        else {
            sub.initialize {
                ItemStore.shared.fetchFacts(attribute: "type").map({ $0.itemId }) // limit batch size?
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(sub.value, id: \.self) { itemId in
                    Button {
                        select(itemId)
                    } label: {
                        ItemCell(itemId: itemId)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
    }
}

struct ItemCell: View {
    let itemId: String
    
    @StateObject private var type = SimpleItemStoreSubscriber(initialValue: nil as String?)
    @StateObject private var name = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
    func onAppear() {
        type.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "type").first?.typedValue?.stringValue
        }
        
        name.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "name").first?.typedValue?.stringValue ??
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "title").first?.typedValue?.stringValue ??
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "subject").first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        VStack {
            Text(name.value ?? "Unnamed")
                .font(.title2)
            
            Text(type.value ?? "Untyped")
                .font(.caption)
                .fontDesign(.monospaced)
        }
        .onAppear(perform: onAppear)
    }
}

//#Preview {
//    ItemSelector()
//}
