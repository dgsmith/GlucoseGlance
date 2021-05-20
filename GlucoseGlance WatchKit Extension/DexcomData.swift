/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data object that tracks the number of drinks that the user has drunk.
*/

import SwiftUI
import Combine
import ClockKit
import os
import ShareClient

// The data model for the Coffee Tracker app.
class DexcomData: ObservableObject {
    
    let logger = Logger(
        subsystem: "me.graysonsmith.GlucoseGlance.watchkitapp.watchkitextension.CoffeeData",
        category: "Model")
    
    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    static let shared = DexcomData()
    
    lazy var client = ShareClient(
        username: GGOptions.username,
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
        
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = .autoupdatingCurrent
        
        return dateFormatter
    }()
    
    // A background queue used to save and load the model data.
    private var background = DispatchQueue(label: "Background Queue",
    qos: .userInitiated)
        
    @Published public var currentGlucoseMeasurements = [ShareGlucose]() {
        didSet {
            logger.debug("A value has been assigned to the current glucose measurements property.")
            
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
    private var savedGlucose = [ShareGlucose]()
    
    public var currentGlucose: ShareGlucose {
        return currentGlucoseMeasurements.first ?? ShareGlucose(glucose: 0, trend: 0, timestamp: Date())
    }
    
    public var currentGlucoseDelta: Double {
        if currentGlucoseMeasurements.count <= 1 {
            return 0
        }
        
        return Double(currentGlucose.glucose) - Double(currentGlucoseMeasurements[1].glucose)
    }
    
    public var currentGlucoseString: String {
        guard let result = numberFormatter.string(from: NSNumber(value: currentGlucose.glucose)) else {
            fatalError("*** Unable to create a string for \(currentGlucose.glucose) ***")
        }
        
        return result
    }
    
    public var currentGlucoseTrendSymbolString: String {
        guard let result = currentGlucose.trendType?.symbol else {
            return "-"
        }
        
        return result
    }
    
    public var currentGlucoseDeltaString: String {
        let prefix = currentGlucoseDelta >= 0 ? "+" : ""
        guard let result = numberFormatter.string(from: NSNumber(value: currentGlucoseDelta)) else {
            fatalError("*** Unable to create a string for \(currentGlucose.glucose) ***")
        }
        
        return "\(prefix)\(result)"
    }
    
    public var currentGlucoseTimeString: String {
        return dateFormatter.string(from: currentGlucose.timestamp)
    }
    
    public func currentGlucoseTimeDeltaString(atDate date: Date) -> (long: String, short: String) {
        let minutes = Int(round(date.timeIntervalSince(currentGlucose.timestamp) / 60))
        
        if minutes < GGOptions.nowThreshold {
            return ("NOW", "NOW")
        }
        
        if minutes > GGOptions.oldThreshold {
            return ("OLD", "OLD")
        }
        
        let minString = minutes == 1 ? "min" : "mins"
        
        guard let result = numberFormatter.string(from: NSNumber(value: minutes)) else {
            fatalError("*** Unable to create a string for \(minutes) ***")
        }
        
        return ("\(result) \(minString) ago", "\(result) \(minString)")
    }
    
    public func currentGlucoseTimeDeltaValue(atDate date: Date) -> Double {
        return date.timeIntervalSince(currentGlucose.timestamp) / 60.0
    }
        
    public func color(forGlucose glucose: UInt16) -> UIColor {
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
        
    private func saveGlucoseMeasurements() -> Data? {
        // Don't save the data if there haven't been any changes.
        if currentGlucoseMeasurements == savedGlucose {
            logger.debug("The glucose measurements hasn't changed. No need to save.")
            return nil
        }
        
        // Save as a binary plist file.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        let data: Data
        
        do {
            // Encode the currentDrinks array.
            data = try encoder.encode(currentGlucoseMeasurements)
        } catch {
            logger.error("An error occurred while encoding the data: \(error.localizedDescription)")
            return nil
        }
        
        return data
    }
    
    // Begin saving the drink data to disk.
    private func save() {
        
        let glucoseData = saveGlucoseMeasurements()
        
        // nothing to do
        if glucoseData == nil {
            return
        }
        
        // Save the data to disk as a binary plist file.
        let saveAction = { [unowned self] in
            do {
                // Write the data to disk
                if let glucoseData = glucoseData {
                    try glucoseData.write(to: self.getGlucoseDataURL(), options: [.atomic])
                }
    
                // Update the saved value.
                self.savedGlucose = currentGlucoseMeasurements
                
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
        
            var glucoses: [ShareGlucose]
            
            do {
                // Decode the data.
                let decoder = PropertyListDecoder()
                let glucoseData = try Data(contentsOf: self.getGlucoseDataURL())
                
                glucoses = try decoder.decode([ShareGlucose].self, from: glucoseData)
                
                logger.debug("Data loaded from disk")
                
            } catch CocoaError.fileReadNoSuchFile {
                logger.debug("No file found--creating an empty drink list.")
                glucoses = []
                
            } catch {
                fatalError("*** An unexpected error occurred while loading the drink list: \(error.localizedDescription) ***")
            }
            
            // Update the entires on the main queue.
            DispatchQueue.main.async { [unowned self] in
                
                savedGlucose = glucoses
                
                // Filter the drinks.
                currentGlucoseMeasurements = filterGlucoseMeasurements(glucoseMeasurements: glucoses)
                                
                self.loadNewDexcomData()
            }
        }
    }
    
    public func loadNewDexcomData(completionHandler: @escaping (Bool) -> Void = { _ in }) {
        logger.debug("Loading Data from Dexcom")
        
        self.client.fetchLast(GGOptions.dexcomFetchCount) { (error, newGlucose) in
            if let error = error {
                self.logger.debug("Got fetch error from Dexcom: \(error)")
                completionHandler(false)
                return
            }
            
            guard let newGlucose = newGlucose else {
                completionHandler(false)
                return
            }
            
            DispatchQueue.main.async {
                // Get a copy of the current glucose data.
                let oldGlucose = self.currentGlucoseMeasurements
                
                let newNewGlucose = Set(oldGlucose).union(Set(newGlucose)).sorted { lhs, rhs in
                    lhs.timestamp.compare(rhs.timestamp) == .orderedDescending
                }
                                                                
                self.currentGlucoseMeasurements = newNewGlucose
                completionHandler(true)
            }
        }
    }
        
    // Returns the URL for the plist file that stores the glucose data.
    private func getGlucoseDataURL() throws -> URL {
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

// Filter array to only the drinks in the last 24 hours.
private func filterGlucoseMeasurements(glucoseMeasurements: [ShareGlucose]) -> [ShareGlucose] {
    // The current date and time.
    let endDate = Date()
    
    // The date and time 24 hours ago.
    let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)
    
    // Return an array of drinks with a date parameter between
    // the start and end dates.
    return glucoseMeasurements.filter { (glucose) -> Bool in
        (startDate.compare(glucose.timestamp) != .orderedDescending) &&
            (endDate.compare(glucose.timestamp) != .orderedAscending)
    }
}
