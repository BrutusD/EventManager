//
//  EventManagerTests.swift
//  EventManagerTests
//
//  Created by BSH on 01.02.19.
//  Copyright © 2019 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import XCTest
import EventKit
@testable import EventManager

class EventManagerTests: XCTestCase {
    // - MARK: Propeties
    var testStore: MockEventStore!
    var eventManager: EventManager<MockStoreEvent>!
    let validTestPreset = EventCreationPreset(title: "TestPreset", date: Date())!
    let validTestEvent = MockStoreEvent()
    
    let statesForFailTest = [MockEventStore.MockAuthorisationStatus.denied, MockEventStore.MockAuthorisationStatus.restricted]
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
       
        // Initalize a new test store
        testStore = MockEventStore()

        // Initalize an event manager, that handles mock events
        eventManager = EventManager<MockStoreEvent>(with: testStore)
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
    func testEventCreationSucceeds() throws {
        // - MARK: acces granted
        // Switch the authorisationStatus to .authorized
        MockEventStore.authorisationStatus = .authorized
        // Save valid preset to the test store
        let firstTestEventIdentifier = try eventManager.createCalendarEvent(for: validTestPreset)
        
        XCTAssertNotNil(testStore.testEvent)
        XCTAssertNotNil(firstTestEventIdentifier)
        XCTAssertEqual(testStore.testEvent?.title, validTestPreset.title)
        XCTAssertEqual(testStore.testEvent?.startDate, validTestPreset.date)
        
        
        // - MARK: not determined then granted
        // Prepare the store to a not determined statet which will be granted when asked for it
        MockEventStore.authorisationShouldBeGranted = true
        
        // Save valid preset to the test store
        let secondTestEventIdentifier = try eventManager.createCalendarEvent(for: validTestPreset)
        
        XCTAssertNotNil(testStore.testEvent)
        XCTAssertNotNil(secondTestEventIdentifier)
        XCTAssertEqual(testStore.testEvent?.title, validTestPreset.title)
        XCTAssertEqual(testStore.testEvent?.startDate, validTestPreset.date)
    }
    
    func testEventCreationFails() throws {
        // - MARK: not determined then denied
        // Prepare the store to a not determine state wich will denie a request for acces
        MockEventStore.authorisationShouldBeGranted = false
        
        // Make sure an error is thrown after in the creation process
        XCTAssertThrowsError(try eventManager.createCalendarEvent(for: validTestPreset))
        
        
        // - MARK: denied, restricted
        // - NOTE: Why does this not produce the console logs that I wrot in the confirmAuthorisation(for: EKEntityType
        // Make sure an error is thrown for each fail state
        for state in statesForFailTest {
            MockEventStore.authorisationStatus = state
            
            XCTAssertThrowsError(try eventManager.createCalendarEvent(for: validTestPreset))
        }
    }
    

    
    func testEventRemovalSucceeds() throws {
        // Create a preset for the test event
        let testPresetForTestEvent = EventCreationPreset(title: validTestEvent.title, date: validTestEvent.startDate, identifierForEvent: validTestEvent.eventIdentifier)!
        
        
        // - MARK: authorized
        MockEventStore.authorisationStatus = .authorized

        // Plant the test event in the event store
        testStore.testEvent = validTestEvent
        
        // Try to remove it frome the store
        XCTAssertNoThrow(try eventManager.removeCalendarEventCorrespondingTo(testPresetForTestEvent))
        // Make sure the event is no longer there
        XCTAssertNil(testStore.testEvent)
        
        
        // - MARK: not determined then authorized
        MockEventStore.authorisationShouldBeGranted = true
        
        // Plant the test event in the event store
        testStore.testEvent = validTestEvent
        
        // Try to remove it frome the store
        XCTAssertNoThrow(try eventManager.removeCalendarEventCorrespondingTo(testPresetForTestEvent))
        // Make sure the event is no longer there
        XCTAssertNil(testStore.testEvent)
        
    }
    
