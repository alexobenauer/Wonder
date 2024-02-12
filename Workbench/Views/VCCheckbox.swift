//
//  VCCheckbox.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct VCCheckbox: View {
    let itemId: String
    let attribute: String
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: false)
    @State private var isChecked = false
    
    var body: some View {
        VStack {
#if os(macOS)
            Toggle("On / off", isOn: $isChecked)
                .labelsHidden()
#else
            Button {
                isChecked.toggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.square" : "square")
            }
            .accessibilityHint(Text("On / off"))
#endif
        }
        .onChange(of: sub.value) {
            if isChecked != sub.value {
                self.isChecked = sub.value
            }
        }
        .onChange(of: isChecked) {
            if sub.value != isChecked {
                ItemStore.shared.insert(fact: Fact(
                    itemId: itemId,
                    attribute: attribute,
                    value: .boolean(isChecked)
                ))
            }
        }
        .onAppear {
            sub.initialize {
                ItemStore.shared.fetchFacts(itemId: itemId, attribute: attribute).first?.typedValue?.booleanValue ?? false
            }
        }
        
    }
}

#Preview {
    VCCheckbox(itemId: "", attribute: "")
}
