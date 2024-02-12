//
//  DraftingTable.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/1/24.
//

import SwiftUI

fileprivate class DraftingTableStore: ItemStoreSubscriber, ObservableObject {
    init(itemId: String) {
        self.itemId = itemId
        self.unsubscribe = ItemStore.shared.subscribeToNewFacts(self)
        
        reload()
    }
    
    struct Row {
        let itemId: String
        let type: String
        let children: [Row]
        
        let relationshipId: String
        let parentId: String
        
        let lastUpdated: Date
    }
    
    let itemId: String
    var unsubscribe: (() -> Void)? = nil
    
    @Published var rows: [Row] = []
    
    func newFacts(_ facts: [Fact]) {
        if facts.contains(where: { fact in
            fact.attribute == "fromItemId" && fact.value == itemId
        }) {
            reload()
            return
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
        var seenIds: [String] = []
        
        func getRows(itemId: String) -> [Row] {
            if seenIds.contains(itemId) {
                return [] // TODO: ?
            }
            
            seenIds.append(itemId)
            
            var rows: [Row] = []
            
            let refs = ItemStore.shared.fetchFacts(attribute: "fromItemId", value: itemId).map({ (itemId: $0.itemId, timestamp: $0.timestamp) })
            
            for ref in refs {
                let toItemId = ItemStore.shared.fetchFacts(itemId: ref.itemId, attribute: "toItemId").first
                let toItemType = ItemStore.shared.fetchFacts(itemId: toItemId?.value ?? "", attribute: "type").first
                let children = getRows(itemId: toItemId?.value ?? "")
                let parentId = itemId
                let lastUpdated = ([ref.timestamp, toItemType?.timestamp ?? .distantPast] + children.map({ $0.lastUpdated })).max() ?? .distantPast
                
                if let itemId = toItemId?.value,
                   let type = toItemType?.value {
                    rows.append(Row(
                        itemId: itemId,
                        type: type,
                        children: children,
                        relationshipId: ref.itemId,
                        parentId: parentId,
                        lastUpdated: lastUpdated
                    ))
                }
            }
            
            return rows
        }
        
        self.rows = getRows(itemId: itemId)
            .sorted(by: { a, b in
                a.lastUpdated > b.lastUpdated
            })
    }
}

struct DraftingTable: View {
    init(itemId: String) {
        self.itemId = itemId
        self._store = StateObject(wrappedValue: DraftingTableStore(itemId: itemId))
    }
    
    var itemId: String
    @StateObject private var store: DraftingTableStore
    
    var body: some View {
        ScrollView {
            VStack {
                PromptInput(referenceFromItemId: itemId, refType: "content")
                    .padding(.bottom)
                
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(store.rows, id: \.itemId) { row in
                        RefRow(refItemId: row.relationshipId, newRefsType: "content")
                    }
                    
                    HStack {
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: 650, alignment: .center)
            .padding()
            
            HStack {
                Spacer()
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    DraftingTable(itemId: "")
}
