//
//  GlucoseReading.swift
//  dexcom_test
//
//  Created by Grayson Smith on 6/17/21.
//

import Foundation

public struct GlucoseReading: Codable, Hashable, Comparable {
    public let value: Int
    public let trend: GlucoseTrend
    public let timestamp: Date
        
    public static func < (lhs: GlucoseReading, rhs: GlucoseReading) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }
    
    public init() {
        self.init(value: 100, trend: .unknown, timestamp: .distantPast)
    }
    
    public init(value: Int, trend: GlucoseTrend, timestamp: Date) {
        self.value = value
        self.trend = trend
        self.timestamp = timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.value = try container.decode(Int.self, forKey: .value)
        
        let trendInt = try container.decode(Int.self, forKey: .trend)
        guard let trend = GlucoseTrend(rawValue: trendInt) else {
            throw DecodingError.dataCorruptedError(forKey: .trend,
                                                   in: container,
                                                   debugDescription: "Glucose trend does not match format expected.")

        }
        self.trend = trend
        
        let wtString = try container.decode(String.self, forKey: .timestamp)
        // wt looks like "/Date(1462404576000)/"
        let dateSearch = wtString.range(of: #"\d+"#, options: .regularExpression)
        guard let dateSearch = dateSearch, let dateNumber = Double(wtString[dateSearch]) else {
            throw DecodingError.dataCorruptedError(forKey: .timestamp,
                                                   in: container,
                                                   debugDescription: "Date in unexpected format")
        }

        self.timestamp = Date(timeIntervalSince1970: dateNumber / 1000)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(value, forKey: .value)
        try container.encode(trend.rawValue, forKey: .trend)
        try container.encode("/Date(\(timestamp.timeIntervalSince1970 * 1000))/", forKey: .timestamp)
    }
        
    private enum CodingKeys: String, CodingKey {
        case value = "Value"
        case trend = "Trend"
        case timestamp = "WT"
    }
}

extension GlucoseReading: CustomStringConvertible {
    public var description: String {
        return "(\(self.timestamp)) \(self.value) \(self.trend.symbol)"
    }
}

public enum GlucoseTrend: Int, CaseIterable, Codable {
    case unknown      = 0
    case upUpUp       = 1
    case upUp         = 2
    case up           = 3
    case flat         = 4
    case down         = 5
    case downDown     = 6
    case downDownDown = 7

    public var symbol: String {
        switch self {
        case .unknown:
            return ""
        case .upUpUp:
            return "⇈"
        case .upUp:
            return "↑"
        case .up:
            return "↗︎"
        case .flat:
            return "→"
        case .down:
            return "↘︎"
        case .downDown:
            return "↓"
        case .downDownDown:
            return "⇊"
        }
    }

    public var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .upUpUp:
            return "Rising very fast"
        case .upUp:
            return "Rising fast"
        case .up:
            return "Rising"
        case .flat:
            return "Flat"
        case .down:
            return "Falling"
        case .downDown:
            return "Falling fast"
        case .downDownDown:
            return "Falling very fast"
        }
    }
}
