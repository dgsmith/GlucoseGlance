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
                GeometryReader { geo in
                    ContentView()
                        .navigationTitle {
                            if geo.size.width > 324.0 / 2.0 {
                                Text("Glucose Glance")
                                    .foregroundColor(options.theme.main)
                                    .offset(x: -9.5, y: 0)
                            } else {
                                Text("Glucose Glance")
                                    .foregroundColor(options.theme.main)
                                    .offset(x: -3.5, y: 0)
                            }
                        }
                }
            }
        }
    }
}
