//
//  CKDrive.swift
//  ItemizedPlayground
//
//  Created by Alexander Obenauer on 11/10/23.
//

import Foundation
import SwiftData

#if CLOUDKIT

class CKDrive: ItemDrive {
    let name: String
    let container: ModelContainer

    init(name: String, inMemory: Bool) {
        self.name = name
        
        let schema = Schema([
            Fact.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            name,
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        
        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        // Is it possible we'll miss some updates this way, leading to some refresh errors?
        DispatchQueue.main.async {
            _ = self.newFacts()
            
            // Handle migrations here, with the results of the above method call
        }
    }
    
    var seenIds: [PersistentIdentifier] = []
    
    @MainActor
    func newFacts() -> [Fact] {
        do {
            let allIds = try container.mainContext.fetchIdentifiers(FetchDescriptor<Fact>())
            
            let newIds = Set(allIds).subtracting(seenIds)
            
            self.seenIds = allIds
            
            return try container.mainContext.fetch(FetchDescriptor<Fact>(predicate: #Predicate {
                newIds.contains($0.persistentModelID)
            }))
        } catch {
            
        }
        
        return []
    }
    
    @MainActor
    func insert(fact: Fact) {
        container.mainContext.insert(fact)
    }
    
    @MainActor
    func fetchFacts(
        itemId: String? = nil,
        attribute: String? = nil,
        value: String? = nil
    ) -> [Fact] {
        let context = container.mainContext
        
        let predicate = #Predicate<Fact> {
            (itemId == nil || $0.itemId == itemId!) &&
            (attribute == nil || $0.attribute == attribute!) &&
            (value == nil || $0.value == value!)
        }
        
        let descriptor = FetchDescriptor<Fact>(
            predicate: predicate,
            sortBy: [.init(\.timestamp, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        }
        catch {
            print(error)
        }
        
        return []
    }
    
    @MainActor
    func fetchFacts(
        itemId: String?,
        attribute: String?,
        valueAtOrAbove: Double,
        valueAtOrBelow: Double
    ) -> [Fact] {
        let context = container.mainContext
        
        let predicate = #Predicate<Fact> {
            (itemId == nil || $0.itemId == itemId!) &&
            (attribute == nil || $0.attribute == attribute!) &&
            ($0.numericalValue >= valueAtOrAbove) &&
            ($0.numericalValue <= valueAtOrBelow)
        }
        
        let descriptor = FetchDescriptor<Fact>(
            predicate: predicate,
            sortBy: [.init(\.timestamp, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        }
        catch {
            print(error)
        }
        
        return []
    }
    
    @MainActor
    func fetchFacts(
        createdAtOrAfter: Date,
        createdAtOrBefore: Date
    ) -> [Fact] {
        let context = container.mainContext
        
        let predicate = #Predicate<Fact> {
            $0.timestamp >= createdAtOrAfter &&
            $0.timestamp <= createdAtOrBefore
        }
        
        let descriptor = FetchDescriptor<Fact>(
            predicate: predicate,
            sortBy: [.init(\.timestamp, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        }
        catch {
            print(error)
        }
        
        return []
    }
}

#endif

// In the future, this could use https://developer.apple.com/documentation/cloudkit/ckrecordzonesubscription or https://developer.apple.com/documentation/cloudkit/ckfetchrecordzonechangesoperation to fetch new facts, rather than caching.
