//
//  ItemDefaultsProtocol.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/9/24.
//

import SwiftUI

protocol ItemDefaults {
    static func itemView(itemId: String) -> AnyView?
    static func updateView(fact: Fact) -> AnyView?
    static func color(itemId: String) -> Color?
}
