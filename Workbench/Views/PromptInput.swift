//
//  PromptInput.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/22/24.
//

import SwiftUI

struct PromptInput: View {
    var referenceFromItemId: String = ItemStore.rootId()
    var refType: String = "content"
    
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var locationProvider: CurrentLocationProvider
    
    func insert() {
        let inputText = self.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if inputText.count == 0 {
            return
        }
        
        if inputText.starts(with: "-") {
            let title: String = inputText.split(separator: " ").dropFirst().joined(separator: " ")
            
            ItemStore.shared.createItem(
                type: "todo",
                attributes: [
                    "title": .string(title)
                ],
                referenceFrom: referenceFromItemId,
                referenceType: refType,
                resource: nil
            )
        }
        else if inputText.hasPrefix("http") {
            let parts = inputText.split(separator: " ").map { String($0) }
            let url: String = parts.first!
            let title: String = parts.dropFirst().joined(separator: " ")
            
            ItemStore.shared.createItem(
                type: "link",
                attributes: [
                    "url": .string(url),
                    "title": .string(title)
                ],
                referenceFrom: referenceFromItemId,
                referenceType: refType,
                resource: nil
            )
        }
        else if inputText.hasPrefix("itemid:") {
            var itemId = inputText
            itemId.removeFirst(7)
            
            ItemStore.shared.relateItems(
                fromItemId: referenceFromItemId,
                toItemId: itemId,
                referenceType: refType,
                resource: nil
            )
        }
        else if inputText == "/location" {
            locationProvider.userRequestForLocation()
        }
        else {
            ItemStore.shared.createItem(
                type: "note",
                attributes: [
                    "title": .string(inputText)
                ],
                referenceFrom: referenceFromItemId,
                referenceType: refType,
                resource: nil
            )
        }
        
        self.inputText = ""
    }
    
    var body: some View {
        HStack {
            TextEditor(text: $inputText)
                .textEditorStyle(.plain)
                .focused($isFocused)
                .font(.system(size: 14))
            #if os(macOS)
                .frame(minHeight: 17)
            #else
                .frame(minHeight: 34)
            #endif
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
            
            Button {
                insert()
            } label: {
                Text("Submit")
            }
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .padding()
        #if os(macOS)
        .background(colorScheme == .dark ? .white.opacity(0.1) : .white.opacity(0.5))
        #else
        .background(colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .onTapGesture {
            isFocused = true
        }
    }
}

#Preview {
    PromptInput(referenceFromItemId: "", refType: "content")
}
