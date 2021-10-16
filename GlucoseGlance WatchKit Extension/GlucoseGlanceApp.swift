/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point for the Glucose Glance app.
*/

import SwiftUI
import SwiftCom

@main
struct GlucoseGlanceApp: App {
    
    @WKExtensionDelegateAdaptor private var appDelegate: ExtensionDelegate
    
    @ObservedObject private var options = GGOptions.shared
        
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .navigationTitle(Text("Glucose Glance"))
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
