//
//  EventManagerTests.swift
//  EventManagerTests
//
//  Created by BSH on 17.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import XCTest
@testable import EventManager




class EventManagerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // MARK: EventCreationPreset Class Tests
    //Confirm that the EventCreationPreset initializer returns a EventCreationPreset object when passed valid parameters.
    func testEventInitializationSucceds() {
        // Initialize with a valid UUID, that seem to be two uuids seeperated by a colon
        let UUIDEvent = EventCreationPreset.init(title: "Test Event", date: Date(), identifierForEvent: UUID().uuidString + ":" + UUID().uuidString)
        XCTAssertNotNil(UUIDEvent)
    }
    
    //Confirm that the EventCreationPreset initializer returns nil whe passed a non vailid uuid string
    func testEventInitializationFails() {
        // invalid UUID string, that looks valid but is not
        let someStringEvent = EventCreationPreset.init(title: "Test Event", date: Date(), identifierForEvent: "F8EAC467-9EC2-476C-BF30-45588240A8D0")
        XCTAssertNil(someStringEvent)
        
        // Empty title string
        let emptyNameStringEvent = EventCreationPreset.init(title: "", date: Date(), identifierForEvent: UUID().uuidString)
        XCTAssertNil(emptyNameStringEvent)
    }

    /*
     - TODO: Write test for the event helper
     Information on how to write test for EventKit using the EKEventStore [from Stack Overflow](https://stackoverflow.com/questions/25410129/any-chance-to-write-unit-tests-against-ekeventstore?rq=1)
     */
    
    // - ToDo: Write a test, that assainges different strings to an event preset. some work some don't
    

}
