//
//  ItemInfo.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/5/24.
//

import SwiftUI

struct ItemInfo: View {
    let itemId: String
    var overrideTimestamp: Date? = nil
    
    @StateObject private var type = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
    func onAppear() {
        type.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "type").first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        HStack {
            Text(type.value ?? "")
            
            Spacer()
            
            if let overrideTimestamp {
                TimestampText(date: overrideTimestamp, format: "E, MMM d h:mm a")
            }
            else {
                VCTimestampText(itemId: itemId, attribute: "created", format: "E, MMM d h:mm a")
            }
        }
        .font(.system(size: 12, design: .monospaced))
        .onAppear(perform: onAppear)
    }
}

//#Preview {
//    ItemInfo()
//}
