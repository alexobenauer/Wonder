//
//  Item.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

let itemDefaults: [String: ItemDefaults.Type] = [
    "note": NoteItemDefaults.self,
    "link": LinkItemDefaults.self,
    "todo": TodoItemDefaults.self,
    "event": EventItemDefaults.self,
    "location": LocationItemDefaults.self
]

struct ItemView: View {
    let itemId: String
    var selectedItemViewId: String? = nil
    
    @StateObject private var type = SimpleItemStoreSubscriber(initialValue: nil as String?)
    @StateObject private var lastItemViewId = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
    // MARK: -
    // View directory would typically be in the item store (views are items themselves), but for the Swift environment Workbench, they're part of the compiled codebase. The "target" static optionals are for target-specific injections (only needed outside of Workbench).
    static var targetViewIds: ((_ itemType: String) -> [String])?
    static var targetView: ((_ itemViewId: String?, _ itemId: String) -> (AnyView)?)?
    
    static func viewIds(itemType: String) -> [String] {
        (Self.targetViewIds?(itemType) ?? []) + (itemDefaults[itemType] != nil ? [itemType] : [])
    }
    
    static func view(itemViewId: String, itemId: String) -> AnyView? {
        Self.targetView?(itemViewId, itemId) ?? itemDefaults[itemViewId]?.itemView(itemId: itemId)
    }
    
    static func color(itemId: String, itemType: String? = nil) -> Color? {
        if let type = itemType ?? ItemStore.shared.fetchFacts(itemId: itemId, attribute: "type").first?.value {
            return itemDefaults[type]?.color(itemId: itemId)
        }
        
        return nil
    }
    
    static func updateView(fact: Fact, itemType: String? = nil) -> AnyView? {
        if let type = itemType ?? ItemStore.shared.fetchFacts(itemId: fact.itemId, attribute: "type").first?.value {
            return itemDefaults[type]?.updateView(fact: fact)
        }
        
        return nil
    }
    // MARK: -
    
    func onAppear() {
        type.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "type").first?.typedValue?.stringValue
        }
        
        lastItemViewId.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "lastItemViewId").first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        VStack {
            Self.view(itemViewId: selectedItemViewId ?? lastItemViewId.value ?? Self.viewIds(itemType: type.value ?? "").first ?? "", itemId: itemId) ?? AnyView(Text("No known view for item type \(type.value ?? "-")"))
        }
        .font(.system(size: 14))
        .onAppear(perform: onAppear)
    }
}

#Preview {
    ItemView(itemId: "")
}
