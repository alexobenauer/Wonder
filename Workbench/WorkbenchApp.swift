//
//  WorkbenchApp.swift
//  Workbench
//
//  Created by Alexander Obenauer on 2/1/24.
//

import SwiftUI
import SwiftData

@main
struct WorkbenchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    ItemStore.shared.prepare()
                }
        }
    }
}
