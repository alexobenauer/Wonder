//
//  EventsProvider.swift
//  Wonder
//
//  Created by Alexander Obenauer on 2/5/24.
//

import SwiftUI
import EventKit

class EventsProvider: ObservableObject {
    let resourceId = "local-events"
    let ekStore = EKEventStore()
    
    @Published var calendars: [EKCalendar] = []
    @Published var ekAuthStatus: EKAuthorizationStatus? = nil
    @Published var lastError: String? = nil
    
    init() {
        ItemStore.shared.mountDrive(forResource: resourceId)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ekUpdate), name: .EKEventStoreChanged, object: nil)
        
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        self.ekAuthStatus = EKEventStore.authorizationStatus(for: .event)
        
        if ekAuthStatus == .fullAccess {
            setup()
        }
    }
    
    func setup() {
        ekStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.ekAuthStatus = EKEventStore.authorizationStatus(for: .event)
                
                if let error {
                    self.lastError = error.localizedDescription
                }
                else {
                    self.calendars = self.ekStore.calendars(for: .event)
                    self.ekUpdate()
                }
            }
        }
    }
    
    private let ekUpdateDebouncer = Debouncer(delay: 0.5)
    @objc func ekUpdate() {
        DispatchQueue.main.async {
            self.ekUpdateDebouncer.debounce {
                self._provideEvents()
            }
        }
    }
    
    private func _provideEvents() {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            return
        }
        
        // Range to fetch events within:
        let fetchDaysBefore = Int(ItemStore.shared.fetchFacts(itemId: resourceId, attribute: "fetchDaysBefore").first?.typedValue?.numberValue ?? 100)
        let fetchDaysAfter = Int(ItemStore.shared.fetchFacts(itemId: resourceId, attribute: "fetchDaysAfter").first?.typedValue?.numberValue ?? 100)
        
        let start = Calendar.current.date(
            byAdding: .day,
            value: fetchDaysBefore * -1,
            to: Date()
        )!
        let end = Calendar.current.date(
            byAdding: .day,
            value: fetchDaysAfter,
            to: Date()
        )!
        
        // Calendars to fetch events from:
        let calendars = self.calendars.filter { calendar in
            ItemStore.shared.fetchFacts(itemId: calendar.calendarIdentifier, attribute: "enabled").first?.typedValue?.booleanValue ?? false
        }
        
        let predicate = ekStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = ekStore.events(matching: predicate) // may want to run on another thread acc. to https://developer.apple.com/documentation/eventkit/retrieving_events_and_reminders

        guard let drive = ItemStore.shared.resourceDrives[resourceId] as? SLDrive else {
            print("Error: Expected an SLDrive for events provider")
            return
        }
        
        drive.resetDatabase()
        
        var allFacts: [Fact] = []
        
        for event in events {
            let timestamp = event.creationDate ?? Date.distantPast
            var itemId = event.eventIdentifier!
            
            if event.hasRecurrenceRules {
                itemId += "-\(event.startDate.timeIntervalSince1970)"
            }
            
            allFacts += ItemStore._factsToCreateItem(
                itemId: itemId,
                type: "event",
                attributes: [
                    "title": .string(event.title),
                    "calendarIdentifier": .string(event.calendar.calendarIdentifier)
                ],
                timestamp: timestamp
            )
            
            if event.isAllDay {
                allFacts += [
                    Fact(
                        itemId: itemId,
                        attribute: "startDay",
                        value: .string(ItemStore.string(forDate: event.startDate)),
                        timestamp: timestamp
                    ),
                    Fact(
                        itemId: itemId,
                        attribute: "endDay",
                        value: .string(ItemStore.string(forDate: event.endDate)),
                        timestamp: timestamp
                    )
                ]
            }
            else {
                allFacts += [
                    Fact(
                        itemId: itemId,
                        attribute: "startTime",
                        value: .timestamp(event.startDate),
                        timestamp: timestamp
                    ),
                    Fact(
                        itemId: itemId,
                        attribute: "endTime",
                        value: .timestamp(event.endDate),
                        timestamp: timestamp
                    )
                ]
            }
            
            if let url = event.url {
                allFacts.append(Fact(
                    itemId: itemId,
                    attribute: "url",
                    value: .string(url.absoluteString),
                    timestamp: timestamp
                ))
            }
            
            if let notes = event.notes {
                allFacts.append(Fact(
                    itemId: itemId,
                    attribute: "notes",
                    value: .string(notes),
                    timestamp: timestamp
                ))
            }
            
            if let location = event.location {
                allFacts.append(Fact(
                    itemId: itemId,
                    attribute: "location",
                    value: .string(location),
                    timestamp: timestamp
                ))
            }
        }
        
        ItemStore.shared.insert(facts: allFacts, resource: resourceId)
    }
}

