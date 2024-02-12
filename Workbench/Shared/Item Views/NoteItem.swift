//
//  NoteItemView.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct NoteItemDefaults: ItemDefaults {
    static func itemView(itemId: String) -> AnyView? {
        AnyView(NoteItemView(itemId: itemId))
    }
    
    static func color(itemId: String) -> Color? {
        Color(red: 217/255, green: 142/255, blue: 22/255)
    }
    
    static func updateView(fact: Fact) -> AnyView? {
        nil
    }
}

fileprivate struct NoteItemView: View {
    let itemId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            VCText(itemId: itemId, attribute: "title")
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    NoteItemView(itemId: "")
}
