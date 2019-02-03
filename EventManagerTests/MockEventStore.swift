//
//  MockEventStore.swift
//  EventManagerTests
//
//  Created by BSH on 03.02.19.
//  Copyright © 2019 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import Foundation
import EventKit
@testable import EventManager

// MARK: Mock Classes
class MockEventStore: EventStoring {
    var testEvent: MockStoreEvent? = nil
    
    // MARK: Properties
    /// Determines what EKAuthorizationstatus will be returned
    enum MockAuthorisationStatus: Int {
        case notDetermined = 0, restricted, denied, authorized
    }
    // What does the static imply for consequences when changing the status of this parameter
    static var authorisationStatus: MockAuthorisationStatus = .authorized
    
    // Set the authorisation status to not determined and express weather it should be granted or not at request.
    static var authorisationShouldBeGranted = true {
        didSet { authorisationStatus = .notDetermined }
    }
    
    /// In a real EKEventStore this is the calender, where events would be stored to pre default
    // - TODO: EKCalendar kann nur mit einem EKEventStore initialisiert werden. Wenn ich wirklich testen will, muss ich auch den mocken.
    var defaultCalendarForNewEvents : EKCalendar? = nil
    
    // MARK: Methods
    func requestAccess(to entityType: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler) {
        if MockEventStore.authorisationShouldBeGranted {
            MockEventStore.authorisationStatus = .authorized
        } else {
            MockEventStore.authorisationStatus = .denied
        }
    }
    
    static func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus {
        return EKAuthorizationStatus.init(rawValue: authorisationStatus.rawValue)!
    }
    
    // Store the mock event in testEvent.
    func save(_ event: MockStoreEvent, span: EKSpan, commit: Bool) throws {
        testEvent = event
    }
    
    // Retrun the test event, if the identifier matches.
    func event(withIdentifier identifier: String) -> MockStoreEvent? {
        if identifier == testEvent?.eventIdentifier {
            return testEvent
        } else {
            return nil
        }
    }
    
    
    func remove(_ event: MockStoreEvent, span: EKSpan) throws {
        testEvent = nil
    }
    
    func reset() {
        print("EventStore is reset")
    }
    
}
