//
//  EventManager.swift
//  EventManager
//
//  Created by BSH on 26.01.19.
//  Copyright © 2019 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import Foundation
import EventKit

/**
 A class that combines all the interactions with the EKEventStore and Mock versions of that store.
 
  -  NOTE: I got my main inspiration for the three key functions to add, change and delete an EKEvent from the event store and how to get acces to it from this Stack Overflow question thread (esp. Rujoota Shah's Answer from Sep 25 '16 at 2:44): [How to add an event in the device calendar using swift](https://stackoverflow.com/questions/28379603/how-to-add-an-event-in-the-device-calendar-using-swift)
 */

class EventManager<StoreEvent: EventStoreEvent>  {
    // MARK: Properties
    /// The store from the system with wich the event manager interacts.
    /// - TODO: Make the store property private.
    var store: StoreEvent.MatchingEventStore
    
    // MARK: Initializer
    required init(with eventStore: StoreEvent.MatchingEventStore) {
        self.store = eventStore
    }

    // MARK: Methods
    /**
     Creates creates an event Object in an adequat event store, saves it and returnes the identifiyer for that event.
     
     - Parameter eventCreationPreset: The preset for wich a calender event should be created.
     - Throws: An error of type EventManagerError or an NSError
     - Returns: A String containing the calender event identifier.
     */
    func createCalendarEvent(for eventCreationPreset: EventCreationPreset) throws -> String {
        
        // Act based on the current authorisation status.
        try confirmAuthorization(for: .event)
        
        // Crate a new event with instructions from the preset.
        var eventStoreEvent = StoreEvent.createEvent(eventStore: store)
        eventStoreEvent.title = eventCreationPreset.title
        eventStoreEvent.startDate = eventCreationPreset.date
        eventStoreEvent.endDate = Date(timeInterval: EventCreationPreset.twoHourTimeInterval!, since: eventCreationPreset.date)
        eventStoreEvent.calendar = store.defaultCalendarForNewEvents
        
        // Save the event to the event store
        do {
            try store.save(eventStoreEvent , span: .thisEvent, commit: true)
            print("Saved event of type \(type(of: eventStoreEvent)) titled \(String(describing: eventStoreEvent.title)) with identifier \(String(describing: eventStoreEvent.eventIdentifier)) to the event store.")        }
        
        // Return the now set event identifieer
        return eventStoreEvent.eventIdentifier
    }
    
    /**
     Removes the calender event for a corresponding event creation preset from the event store.
     
     - Parameter eventCreationPreset: A event creation preset for wich the corresponding calender event should be deleted
     - Throws: An error of type `EventManagerError`
     - Todo: Should this method simply be called remove? And the other two accordingly create and edit?
     */
    func removeCalendarEventCorrespondingTo(_ eventCreationPreset: EventCreationPreset) throws {
        
        // Act based on the current authorisation status.
        try confirmAuthorization(for: .event)
        
        // Read the identifier from the event preset
        guard let identifier = eventCreationPreset.getIdentifier() else {
            throw EventManagerError.unableToRetrieveEventID
        }
        
        // Retriev the event with the identifier from the event store
        guard let eventToRemove = store.event(withIdentifier: identifier) else {
            throw EventManagerError.unableToRetrieveEvent(identifier: identifier)
        }
        
        // Remove the event from the store
        do {
            try store.remove(eventToRemove, span: .thisEvent)
            print("Removed event object of type \(type(of: eventToRemove)) titled \(String(describing: eventToRemove.title)) with identifier \(String(describing: identifier)) from store.")
        } catch {
            print("Failed to remove event from event store with error: \(error)")
        }
    }
    
    
    /**
     Edits a calender event according to an event creation preset.
     
     - Parameter eventCreationPreset: An event creation preset wich is the base for an existing calender event that was created before.
     - Throws: Errors of type `EventManagerError` or NSError
     */
    func editCalendarEventCorrespondingTo(_ eventCreationPreset: EventCreationPreset) throws {
        // Act based on the current authorisation status.
        try confirmAuthorization(for: .event)
        
        // Read the identifier from the event preset
        guard let identifier = eventCreationPreset.getIdentifier() else {
            throw EventManagerError.unableToRetrieveEventID
        }
        
        // Get the calender event associated with the identifier from the store.
        guard var eventToEdit = self.store.event(withIdentifier: identifier) else {
            throw EventManagerError.unableToRetrieveEvent(identifier: identifier)
        }
        
        // Update the properties of the calender event with the ones from the preset.
        eventToEdit.title = eventCreationPreset.title
        eventToEdit.startDate = eventCreationPreset.date
        eventToEdit.endDate = eventCreationPreset.date.addingTimeInterval(EventCreationPreset.twoHourTimeInterval!)
        
        // Save the updated event to the store or react to errors that might occure.
        // TODO: Warum muss ich das event hier nicht downcasten, bei create aber schon?
        do {
            try store.save(eventToEdit , span: .thisEvent, commit: true)
            print("Updating event object of type \(type(of: eventToEdit)) titled \(String(describing: eventToEdit.title)) with identifier \(String(describing: identifier)) succsefull.")
        } catch {
            print("Failed to update event with error message: \(error).")
        }
        
    }
    
    
    // - MARK: Updating event creation presets
    // TODO: Refactor seperating logic and effects, wich is explained here.
    // (https://developer.apple.com/videos/play/wwdc2017-414/?time=896)
    
