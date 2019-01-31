//
//  EventManagerTests.swift
//  EventManagerTests
//
//  Created by BSH on 17.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import XCTest
@testable import EventManager

class EventCreationPresetTests: XCTestCase {
    // A preset to be used in other tests.
    let eventPresetWithoutID = EventCreationPreset.init(title: "Geheimes Haus", date: Date())
    
//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        do {
            try eventPresetWithoutID!.set("no valid string")
        } catch {
            print("Could not wipe the identifier, the test is INVALID!")
        }
    }
//
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    // Confirm that the EventCreationPreset initializer returns a EventCreationPreset object when passed valid parameters.
    func testEventPresetInitializationSucceds() {
        // Initialize with a valid UUID, that seem to be two uuids seeperated by a colon
        let UUIDEvent = EventCreationPreset.init(title: "Test Event", date: Date(), identifierForEvent: UUID().uuidString + ":" + UUID().uuidString)
        XCTAssertNotNil(UUIDEvent)
    }
    
    // Confirm that the EventCreationPreset initializer returns nil whe passed a non vailid titel string.
    func testEventPresetInitializationFails() {
        // Empty title string will not produce a valid event preset
        let someStringEvent = EventCreationPreset.init(title: "", date: Date())
        XCTAssertNil(someStringEvent)
        
    }
    
    // Confirm that the preset will accept a proper identifier
    func testAcceptableIdentifierWillBeStored() throws {
        let identifierString = UUID().uuidString + ":" + UUID().uuidString
        try eventPresetWithoutID?.set(identifierString)
        XCTAssertNotNil(eventPresetWithoutID!.getIdentifier())
    }
    
    // Confirm that the preset will not accept a unpropper identifier and set the id to be nil
    func testUnacceptableIdentifierWontBeStored() throws {
        XCTAssertThrowsError(try eventPresetWithoutID?.set(UUID().uuidString))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
    }

    /*
     - TODO: Write test for the event helper
     Information on how to write test for EventKit using the EKEventStore [from Stack Overflow](https://stackoverflow.com/questions/25410129/any-chance-to-write-unit-tests-against-ekeventstore?rq=1)
     */
    
    // - ToDo: Write a test, that assainges different strings to an event preset. some work some don't
    

}
