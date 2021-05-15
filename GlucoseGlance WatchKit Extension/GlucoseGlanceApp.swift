//
//  GlucoseGlanceApp.swift
//  GlucoseGlance WatchKit Extension
//
//  Created by Grayson Smith on 5/15/21.
//

import SwiftUI

@main
struct GlucoseGlanceApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
