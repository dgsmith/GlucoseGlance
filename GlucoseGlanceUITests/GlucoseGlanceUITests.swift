//
//  GlucoseGlanceUITests.swift
//  GlucoseGlanceUITests
//
//  Created by Grayson Smith on 5/15/21.
//

import XCTest
import Darwin

class GlucoseGlanceUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
//        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUpToDate() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launchArguments = ["UI-TESTING"]
        
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        
        let readings = [
            GlucoseReading(value: 156, trend: .down, timestamp: baseDate),
            GlucoseReading(value: 168, trend: .down, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings_1": string]
        app.launch()
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "156")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, GlucoseTrend.down.symbol)
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "-12")
    }
    
    func testFarApartReadings() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launchArguments = ["UI-TESTING"]
        
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        
        let readings = [
            GlucoseReading(value: 301, trend: .up, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .up, timestamp: baseDate.advanced(by: -1.0 * GGOptions.readingOldnessInterval))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings_1": string]
        app.launch()
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "301")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, GlucoseTrend.up.symbol)
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
    }
    
    func testLongAgoFarApartReadings() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launchArguments = ["UI-TESTING"]
        
        // 10 years?
        let baseDate = Date(timeIntervalSince1970: (10.0 * 60.0 * 60.0 * 24.0 * 7.0 * 52.0))
        
        let readings = [
            GlucoseReading(value: 234, trend: .upUp, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .upUp, timestamp: baseDate.advanced(by: -1.0 * GGOptions.readingOldnessInterval))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings_1": string]
        app.launch()
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "234")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, GlucoseTrend.upUp.symbol)
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
    }
    
    func testLongAgoReadings() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launchArguments = ["UI-TESTING"]
        
        // 10 years?
        let baseDate = Date(timeIntervalSince1970: (10.0 * 60.0 * 60.0 * 24.0 * 7.0 * 52.0))
        
        let readings = [
            GlucoseReading(value: 98, trend: .downDownDown, timestamp: baseDate),
            GlucoseReading(value: 110, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings_1": string]
        app.launch()
                
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "98")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, GlucoseTrend.downDownDown.symbol)
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "-12")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
    }
}