    func testRemovalFails() throws {
        // Create a preset for the test event
        let testPresetForTestEvent = EventCreationPreset(title: validTestEvent.title, date: validTestEvent.startDate, identifierForEvent: validTestEvent.eventIdentifier)!
        
        
        // - MARK: not determined then denied
        MockEventStore.authorisationShouldBeGranted = false
        
        // Plant the test event in the event store
        testStore.testEvent = validTestEvent
        
        // Try to remove it frome the store
        XCTAssertThrowsError(try eventManager.removeCalendarEventCorrespondingTo(testPresetForTestEvent))
        // Make sure the event is still there
        XCTAssertNotNil(testStore.testEvent)
        
        
        // - MARK: denied, restricted
        // Make sure an error is thrown for each fail state
        for state in statesForFailTest {
            MockEventStore.authorisationStatus = state
            
            // Plant the test event in the event store
            testStore.testEvent = validTestEvent
            
            // Try to remove it
            XCTAssertThrowsError(try eventManager.removeCalendarEventCorrespondingTo(testPresetForTestEvent))
            // Make sure the event is still there
            XCTAssertNotNil(testStore.testEvent)
        }
        
        
        // - MARK: invalid identifier / preset
        MockEventStore.authorisationStatus = .authorized
        // Create an invalid test preset
        let invalidTestPreset = EventCreationPreset(title: "This can not be found", date: Date(), identifierForEvent: UUID().uuidString + ":" + UUID().uuidString)!
        // Try to remove it frome the store
        XCTAssertThrowsError(try eventManager.removeCalendarEventCorrespondingTo(invalidTestPreset))
    }
    
    func testEventEditingSucceeds() throws {
        // - MARK: Set up
        // Create an Identifier
        let identifier = UUID().uuidString + ":" + UUID().uuidString
        
        // Create a preset before and after editing
        let oldPreset = EventCreationPreset(title: "Old Title", date: Date(), identifierForEvent: identifier)!
        let newPreset = EventCreationPreset(title: "New title", date: Date(timeIntervalSince1970: 3600), identifierForEvent: identifier)!
        
        // Create a mock event from the before preset
        var eventFromOldPreset : MockStoreEvent {
            let event = MockStoreEvent()
            event.title = oldPreset.title
            event.startDate = oldPreset.date
            event.eventIdentifier = identifier
            return event
        }

        
        // - MARK: authorized
        MockEventStore.authorisationStatus = .authorized
        // Save the old event to the test store and try to change it
        testStore.testEvent = eventFromOldPreset
        XCTAssertNoThrow(try eventManager.editCalendarEventCorrespondingTo(newPreset))
        XCTAssertEqual(testStore.testEvent!.title, newPreset.title)
        XCTAssertEqual(testStore.testEvent!.startDate, newPreset.date)
        
        // - MARK: not determined then authorized
        MockEventStore.authorisationShouldBeGranted = true
        // Save the old event to the test store and try to change it
        testStore.testEvent = eventFromOldPreset
        XCTAssertNoThrow(try eventManager.editCalendarEventCorrespondingTo(newPreset))
        XCTAssertEqual(testStore.testEvent!.title, newPreset.title)
        XCTAssertEqual(testStore.testEvent!.startDate, newPreset.date)
    }
    
