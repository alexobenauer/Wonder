//
//  ContentView.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/1/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let eventsProvider = EventsProvider()
    let locationProvider = CurrentLocationProvider()
    
    var providers: [String: any View] {[
        "Events": EventsProviderSettings(eventsProvider: eventsProvider),
        "Location": CurrentLocationProviderSettings(locationProvider: locationProvider)
    ]}
    
    var apps: [String: any View] {[
        // Apps that are really super item views; looking at an item at a time, and its relationships
        "Folio": Folio(itemId: "folio"),
        "Canvas": Canvas(itemId: "folio"),
        "Drafting Table": DraftingTable(itemId: ItemStore.rootId()),
        
        // System-wide apps that look at all items/facts in the store
        //  (they could be developed a little further to match the above, but sometimes with an undesirable performance penalty)
        "Timeline": Timeline(),
        "Fact Explorer": FactExplorer(),
        "Item Explorer": ItemExplorer(),
        "Agenda": Agenda()
    ]}
    
    var body: some View {
        NavigationSplitView {
            List {
                Section {
                    ForEach(apps.keys.sorted(), id: \.self) { name in
                        NavigationLink {
                            AnyView(apps[name]!)
                        } label: {
                            Text(name)
                        }
                    }
                } header: {
                    Text("Apps")
                }
                
                Section {
                    ForEach(providers.keys.sorted(), id: \.self) { name in
                        NavigationLink {
                            AnyView(providers[name]!)
                        } label: {
                            Text(name)
                        }
                    }
                } header: {
                    Text("Providers")
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
        } detail: {
            Text("Select an app or provider")
        }
        .environment(locationProvider)
    }
}

#Preview {
    ContentView()
}
