//
//  FactExplorer.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/1/24.
//

import SwiftUI

extension Fact: Identifiable {
    var id: String {
        factId + timestamp.description
    }
}

struct FactExplorer: View {
    @State private var selectedFact: Fact? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            FactsTable(selectedFact: $selectedFact)
            Divider()
            FactForm(fact: selectedFact).id(selectedFact?.id ?? "*")
        }
    }
}

fileprivate struct FactsTable: View {
    @Binding var selectedFact: Fact?
    
    @StateObject private var sub = SimpleItemStoreSubscriber(getValue: {
        ItemStore.shared.fetchFacts(includeDeleted: true)
    })
    
    @State private var selectedFactIdentifiers = Set<Fact.ID>()
    @State private var sortOrder = [KeyPathComparator(\Fact.timestamp)]
    
    var body: some View {
        Table(sub.value,
              selection: $selectedFactIdentifiers,
              sortOrder: $sortOrder
        ) {
            TableColumn("Fact ID", value: \.factId)
            TableColumn("Item ID", value: \.itemId)
            TableColumn("Attribute", value: \.attribute)
            TableColumn("Value", value: \.value)
            TableColumn("Numerical Value", value: \.numericalValue.description)
            TableColumn("Type", value: \.type)
            TableColumn("Flags", value: \.flags.description)
            TableColumn("Timestamp", value: \.timestamp.description)
        }
        .onChange(of: sortOrder) { _, sortOrder in
            sub.value.sort(using: sortOrder)
        }
        .onChange(of: selectedFactIdentifiers) {
            if selectedFactIdentifiers.count == 1 {
                self.selectedFact = sub.value.first(where: { $0.id == selectedFactIdentifiers.first! })
            }
            else {
                self.selectedFact = nil
            }
        }
    }
}

fileprivate struct FactForm: View {
    init(fact: Fact?) {
        if let fact {
            self.fact = fact
        }
        else {
            self.fact = Fact(itemId: "", attribute: "", value: .null)
        }
    }
    
    @State private var fact: Fact
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Form {
                    Section(header: Text("Fact Information")) {
                        TextField("Fact ID", text: $fact.factId)
                        TextField("Item ID", text: $fact.itemId)
                        TextField("Attribute", text: $fact.attribute)
                        
                        if fact.type == "string" {
                            TextField("Value", text: $fact.value)
                        } else if fact.type == "number" {
                            TextField("Numerical Value", value: $fact.numericalValue, formatter: NumberFormatter())
                        }
                        
                        DatePicker("Timestamp", selection: $fact.timestamp, displayedComponents: .date)
                    }
                    
                    Section(header: Text("Additional Information")) {
                        Picker("Type", selection: $fact.type) {
                            Text("String").tag("string")
                            Text("Number").tag("number")
                        }
                        
                        Stepper("Flags: \(fact.flags)", value: $fact.flags)
                    }
                }
                .padding()
                
                if fact.factId.count > 0 {
                    HStack {
                        Button {
                            ItemStore.shared.deleteFact(fact)
                        } label: {
                            Text("Delete fact")
                        }
                     
                        Text("Inserts a 'deletion' fact mirroring this one.")
                            .font(.caption)
                            .opacity(0.5)
                    }
                }
            }
        }
    }
}

#Preview {
    FactExplorer()
}
