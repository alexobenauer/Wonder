//
//  ItemStore.swift
//  ItemizedPlayground
//
//  Created by Alexander Obenauer on 10/19/23.
//

import Foundation

#if CLOUDKIT
import SwiftData
import CloudKit
#endif

class ItemStore: ObservableObject {
    static let shared = ItemStore()
    
    #if CLOUDKIT
    let userDrive: CKDrive
    #else
    let userDrive: SLDrive
    #endif
    
    var deletionsDrive: SLDrive
    var resourceDrives: [String: ItemDrive] // providers, apps, devices
    
    let notifier = SubscriberNotifier()
    
    private init() {
        #if CLOUDKIT
        self.userDrive = CKDrive(name: "User DB", inMemory: false)
        #else
        
        #if os(macOS)
        self.userDrive = SLDrive(name: "itemstore", inMemory: false)
        #elseif os(iOS)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseURL = documentsDirectory.appendingPathComponent("itemstore")
        
        self.userDrive = SLDrive(name: databaseURL.absoluteString, inMemory: false)
        #endif
        
        #endif
        
        self.resourceDrives = [:]
        
        self.deletionsDrive = SLDrive(name: "deletions", inMemory: true) // when to update
        
        #if CLOUDKIT
        NotificationCenter.default.addObserver(self, selector: #selector(ckRemoteChange(_:)), name: .NSManagedObjectContextDidSave, object: nil)
        #endif
    }
    
    func prepare() {
        _updateDeletionsDrive()
    }

    func mountDrive(forResource resource: String, inMemory: Bool = true) {
        if resourceDrives.keys.contains(resource) {
            return
        }
        
        self.resourceDrives[resource] = SLDrive(name: resource, inMemory: inMemory)
    }
    
    func drive(forResource resource: String?) -> ItemDrive? {
        guard let resource else {
            return userDrive
        }
        
        return resourceDrives[resource]
    }
    
    func allDrives() -> [ItemDrive] {
        [userDrive, deletionsDrive] + Array(resourceDrives.values)
    }
    
    #if CLOUDKIT
    private let ckRemoteChangeDebouncer = Debouncer(delay: 0.5)
    @objc func ckRemoteChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.ckRemoteChangeDebouncer.debounce {
                // This is working well, but is it firing also for local changes? Can we detect to skip that update somehow?
                let newFacts = self.userDrive.newFacts()
                print("New facts: \(newFacts.count)")
                
                if newFacts.count > 0 {
                    self.drivesUpdated(newFacts: newFacts, "ckRemoteChange")
                }
            }
        }
    }
    #endif
    
    func drivesUpdated(newFacts: [Fact], _ log: String = "unspecified source.") {
        print("Update: \(log)")
        
        // TODO: Only update deletions if one of these facts is a "deleted" attribute on an item, or the flip of a flag bit (how would we efficiently check if it's a 1 -> 0 flip?)
        _updateDeletionsDrive()
        notifier.notifySubscribers(newFacts: newFacts)
    }

    // MARK: - Basic fact functions

    func insert(fact: Fact, resource: String? = nil) {
        guard let drive = drive(forResource: resource) else {
            fatalError()
        }
        
        drive.insert(fact: fact)
        
        drivesUpdated(newFacts: [fact])
    }
    
    func insert(facts: [Fact], resource: String? = nil) {
        guard let drive = drive(forResource: resource) else {
            fatalError()
        }
        
        for fact in facts {
            drive.insert(fact: fact)
        }
        
        drivesUpdated(newFacts: facts)
    }
    
    func fetchFacts(
        itemId: String? = nil,
        attribute: String? = nil,
        value: String? = nil,
        includeDeleted: Bool = false,
        resource: String? = nil
    ) -> [Fact] {
        var drives = allDrives()
        
        if let resource {
            if let drive = resourceDrives[resource] {
                drives = [drive]
            }
            else {
                return []
            }
        }
        
        let result = drives
            .reduce([], { partialResult, drive in
                partialResult + drive.fetchFacts(
                    itemId: itemId,
                    attribute: attribute,
                    value: value
                )
            })
            .sorted { a, b in
                a.timestamp > b.timestamp
            }
        
        return includeDeleted ? result : _removeDeletedFacts(result)
    }
    
    func fetchFacts(
        itemId: String? = nil,
        attribute: String? = nil,
        valueAtOrAbove: Double,
        valueAtOrBelow: Double,
        includeDeleted: Bool = false,
        resource: String? = nil
    ) -> [Fact] {
        var drives = allDrives()
        
        if let resource {
            if let drive = resourceDrives[resource] {
                drives = [drive]
            }
            else {
                return []
            }
        }
        
        let result = drives
            .reduce([], { partialResult, drive in
                partialResult + drive.fetchFacts(
                    itemId: itemId,
                    attribute: attribute,
                    valueAtOrAbove: valueAtOrAbove,
                    valueAtOrBelow: valueAtOrBelow
                )
            })
            .sorted { a, b in
                a.timestamp > b.timestamp
            }
        
        return includeDeleted ? result : _removeDeletedFacts(result)
    }
    
    func fetchFacts(
        createdAtOrAfter: Date?,
        createdAtOrBefore: Date?,
        includeDeleted: Bool = false,
        resource: String? = nil
    ) -> [Fact] {
        guard let createdAtOrAfter, let createdAtOrBefore else {
            fatalError("Open-ended date ranges not currently supported.")
        }
        
        var drives = allDrives()
        
        if let resource {
            if let drive = resourceDrives[resource] {
                drives = [drive]
            }
            else {
                return []
            }
        }
        
        let result = drives
            .reduce([], { partialResult, drive in
                partialResult + drive.fetchFacts(createdAtOrAfter: createdAtOrAfter, createdAtOrBefore: createdAtOrBefore)
            })
            .sorted { a, b in
                a.timestamp > b.timestamp
            }
        
        return includeDeleted ? result : _removeDeletedFacts(result)
    }
    
    fileprivate func _removeDeletedFacts(_ facts: [Fact]) -> [Fact] {
        var toRemove: [String] = []
        var filtered: [Fact] = []
        
        for fact in facts {
            if fact.flags & 1 == 1 {
                toRemove.append(fact.factId)
            }
            
            if !toRemove.contains(fact.factId) {
                filtered.append(fact)
            }
        }
        
        return filtered
    }

    
    // MARK: - Extended fact functions

    @discardableResult
    func createItem(
        type: String?,
        attributes: [String: TypedValue]? = nil,
        referenceFrom: String? = nil,
        referenceType: String? = nil,
        referenceAttributes: [String: TypedValue]? = nil,
        resource: String?
    ) -> String {
        let itemId = UUID().uuidString
        
        let facts = Self._factsToCreateItem(
            itemId: itemId,
            type: type,
            attributes: attributes,
            referenceFrom: referenceFrom,
            referenceType: referenceType,
            referenceAttributes: referenceAttributes)
        
        insert(facts: facts, resource: resource)
        
        return itemId
    }
    
    static func _factsToCreateItem(
        itemId: String,
        type: String?,
        attributes: [String: TypedValue]? = nil,
        referenceFrom: String? = nil,
        referenceType: String? = nil,
        referenceAttributes: [String: TypedValue]? = nil,
        timestamp: Date? = nil
    ) -> [Fact] {
        var facts: [Fact] = []
        
        facts.append(Fact(itemId: itemId, attribute: "created", value: .timestamp(timestamp ?? Date()), timestamp: timestamp))
        
        if let type {
            facts.append(Fact(itemId: itemId, attribute: "type", value: .string(type), timestamp: timestamp))
        }
        
        for attribute in attributes ?? [:] {
            facts.append(Fact(itemId: itemId, attribute: attribute.key, value: attribute.value, timestamp: timestamp))
        }
        
        if let referenceFrom {
            facts.append(contentsOf: _factsToRelateItems(
                relationshipItemId: UUID().uuidString,
                fromItemId: referenceFrom,
                toItemId: itemId,
                referenceType: referenceType,
                referenceAttributes: referenceAttributes,
                timestamp: timestamp
            ))
        }
        
        return facts
    }
    
    @discardableResult
    func relateItems(
        fromItemId: String,
        toItemId: String,
        referenceType: String? = nil,
        referenceAttributes: [String: TypedValue]? = nil,
        resource: String?
    ) -> String {
        let relationshipItemId = UUID().uuidString
        
        let facts = Self._factsToRelateItems(
            relationshipItemId: relationshipItemId,
            fromItemId: fromItemId,
            toItemId: toItemId,
            referenceType: referenceType,
            referenceAttributes: referenceAttributes
        )
        
        insert(facts: facts, resource: resource)
        
        return relationshipItemId
    }
    
    static func _factsToRelateItems(
        relationshipItemId: String,
        fromItemId: String,
        toItemId: String,
        referenceType: String? = nil,
        referenceAttributes: [String: TypedValue]? = nil,
        timestamp: Date? = nil
    ) -> [Fact] {
        let rid = relationshipItemId
        var facts: [Fact] = []
        
        facts.append(Fact(itemId: rid, attribute: "created", value: .timestamp(timestamp ?? Date()), timestamp: timestamp))
        facts.append(Fact(itemId: rid, attribute: "type", value: .string("reference"), timestamp: timestamp))
        
        if let referenceType {
            facts.append(Fact(itemId: rid, attribute: "referenceType", value: .string(referenceType), timestamp: timestamp))
        }
        
        facts.append(Fact(itemId: rid, attribute: "fromItemId", value: .itemId(fromItemId), timestamp: timestamp))
        facts.append(Fact(itemId: rid, attribute: "toItemId", value: .itemId(toItemId), timestamp: timestamp))
        
        for attribute in referenceAttributes ?? [:] {
            facts.append(Fact(itemId: rid, attribute: attribute.key, value: attribute.value, timestamp: timestamp))
        }
        
        return facts
    }
    
    // PERF: could offer way to scope down to one drive
    func getRelationshipIds(
        fromItemId: String? = nil,
        toItemId: String? = nil,
        referenceType: String? = nil
    ) -> [String] {
        var results: [[Fact]] = []
        
        if let fromItemId {
            results.append(fetchFacts(attribute: "fromItemId", value: fromItemId))
        }
        
        if let toItemId {
            results.append(fetchFacts(attribute: "toItemId", value: toItemId))
        }
        
        if let referenceType {
            results.append(fetchFacts(attribute: "referenceType", value: referenceType))
        }
        
        if results.count == 0 {
            return []
        }
        
        var dates: [String: Date] = [:]
        for result in results {
            for fact in result {
                dates[fact.itemId] = fact.timestamp
            }
        }
        
        if results.count == 1 {
            return results[0].map({ $0.itemId })
        }
        
        var referenceItemIds = Set(results[0].map({ $0.itemId }))
        
        for array in results.dropFirst() {
            referenceItemIds = referenceItemIds.intersection(Set(array.map({ $0.itemId })))
        }
        
        return referenceItemIds.sorted { a, b in
            (dates[a] ?? .distantPast) > (dates[b] ?? .distantPast)
        }
    }
    
    func deleteFact(_ fact: Fact) {
        insert(fact: Fact(
            factId: fact.factId,
            itemId: fact.itemId,
            attribute: fact.attribute,
            value: fact.value,
            numericalValue: fact.numericalValue,
            type: fact.type,
            flags: fact.flags ^ 1,
            timestamp: Date()
        ))
    }
    
    func deleteItem(itemId: String, successorItemId: String? = nil) {
        insert(facts: [
            Fact(itemId: itemId, attribute: "deleted", value: .timestamp(Date()))
        ] + (successorItemId == nil ? [] : [
            Fact(itemId: itemId, attribute: "successor", value: .itemId(successorItemId!))
        ]))
    }
    
    private func _updateDeletionsDrive() {
        deletionsDrive.resetDatabase() // TODO: Iffy; we want append-only during runtime...
        
        let facts = fetchFacts(attribute: "deleted")
        var deletions: [String: Date] = [:]
        
        for fact in facts {
            if let timestamp = deletions[fact.itemId] {
                deletions[fact.itemId] = max(fact.timestamp, timestamp)
            }
            else {
                deletions[fact.itemId] = fact.timestamp
            }
        }
        
        for (itemId, deletedAt) in deletions {
            for fact in fetchFacts(itemId: itemId) {
                if fact.timestamp <= deletedAt && fact.attribute != "deleted" {
                    deletionsDrive.insert(fact: Fact(
                        factId: fact.factId,
                        itemId: fact.itemId,
                        attribute: fact.attribute,
                        value: fact.value,
                        numericalValue: fact.numericalValue,
                        type: fact.type,
                        flags: fact.flags ^ 1,
                        timestamp: deletedAt
                    ))
                }
            }
        }
    }
    
    func selectView(itemId: String, relationshipItemId: String, itemViewId: String?) {
        if let itemViewId {
            insert(facts: [
                Fact(itemId: itemId, attribute: "lastItemViewId", value: .itemId(itemViewId)),
                Fact(itemId: relationshipItemId, attribute: "itemViewId", value: .itemId(itemViewId))
            ], resource: nil)
        } else {
            insert(facts: [
                Fact(itemId: itemId, attribute: "lastItemViewId", value: .null),
                Fact(itemId: relationshipItemId, attribute: "itemViewId", value: .null)
            ], resource: nil)
        }
    }
    
    // MARK: -
    
    fileprivate static let dayDateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    static func string(forDate date: Date) -> String {
        dayDateFormatter.timeZone = TimeZone.current
        return dayDateFormatter.string(for: date)!
    }
    
    static func date(forString string: String) -> Date? {
        dayDateFormatter.date(from: string)?.startOfDay
    }
    
    static func rootId() -> String {
        "root"
    }
}
