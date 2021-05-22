/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A wrapper view that instantiates the coffee tracker view and the data for the hosting controller.
*/

import SwiftUI
import os

// A wrapper view that simplifies adding the main view to the hosting controller.
struct ContentView: View {
    
    let logger = Logger(
        subsystem: "me.graysonsmith.GlucoseGlance.watchkitapp.watchkitextension.ContengView",
        category: "Root View")
    
    @Environment(\.scenePhase) private var scenePhase
    
    // Access the shared model object.
    let data = DexcomData.shared
    
    // Create the main view, and pass the model.
    var body: some View {
        GlucoseGlanceView()
            .environmentObject(data)
            .onChange(of: scenePhase) { (phase) in
                switch phase {
                
                case .inactive:
                    logger.debug("Scene became inactive.")
                
                case .active:
                    logger.debug("Scene became active.")
                    
                    let model = DexcomData.shared
                    model.loadNewDexcomData()
                    
                case .background:
                    logger.debug("Scene moved to the background.")
                    
                    // Schedule a background refresh task
                    // to update the complications.
                    scheduleBackgroundRefreshTasks()
                    
                @unknown default:
                    logger.debug("Scene entered unknown state.")
                    assertionFailure()
                }
            }
    }
    
}

// The preview for the content view.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
