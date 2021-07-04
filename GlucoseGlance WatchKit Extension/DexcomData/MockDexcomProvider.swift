//
//  MockDexcomProvider.swift
//  GlucoseGlanceTests
//
//  Created by Grayson Smith on 6/19/21.
//

import Foundation
import os

actor MockDexcomProvider: DexcomProvidable {
    
    private let logger = Logger(
        subsystem: "me.graysonsmith.GlucoseGlance.MockDexcomProvider",
        category: "MockDexcomProvider")
    
    internal enum State: Equatable {
        case uninitialized
        case initialized
        case authenticated(Bool)
        case fetchedReading(times: Int)
    }
    
    private var state: State = .uninitialized
    
    private var readings: [[GlucoseReading]] = []
    
    private var shouldAuthenticate = true
    
    internal func getState() -> State {
        return state
    }
    
    internal func getReadings() -> [[GlucoseReading]] {
        return readings
    }
    
    internal func getShouldAuthenticate() -> Bool {
        return shouldAuthenticate
    }
    
    public convenience init() {
        var parsedReadings: [[GlucoseReading]] = []
        var shouldAuthenticate = true
        
        do {
            parsedReadings.append(try parseEnvironment(forKey: "gg_readings_1"))
            parsedReadings.append(try parseEnvironment(forKey: "gg_readings_2"))
            
            shouldAuthenticate = try parseEnvironment(forKey: "gg_shouldAuthenticate")
        } catch {
            print("Error trying to decode readings: \(error.localizedDescription)")
        }
        
        self.init(readings: parsedReadings, shouldAuthenticate: shouldAuthenticate)
    }
    
    public init(readings: [[GlucoseReading]], shouldAuthenticate: Bool) {
        self.readings = readings
        self.shouldAuthenticate = shouldAuthenticate
        
        logger.debug("Got should auth: \(shouldAuthenticate)")
        
        for reading in readings {
            logger.debug("---")
            logger.debug("Got reading:")
            logger.debug("\(reading)")
        }
        
        state = .initialized
    }

    public func authenticate() async throws {
        switch state {
        case .initialized:
            state = .authenticated(shouldAuthenticate)
            
            if !shouldAuthenticate {
                // TODO: something else?
                throw ShareError.loginError(errorCode: "I DON'T KNOW")
            }
            
        default:
            logger.debug("Invalid case for authenticate to be called")
        }
        
        return
    }

    public func fetchLatestReadings(_ numReadings: Int) async throws -> [GlucoseReading] {
        if case .initialized = state {
            try await authenticate()
        }
        
        switch state {
        case .authenticated(let authenticated):
            if !authenticated {
                return []
            }
            
            state = .fetchedReading(times: 1)
            guard !readings.isEmpty else {
                return []
            }
            
            return Array(readings[0].prefix(numReadings))
            
        case .fetchedReading(let times):
            // if times == 1, we'll return the 2nd element
            // if no element next, we'll just return nothing
            guard readings.count > times else {
                return []
            }
            
            state = .fetchedReading(times: times + 1)
            
            return Array(readings[times].prefix(numReadings))
            
        default:
            logger.debug("Invalid state for fetching")
            return []
        }
    }
    
    public func invalidateSession() async {
        state = .initialized
    }
    
}

enum EnvirnomentParseError: Error {
    case NoValueForKey
    case InvalidData
}

private func parseEnvironment<T: Decodable>(forKey key: String) throws -> T {
    guard let envReadings = ProcessInfo.processInfo.environment[key] else {
        throw EnvirnomentParseError.NoValueForKey
    }
    
    guard let rawData = envReadings.data(using: .utf8) else {
        throw EnvirnomentParseError.InvalidData
    }
    
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: rawData)
}
