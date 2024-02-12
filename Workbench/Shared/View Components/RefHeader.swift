//
//  RefHeader.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/4/24.
//

import SwiftUI

struct RefHeader: View {
    let refItemId: String
    let allowNewRefs: Bool
    
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
        HStack {
            if let itemId = itemId.value {
                Text(itemId)
                    .font(.system(size: 10, design: .monospaced))
                
                Spacer()
                
                ItemViewMenu(itemId: itemId, relationshipItemId: refItemId, selectedItemViewId: viewId.value, allowNewRefs: allowNewRefs)
                    .font(.system(size: 10))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .onAppear(perform: onAppear)
    }
}

struct ItemViewMenu: View {
    let itemId: String
    let relationshipItemId: String
    let selectedItemViewId: String?
    let allowNewRefs: Bool
    
    @StateObject private var itemType = SimpleItemStoreSubscriber(initialValue: nil as String?)
    @State private var isShowingMenu = false
    
    func onAppear() {
        itemType.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "type").first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        Button {
            isShowingMenu = true
        } label: {
            Text(selectedItemViewId ?? ItemView.viewIds(itemType: itemType.value ?? "").first ?? "-")
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isShowingMenu) {
            ForEach(ItemView.viewIds(itemType: itemType.value ?? ""), id: \.self) { itemViewId in
                HStack {
                    Button {
                        ItemStore.shared.selectView(itemId: itemId, relationshipItemId: relationshipItemId, itemViewId: itemViewId)
                        isShowingMenu = false
                    } label: {
                        Text(itemViewId)
                        
                        Spacer()
                    }
                    .buttonStyle(.plain)
                    
                    if allowNewRefs {
                        Button {
                            let facts = ItemStore.shared.fetchFacts(itemId: relationshipItemId)
                            let newRefId = UUID().uuidString
                            
                            ItemStore.shared.insert(facts: facts.map({ fact in
                                switch fact.attribute {
                                // TODO: Adjust position when in positioned node
                                case "itemViewId":
                                    return Fact(itemId: newRefId, attribute: fact.attribute, value: .itemId(itemViewId))
                                default:
                                    return Fact(itemId: newRefId, attribute: fact.attribute, value: fact.typedValue ?? .null)
                                }
                            }))
                            
                            isShowingMenu = false
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .accessibilityHint(Text("Open view in new reference"))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear(perform: onAppear)
    }
}

//#Preview {
//    RefHeader()
//}
