//
//  DexcomDataStore.swift
//  dexcom_test
//
//  Created by Grayson Smith on 6/14/21.
//

import Foundation
import os

public enum ShareError: Error {
    case httpError(Error)
    // some possible values of errorCode:
    // SSO_AuthenticateAccountNotFound
    // SSO_AuthenticatePasswordInvalid
    // SSO_AuthenticateMaxAttemptsExceeed
    case loginError(errorCode: String)
    case fetchError
    case dataError(reason: String)
    case dateError
}

extension ShareError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .httpError(let error):
            return "HTTP Error: \(error)"
            
        case .loginError(let errorCode):
            return "Login Error: \(errorCode)"
            
        case .fetchError:
            return "Fetch Error"
            
        case .dataError(let reason):
            return "Data Error, Reason: \(reason)"
            
        case .dateError:
            return "Date Error"
        }
    }
}

public enum KnownShareServer: String {
    case US="https://share1.dexcom.com"
    case NON_US="https://shareous1.dexcom.com"
}

// From the Dexcom Share iOS app, via @bewest and @shanselman:
// https://github.com/bewest/share2nightscout-bridge
private let dexcomUserAgent = "Dexcom Share/3.0.2.11 CFNetwork/711.2.23 Darwin/14.0.0"
private let dexcomApplicationId = "d89443d2-327c-4a6f-89e5-496bbb0317db"
private let dexcomLoginPath = "/ShareWebServices/Services/General/LoginPublisherAccountByName"
private let dexcomLatestGlucosePath = "/ShareWebServices/Services/Publisher/ReadPublisherLatestGlucoseValues"
private let maxReauthAttempts = 2


actor DexcomProvider {
    private let logger = Logger(subsystem: "me.graysonsmith.test.DataStore", category: "DataStore")
    
    private var token: String?
    
    private let username: String
    private let password: String
    private let shareServer: KnownShareServer
    
    private var lastFetchedReadings: [GlucoseReading] = []
    private var lastFetch: Date = Date.distantPast
    private let allowedFetchInterval: TimeInterval = GGOptions.dexcomFetchLimit
    
    public init(username: String, password: String, shareServer: KnownShareServer) {
        self.username = username
        self.password = password
        self.shareServer = shareServer
    }

    public func fetchLatestReadings(_ numReadings: Int) async throws -> [GlucoseReading] {
        logger.log("Fetching latest (\(numReadings)) readings...")
        
        let now = Date()
        let timeSinceLastFetch = lastFetch.distance(to: now)
        guard timeSinceLastFetch > allowedFetchInterval else {
            logger.log("Last fetch too recent (\(timeSinceLastFetch))")
            return lastFetchedReadings
        }
        
        lastFetch = now
        
        if token == nil {
            try await authenticate()
        }

        guard var components = URLComponents(string: shareServer.rawValue + dexcomLatestGlucosePath) else {
            throw ShareError.fetchError
        }

        components.queryItems = [
            URLQueryItem(name: "sessionId", value: token),
            URLQueryItem(name: "minutes", value: String(1440)),
            URLQueryItem(name: "maxCount", value: String(numReadings))
        ]

        guard let url = components.url else {
            throw ShareError.fetchError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(dexcomUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([GlucoseReading].self, from: data)
        lastFetchedReadings = decoded
        
        return decoded
    }

    public func authenticate() async throws {
        logger.log("Authenticating...")
        
        let uploadData = [
            "accountName": username,
            "password": password,
            "applicationId": dexcomApplicationId
        ]

        guard let encodedData = try? JSONSerialization.data(withJSONObject: uploadData, options:[]) else {
            throw ShareError.dataError(reason: "Failed to encode JSON for POST")
        }

        guard let url = URL(string: shareServer.rawValue + dexcomLoginPath) else {
            throw ShareError.fetchError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(dexcomUserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = encodedData

        let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
        let decoded = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

        guard let token = decoded as? String else {
            throw ShareError.loginError(errorCode: "unknown")
        }

        self.token = token
    }
}
