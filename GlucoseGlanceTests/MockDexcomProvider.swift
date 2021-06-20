//
//  MockDexcomProvider.swift
//  GlucoseGlanceTests
//
//  Created by Grayson Smith on 6/19/21.
//

import Foundation

actor MockDexcomProvider: DexcomProvidable {
    
    private let readings: [GlucoseReading]
    
    init() {
        let decoder = JSONDecoder()
        
        guard let envReadings = ProcessInfo.processInfo.environment["gg_readings"] else {
            print("No env readings")
            readings = []
            return
        }
        
        guard let rawData = envReadings.data(using: .utf8) else {
            print("Could not raw parse env readings")
            readings = []
            return
        }
        
        do {
            readings = try decoder.decode([GlucoseReading].self, from: rawData)
        } catch {
            print("Error trying to decode readings: \(error.localizedDescription)")
            readings = []
            return
        }
        
        print("---")
        print("Got readings:")
        print(readings)
        print("---")
    }

    func authenticate() async throws {
        return
    }

    func fetchLatestReadings(_ numReadings: Int) async throws -> [GlucoseReading] {
        return readings
    }
}
