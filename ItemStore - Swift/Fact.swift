//
//  Fact.swift
//  ItemizedPlayground
//
//  Created by Alexander Obenauer on 10/19/23.
//

import Foundation
import SwiftData

#if CLOUDKIT
@Model
#endif
final class Fact {
    var factId: String = ""
    var itemId: String = ""
    var attribute: String = ""
    var value: String = ""
    var numericalValue: Double = 0.0
    var type: String = "string"
    var flags: Int = 0
    var timestamp: Date = Date()
    
    init(factId: String, itemId: String, attribute: String, value: String, numericalValue: Double, type: String, flags: Int, timestamp: Date) {
        self.factId = factId
        self.itemId = itemId
        self.attribute = attribute
        self.value = value
        self.numericalValue = numericalValue
        self.type = type
        self.flags = flags
        self.timestamp = timestamp
    }
    
    convenience init(itemId: String, attribute: String, value: TypedValue, timestamp: Date? = nil) {
        self.init(
            factId: UUID().uuidString,
            itemId: itemId,
            attribute: attribute,
            value: value.stringValue,
            numericalValue: value.numberValue ?? 0,
            type: value.type,
            flags: 0,
            timestamp: timestamp ?? Date()
        )
    }

    var typedValue: TypedValue? {
        TypedValue(value: self.value, type: self.type)
    }
    
    var flagsDescription: String {
        var all: [String] = []
        
        if (flags & 1) == 1 {
            all.append("Deleted")
        }
        
        if all.count > 0 {
            return all.joined(separator: ", ")
        }
        
        return ""
    }
    
    var codable: CodableFact {
        CodableFact(
            factId: factId,
            itemId: itemId,
            attribute: attribute,
            value: value,
            numericalValue: numericalValue,
            type: type,
            flags: flags,
            timestamp: timestamp
        )
    }
}

enum TypedValue {
    case string(String)
    case number(Double)
    case timestamp(Date)
    case itemId(String)
    case boolean(Bool)
    case null
    
    init?(value: String, type: String) {
        switch type {
        case "string":
            self = .string(value)
        case "number":
            if let value = Double(value) {
                self = .number(value)
            }
            else {
                print("Error: couldn't convert value to double")
                return nil
            }
        case "timestamp":
            if let dValue = Double(value) {
                self = .timestamp(Date(timeIntervalSince1970: dValue))
            }
            else {
                print("Error: couldn't convert value to double for timestamp")
                return nil
            }
        case "itemId":
            self = .itemId(value)
        case "boolean":
            self = .boolean(value == "true")
        case "null":
            self = .null
        default:
            print("Error: unrecognized type in TypedValue init", type)
            return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .string(let str): return str
        case .number(let dbl): return "\(dbl)"
        case .timestamp(let date): return "\(date.timeIntervalSince1970)"
        case .itemId(let str): return str
        case .boolean(let bool): return bool ? "true" : "false"
        case .null: return "null"
        }
    }
    
    var numberValue: Double? {
        if case let .number(dbl) = self {
            return dbl
        }
        else if case let .timestamp(date) = self {
            return date.timeIntervalSince1970
        }
        
        return nil
    }
    
    var booleanValue: Bool? {
        if case let .boolean(bool) = self {
            return bool
        }
        
        return nil
    }
    
    var dateValue: Date? {
        if case let .timestamp(date) = self {
            return date
        }
        
        return nil
    }
    
    var type: String {
        switch self {
        case .string(_): return "string"
        case .number(_): return "number"
        case .timestamp(_): return "timestamp"
        case .itemId(_): return "itemId"
        case .boolean(_): return "boolean"
        case .null: return "null"
        }
    }
}

struct CodableFact: Codable {
    var factId: String
    var itemId: String
    var attribute: String
    var value: String
    var numericalValue: Double
    var type: String
    var flags: Int
    var timestamp: Date
}
