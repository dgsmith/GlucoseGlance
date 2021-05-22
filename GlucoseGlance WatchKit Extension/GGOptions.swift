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
    #error("Enter your Dexcom login information here")
    public static let username: String = "YOUR_USERNAME_HERE"
    public static let password: String = "YOUR_PASSWORD_HERE"
    
    public static let dexcomServer: KnownShareServers = .US

    // MARK: Display Options    
    // The following options define the three diferent levels: low, in-range, and high.
    // Corresponding colors are red, green, and yellow.
    
    /// Threshold at which glucose numbers below this number show as red, where possible.
    public static let redThreshold: UInt16 = 90
    
    /// Threshold at which glucose numbers above this number show as yellow, where possible
    public static let yellowThreshold: UInt16 = 300
    
    /// The TimeInterval for which to automatically check for Dexcom updates
    public static let automaticFetchInterval: TimeInterval = (5.0 * 60.0) + 20.0
    
    // MARK: Complication Options
    // TODO: finish these options
    
    /// TimeInterval to use with circular complications. Each gauge represents the time elapsed since the last glucose update.
    /// Setting this value will adjust the gauge's end, e.g. if set to 6 minutes then once it has been 6 minutes since the last Dexom reading the gauge will be full.
    public static let timeGuageEndMinutes: TimeInterval = 6.0 * 60.0
    
    // MARK: Debug Options
    /// Number of glucose readings to fetch from Dexcom at a time
    public static let dexcomFetchCount: Int = 10
}
