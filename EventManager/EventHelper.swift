//
//  EventHelper.swift
//  EventManager
//
//  Created by BSH on 28.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import EventKit

// - TODO: Rewirite it to satisfy the EventHandling protocol
/*
protocol EventHandling {
    func create(from preset: EventCreationPreset) throws -> EKEvent
    func save(_ event: EKEvent) throws -> String
    func removeCalenderEvent(of preset: EventCreationPreset) throws
    ...
}
*/
/**
 A class that abstracts all interaction with the EKEventStore object for you

 -  NOTE: I got my main inspiration for the three key functions to add, change and delete an EKEvent from the event store and how to get acces to it from this Stack Overflow question thread (esp. Rujoota Shah's Answer from Sep 25 '16 at 2:44): [How to add an event in the device calendar using swift](https://stackoverflow.com/questions/28379603/how-to-add-an-event-in-the-device-calendar-using-swift)

*/
class EventHelper {
    
    // MARK: Properties
    /// The store with wich all methods in the eventHelper interact
    /*private*/ let store: EKEventStore!
    
//    let secondStore: EKEventStore!
    // MARK: Initializer
    init(with store: EKEventStore) {
        self.store = store
    }
    
    
    // MARK: Methods
    /**
     Creates an event in the callender according to the information in the passed event creation preset.
     
     - Parameter eventCreationPreset: The event creation preset for which a calender event should be created.
     - Throws: An error of type EventHelperError
     - Returns: A string containing the calender event identifier if creation is succsesful, otherwise nil.
     - TODO: Delete the `throws` keyword or let it throw an error. Make the returned string non optional then.
     
     */
    // TODO: Delete the `throws` keyword or let it throw an error. Make the returned string non optional then.
    func createCalendarEvent(for eventCreationPreset: EventCreationPreset) throws -> String? {
        
        // Act based on the current authorisation status.
        try confirmAuthorization(for: .event)
        
        // Create a new event with instructions from the preset.
        let newEvent = EKEvent(eventStore: store /*as! EKEventStore*/)
        newEvent.title = eventCreationPreset.title
        newEvent.startDate = eventCreationPreset.date
        newEvent.endDate = eventCreationPreset.date.addingTimeInterval(EventCreationPreset.twoHourTimeInterval!)
        
        // Choose the calender the event should be written to.
        newEvent.calendar = self.store.defaultCalendarForNewEvents
        
        // Try to save the new event with the event store or handle any errors.
        do {
            try self.store.save(newEvent, span: .thisEvent, commit: true)
            print("Saved event with identifier: \(String(describing: newEvent.eventIdentifier))")
            
            return newEvent.eventIdentifier
        } catch let error as NSError {
            print("Failed to save event with error: \(error)")
            return nil
        }
    }
    
