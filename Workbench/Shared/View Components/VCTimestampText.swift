//
//  VCTimestampText.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/3/24.
//

import SwiftUI

struct VCTimestampText: View {
    let itemId: String
    let attribute: String
    let format: String
    var defaultText: String? = nil
    
    @StateObject private var sub = SimpleItemStoreSubscriber(initialValue: nil as Date?)
    
    var body: some View {
        TimestampText(date: sub.value, format: format, defaultText: defaultText)
            .onAppear {
                sub.initialize {
                    ItemStore.shared.fetchFacts(
                        itemId: itemId,
                        attribute: attribute
                    ).first?.typedValue?.dateValue
                }
            }
    }
}

struct TimestampText: View {
    let date: Date?
    let format: String
    var defaultText: String? = nil
    
    var string: String? {
        if let date {
            return getString(forDate: date, inFormat: format)
        }
        
        return nil
    }
    
    var body: some View {
        Text(string ?? defaultText ?? "")
    }
}

fileprivate var dateFormatters: [String: DateFormatter] = [:]
fileprivate func getString(forDate date: Date, inFormat format: String) -> String {
    if let df = dateFormatters[format] {
        return df.string(from: date)
    }
    
    let df = DateFormatter()
    df.dateFormat = format
    dateFormatters[format] = df
    return df.string(from: date)
}

//#Preview {
//    VCTimestampText()
//}
