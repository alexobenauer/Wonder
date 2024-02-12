//
//  LinkItem.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct LinkItemDefaults: ItemDefaults {
    static func itemView(itemId: String) -> AnyView? {
        AnyView(LinkItemView(itemId: itemId))
    }
    
    static func color(itemId: String) -> Color? {
        Color(red: 179/255, green: 71/255, blue: 18/255)
    }
    
    static func updateView(fact: Fact) -> AnyView? {
        nil
    }
}

fileprivate struct LinkItemView: View {
    let itemId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            VCLink(itemId: itemId, attribute: "url")
            
            VCText(itemId: itemId, attribute: "title")
                .textSelection(.enabled)
        }
    }
}

#Preview {
    LinkItemView(itemId: "")
}
