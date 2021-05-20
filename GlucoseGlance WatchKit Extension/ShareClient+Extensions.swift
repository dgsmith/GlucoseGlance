//
//  ShareClient+Extensions.swift
//  GlucoseGlance WatchKit Extension
//
//  Created by Grayson Smith on 5/15/21.
//

import Foundation
import ShareClient

public enum GlucoseTrend: Int, CaseIterable {
    case upUpUp       = 1
    case upUp         = 2
    case up           = 3
    case flat         = 4
    case down         = 5
    case downDown     = 6
    case downDownDown = 7

    public var symbol: String {
        switch self {
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

extension ShareGlucose {    
    public var trendType: GlucoseTrend? {
        return GlucoseTrend(rawValue: Int(trend))
    }
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
