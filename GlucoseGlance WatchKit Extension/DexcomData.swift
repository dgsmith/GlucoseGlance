/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data object that tracks the number of drinks that the user has drunk.
*/

import SwiftUI
import Combine
import ClockKit
import os

protocol DexcomDataModelInterface {
    var currentReading: GlucoseReading { get }
    
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
        if glucose < GGOptions.redThreshold {
            return .red
        }
        
        if glucose > GGOptions.yellowThreshold {
            return .yellow
        }
        
        return .green
    }
}

// The data model for the Glucose Glance app.
class DexcomData: ObservableObject, DexcomDataModelInterface {
    
    let logger = Logger(
        subsystem: "me.graysonsmith.GlucoseGlance.watchkitapp.watchkitextension.DexcomData",
        category: "Model")
    
    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = DexcomData()
    
    lazy var provider = DexcomProvider(username: GGOptions.username,
                                       password: GGOptions.password,
                                       shareServer: GGOptions.dexcomServer)
    
    // A number formatter that limits numbers
    // to three significant digits.
    lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 1
        return formatter
    }()
            
    // A background queue used to save and load the model data.
    private var background = DispatchQueue(
        label: "Background Queue",
        qos: .userInitiated)
            
    @Published public var currentGlucoseReadings = [GlucoseReading]() {
        didSet {
            logger.debug("A value has been assigned to the current glucose readings property.")
            
            // Update any complications on active watch faces.
            let server = CLKComplicationServer.sharedInstance()
            for complication in server.activeComplications ?? [] {
                server.reloadTimeline(for: complication)
            }
            
            // Begin saving the data.
            self.save()
        }
    }
    
    // Use this value to determine whether you have changes that can be saved to disk.
    private var savedGlucoseReadings = [GlucoseReading]()
    
    public var currentReading: GlucoseReading {
        return currentGlucoseReadings.first ?? GlucoseReading(value: 0, trend: .unknown, timestamp: Date.distantPast)
    }
    
    public var currentReadingDelta: Double? {
        if currentGlucoseReadings.count <= 1 {
            return 0
        }
        
        let latest = currentGlucoseReadings[0]
        let nextLatest = currentGlucoseReadings[1]
        
        if latest.timestamp.distance(to: nextLatest.timestamp) > 5.5 * 60.0 {
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
        if glucose < GGOptions.redThreshold {
            return .red
        }
        
        if glucose > GGOptions.yellowThreshold {
            return .yellow
        }
        
        return .green
    }
        
    // MARK: - Private Methods
    
    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    private init() {
        
        // Begin loading the data from disk.
        load()
    }
        
    private func saveGlucoseReadings() -> Data? {
        // Don't save the data if there haven't been any changes.
        if currentGlucoseReadings == savedGlucoseReadings {
            logger.debug("The glucose readings haven't changed. No need to save.")
            return nil
        }
        
        // Save as a binary plist file.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data: Data
        
        do {
            // Encode the currentGlucoseReadings array.
            data = try encoder.encode(currentGlucoseReadings)
            
        } catch {
            logger.error("An error occurred while encoding the data: \(error.localizedDescription)")
            return nil
        }
        
        return data
    }
    
    // Begin saving the glucose readings to disk.
    private func save() {
        
        let glucoseData = saveGlucoseReadings()
        
        guard let glucoseData = glucoseData else {
            return
        }
        
        // Save the data to disk as a binary plist file.
        let saveAction = { [unowned self] in
            do {
                // Write the data to disk
                try glucoseData.write(to: self.getGlucoseReadingsDataURL(), options: [.atomic])
    
                // Update the saved value.
                self.savedGlucoseReadings = currentGlucoseReadings
                
                self.logger.debug("Saved!")
                
            } catch {
                self.logger.error("An error occurred while saving the data: \(error.localizedDescription)")
            }
        }
        
        // If the app is running in the background, save synchronously.
        if WKExtension.shared().applicationState == .background {
            logger.debug("Synchronously saving the model on \(Thread.current).")
            saveAction()
        } else {
            // Otherwise save the data on a background queue.
            background.async { [unowned self] in
                logger.debug("Asynchronously saving the model on a background thread.")
                saveAction()
            }
        }
    }
    
    // Begin loading the data from disk.
    private func load() {
        // Read the data from a background queue.
        background.async { [unowned self] in
            logger.debug("Loading the model.")
        
            var readingsFromDisk: [GlucoseReading]
            
            do {
                // Decode the data.
                let decoder = PropertyListDecoder()
                let readingsData = try Data(contentsOf: self.getGlucoseReadingsDataURL())
                
                readingsFromDisk = try decoder.decode([GlucoseReading].self, from: readingsData)
                
                logger.debug("Data loaded from disk")
                
            } catch CocoaError.fileReadNoSuchFile {
                logger.debug("No file found--creating an empty drink list.")
                readingsFromDisk = []
                
            } catch {
                fatalError("*** An unexpected error occurred while loading the drink list: \(error.localizedDescription) ***")
            }
            
            // Update the entires on the main queue.
            DispatchQueue.main.async { [unowned self] in
                
                savedGlucoseReadings = readingsFromDisk
                
                // Filter the drinks.
                currentGlucoseReadings = filterGlucoseReadings(readingsFromDisk)
                                
                asyncDetached {
                    await self.checkForNewReadings()
                }
            }
        }
    }
    
    public func checkForNewReadings() async -> Bool {
        logger.debug("Checking for new readings from Dexcom")
        
        do {
            let latestReadings = try await self.provider.fetchLatestReadings(GGOptions.dexcomFetchCount)
            
            await MainActor.run {
                // Get a copy of the current glucose data.
                let currentReadings = self.currentGlucoseReadings
                
                // Combine old and new together
                let newestReadings = Set(currentReadings).union(Set(latestReadings)).sorted { lhs, rhs in
                    lhs.timestamp.compare(rhs.timestamp) == .orderedDescending
                }
                                         
                // Only update if there have been changes.
                if self.currentGlucoseReadings == newestReadings {
                    logger.debug("No new readings found.")
                } else {
                    self.currentGlucoseReadings = newestReadings
                }
            }
            
            return true
    
        } catch {
            self.logger.debug("Got fetch error from Dexcom: \(error.localizedDescription)")
            return false
        }
    }
        
    // Returns the URL for the plist file that stores the glucose data.
    private func getGlucoseReadingsDataURL() throws -> URL {
        // Get the URL for the app's document directory.
        let fileManager = FileManager.default
        let documentDirectory = try fileManager.url(for: .documentDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: false)
        
        // Append the file name to the directory.
        return documentDirectory.appendingPathComponent("GlucoseGlance.plist")
    }
}

// Filter array to only the glucose readings in the last 24 hours.
private func filterGlucoseReadings(_ readings: [GlucoseReading]) -> [GlucoseReading] {
    // The current date and time.
    let endDate = Date()
    
    // The date and time 24 hours ago.
    let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)
    
    // Return an array of glucose readings with a date parameter between
    // the start and end dates.
    return readings.filter { (reading) -> Bool in
        (startDate.compare(reading.timestamp) != .orderedDescending) &&
            (endDate.compare(reading.timestamp) != .orderedAscending)
    }
}
