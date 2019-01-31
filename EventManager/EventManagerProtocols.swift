//
//  EventManagerProtocols.swift
//  EventManager
//
//  Created by BSH on 15.01.19.
//  Copyright © 2019 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import Foundation
import EventKit

// MARK: EventStoring Protocol
/**
 A protocol that abstracts all interfaces of EKEventStore that are used by the EventHelper Object.
 EKEventStore is an object that accesses the user’s calendar and reminder events and supports the scheduling of new events.
 - Note: I use this to create a mock event store for unit testing. [The EKEventStore Documentation](https://developer.apple.com/documentation/eventkit/ekeventstore)
 - TODO: Use EKCalenderItem instead of EKEvent. It has a more reliable identifier that should be consistent across multiple devices and oses.
 
 */
protocol EventStoring {
    associatedtype Event: EventStoreEvent where Event.MatchingEventStore == Self
    /**
     Prompts the user to grant or deny access to event or reminder data.
     
     In iOS 6 and later, requesting access to an event store asynchronously prompts your users for permission to use their data. The user is only prompted the first time your app requests access to an entity type; any subsequent instantiations of EKEventStore uses existing permissions. When the user taps to grant or deny access, the completion handler will be called on an arbitrary queue. Your app is not blocked while the user decides to grant or deny permission.
     After users choose their permission level, the event store either calls the completion handler or broadcasts an EKEventStoreChanged. The completion handler is called on iOS 6 and later, and the notification is broadcasted on iOS 5. Because users may deny access to the event store, your app should handle an empty data case.
     
     - Parameter entityType: The event or reminder entity type.
     - Parameter completion: The block to call when the request completes.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1507547-requestaccess)
     */
    func requestAccess(to entityType: EKEntityType, completion: @escaping EKEventStoreRequestAccessCompletionHandler)
    
    /**
     Returns the authorization status for the given entity type.
     - Parameter entityType: The event or reminder entity type.
     - Returns: The app’s authorization status of the given type.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1507239-authorizationstatus)
     */
    static func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus
    
    /**
     Saves an event or recurring events to the event store by either batching or committing the changes.
     
     This method raises an exception if it is passed an event from another event store.
     When an event is saved, it is updated in the Calendar database. Any fields you did not modify are updated to reflect the most recent value in the database. If the event has been deleted from the database, it is re-created as a new event.

     - Parameters:
         - event:  The event to be saved.
         - span: The span to use. Indicates whether the save affects future instances of the event in the case of a recurring event.
         - commit: To save the event immediately, pass true; otherwise, the change is batched until the commit() method is invoked.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1507295-save)
    */
    func save(_ event: Event, span: EKSpan, commit: Bool) throws
    
    /**
     Returns the first occurrence of an event with a given identifier.
     - parameter identifier: The identifier of the event.
     - Returns: The event corresponding to identifier, or nil if no event is found.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1507490-event)
     */
    func event/*<Event: EventStoreEvent>*/(withIdentifier identifier: String) -> Event?
    
    /**
     Removes an event from the event store.
     
     This method raises an exception if it is passed an event from another event store.
     - Parameters:
         - event: The event to be removed.
         - span: The span to use. Indicates whether to remove future instances of the event in the case of a recurring
         - error: The error if one occurred; otherwise, nil.
     - Returns: If the event has successfully removed, true; otherwise, false. Also returns false if event cannot be removed because it is not in the event store.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1615882-remove)
     */
    func remove/*<Event: EventStoreEvent>*/(_ event: Event, span: EKSpan) throws
    
    /**
     The calendar that events are added to by default, as specified by user settings.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1507062-defaultcalendarfornewevents)
     */
    var defaultCalendarForNewEvents: EKCalendar? { get }

    /**
     Returns the event store to its saved state.
     
     This method updates all the properties of all the objects with their corresponding values in the event store. Any local changes that were not saved before invoking this method will be lost. All objects that were created or retrieved using this store are disassociated from it and should be considered invalid.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekeventstore/1507345-reset)
     */
    func reset()
}

