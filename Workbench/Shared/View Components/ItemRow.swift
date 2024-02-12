//
//  ItemRow.swift
//  Workbench
//
//  Created by Alexander Obenauer on 1/27/24.
//

import SwiftUI

struct ItemRow<Content: View>: View {
    init(itemId: String, preferItemViewId: String? = nil, refType: String, @ViewBuilder additionalContent: @escaping () -> Content? = { nil }) {
        self.itemId = itemId
        self.preferItemViewId = preferItemViewId
        self.refType = refType
        self.additionalContent = additionalContent
    }
    
    let itemId: String
    var preferItemViewId: String? = nil
    
    let refType: String
    
    let additionalContent: () -> Content?
    
    @StateObject private var replies = SimpleItemStoreSubscriber(initialValue: [String]())
    
    @State private var isMenuOpen = false
    @State private var isPromptOpen = false
    @State private var isRepliesOpen = true
    
    func onAppear() {
        replies.initialize {
            ItemStore.shared.getRelationshipIds(fromItemId: itemId)
        }
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Button {
                    isRepliesOpen.toggle()
                } label: {
                    Image(systemName: "chevron.down")
                        .rotationEffect(isRepliesOpen ? .zero : .degrees(270))
                        .accessibilityLabel(Text(isRepliesOpen ? "Close replies" : "Open replies"))
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(replies.value.count > 0 ? 1 : 0.25)
                
                ItemView(itemId: itemId)
                
                Spacer()
                
                Button {
                    isPromptOpen.toggle()
                    
                    if isPromptOpen {
                        isRepliesOpen = true
                    }
                } label: {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .opacity(isPromptOpen ? 1 : 0.25)
                
                Button {
                    isMenuOpen.toggle()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(isMenuOpen ? 1 : 0.25)
            }
            
            if isMenuOpen {
                HStack {
                    VCTimestampText(itemId: itemId, attribute: "created", format: "E, MMM d h:mm a")
                        .font(.system(size: 12, design: .monospaced))
                        .opacity(0.5)
                    
                    Spacer()
                    
                    ItemMenu(itemId: itemId)
                    
                    additionalContent()
                }
            }
            
            if isRepliesOpen && replies.value.count > 0 {
                HStack {
                    Divider()
                        .padding(.horizontal, 7)
                    
                    RefList(fromItemId: itemId, refType: refType, sortOrder: .forward)
                }
            }
            
            if isPromptOpen {
                HStack {
                    Divider()
                        .padding(.horizontal, 7)
                    
                    PromptInput(referenceFromItemId: itemId, refType: refType)
                }
            }
        }
        .onAppear(perform: onAppear)
    }
}

fileprivate struct ItemMenu: View {
    let itemId: String
    
    var body: some View {
        Button {
            let url = "itemid:" + itemId
            
            #if os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(url, forType: .string)
            #else
            UIPasteboard.general.string = url
            #endif
        } label: {
            Text("Copy URL")
        }
    }
}

//#Preview {
//    ItemRow(itemId: "")
//}