    func testEvenEditingFails() throws {
        // - MARK: Set up
        // Create an Identifier
        let identifier = UUID().uuidString + ":" + UUID().uuidString
        
        // Create a presets for befor and after editing
        let oldPreset = EventCreationPreset(title: "Old Title", date: Date(), identifierForEvent: identifier)!
        let newPreset = EventCreationPreset(title: "New title", date: Date(timeIntervalSince1970: 3600), identifierForEvent: identifier)!
        
        // Create a mock event from the befor preset
        var eventFromOldPreset : MockStoreEvent {
            let event = MockStoreEvent()
            event.title = oldPreset.title
            event.startDate = oldPreset.date
            event.eventIdentifier = identifier
            return event
        }
        
        
        // - MARK: not determined then denied
        MockEventStore.authorisationShouldBeGranted = false
        // Save the old event to the test store and try to change it
        testStore.testEvent = eventFromOldPreset
        XCTAssertThrowsError(try eventManager.editCalendarEventCorrespondingTo(newPreset))
    
        
        // - MARK: denied, restricted
        // Make sure an error is thrown for each fail state
        for state in statesForFailTest {
            MockEventStore.authorisationStatus = state
            
            // Save the old event to the test store and try to change it
            testStore.testEvent = eventFromOldPreset
            XCTAssertThrowsError(try eventManager.editCalendarEventCorrespondingTo(newPreset))
        }
        
        
        // - MARK: invalid identifier / preset
        MockEventStore.authorisationStatus = .authorized
        // Create an invalid test preset
        let invalidTestPreset = EventCreationPreset(title: "This can not be found", date: Date(), identifierForEvent: UUID().uuidString + ":" + UUID().uuidString)!
        // Try to edit it in the store
        XCTAssertThrowsError(try eventManager.editCalendarEventCorrespondingTo(invalidTestPreset))
    }
    
    
    /**
     A function that returnes a mock Event and four event creation presets to test update mechanics of an event manager
     */
    func updatePresetObjects() -> (updatedEvent: MockStoreEvent, presetNeedsUpdate: EventCreationPreset, titelNeedsUpdate: EventCreationPreset, dateNeedsUpdate: EventCreationPreset, upToDatePreset: EventCreationPreset) {
        
        // Create an mock event
        let updatedEvent = MockStoreEvent()
        
        // Create a corresponding preset with title and date parameters that need updating
        let presetNeedsUpdate = EventCreationPreset(title: "Old Title", date: Date(timeIntervalSince1970: 3600), identifierForEvent: updatedEvent.eventIdentifier)!
        // Create a corresponding preset with title in need of updating
        let presetTitelNeedsUpdate = EventCreationPreset(title: "Old Title", date: updatedEvent.startDate, identifierForEvent: updatedEvent.eventIdentifier)!
        // Create a corresponding preset with date in need of updating
        let presetDateNeedsUpdate = EventCreationPreset(title: updatedEvent.title, date: Date(timeIntervalSince1970: 3600), identifierForEvent: updatedEvent.eventIdentifier)!
        // Create a corresponding preset that needs no update
        let upToDatePreset = EventCreationPreset(title: updatedEvent.title, date: updatedEvent.startDate, identifierForEvent: updatedEvent.eventIdentifier)!
        
        return (updatedEvent, presetNeedsUpdate, presetTitelNeedsUpdate, presetDateNeedsUpdate, upToDatePreset)
    }
    
    func testEventPresetNeedsUpdateSucceds() throws {
        // - MARK: Set up
        // Create the test event and presets and put the event in the event store
        let updateTestObjects = updatePresetObjects()
        testStore.testEvent = updateTestObjects.updatedEvent

        // - MARK: authorized
        MockEventStore.authorisationStatus = .authorized
        // Try to find out if the preset needs an update
        XCTAssertTrue(try eventManager.needsToUpdate(updateTestObjects.presetNeedsUpdate))
        XCTAssertTrue(try eventManager.needsToUpdate(updateTestObjects.titelNeedsUpdate))
        XCTAssertTrue(try eventManager.needsToUpdate(updateTestObjects.dateNeedsUpdate))
        XCTAssertFalse(try eventManager.needsToUpdate(updateTestObjects.upToDatePreset))

        
        // - MARK: not determined then authorized
        MockEventStore.authorisationShouldBeGranted = true
        // Try to find out if the preset needs an update
        XCTAssertTrue(try eventManager.needsToUpdate(updateTestObjects.presetNeedsUpdate))
        XCTAssertTrue(try eventManager.needsToUpdate(updateTestObjects.titelNeedsUpdate))
        XCTAssertTrue(try eventManager.needsToUpdate(updateTestObjects.dateNeedsUpdate))
        XCTAssertFalse(try eventManager.needsToUpdate(updateTestObjects.upToDatePreset))

    }
    
