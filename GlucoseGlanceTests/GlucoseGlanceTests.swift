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
    }

    func testExample() throws {
        let expectation = XCTestExpectation()
        
        let data = DexcomData.shared
        
        async {
            let result = await data.checkForNewReadings()
            
            XCTAssert(result)
            expectation.fulfill()
        }
    }

}
