//
//  Timeline.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/2/24.
//

import SwiftUI

struct Timeline: View {
    @State private var dates: [Date] = [
        Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        Date(),
        Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(dates, id: \.timeIntervalSince1970) { date in
                    TimestampText(date: date, format: "EEEE, MMMM d")
                        .font(.title)
                        .bold()
                        .foregroundStyle(Color.accentColor)
                    
                    DayTimeline(date: date)
                }
            }
            .padding()
            
            HStack {
                Spacer()
            }
        }
    }
}

class ActivityListSubscriber: ItemStoreSubscriber, ObservableObject {
    let startTime: Date
    let endTime: Date
    
    private var unsubscribe: (() -> Void)? = nil
    
    @Published var activities: [Activity] = []
    
    init(startTime: Date, endTime: Date) {
        self.startTime = startTime
        self.endTime = endTime
        
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
        
        reload()
    }
    
    deinit {
        unsubscribe?()
    }
    
    func newFacts(_ facts: [Fact]) {
        let dateId = ItemStore.string(forDate: startTime)
        
        for fact in facts {
            if fact.timestamp >= startTime && fact.timestamp <= endTime {
                reload()
                return
            }
            
            if fact.attribute == "startTime", let time = fact.typedValue?.dateValue, time >= startTime, time <= endTime {
                reload()
                return
            }
            
            if fact.attribute == "startDay", fact.value == dateId {
                reload()
                return
            }
        }
    }
    
    private let reloadDebouncer = Debouncer(delay: 0.5)
    
    private func reload() {
        DispatchQueue.main.async {
            self.reloadDebouncer.debounce {
                self.reloadImmediately()
            }
        }
    }
    
    private func reloadImmediately() {
        var activities: [Activity] = []
        let facts = ItemStore.shared.fetchFacts(createdAtOrAfter: startTime, createdAtOrBefore: endTime)
        let timed = ItemStore.shared.fetchFacts(attribute: "startTime", valueAtOrAbove: startTime.timeIntervalSince1970, valueAtOrBelow: endTime.timeIntervalSince1970)
        let allDay = ItemStore.shared.fetchFacts(attribute: "startDay", value: ItemStore.string(forDate: startTime))
        
        for fact in facts {
            if activities.count > 0 && 
                activities[activities.count-1].facts[activities[activities.count-1].facts.count-1].itemId == fact.itemId &&
                activities[activities.count-1].facts[activities[activities.count-1].facts.count-1].timestamp.timeIntervalSince1970.rounded(.down) == fact.timestamp.timeIntervalSince1970.rounded(.down)
            {
                activities[activities.count-1].facts.append(fact)
            }
            else {
                activities.append(Activity(facts: [fact]))
            }
        }
        
        for fact in timed {
            activities.append(Activity(facts: [fact], scheduledType: true))
        }
        
        for fact in allDay {
            activities.append(Activity(facts: [fact], scheduledType: true))
        }
        
        self.activities = activities
            .sorted(by: { a, b in
                a.timestamp < b.timestamp
            })
    }
    
    struct Activity: Identifiable {
        var facts: [Fact]
        let itemId: String
        let itemType: String?
        let timestamp: Date
        let scheduledType: Bool
        
        init(facts: [Fact], scheduledType: Bool = false) {
            self.facts = facts
            self.itemId = facts.first!.itemId
            self.itemType = ItemStore.shared.fetchFacts(itemId: facts.first!.itemId, attribute: "type").first?.value
            self.scheduledType = scheduledType
            
            if scheduledType {
                if let date = facts.first?.typedValue?.dateValue {
                    self.timestamp = date
                }
                else {
                    self.timestamp = ItemStore.date(forString: facts.first!.value) ?? .distantPast
                }
            }
            else {
                self.timestamp = facts.first!.timestamp
            }
        }
        
        enum ActivityType: String {
            case created
            case updated
            case deleted
            case addedToTimeline
            case scheduledFor
        }
        
        var activityType: ActivityType {
            if scheduledType {
                return .scheduledFor
            }
            else if facts.contains(where: { $0.attribute == "created" }) {
                return .created
            }
            else if facts.contains(where: { $0.attribute == "deleted" }) {
                return .deleted
            }
            else {
                return .updated
            }
        }
        
        var id: String {
            facts.first!.factId + "+" + activityType.rawValue
        }
    }
}

fileprivate struct DayTimeline: View {
    let date: Date
    
    @StateObject private var sub: ActivityListSubscriber
    
    init(date: Date) {
        self.date = date
        self._sub = StateObject(wrappedValue: ActivityListSubscriber(startTime: date.startOfDay, endTime: date.endOfDay))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(sub.activities) { activity in
                ActivityRow(activity: activity)
            }
        }
    }
}

fileprivate struct ActivityRow: View {
    init(activity: ActivityListSubscriber.Activity) {
        self.activity = activity
    }
    
    let activity: ActivityListSubscriber.Activity
    
    var view: AnyView? {
        switch activity.activityType {
        case .created, .scheduledFor:
            if activity.itemType == "reference" {
                return nil
            }
            
            return AnyView(
                ItemView(itemId: activity.facts.first!.itemId)
            )
        case .updated:
            return ItemView.updateView(fact: activity.facts.first!, itemType: activity.itemType)
        default:
            return nil
        }
    }
    
    var body: some View {
        if let view {
            HStack(alignment: .top) {
                TimestampText(date: activity.timestamp, format: "h:mm a")
                    .font(.system(size: 12, design: .monospaced))
                    .opacity(activity.activityType == .updated ? 0 : 0.5)
                    .frame(width: 100, alignment: .trailing)
                    .padding(.top, 2)
                
                ZStack {
                    Rectangle()
                        .fill(.primary.opacity(0.1))
                        .frame(width: 1)
                    
                    VStack {
                        ZStack {
                            Circle()
                                .fill(ItemView.color(itemId: activity.facts.first!.itemId) ?? .gray)
                                .frame(width: 11, height: 11)
                                .padding(.top, 3)
                        }
                        Spacer()
                    }
                    .opacity(activity.activityType == .updated ? 0 : 1)
                }
                .padding(.leading, 8)
                .padding(.trailing, 16)
                
                VStack { view }
                    .frame(maxWidth: 650, alignment: .leading)
                    .padding(.bottom, 12)
            }
        }
        else {
            // todo: add a summary line of the skipped facts
        }
    }
}

#Preview {
    Timeline()
}
