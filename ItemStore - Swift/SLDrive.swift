//
//  SLDrive.swift
//  ItemizedPlayground
//
//  Created by Alexander Obenauer on 11/10/23.
//

import Foundation

class SLDrive: ItemDrive {
    let name: String
    let inMemory: Bool
    var database: UnsafeMutablePointer<CSLDatabase>?
    
    init(name: String, inMemory: Bool) {
        self.name = name
        self.inMemory = inMemory
        self.database = openDatabase(name, inMemory)
    }
    
    deinit {
        closeDatabase(database)
    }
    
    func resetDatabase() {
        let lastDatabase = self.database
        
        self.database = openDatabase(name, inMemory)
        
        closeDatabase(lastDatabase)
    }
    
    func insert(fact: Fact) {
        csl_insertFact(
            database,
            fact.factId,
            fact.itemId,
            fact.attribute,
            fact.value,
            fact.numericalValue,
            fact.type,
            Int32(fact.flags),
            isoFormatter.string(from: fact.timestamp)
        )
    }
    
    func fetchFacts(
        itemId: String?,
        attribute: String?,
        value: String?
    ) -> [Fact] {
        cFactsCollectionToSwiftArray(
            csl_fetchFacts(
                database,
                itemId,
                attribute,
                value
            )
        )
    }
    
    func fetchFacts(
        itemId: String?,
        attribute: String?,
        valueAtOrAbove: Double,
        valueAtOrBelow: Double
    ) -> [Fact] {
        cFactsCollectionToSwiftArray(
            csl_fetchFactsByValueRange(
                database,
                itemId,
                attribute,
                valueAtOrAbove,
                valueAtOrBelow
            )
        )
    }
    
    func fetchFacts(
        createdAtOrAfter: Date,
        createdAtOrBefore: Date
    ) -> [Fact] {
        cFactsCollectionToSwiftArray(
            csl_fetchFactsByDate(
                database,
                isoFormatter.string(from: createdAtOrAfter),
                isoFormatter.string(from: createdAtOrBefore)
            )
        )
    }
}

fileprivate let isoFormatter = ISO8601DateFormatter()

fileprivate func cFactsCollectionToSwiftArray(_ cFactsCollection: UnsafeMutablePointer<CFactsCollection>?) -> [Fact] {
    guard let cFactsCollection else {
        return []
    }
    
    let factsPointer = UnsafeBufferPointer(
        start: cFactsCollection.pointee.facts,
        count: Int(cFactsCollection.pointee.count)
    )
    
    let factsArray = Array(factsPointer).map { cFact -> Fact in
        return Fact(
            factId: String(cString: cFact.factId),
            itemId: String(cString: cFact.itemId),
            attribute: String(cString: cFact.attribute),
            value: String(cString: cFact.value),
            numericalValue: cFact.numericalValue,
            type: String(cString: cFact.type),
            flags: Int(cFact.flags),
            timestamp: isoFormatter.date(from: String(cString: cFact.timestamp)) ?? Date.distantPast
        )
    }
    
    freeFactsCollection(cFactsCollection)
    
    return factsArray
}