    /**
     Removes the calender event that was created whith the event creation preset from the event store
     
     - Parameter eventCreationPreset: A event creation preset for which the corresponding calender event should be deleted
     - Throws: An error of type `EventHelperError`
     - TODO: Should this method simply be called remove? And the other two accordingly just create and edit?
     */
    func removeCalenderEventCorrspondingTo(_ eventCreationPreset: EventCreationPreset) throws {
        try confirmAuthorization(for: .event)
        
        // Find the calender event with the identifier from the preset.
        if let eventID = eventCreationPreset.getIdentifier(), let eventToRemove = self.store.event(withIdentifier: eventID) {
            print("Deletion Proces for \(String(describing: eventToRemove))")
            
            // Delete it from the eventstore or handle occuring errors.
            do {
                try self.store.remove(eventToRemove, span: .thisEvent)
                print("Removed EKEvent with identifier: \(String(describing: eventID))")
            } catch {
                print("Failed to remove event from event store with error: \(error)")
            }
        }
    }
    
    
    /**
    Edits an calender event which was created with a event creation preset passed as an argument.
     
     - Parameter eventCreationPreset: A event creation preset with which a calendar event was created before.
     - Throws: Errors of type `EventHelperError` if it was unable to reciev the event identifier or the event.
     
    */
    func editCalenderEventCorrespondingTo(_ eventCreationPreset: EventCreationPreset) throws {
        try confirmAuthorization(for: .event)
        
        // Make sure there is a event identifier stored in the event creation preset.
        guard let eventID = eventCreationPreset.getIdentifier() else {
            throw EventHelperError.unableToRetrieveEventID
        }
        
        // Get the calender event assosiated with the identifier from the store.
        guard let eventToUpdate = self.store.event(withIdentifier: eventID) else {
            throw EventHelperError.unableToRetrieveEvent(identifier: eventID)
        }
            
        // Update the properties of the calender event with the parameters of the preset.
        eventToUpdate.title = eventCreationPreset.title
        eventToUpdate.startDate = eventCreationPreset.date
        eventToUpdate.endDate = eventCreationPreset.date.addingTimeInterval(EventCreationPreset.twoHourTimeInterval!)
        
        // Save the updated event to the store or react to errors that might occure.
        do {
            try self.store.save(eventToUpdate, span: .thisEvent, commit: true)
            print("Updated EKEvent with identifier: \(String(describing: eventID))")
        } catch {
            print("Failed to update event from event store with error: \(error).")
        }
    }

    
    // MARK: Privat Methods
    /**
     Requests the Authorisation to the event store for an entity type.
     
     Prints to the console weather the user has granted or denied the acces.
    
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
        switch EKEventStore.authorizationStatus(for: entityType) {
        case EKAuthorizationStatus.notDetermined:
            // First request authorisation for the entity type.
            requestAuthorisation(for: entityType)
            
            store.reset()
            
            try confirmAuthorization(for: entityType)
            
        case EKAuthorizationStatus.denied:
            print("Access to the event store was denied.")
            throw EventHelperError.authorisationDenied
            
        case EKAuthorizationStatus.restricted:
            print("Access to the event store was restricted.")
            throw EventHelperError.authorisationRestricted
            
        case EKAuthorizationStatus.authorized:
            print("Acces to the event store granted.")
        }
    }
    
    // - MARK: Updating EventPresets
    // TODO: Rewrite it Seperating Logic and Effects, which is explained here.
    // (https://developer.apple.com/videos/play/wwdc2017-414/?time=896)
    
    /// This checks weather an preset needs to be uptdated, since the event created with it got changes outside of the app.
    /// - Todo: What if the callender changed, how to retrieve the event then?
    func needsToUpdate(_ preset: EventCreationPreset) throws -> Bool {
        try confirmAuthorization(for: .event)
        
        guard let identifier = preset.getIdentifier() else {
            throw EventHelperError.unableToRetrieveEventID
        }
        
        guard let event = store.event(withIdentifier: identifier) else {
            throw EventHelperError.unableToRetrieveEvent(identifier: identifier)
        }
        
        // If either title or date does not match ist counterpart return true
        if (preset.title != event.title) || (preset.date != event.startDate) {
            print("Preset \(preset) needs update.")
            return true
        } else {
            // If both are the same return false
            print("Preset \(preset) is up to date.")
            return false
        }
    }
    
    // Updates a preset if the event that was created from it changed outside of the app.
    func update(_ preset: EventCreationPreset) throws {
        try confirmAuthorization(for: .event)
        
        guard let identifier = preset.getIdentifier() else {
            throw EventHelperError.unableToRetrieveEventID
        }
        
        guard let event = store.event(withIdentifier: identifier) else {
            throw EventHelperError.unableToRetrieveEvent(identifier: identifier)
        }
        
        // Update the fields of the preset.
        preset.title = event.title
        preset.date = event.startDate
        print("Preset \(preset) was updated.")
    }
    

}


// MARK: Error Conditions
/// The kinds of error EventHelper may produce.
/// - TODO: An error if the update of a preset is not succsesfull?
enum EventHelperError: Error {
    /// The acces to the event store was denied.
    case authorisationDenied
    ///the access to the event store is restricted.
    case authorisationRestricted
    /// The retrieval of an EKEvent object from the event store with a particular identifier was unsuccsessfull.
    case unableToRetrieveEvent(identifier: String?)
    /// The retrieval of the identifier from a EventCreationPreset was unsuccsessfull.
    case unableToRetrieveEventID
}
