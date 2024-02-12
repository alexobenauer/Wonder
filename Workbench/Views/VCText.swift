//
//  VCText.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct VCText: View {
    let itemId: String
    let attribute: String
    var defaultText: String? = nil
    
    var body: some View {
        ItemStoreValue {
            ItemStore.shared.fetchFacts(
                itemId: itemId,
                attribute: attribute
            ).first?.typedValue?.stringValue ?? defaultText
        } content: { text in
            Text(text)
        }
    }
}

//#Preview {
//    VCText()
//}
