//
//  EventItem.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/8/24.
//

import SwiftUI

struct EventItemDefaults: ItemDefaults {
    static func itemView(itemId: String) -> AnyView? {
        AnyView(EventItemView(itemId: itemId))
    }
    
    static func color(itemId: String) -> Color? {
        Color(red: 160/255, green: 42/255, blue: 42/255)
    }
    
    static func updateView(fact: Fact) -> AnyView? {
        nil
    }
}

fileprivate struct EventItemView: View {
    let itemId: String
    
    @StateObject private var date = SimpleItemStoreSubscriber(initialValue: nil as Date?)
    @StateObject private var day = SimpleItemStoreSubscriber(initialValue: nil as String?)
    
    func onAppear() {
        date.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "startTime").first?.typedValue?.dateValue
        }
        
        day.initialize {
            ItemStore.shared.fetchFacts(itemId: itemId, attribute: "startDay").first?.typedValue?.stringValue
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                VCText(itemId: itemId, attribute: "title")
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                
                VCLink(itemId: itemId, attribute: "url")
                
                VCText(itemId: itemId, attribute: "notes")
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
            if let date = date.value {
                Text(date, format: .dateTime)
                    .font(.system(size: 10, design: .monospaced))
            }
            else if let day = day.value{
                Text(day)
                    .font(.system(size: 10, design: .monospaced))
            }
        }
        .onAppear(perform: onAppear)
    }
}

#Preview {
    EventItemView(itemId: "")
}