// Let EKEventStore conform to the protocol by letting the generic functions call there concrete counterparts on EKEventStore
extension EKEventStore: EventStoring {
//    func save<Event>(_ event: Event, span: EKSpan, commit: Bool) throws {
//        // Try to downcast event to EKEvent or print an Error Message
//        if let eventStoreEvent = event as? EKEvent {
//            try self.save(eventStoreEvent , span: span, commit: commit)
//        } else {
//            print("Das ist kein EKEvent, sondern \(String(describing: event))")
//        }
//    }
//
//    func event<Event>(withIdentifier identifier: String) -> Event? {
//        return self.event(withIdentifier: identifier)
//    }
//
//    func remove<Event>(_ event: Event, span: EKSpan) throws {
//        // Try to downcast event to EKEvent or print an Error Message
//        if let eventStoreEvent = event as? EKEvent {
//            try self.remove(eventStoreEvent, span: span)
//        } else {
//            print("Das ist kein EKEvent, sondern \(String(describing: event))")
//        }
//    }
    
//    typealias Event = MockEvent
}


// MARK: EventStoreEvent protocol
/**
 a protocol that abtracts all interfaces of EKEvent that are used by the EventHelper Object.
 EKEvent is an class that represents an event added to a calendar.
 - Note: I use this to creat  mock events for unit testing. [The EKEvent Documenentation](https://developer.apple.com/documentation/eventkit/ekevent)
 - Note: Some of the properties come from EKEvent it self and some it inherits from its super Class EKCalenderItem
 */
protocol EventStoreEvent {
    associatedtype MatchingEventStore: EventStoring
    
    /// The title for the calendar item.
    /// - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekcalendaritem/1507305-title)
    var title: String! { get set }
    
    ///The start date of the event.
    ///
    /// Floating events such as all-day events are returned in the default time zone.
    /// - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekevent/1507372-startdate
    var startDate: Date! { get set }
    
    /// The end date for the event.
    ///- Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekevent/1507121-enddate)
    var endDate: Date! { get set }
    
    /// The calendar for the calendar item.
    /// - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekcalendaritem/1507169-calendar)
    var calendar: EKCalendar! { get set }
    
    /**
     A unique identifier for the event.
     
     You can use this identifier to look up an event with the EKEventStore method event(withIdentifier:).
     If the calendar of an event changes, its identifier most likely changes as well.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekevent/1507437-eventidentifier)
     */
    var eventIdentifier: String! { get }
    
    /**
     Creates and returns a new event belonging to a specified event store.
     
     - parameters:
         - eventStore: The event store to which the event belongs.
     - Note: [Documentation of the correlating method in EventKit](https://developer.apple.com/documentation/eventkit/ekevent/1507483-init)
     */
    static func createEvent(eventStore: MatchingEventStore) -> Self
}

//extension EKEvent {
//    convenience init?<Store: EventStoring>(genericEventStore: Store) {
//        if let appleEventStore = genericEventStore as? EKEventStore {
//            self.init(eventStore: appleEventStore)
//        } else {
//            return nil
//        }
//    }
//}

extension EKEvent: EventStoreEvent {
    typealias MatchingEventStore = EKEventStore
    
    static func createEvent(eventStore: MatchingEventStore) -> Self {
        return self.init(eventStore: eventStore)
    }
}

// MARK: EventManager protocol
/**
 All the interfaces a viewcontroller needs to handle events in an event store
 */
protocol EventManagerProtocol {
    associatedtype EventStore: EventStoring
    
    var store: EventStore { get }
//    var eventStoreEvent: Event? { get set }
    
    init(with store: EventStore)
    
    func createCalendarEvent(for eventCreationPreset: EventCreationPreset) throws -> String
    
    func removeCalendarEventCorrespondingTo(_ eventCreationPreset: EventCreationPreset) throws
    
    func editCalendarEventCorrespondingTo(_ eventCreationPreset: EventCreationPreset) throws
    
    // - TODO : The method name shoul express better what is returned
    func needsToUpdate(_ preset: EventCreationPreset) throws -> Bool
    
    func update(_ preset: EventCreationPreset) throws
}
