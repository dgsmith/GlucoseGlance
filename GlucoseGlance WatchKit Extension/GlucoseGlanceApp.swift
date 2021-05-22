/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The entry point for the Glucose Glance app.
*/

import SwiftUI

@main
struct GlucoseGlanceApp: App {
    
    @WKExtensionDelegateAdaptor private var appDelegate: ExtensionDelegate
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
