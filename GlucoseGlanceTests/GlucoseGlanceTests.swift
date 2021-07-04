//
//  GlucoseGlanceTests.swift
//  GlucoseGlanceTests
//
//  Created by Grayson Smith on 5/15/21.
//

import XCTest
@testable import GlucoseGlance_WatchKit_Extension

class GlucoseGlanceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
//        sleep(3)
        unsetenv("gg_readings_1")
        unsetenv("gg_readings_2")
        unsetenv("gg_shouldAuthenticate")
    }
    
    func testGenerateContiguousReadings() throws {
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        let readings = generateContiguousReadings(5, endingAt: baseDate)
        
        print(readings)
        var previousReading: GlucoseReading?
        for reading in readings {
            XCTAssert(reading.value >= 60)
            XCTAssert(reading.value <= 350)
            
            if let previousReading = previousReading {
                XCTAssertEqual(reading.timestamp.distance(to: previousReading.timestamp), 5.0 * 60.0)
            }
            
            previousReading = reading
        }
    }
    
    func testMock() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        
        // 112, 100, 98, 80
        let readings1 = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0)),
            GlucoseReading(value: 114, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 10.0 * 60.0))
        ]
        
        let readings2 = [
            GlucoseReading(value: 80, trend: .down, timestamp: baseDate.advanced(by: 10.0 * 60.0)),
            GlucoseReading(value: 98, trend: .flat, timestamp: baseDate.advanced(by: 5.0 * 60.0))
        ]
        
        let shouldAuth = true
        
        let encoder = JSONEncoder()
        
        let encoded_readings_1 = try encoder.encode(readings1)
        let encoded_readings_2 = try encoder.encode(readings2)
        let encoded_shouldAuth = try encoder.encode(shouldAuth)
        
        let string_readings_1 = String(data: encoded_readings_1, encoding: .utf8)!
        let string_readings_2 = String(data: encoded_readings_2, encoding: .utf8)!
        let string_shouldAuth = String(data: encoded_shouldAuth, encoding: .utf8)!
        
        XCTAssertEqual(setenv("gg_readings_1", string_readings_1, 1), 0)
        XCTAssertEqual(setenv("gg_readings_2", string_readings_2, 1), 0)
        XCTAssertEqual(setenv("gg_shouldAuthenticate", string_shouldAuth, 1), 0)
        
        let provider = MockDexcomProvider()
        
        Task {
            try await provider.authenticate()
            
            let state = await provider.getState()
            
            XCTAssertEqual(state, .authenticated(true))
            
            var readings = try await provider.fetchLatestReadings(2)
            
            XCTAssert(readings.count == 2)
            XCTAssertEqual(readings[0], readings1[0])
            XCTAssertEqual(readings[1], readings1[1])
            
            readings = try await provider.fetchLatestReadings(2)
            
            XCTAssert(readings.count == 2)
            XCTAssertEqual(readings[0], readings2[0])
            XCTAssertEqual(readings[1], readings2[1])
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testEmpty() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
                
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        Task {
            _ = await data.checkForNewReadings()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(data.currentGlucoseReadings, [])
        
        XCTAssertEqual(data.currentReading, GlucoseReading())
        XCTAssert(data.isCurrentReadingTooOld)
        XCTAssertEqual(data.currentReadingDelta, nil)
        XCTAssertEqual(data.currentReadingDeltaString, "")
        XCTAssertEqual(data.currentReadingValueString, "100")
        XCTAssertEqual(data.currentReadingTrendSymbolString, "→")
    }

    func testUpToDate() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        XCTAssertEqual(setenv("gg_readings_1", string, 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        Task {
            _ = await data.checkForNewReadings()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(data.currentGlucoseReadings, readings)

        XCTAssertFalse(data.isCurrentReadingTooOld)
        XCTAssertEqual(data.currentReadingDelta, -12)
        XCTAssertEqual(data.currentReadingDeltaString, "-12")
        XCTAssertEqual(data.currentReadingValueString, "100")
        XCTAssertEqual(data.currentReadingTrendSymbolString, "→")
    }
    
    func testFarApartReadings() throws {
        
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * GGOptions.readingOldnessInterval))
        ]
        let encoder = JSONEncoder()
        XCTAssertEqual(setenv("gg_readings_1", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        Task {
            _ = await data.checkForNewReadings()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
                
        XCTAssertEqual(data.currentGlucoseReadings, readings)
        
        XCTAssertFalse(data.isCurrentReadingTooOld)
        XCTAssertEqual(data.currentReadingDelta, nil)
        XCTAssertEqual(data.currentReadingDeltaString, "")
        XCTAssertEqual(data.currentReadingValueString, "100")
        XCTAssertEqual(data.currentReadingTrendSymbolString, "→")
    }
    
    func testLongAgoFarApartReadings() throws {
        
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        // 10 years?
        let baseDate = Date(timeIntervalSince1970: (10.0 * 60.0 * 60.0 * 24.0 * 7.0 * 52.0))
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * GGOptions.readingOldnessInterval))
        ]
        let encoder = JSONEncoder()
        XCTAssertEqual(setenv("gg_readings_1", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        Task {
            _ = await data.checkForNewReadings()
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
                
        XCTAssertEqual(data.currentGlucoseReadings, readings)
        
        XCTAssert(data.isCurrentReadingTooOld)
        XCTAssertEqual(data.currentReadingDelta, nil)
        XCTAssertEqual(data.currentReadingDeltaString, "")
        XCTAssertEqual(data.currentReadingValueString, "100")
        XCTAssertEqual(data.currentReadingTrendSymbolString, "→")
    }
    
    func testLongAgoReadings() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        // 10 years?
        let baseDate = Date(timeIntervalSince1970: (10.0 * 60.0 * 60.0 * 24.0 * 7.0 * 52.0))
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        let encoder = JSONEncoder()
        XCTAssertEqual(setenv("gg_readings_1", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
                
        Task {
            _ = await data.checkForNewReadings()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
                
        XCTAssertEqual(data.currentGlucoseReadings, readings)
        
        XCTAssertEqual(data.currentReadingDelta, -12)
        XCTAssertEqual(data.currentReadingDeltaString, "-12")
        XCTAssert(data.isCurrentReadingTooOld)
    }
    
    func testLongAgoThenRecentReadings() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        // 10 years?
        let baseDate = Date(timeIntervalSince1970: (10.0 * 60.0 * 60.0 * 24.0 * 7.0 * 52.0))
        let newDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        let encoder = JSONEncoder()
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        XCTAssertEqual(setenv("gg_readings_1", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let readings2 = [
            GlucoseReading(value: 80, trend: .down, timestamp: newDate),
            GlucoseReading(value: 98, trend: .flat, timestamp: newDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        XCTAssertEqual(setenv("gg_readings_2", String(data: try! encoder.encode(readings2), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
                
        Task {
            _ = await data.checkForNewReadings()
            
            XCTAssertEqual(data.currentGlucoseReadings, readings)
            
            XCTAssertEqual(data.currentReadingDelta, -12)
            XCTAssertEqual(data.currentReadingDeltaString, "-12")
            XCTAssert(data.isCurrentReadingTooOld)
            
            _ = await data.checkForNewReadings()
            
            XCTAssertEqual(data.currentGlucoseReadings, readings2)
            
            XCTAssertEqual(data.currentReadingDelta, -18)
            XCTAssertEqual(data.currentReadingDeltaString, "-18")
            XCTAssertFalse(data.isCurrentReadingTooOld)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
                
//        XCTAssertEqual(data.currentGlucoseReadings, readings)
//
//        XCTAssertEqual(data.currentReadingDelta, -12)
//        XCTAssertEqual(data.currentReadingDeltaString, "-12")
//        XCTAssert(data.isCurrentReadingTooOld)
    }

}

func generateContiguousReadings(_ numReadings: Int, endingAt endingDate: Date) -> [GlucoseReading] {
    var readings = [GlucoseReading]()
    let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(endingDate.timeIntervalSince1970)))
    
    for i in 0..<numReadings {
        let value = (60...350).randomElement()!
        let trend = GlucoseTrend.allCases.randomElement()!
        let timestamp = baseDate.advanced(by: -1.0 * (5.0 * Double(i)) * 60.0)
        readings.append(GlucoseReading(value: value, trend: trend, timestamp: timestamp))
    }
    
    return readings
}