    func testEventPresetNeedsUpdateFails() throws {
        // - MARK: not determined then denied
        MockEventStore.authorisationShouldBeGranted = false
        
        // Create the test event and presets and put the event in the event store
        let updateTestObjects = updatePresetObjects()
        testStore.testEvent = updateTestObjects.updatedEvent
        
        // Try to find out if the preset needs an update
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.presetNeedsUpdate))
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.titelNeedsUpdate))
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.dateNeedsUpdate))
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.upToDatePreset))
        
        
        // - MARK: denied, restricted
        // Make sure an error is thrown for each fail state
        for state in statesForFailTest {
            MockEventStore.authorisationStatus = state
            
            // Create the test event and presets and put the event in the event store
            let updateTestObjects = updatePresetObjects()
            testStore.testEvent = updateTestObjects.updatedEvent
            
            // Try to find out if the preset needs an update.
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.presetNeedsUpdate))
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.titelNeedsUpdate))
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.dateNeedsUpdate))
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.upToDatePreset))
        }
    }
    
    func testUpdateEventPresetSucceeds() throws {
        // - MARK: authorized
        MockEventStore.authorisationStatus = .authorized
        
        // Create an event and put it in the event store
        var updateTestObjects = updatePresetObjects()
        testStore.testEvent = updateTestObjects.updatedEvent
        
        // Try to update the presets and validate the change
        XCTAssertNoThrow(try eventManager.update(updateTestObjects.presetNeedsUpdate))
        XCTAssertEqual(updateTestObjects.presetNeedsUpdate.title, updateTestObjects.updatedEvent.title)
        XCTAssertEqual(updateTestObjects.presetNeedsUpdate.date, updateTestObjects.updatedEvent.startDate)
        
        XCTAssertNoThrow(try eventManager.update(updateTestObjects.titelNeedsUpdate))
        XCTAssertEqual(updateTestObjects.titelNeedsUpdate.title, updateTestObjects.updatedEvent.title)
        
        XCTAssertNoThrow(try eventManager.update(updateTestObjects.dateNeedsUpdate))
        XCTAssertEqual(updateTestObjects.dateNeedsUpdate.date, updateTestObjects.updatedEvent.startDate)


        // - MARK: not determined then authorized
        MockEventStore.authorisationShouldBeGranted = true
        
        // Create an event and put it in the event store
        updateTestObjects = updatePresetObjects()
        testStore.testEvent = updateTestObjects.updatedEvent
        
        // Try to update the presets and validate the change
        XCTAssertNoThrow(try eventManager.update(updateTestObjects.presetNeedsUpdate))
        XCTAssertEqual(updateTestObjects.presetNeedsUpdate.title, updateTestObjects.updatedEvent.title)
        XCTAssertEqual(updateTestObjects.presetNeedsUpdate.date, updateTestObjects.updatedEvent.startDate)
        
        XCTAssertNoThrow(try eventManager.update(updateTestObjects.titelNeedsUpdate))
        XCTAssertEqual(updateTestObjects.titelNeedsUpdate.title, updateTestObjects.updatedEvent.title)
        
        XCTAssertNoThrow(try eventManager.update(updateTestObjects.dateNeedsUpdate))
        XCTAssertEqual(updateTestObjects.dateNeedsUpdate.date, updateTestObjects.updatedEvent.startDate)
    }
    
    func testUpdateEventPresetFails() throws {
        // - MARK: Set up
        // Create the test event and presets and put the event in the event store
        let updateTestObjects = updatePresetObjects()
        testStore.testEvent = updateTestObjects.updatedEvent
        
        
        // - MARK: not determined then denied
        MockEventStore.authorisationShouldBeGranted = false
        // Try to update presets
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.presetNeedsUpdate))
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.titelNeedsUpdate))
        XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.dateNeedsUpdate))
        
        
        // - MARK: denied, restricted
        // Make sure an error is thrown for each fail state
        for state in statesForFailTest {
            MockEventStore.authorisationStatus = state
            
            // Try to find out if the preset needs an update.
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.presetNeedsUpdate))
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.titelNeedsUpdate))
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.dateNeedsUpdate))
            XCTAssertThrowsError(try eventManager.needsToUpdate(updateTestObjects.upToDatePreset))
        }
    }
   
}


