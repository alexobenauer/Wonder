//
//  VCTextMultilineInput.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/5/24.
//

import SwiftUI

struct VCTextMultilineInput: View {
    let itemId: String
    let attribute: String
    
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
        VStack {
            TextEditor(text: $typedText)
                .border(Color.primary.opacity(0.1), width: 1)
                .onChange(of: sub.value) {
                    if sub.value != typedText {
                        self.typedText = sub.value ?? ""
                    }
                }
            
            Button {
                if (typedText != sub.value) {
                    ItemStore.shared.insert(fact: Fact(
                        itemId: itemId,
                        attribute: attribute,
                        value: .string(typedText)
                    ))
                }
            } label: {
                Text("Save")
            }
            .disabled(typedText == sub.value)
        }
        .onAppear(perform: onAppear)
    }
}

#Preview {
    VCTextMultilineInput(itemId: "", attribute: "")
}
