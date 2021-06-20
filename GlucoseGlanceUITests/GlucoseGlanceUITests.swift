//
//  GlucoseGlanceUITests.swift
//  GlucoseGlanceUITests
//
//  Created by Grayson Smith on 5/15/21.
//

import XCTest

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
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings": string]
        app.launch()
        
        // Empty info
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReading.timestamp"].label, "4:07PM")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
        
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "→")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "-12")
    }
    
    func testFarApartReadings() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launchArguments = ["UI-TESTING"]
        
        let baseDate = Date(timeIntervalSince1970: TimeInterval(Int(Date().timeIntervalSince1970)))
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * GGOptions.readingOldnessInterval))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings": string]
        app.launch()
        
        // Empty info
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReading.timestamp"].label, "4:07PM")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
        
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "→")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
    }
    
    func testLongAgoFarApartReadings() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        
        app.launchArguments = ["UI-TESTING"]
        
        // 10 years?
        let baseDate = Date(timeIntervalSince1970: (10.0 * 60.0 * 60.0 * 24.0 * 7.0 * 52.0))
        
        let readings = [
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * GGOptions.readingOldnessInterval))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings": string]
        app.launch()
        
        // Empty info
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReading.timestamp"].label, "4:07PM")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
        
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "→")
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
            GlucoseReading(value: 100, trend: .flat, timestamp: baseDate),
            GlucoseReading(value: 112, trend: .flat, timestamp: baseDate.advanced(by: -1.0 * 5.0 * 60.0))
        ]
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(readings)
        let string = String(data: encoded, encoding: .utf8)!
        app.launchEnvironment = ["gg_readings": string]
        app.launch()
        
        // Empty info
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "")
        XCTAssertEqual(app.staticTexts["currentReading.timestamp"].label, "4:07PM")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
        
        
        app.buttons.firstMatch.tap()
        sleep(3)
        
        XCTAssertEqual(app.staticTexts["currentReadingValueString"].label, "100")
        XCTAssertEqual(app.staticTexts["currentReadingTrendSymbolString"].label, "→")
        XCTAssertEqual(app.staticTexts["currentReadingDeltaString"].label, "-12")
        XCTAssertEqual(app.staticTexts["isCurrentReadingTooOld"].label, "OLD")
    }
}
