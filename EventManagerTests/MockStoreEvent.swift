//
//  MockStoreEvent.swift
//  EventManagerTests
//
//  Created by BSH on 03.02.19.
//  Copyright © 2019 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import Foundation
import EventKit
@testable import EventManager

class MockStoreEvent: EventStoreEvent {
    // MARK: Typealias
    typealias MatchingEventStore = MockEventStore
    
    // MARK: Properties
    var title: String!
    
    var startDate: Date!
    
    var endDate: Date!
    
    var calendar: EKCalendar!
    
    var eventIdentifier: String!
    
    // MARK: Initializer
    required init() {
        self.title = "Die Groeßte Gemeneinheit der Welt"
        self.startDate = Date()
        self.endDate = Date(timeInterval: 3600, since: self.startDate)
        //            self.calendar = EKCalendar()
        self.eventIdentifier = UUID().uuidString + ":" + UUID().uuidString
    }
    
    static func createEvent(eventStore: MatchingEventStore) -> Self {
        return self.init()
    }
}
