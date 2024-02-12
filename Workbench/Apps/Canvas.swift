//
//  Canvas.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/9/24.
//

import SwiftUI

struct Canvas: View {
    var itemId: String
    
    var body: some View {
        RefCanvas(fromItemId: itemId, refType: "content", defaultNewItemType: "note")
    }
}

#Preview {
    Canvas(itemId: "")
}
