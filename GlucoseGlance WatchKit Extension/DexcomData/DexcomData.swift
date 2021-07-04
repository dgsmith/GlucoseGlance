/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data object that tracks the number of drinks that the user has drunk.
*/

import SwiftUI
import Combine
#if os(watchOS)
import ClockKit
#else
import WidgetKit
#endif
import os

protocol DexcomDataModelInterface {
    var currentReading: GlucoseReading { get }
    var isCurrentReadingTooOld: Bool { get }
    
    var currentReadingValueString: String { get }
    var currentReadingTrendSymbolString: String { get }
    
    var currentReadingDeltaString: String { get }
    
    func color(forGlucose glucose: Int) -> UIColor
}

struct ExampleDexcomData: DexcomDataModelInterface {
    // A number formatter that limits numbers
    // to three significant digits.
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 1
        return formatter
    }()
    
    let currentReading: GlucoseReading
    
    let isCurrentReadingTooOld: Bool = false
    
    var currentReadingValueString: String {
        let value = currentReading.value
        guard let result = numberFormatter.string(from: NSNumber(value: value)) else {
            fatalError("*** Unable to create a string for \(currentReading.value) ***")
        }
        
        return result
    }
    
    var currentReadingTrendSymbolString: String {
        return currentReading.trend.symbol
    }
    
    var currentReadingDeltaString: String {
        return "+1"
    }
    
    init(timestamp: Date) {
        currentReading = GlucoseReading(value: 100,
                                        trend: .flat,
                                        timestamp: timestamp.advanced(by: -1 * 2.0 * 60.0))
    }
    
    func color(forGlucose glucose: Int) -> UIColor {
        if glucose < GGOptions.shared.belowRangeThreshold {
            return .red
        }
        
        if glucose > GGOptions.shared.aboveRangeThreshold {
            return .yellow
        }
        
        return .green
    }
}

private func UITesting() -> Bool {
    return ProcessInfo.processInfo.arguments.contains("UI-TESTING")
}

// The data model for the Glucose Glance app.
class DexcomData: ObservableObject, DexcomDataModelInterface {
    
    private let logger = Logger(
        subsystem: "me.graysonsmith.GlucoseGlance.watchkitapp.watchkitextension.DexcomData",
        category: "Model")
    
    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = UITesting() ? DexcomData(provider: MockDexcomProvider()) : DexcomData()
    
    private let provider: DexcomProvidable
    
    // A number formatter that limits numbers
    // to three significant digits.
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 1
        return formatter
    }()
            
    @Published public var currentGlucoseReadings = [GlucoseReading]() {
        didSet {
            guard !UITesting() else {
                return
            }
            
            logger.debug("A value has been assigned to the current glucose readings property.")
            
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
    
    @Published public var lastDexcomError: String? = nil
        
    public var currentReading: GlucoseReading {
        return currentGlucoseReadings.first ?? GlucoseReading()
    }
    
    public var isCurrentReadingTooOld: Bool {
        if currentReading.timestamp.distance(to: .now) > GGOptions.shared.readingOldnessInterval {
            return true
        }
        
        return false
    }
    
    public var currentReadingDelta: Double? {
        if currentGlucoseReadings.count <= 1 {
            return nil
        }
        
        let latest = currentGlucoseReadings[0]
        let nextLatest = currentGlucoseReadings[1]
        
        if nextLatest.timestamp.distance(to: latest.timestamp) > 5.5 * 60.0 {
            return nil
        }
        
        return Double(latest.value) - Double(nextLatest.value)
    }
    
    public var currentReadingDeltaString: String {
        guard let currentGlucoseDelta = currentReadingDelta else {
            return ""
        }
        
        let prefix = currentGlucoseDelta >= 0 ? "+" : ""
        guard let result = numberFormatter.string(from: NSNumber(value: currentGlucoseDelta)) else {
            fatalError("*** Unable to create a string for \(currentReading.value) ***")
        }
        
        return "\(prefix)\(result)"
    }
    
    public var currentReadingValueString: String {
        guard let result = numberFormatter.string(from: NSNumber(value: currentReading.value)) else {
            fatalError("*** Unable to create a string for \(currentReading.value) ***")
        }
        
        return result
    }
    
    public var currentReadingTrendSymbolString: String {
        return currentReading.trend.symbol
    }
                    
    public func color(forGlucose glucose: Int) -> UIColor {
        if glucose < GGOptions.shared.belowRangeThreshold {
            return UIColor(GGOptions.shared.theme.belowRange)
        }
        
        if glucose > GGOptions.shared.aboveRangeThreshold {
            return UIColor(GGOptions.shared.theme.aboveRange)
        }
        
        return UIColor(GGOptions.shared.theme.inRange)
    }
    
    public func checkForNewReadings() async -> Bool {
        logger.debug("Checking for new readings from Dexcom")
        
        do {
            let readings = try await provider.fetchLatestReadings(GGOptions.shared.dexcomFetchCount)
            
            await MainActor.run {
                currentGlucoseReadings = readings
                lastDexcomError = nil
            }
            
            return true
    
        } catch {
            lastDexcomError = error.localizedDescription
            logger.debug("Got fetch error from Dexcom: \(error.localizedDescription, privacy: .public)")
            await provider.invalidateSession()
            return false
        }
    }
        
    // MARK: - Private Methods
    
    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    internal init(provider: DexcomProvidable = DexcomProvider.shared) {
        self.provider = provider
    }
    
}
