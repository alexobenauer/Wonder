//
//  VCTextInput.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/5/24.
//

import SwiftUI

struct VCTextInput: View {
    let itemId: String
    let attribute: String
    let placeholder: String
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: nil as String?)
    @State private var typedText = ""
    
    func onAppear() {
        sub.initialize {
            ItemStore.shared.fetchFacts(
                itemId: itemId,
                attribute: attribute
            ).first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        TextField(placeholder, text: $typedText)
            .onChange(of: sub.value) {
                if sub.value != typedText {
                    self.typedText = sub.value ?? ""
                }
            }
            .onSubmit {
                if (typedText != sub.value) {
                    ItemStore.shared.insert(fact: Fact(
                        itemId: itemId,
                        attribute: attribute,
                        value: .string(typedText)
                    ))
                }
            }
            .onAppear(perform: onAppear)
    }
}

#Preview {
    VCTextInput(itemId: "", attribute: "", placeholder: "Placeholder")
}
