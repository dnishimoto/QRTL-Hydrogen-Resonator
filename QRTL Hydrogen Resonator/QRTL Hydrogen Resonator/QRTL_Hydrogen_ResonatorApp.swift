//
//  QRTL_Hydrogen_ResonatorApp.swift
//  QRTL Hydrogen Resonator
//
//  Created by David Nishimoto on 8/24/26.
//

import SwiftUI
import CoreData

@main
struct QRTL_Hydrogen_ResonatorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