    /**
     Checks weather an preset is in need of updating, since the event created with it got changed outside of the app.
     
     - TODO: What if the callender changed, how to retrieve the event then?
     */
    func needsToUpdate(_ preset: EventCreationPreset) throws -> Bool {
        // Act based on the current authorisation status.
        try confirmAuthorization(for: .event)
        
        guard let identifier = preset.getIdentifier() else {
            throw EventManagerError.unableToRetrieveEventID
        }
        
        guard let event = store.event(withIdentifier: identifier) else {
            throw EventManagerError.unableToRetrieveEvent(identifier: identifier)
        }
        
        // If either title or date do not match return true
        if (preset.title != event.title) || (preset.date != event.startDate) {
            print("Preset \(preset) needs update.")
            return true
        } else {
            // If both are the same return false
            print("Preset \(preset) is up to date.")
            return false
        }
    }
    
    /// Updates a preset if the event that was crated from it changes outside ot the app.
    func update(_ preset: EventCreationPreset) throws {
        // Act based on the current authorisation status.
        try confirmAuthorization(for: .event)
        

        guard let identifier = preset.getIdentifier() else {
            throw EventManagerError.unableToRetrieveEventID
        }
        
        guard let event = store.event(withIdentifier: identifier) else {
            throw EventManagerError.unableToRetrieveEvent(identifier: identifier)
        }
        
        // Update the fields of the preset.
        preset.title = event.title
        preset.date = event.startDate
        print("Preset \(preset) was updated.")
    }
    
    // MARK: Privat Methods
    /**
     Requests the Authorisation to the event store object for a specific kind of entity.
     
     ptints to the console weather the user has granted or denied the acces.
     
     - Parameter entityType: The event or reminder entity type.
     */
    private func requestAuthorisation(for entityType: EKEntityType) {
        store.requestAccess(to: entityType) { (granted, error)  in
            if (granted) && (error == nil) {
                
                // TODO: Find out why DispatchQueue is used here? Where in Stackoverflow did I get the idea for that?
                DispatchQueue.main.async {
                    print("User has granted access to \(String(describing: entityType))")
                }
            } else {
                DispatchQueue.main.async {
                    print("User has denied access to \(String(describing: entityType))")
                }
            }
        }
    }
    
    // #TODO: __The following method still feels wrong.__
    // Should this really be a function? How elese could this be solved? I still have the feeling something with a closure would be more apropiate
    
    /**
     Switches through the authorisationstatus of the eventstore object and acts accordingly.
     
     If authorisation is not determined it requests it and checks again.
     
     - Parameter entityType: The event or reminder entitytype
     - Throws: An error of type `EventHelperError`
     */
    private func confirmAuthorization(for entityType: EKEntityType) throws {
        switch StoreEvent.MatchingEventStore.authorizationStatus(for: entityType) {
        case EKAuthorizationStatus.notDetermined:
            // First request authorisation for the entity type.
            requestAuthorisation(for: entityType)
            
            store.reset()
            
            try confirmAuthorization(for: entityType)
            
        case EKAuthorizationStatus.denied:
            print("Access to the event store was denied.")
            throw EventManagerError.authorisationDenied
            
        case EKAuthorizationStatus.restricted:
            print("Access to the event store was restricted.")
            throw EventManagerError.authorisationRestricted
            
        case EKAuthorizationStatus.authorized:
            print("Acces to the event store granted.")
        }
    }
}



// MARK: Error Conditions
/// The kinds of error EventHelper may produce.
/// - TODO: An error if the update of a preset is not succsesfull?
enum EventManagerError: Error {
    /// The types of the store and the event object do not match
    case StoreEventIncompatibility
    /// The acces to the event store was denied.
    case authorisationDenied
    /// The access to the event store is restricted.
    case authorisationRestricted
    /// The retrieval of an EKEvent object from the event store with a particular identifier was unsuccsessfull.
    case unableToRetrieveEvent(identifier: String?)
    /// The retrieval of the identifier from a EventCreationPreset was unsuccsessfull.
    case unableToRetrieveEventID
}
