//
//  TodoItem.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct TodoItemDefaults: ItemDefaults {
    static func itemView(itemId: String) -> AnyView? {
        AnyView(TodoItemView(itemId: itemId))
    }
    
    static func color(itemId: String) -> Color? {
        Color.white
    }
    
    static func updateView(fact: Fact) -> AnyView? {
        if let updateView = todoUpdateView(fact: fact) {
            return AnyView(updateView)
        }
        
        return nil
    }
}

fileprivate struct TodoItemView: View {
    let itemId: String

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            VCCheckbox(itemId: itemId, attribute: "complete")
            
            VCText(itemId: itemId, attribute: "title")
                .textSelection(.enabled)
        }
    }
}

fileprivate func todoUpdateView(fact: Fact) -> AnyView? {
    if fact.attribute == "complete" {
        let complete = fact.typedValue?.booleanValue ?? false
        
        return AnyView(
            HStack {
                Image(systemName: complete ? "checkmark" : "square.dotted")
                
                Text("Todo marked \(complete ? "complete" : "incomplete"): \(ItemStore.shared.fetchFacts(itemId: fact.itemId, attribute: "title").first?.value ?? "(No title)")")
            }
        )
    }
    
    
    return nil
}

#Preview {
    TodoItemView(itemId: "")
}
