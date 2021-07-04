//
//  GGOptions.swift
//  GlucoseGlance WatchKit Extension
//
//  Created by Grayson Smith on 5/19/21.
//

import Foundation
#if os(watchOS)
import ClockKit
#else
import WidgetKit
#endif

public class GGOptions: ObservableObject {
    
    public static let shared = GGOptions()
    
    private init() {
        let colorThemeIndex = UserDefaults.standard.integer(forKey: "GGOptions.theme")
        theme = themes[colorThemeIndex]
    }
    
    // MARK: Setup Options
    // Enter your Dexcom information
    #error("Enter your Dexcom login information here")
    public let username: String = "YOUR_USERNAME_HERE"
    public let password: String = "YOUR_PASSWORD_HERE"
    
    public let dexcomServer: KnownShareServer = .US

    // MARK: Display Options    
    // The following options define the three diferent levels: low, in-range, and high.
    // Corresponding colors are red, green, and yellow.
    
    /// Threshold at which glucose numbers below this number are considered out of range
    public let belowRangeThreshold: UInt16 = 85
    
    /// Threshold at which glucose numbers above this number are considered above range
    public let aboveRangeThreshold: UInt16 = 250
    
    /// TimeInterval to use when displaying the "oldness" of a reading. When this TimeInterval is reached, a reading is considered "old".
    /// Setting this value will adjust some complication's gauge's ends, e.g. if set to 6 minutes then once it has been 6 minutes since the
    /// last Dexom reading the gauge will be full. Additionally, this value is used by the main display to know when to swap out the
    /// "time since" the last reading with the words, "OLD".
    public let readingOldnessInterval: TimeInterval = 11.0 * 60.0
    
    /// Color theme for use in the application. Changable at runtime
    @Published public var theme: ColorTheme = ColorThemeJamie() {
        didSet {
            guard let newThemeIndex = themes.firstIndex(where: { $0 == theme } ) else {
                print("Invalid theme set: \(theme.name)")
                abort()
            }
            
            UserDefaults.standard.set(newThemeIndex, forKey: "GGOptions.theme")
            
#if os(watchOS)
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
#else
            WidgetCenter.shared.reloadAllTimelines()
#endif
        }
    }
    
    /// Array of all available color themes
    public let themes: [ColorTheme] = [ColorThemePlain(), ColorThemeJamie()]
    
    // TODO: implement?
    /// The TimeInterval for which to automatically check for Dexcom updates
//    public let automaticFetchInterval: TimeInterval = (5.0 * 60.0) + 20.0
        
    // MARK: Debug Options
    /// Number of glucose readings to fetch from Dexcom at a time
    public let dexcomFetchCount: Int = 2
    
    /// TimeInterval between which there can be no additionally fetch from Dexcom. For example, if set to 5 seconds then if a fetch is
    /// made to Dexcom, the next fetch must be 5 seconds after the first.
    /// This is to help prevent making too many requests to Dexcom which will put you on a timeout if too many are made at once.
    public let dexcomFetchLimit: TimeInterval = 5.0
}
