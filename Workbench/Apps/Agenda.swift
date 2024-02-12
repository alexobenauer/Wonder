//
//  Agenda.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/8/24.
//

import SwiftUI

struct Agenda: View {
    @State private var date = Date()
    
    let dateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    func onAppear() {
        let midnight = Calendar.current.startOfDay(for: Date())
        let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: midnight) ?? Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + nextMidnight.timeIntervalSinceNow) {
            self.date = Date()
        }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Button(action: {
                        self.date = Calendar.current.date(byAdding: .day, value: -1, to: self.date) ?? Date()
                    }) {
                        Image(systemName: "arrow.left.circle")
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Text(date, formatter: dateFormatter)
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        self.date = Calendar.current.date(byAdding: .day, value: 1, to: self.date) ?? Date()
                    }) {
                        Image(systemName: "arrow.right.circle")
                            .font(.title)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom)
                
                DayAgenda(date: date)
                    .id(date)

            }
            .padding()
        }
        .onAppear(perform: onAppear)
    }
}

fileprivate struct DayAgenda: View {
    let date: Date
    let dateId: String
    
    init(date: Date) {
        self.date = date
        self.dateId = ItemStore.string(forDate: date)
    }
    
    @StateObject private var allDay = SimpleItemStoreSubscriber(initialValue: [] as [String])
    @StateObject private var timed = SimpleItemStoreSubscriber(initialValue: [] as [String])
    
    func onAppear() {
        allDay.initialize {
            Array(Set(ItemStore.shared.fetchFacts(attribute: "startDay", value: dateId).map({ $0.itemId })))
        }
        
        timed.initialize {
            Array(Set(ItemStore.shared.fetchFacts(attribute: "startTime", valueAtOrAbove: date.startOfDay.timeIntervalSince1970, valueAtOrBelow: date.endOfDay.timeIntervalSince1970).map({ $0.itemId })))
        }
    }
    
    var body: some View {
        VStack {
            ForEach(allDay.value, id: \.self) { itemId in
                ItemView(itemId: itemId)
            }
            
            Divider()
            
            ForEach(timed.value, id: \.self) { itemId in
                ItemView(itemId: itemId)
            }
            
            Divider()
            
            RefList(fromItemId: "", refType: "content", sortOrder: .forward)
            PromptInput(referenceFromItemId: "", refType: "content")
        }
        .onAppear(perform: onAppear)
    }
}

#Preview {
    Agenda()
}
