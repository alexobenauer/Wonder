//
//  RefPositionedNode.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/4/24.
//

import SwiftUI

struct RefPositionedNode: View {
    let refItemId: String
    
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject private var positionX = SimpleItemStoreSubscriber(initialValue: nil as Double?)
    @StateObject private var positionY = SimpleItemStoreSubscriber(initialValue: nil as Double?)
    @StateObject private var sizeW = SimpleItemStoreSubscriber(initialValue: nil as Double?)
    @StateObject private var sizeH = SimpleItemStoreSubscriber(initialValue: nil as Double?)
    
    @State private var position = CGPoint(x: 425, y: 300)
    @State private var size = CGSize(width: 650, height: 400)
    
    func onAppear() {
        positionX.initialize {
            ItemStore.shared.fetchFacts(itemId: refItemId, attribute: "xPosition").first?.typedValue?.numberValue
        }
        
        positionY.initialize {
            ItemStore.shared.fetchFacts(itemId: refItemId, attribute: "yPosition").first?.typedValue?.numberValue
        }
        
        sizeW.initialize {
            ItemStore.shared.fetchFacts(itemId: refItemId, attribute: "width").first?.typedValue?.numberValue
        }
        
        sizeH.initialize {
            ItemStore.shared.fetchFacts(itemId: refItemId, attribute: "height").first?.typedValue?.numberValue
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            RefHeader(refItemId: refItemId, allowNewRefs: true)
                .foregroundStyle(Color.white)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            position = CGPoint(
                                x: position.x + value.translation.width,
                                y: position.y + value.translation.height
                            )
                        }
                        .onEnded { value in
                            ItemStore.shared.insert(facts: [
                                Fact(itemId: refItemId, attribute: "xPosition", value: .number(position.x + value.translation.width)),
                                Fact(itemId: refItemId, attribute: "yPosition", value: .number(position.y + value.translation.height))
                            ])
                        }
                )
            
            RefView(refItemId: refItemId)
                .padding()
                .background(colorScheme == .dark ? Color.init(hue: 0, saturation: 0, brightness: 0.25) : Color(hue: 0, saturation: 0, brightness: 0.95))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 1)
                .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 2)
                .shadow(color: .black.opacity(0.1), radius: 40, x: 0, y: 12)
            
            Spacer()
        }
        .frame(width: size.width, height: size.height)
        .position(position)
        .onChange(of: positionX.value) { self.position = CGPoint(x: positionX.value ?? 425, y: positionY.value ?? 300) }
        .onChange(of: positionY.value) { self.position = CGPoint(x: positionX.value ?? 425, y: positionY.value ?? 300) }
        .onChange(of: sizeW.value) { self.size = CGSize(width: sizeW.value ?? 650, height: sizeH.value ?? 400) }
        .onChange(of: sizeH.value) { self.size = CGSize(width: sizeW.value ?? 650, height: sizeH.value ?? 400) }
        .onAppear(perform: onAppear)
    }
}

#Preview {
    RefPositionedNode(refItemId: "")
}
