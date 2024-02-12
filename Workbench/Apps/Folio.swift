//
//  Folio.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/1/24.
//

import SwiftUI

struct Folio: View {
    var itemId: String
    
    var body: some View {
        ScrollView {
            VStack {
                PromptInput(referenceFromItemId: itemId, refType: "content")
                    .padding(.bottom)
                
                RefList(fromItemId: itemId, refType: "content", sortOrder: .reverse)
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
    Folio(itemId: "")
}
