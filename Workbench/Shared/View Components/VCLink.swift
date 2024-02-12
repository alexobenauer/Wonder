//
//  VCLink.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct VCLink: View {
    let itemId: String
    let attribute: String
    
    var body: some View {
        ItemStoreValue {
            ItemStore.shared.fetchFacts(
                itemId: itemId,
                attribute: attribute
            ).first?.typedValue?.stringValue
        } content: { text in
            Button {
                guard let url = URL(string: text) else {
                    return
                }
                
#if os(macOS)
                NSWorkspace.shared.open(url)
#elseif os(iOS)
                UIApplication.shared.open(url)
#endif
            } label: {
                HStack {
                    Text(text)
                        .lineLimit(1)
                    
                    Image(systemName: "arrow.up.right")
                }
            }
#if os(macOS)
            .buttonStyle(.link)
#endif
        }
    }
}

//#Preview {
//    VCLink()
//}
