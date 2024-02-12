//
//  GenericItemView.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/9/24.
//

import SwiftUI

struct GenericItemView: View {
    let itemId: String
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: [String: Fact]())
    
    func onAppear() {
        sub.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId)
                .reduce(into: [:]) { partialResult, fact in
                    if partialResult[fact.attribute] == nil {
                        partialResult[fact.attribute] = fact
                    }
                }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(itemId)
                    .font(.system(size: 10, design: .monospaced))
                    .padding(.top, 12)
                    .padding(.bottom, 4)
             
                Spacer()
                
                Button {
                    ItemStore.shared.deleteItem(itemId: itemId)
                } label: {
                    Label("Delete item", systemImage: "trash")
                }
                .buttonStyle(.plain)
            }
            
            ForEach(sub.value.keys.sorted(), id: \.self) {
                GenericAttributeView(fact: sub.value[$0]!)
            }
        }
        .onAppear(perform: onAppear)
    }
}

struct GenericAttributeView: View {
    let fact: Fact
    
    var body: some View {
        HStack {
            Text(fact.attribute)
                .fontDesign(.monospaced)
                .frame(width: 150, alignment: .trailing)
            
            switch fact.typedValue ?? .null {
            case .string(let text):
                Text(text)
            case .number(let number):
                Text("\(number)")
            case .timestamp(let date):
                TimestampText(date: date, format: "E, d MMM yyyy HH:mm:ss Z", defaultText: "not set")
                    .fontDesign(.monospaced)
            case .itemId(let string):
                Text("Item ID: \(string)")
                    .fontDesign(.monospaced)
            case .boolean(_):
                HStack {
                    VCCheckbox(itemId: fact.itemId, attribute: fact.attribute)
                    Text(fact.attribute)
                }
            case .null:
                Text("null")
            }
        }
    }
}

//#Preview {
//    GenericItemView()
//}
