//
//  GGOptions.swift
//  GlucoseGlance WatchKit Extension
//
//  Created by Grayson Smith on 5/19/21.
//

import Foundation

public struct GGOptions {
    // MARK: Setup Options
    // Enter your Dexcom information
    #error("Enter your Dexcom login information here")
    public static let username: String = "YOUR_USERNAME_HERE"
    public static let password: String = "YOUR_PASSWORD_HERE"
    
    public static let dexcomServer: KnownShareServer = .US

    // MARK: Display Options    
    // The following options define the three diferent levels: low, in-range, and high.
    // Corresponding colors are red, green, and yellow.
    
    /// Threshold at which glucose numbers below this number show as red, where possible.
    public static let redThreshold: UInt16 = 85
    
    /// Threshold at which glucose numbers above this number show as yellow, where possible
    public static let yellowThreshold: UInt16 = 250
    
    /// TimeInterval to use when displaying the "oldness" of a reading. When this TimeInterval is reached, a reading is considered "old".
    /// Setting this value will adjust some complication's gauge's ends, e.g. if set to 6 minutes then once it has been 6 minutes since the
    /// last Dexom reading the gauge will be full. Additionally, this value is used by the main display to know when to swap out the
    /// "time since" the last reading with the words, "OLD".
    public static let readingOldnessInterval: TimeInterval = 11.0 * 60.0
    
    // TODO: implement?
    /// The TimeInterval for which to automatically check for Dexcom updates
//    public static let automaticFetchInterval: TimeInterval = (5.0 * 60.0) + 20.0
        
    // MARK: Debug Options
    /// Number of glucose readings to fetch from Dexcom at a time
    public static let dexcomFetchCount: Int = 2
    
    /// TimeInterval between which there can be no additionally fetch from Dexcom. For example, if set to 5 seconds then if a fetch is
    /// made to Dexcom, the next fetch must be 5 seconds after the first.
    /// This is to help prevent making too many requests to Dexcom which will put you on a timeout if too many are made at once.
    public static let dexcomFetchLimit: TimeInterval = 5.0
}
