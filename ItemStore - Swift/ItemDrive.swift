//
//  ItemDrive.swift
//  ItemizedPlayground
//
//  Created by Alexander Obenauer on 11/10/23.
//

import Foundation

protocol ItemDrive {
    var name: String { get }
    
    func insert(fact: Fact)
    
    func fetchFacts(
        itemId: String?,
        attribute: String?,
        value: String?
    ) -> [Fact]
    
    func fetchFacts(
        itemId: String?,
        attribute: String?,
        valueAtOrAbove: Double,
        valueAtOrBelow: Double
    ) -> [Fact]
    
    func fetchFacts(
        createdAtOrAfter: Date,
        createdAtOrBefore: Date
    ) -> [Fact]
}
