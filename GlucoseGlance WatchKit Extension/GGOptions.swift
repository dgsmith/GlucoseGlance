//
//  GGOptions.swift
//  GlucoseGlance WatchKit Extension
//
//  Created by Grayson Smith on 5/19/21.
//

import Foundation
import ShareClient

public struct GGOptions {
    // MARK: Setup Options
    // Enter your Dexcom information
    public static let username: String = "YOUR_USERNAME_HERE"
    public static let password: String = "YOUR_PASSWORD_HERE"
    
    public static let dexcomServer: KnownShareServers = .US

    // MARK: Display Options
    /// Threshold at which time dela displays will show "NOW" instead of the time since last Dexcom update.
    public static let nowThreshold: Int = 2
    
    /// Threshold at which time dela displays will show "OLD" instead of the time since last Dexcom update.
    public static let oldThreshold: Int = 7
    
    // The following options define the three diferent levels: low, in-range, and high.
    // Corresponding colors are red, green, and yellow.
    /// Threshold at which glucose numbers below this number show as red, where possible.
    public static let redThreshold: UInt16 = 90
    
    /// Threshold at which glucose numbers above this number show as yellow, where possible
    public static let yellowThreshold: UInt16 = 300
    
    // MARK: Complications
    // TODO: finish these options
    
    // MARK: Debug
    /// Number of glucose readings to fetch from Dexcom at a time
    public static let dexcomFetchCount: Int = 10
}
