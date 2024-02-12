//
//  ItemDefaultsProtocol.swift
//  Pip
//
//  Created by Alexander Obenauer on 2/9/24.
//

import SwiftUI

protocol ItemDefaultsProtocol {
    static var rendersItemTypes: [String] { get }
    static func view(itemId: String) -> AnyView?
    static func color(itemId: String) -> Color?
    static func viewForUpdate(fact: Fact) -> AnyView?
}
