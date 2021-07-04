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
    case fetchError(reason: String)
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
            
        case .fetchError(let reason):
            return "Fetch Error, Reason: \(reason)"
            
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

protocol DexcomProvidable {
    func authenticate() async throws
    func fetchLatestReadings(_ numReadings: Int) async throws -> [GlucoseReading]
    func invalidateSession() async
}

actor DexcomProvider: DexcomProvidable {
    private let logger = Logger(
        subsystem: "me.graysonsmith.GlucoseGlance.watchkitapp.watchkitextension.DexcomProvider",
        category: "DexcomProvider")
    
    private var token: String?
    
    private let username: String
    private let password: String
    private let shareServer: KnownShareServer
    
    private var lastFetchedReadings: [GlucoseReading] = []
    private var lastFetch: Date = Date.distantPast
    private let allowedFetchInterval: TimeInterval = GGOptions.shared.dexcomFetchLimit
    
    public static let shared = DexcomProvider(username: GGOptions.shared.username,
                                              password: GGOptions.shared.password,
                                              shareServer: GGOptions.shared.dexcomServer)
    
    public init(username: String, password: String, shareServer: KnownShareServer) {
        self.username = username
        self.password = password
        self.shareServer = shareServer
    }

    public func fetchLatestReadings(_ numReadings: Int) async throws -> [GlucoseReading] {
        logger.debug("Fetching latest (\(numReadings, privacy: .public)) readings...")
        
        let now = Date()
        let timeSinceLastFetch = lastFetch.distance(to: now)
        let sleeping = UInt32(max(allowedFetchInterval - timeSinceLastFetch, 0))
        logger.debug("Sleeping \(sleeping, privacy: .public)")
        sleep(sleeping)
        
        lastFetch = now
        
        if token == nil {
            try await authenticate()
        }

        guard var components = URLComponents(string: shareServer.rawValue + dexcomLatestGlucosePath) else {
            throw ShareError.fetchError(reason: "Fetch components construction fail")
        }

        components.queryItems = [
            URLQueryItem(name: "sessionId", value: token),
            URLQueryItem(name: "minutes", value: String(1440)),
            URLQueryItem(name: "maxCount", value: String(numReadings))
        ]

        guard let url = components.url else {
            throw ShareError.fetchError(reason: "Fetch URL construction fail")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(dexcomUserAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ShareError.fetchError(reason: "Fetch Request Failed")
        }
        guard response.statusCode == 200 else {
            throw ShareError.fetchError(reason: "\(response.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([GlucoseReading].self, from: data)
        lastFetchedReadings = decoded
        
        return decoded
    }

    public func authenticate() async throws {
        logger.debug("Authenticating...")
        
        let uploadData = [
            "accountName": username,
            "password": password,
            "applicationId": dexcomApplicationId
        ]

        guard let encodedData = try? JSONSerialization.data(withJSONObject: uploadData) else {
            throw ShareError.dataError(reason: "Auth Data Encode Failed")
        }

        guard let url = URL(string: shareServer.rawValue + dexcomLoginPath) else {
            throw ShareError.fetchError(reason: "Auth URL construction fail")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(dexcomUserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = encodedData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw ShareError.loginError(errorCode: "Auth Request Failed")
        }
        guard response.statusCode == 200 else {
            throw ShareError.loginError(errorCode: "\(response.statusCode)")
        }
        
        let decoded: Any
        do {
            decoded = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            throw ShareError.loginError(errorCode: "Auth Decode Failed: \(error.localizedDescription)")
        }

        guard let token = decoded as? String else {
            throw ShareError.loginError(errorCode: "Auth Parse Failed")
        }

        self.token = token
    }
    
    public func invalidateSession() async {
        token = nil
        lastFetch = Date.distantPast
        lastFetchedReadings = []
    }
}