struct EventsProviderSettings: View {
    @ObservedObject var eventsProvider: EventsProvider
    
    func onAppear() {
        eventsProvider.checkAuthStatus()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Events Provider").font(.title).padding(.bottom, 2)
                Text("Gets events from your device's calendars.").padding(.bottom, 24)
                
                switch eventsProvider.ekAuthStatus {
                case .notDetermined:
                    _RequestAccess(eventsProvider: eventsProvider)
                case .fullAccess:
                    _Settings(eventsProvider: eventsProvider)
                case .restricted:
                    Text("Access to calendar events restricted. In System Preferences > Privacy > Calendars > Workbench > Options, select Full Calendar Access.")
                case .denied:
                    Text("Access to calendar events denied. In System Preferences > Privacy > Calendars > Workbench > Options, select Full Calendar Access.")
                case .writeOnly:
                    Text("Access to calendar events only partially granted. In System Preferences > Privacy > Calendars > Workbench > Options, select Full Calendar Access.")
                default:
                    Text("Cannot determine calendar event access. Check System Preferences > Privacy > Calendars > Workbench.")
                }
            }
            .padding()
        }
        .onAppear(perform: onAppear)
    }
}

fileprivate struct _RequestAccess: View {
    let eventsProvider: EventsProvider
    
    var body: some View {
        Button {
            eventsProvider.setup()
        } label: {
            Text("Grant access to calendar events")
        }
    }
}

fileprivate struct _Settings: View {
    @ObservedObject var eventsProvider: EventsProvider
    
    @State private var calendars: [String: [EKCalendar]] = [:]
    
    func update() {
        var calendars: [String: [EKCalendar]] = [:]
        
        for calendar in eventsProvider.calendars {
            calendars[calendar.source.title, default: []].append(calendar)
        }
        
        self.calendars = calendars
    }
    
    func enabledAll() {
        ItemStore.shared.insert(facts:
            eventsProvider.calendars.map { calendar in
                Fact(itemId: calendar.calendarIdentifier, attribute: "enabled", value: .boolean(true))
            }
        )
    }
    
    func disableAll() {
        ItemStore.shared.insert(facts:
            eventsProvider.calendars.map { calendar in
                Fact(itemId: calendar.calendarIdentifier, attribute: "enabled", value: .boolean(false))
            }
        )
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    enabledAll()
                } label: {
                    Text("Enable all")
                }
                
                Button {
                    disableAll()
                } label: {
                    Text("Disable all")
                }
                
                Spacer()
            }
            .padding(.bottom, 12)
            
            ForEach(calendars.keys.sorted(), id: \.self) { source in
                VStack(alignment: .leading, spacing: 8) {
                    Text(source)
                        .bold()
                        .opacity(0.5)
                    
                    ForEach(calendars[source]!, id: \.calendarIdentifier) { calendar in
                        _CalendarRow(calendar: calendar)
                    }
                }
                .padding(.bottom)
            }
            
            HStack {
                Text("Fetch events from:")
                
                VCTextInput(itemId: eventsProvider.resourceId, attribute: "fetchDaysBefore", placeholder: "100")
                    .frame(maxWidth: 100)
                
                Text("days before today, and")
                
                VCTextInput(itemId: eventsProvider.resourceId, attribute: "fetchDaysAfter", placeholder: "100")
                    .frame(maxWidth: 100)
                
                Text("days after today.")
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .onChange(of: eventsProvider.calendars) {
            update()
        }
        .onAppear {
            update()
        }
    }
}

fileprivate struct _CalendarRow: View {
    let calendar: EKCalendar
    
    var body: some View {
        HStack {
            VCCheckbox(itemId: calendar.calendarIdentifier, attribute: "enabled")
            
            #if os(macOS)
            Circle()
                .fill(Color(calendar.color))
                .frame(width: 12, height: 12)
            #endif
            
            Text(calendar.title)
                .fixedSize()
            
            Spacer()
        }
#if os(macOS)
        .accentColor(Color(calendar.color))
#endif
    }
}
