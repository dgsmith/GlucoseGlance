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
        sleep(3)
        unsetenv("gg_readings")
    }
    
    func testEmpty() throws {
        let expectation = self.expectation(description: #function)
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
                
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        async {
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
        XCTAssertEqual(data.currentReadingTrendSymbolString, "")
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
        XCTAssertEqual(setenv("gg_readings", string, 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        async {
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
        XCTAssertEqual(setenv("gg_readings", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        async {
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
        XCTAssertEqual(setenv("gg_readings", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
        
        async {
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
        XCTAssertEqual(setenv("gg_readings", String(data: try! encoder.encode(readings), encoding: .utf8), 1), 0)
        
        let provider = MockDexcomProvider()
        let data = DexcomData(provider: provider)
                
        async {
            _ = await data.checkForNewReadings()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
                
        XCTAssertEqual(data.currentGlucoseReadings, readings)
        
        XCTAssertEqual(data.currentReadingDelta, -12)
        XCTAssertEqual(data.currentReadingDeltaString, "-12")
        XCTAssert(data.isCurrentReadingTooOld)
    }

}
