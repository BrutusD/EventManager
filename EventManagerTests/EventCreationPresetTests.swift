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
        
        // Test if a event without identifier is also not nil
        XCTAssertNotNil(eventPresetWithoutID)
    }
    
    // Confirm that the EventCreationPreset initializer returns nil when passed a non vailid titel string.
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
        let onlyOneUUID = UUID().uuidString
        let notAUUID = "this is no uuid:and this is alos no uuid"
        let similarButNotAUUID1 = "1234567-123-123-123-12345678901"
        let similarButNotAUUID2 = "12345678-12345-12345-1234567890123"
        // A string that is no uuid.
        XCTAssertThrowsError(try eventPresetWithoutID?.set(notAUUID))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
        // A string that consists of only one uuid.
        XCTAssertThrowsError(try eventPresetWithoutID?.set(onlyOneUUID))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
        // Strings that have the wrong number of caracters in each substring.
        XCTAssertThrowsError(try eventPresetWithoutID?.set(similarButNotAUUID1 + ":" + similarButNotAUUID1))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
        XCTAssertThrowsError(try eventPresetWithoutID?.set(similarButNotAUUID2 + ":" + similarButNotAUUID2))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
        XCTAssertThrowsError(try eventPresetWithoutID?.set(similarButNotAUUID1 + ":" + similarButNotAUUID2))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
        XCTAssertThrowsError(try eventPresetWithoutID?.set(similarButNotAUUID2 + ":" + similarButNotAUUID1))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
        // A string that has to many substrings.
        XCTAssertThrowsError(try eventPresetWithoutID?.set(onlyOneUUID + "-1:" + onlyOneUUID + "-1"))
        XCTAssertNil(eventPresetWithoutID!.getIdentifier())
    }
    
    // - TODO: Sadly I do not know yet how this is accomplished :(
//    func testEncodeAndDecode() {
//        let presetToEncode = EventCreationPreset(title: "Freude Schöner 𝕲Ȫⓣ𝕋⒠ℛ  🎆", date: Date(), identifierForEvent: UUID().uuidString + ":" + UUID().uuidString)
//
//        let coder = NSCoder()
//
//        XCTAssertNoThrow(presetToEncode?.encode(with: coder))
//
//        let presetAfterDecode = EventCreationPreset.init(coder: coder)
//        XCTAssertEqual(presetToEncode, presetAfterDecode)
//    }
}
