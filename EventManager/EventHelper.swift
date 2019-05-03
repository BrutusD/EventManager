//
//  EventHelper.swift
//  EventManager
//
//  Created by BSH on 28.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import EventKit

/**
 A class that abstracts all interaction with the EKEventStore object for you

 -  NOTE: I got my main inspiration for the three key functions to add, change and delete an EKEvent from the event store and how to get acces to it from this Stack Overflow question thread (esp. Rujoota Shah's Answer from Sep 25 '16 at 2:44): [How to add an event in the device calendar using swift](https://stackoverflow.com/questions/28379603/how-to-add-an-event-in-the-device-calendar-using-swift)

*/
class EventHelper {
    
    // MARK: Properties
    /// The store with wich all methods in the eventHelper interact
    /*private*/ let store: EKEventStore!
    
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
    func createCalendarEvent(for eventCreationPreset: EventCreationPreset, completion: @escaping (Result<String, EventHelperError>) -> Void) {
        // Act based on the current authorisation status.
        determinAuthorisation(for: .event) { status in
            
            var result: Result<String, EventHelperError>
            
            switch status {
            case .authorized:
                
                // Create a new event with instructions from the preset.
                let newEvent = EKEvent(eventStore: self.store)
                newEvent.title = eventCreationPreset.title
                newEvent.startDate = eventCreationPreset.date
                newEvent.endDate = eventCreationPreset.date.addingTimeInterval(EventCreationPreset.twoHourTimeInterval!)
                
                // Choose the calender the event should be written to.
                newEvent.calendar = self.store.defaultCalendarForNewEvents
                
                // Try to save the new event with the event store or handle any errors.
                do {
                    try self.store.save(newEvent, span: .thisEvent, commit: true)
                    print("Saved event with identifier: \(String(describing: newEvent.eventIdentifier))")
                    
                    // In case of success hand the result to the completion handler
                    result = .success(newEvent.eventIdentifier)
//                    completion(result)
                    
                    // In case of failure give it the failuer result
                } catch let error as NSError {
                    result = .failure(EventHelperError.unexpectedError(error: error))
//                    completion(result)
                }
                
            case .denied:
                result = .failure(EventHelperError.authorisationDenied)
//                completion(result)
            case .restricted:
                result = .failure(EventHelperError.authorisationRestricted)
//                completion(result)
            case .notDetermined:
                fatalError("Something went terribly wrong!")
            }
            
            completion(result)
        }
    }
//    func createCalendarEvent(for eventCreationPreset: EventCreationPreset) throws -> String? {
//
//        // Act based on the current authorisation status.
//        try confirmAuthorization(for: .event)
//
//        // Create a new event with instructions from the preset.
//        let newEvent = EKEvent(eventStore: store)
//        newEvent.title = eventCreationPreset.title
//        newEvent.startDate = eventCreationPreset.date
//        newEvent.endDate = eventCreationPreset.date.addingTimeInterval(EventCreationPreset.twoHourTimeInterval!)
//
//        // Choose the calender the event should be written to.
//        newEvent.calendar = self.store.defaultCalendarForNewEvents
//
//        // Try to save the new event with the event store or handle any errors.
//        do {
//            try self.store.save(newEvent, span: .thisEvent, commit: true)
//            print("Saved event with identifier: \(String(describing: newEvent.eventIdentifier))")
//
//            return newEvent.eventIdentifier
//        } catch let error as NSError {
//            print("Failed to save event with error: \(error)")
//            return nil
//        }
//    }

    
    /**
     Removes the calender event that was created whith the event creation preset from the event store
     
     - Parameter eventCreationPreset: A event creation preset for which the corresponding calender event should be deleted
     - TODO: Should this method simply be called remove? And the other two accordingly just create and edit?
     */
    func removeCalenderEventCorrspondingTo(_ eventCreationPreset: EventCreationPreset, completion: @escaping (EventHelperError?) -> (Void))  {
//        try confirmAuthorization(for: .event)
        // Retrieve the id of the event from the event creation preset
        guard let eventID = eventCreationPreset.identifierForEvent else {
            return completion(EventHelperError.unableToRetrieveEventID)
        }

        determinAuthorisation(for: .event) { status in
            switch status {
            case .authorized:
                // Find the calender event with the identifier from the preset.
                guard let eventToRemove = self.store.event(withIdentifier: eventID) else {
                    return completion(EventHelperError.unableToRetrieveEvent(identifier: eventID))
                }
                
                print("Deleting preset for \(String(describing: eventToRemove))")
                
                // Delete it from the eventstore or handle occuring errors.
                do {
                    try self.store.remove(eventToRemove, span: .thisEvent)
                    print("Removed EKEvent with identifier: \(String(describing: eventID))")
                    completion(nil)
                } catch let error as NSError {
                    completion(EventHelperError.unexpectedError(error: error))
                }
                
            case .denied:
                completion(EventHelperError.authorisationDenied)
            case .restricted:
                completion(EventHelperError.authorisationRestricted)
            case .notDetermined:
                print("There was an unexpected error with the authorisation status in the event removing process. UAAARR!!")
            }

        }
    }
    
    
    /**
    Edits an calender event which was created with a event creation preset passed as an argument.
     
     - Parameter eventCreationPreset: A event creation preset with which a calendar event was created before.
     - Throws: Errors of type `EventHelperError` if it was unable to reciev the event identifier or the event.
     
    */
    func editCalenderEventCorrespondingTo(_ eventCreationPreset: EventCreationPreset, completion: @escaping (EventHelperError?) -> (Void)) {
        // Make sure there is a event identifier stored in the event creation preset.
        guard let eventID = eventCreationPreset.identifierForEvent else {
            return completion(EventHelperError.unableToRetrieveEventID)
        }
        
        determinAuthorisation(for: .event) { status in
            switch status {
            case .authorized:
                // Get the calender event assosiated with the identifier.
                guard let eventToUpdate = self.store.event(withIdentifier: eventID) else {
                    return completion(EventHelperError.unableToRetrieveEvent(identifier: eventID))
                }
                
                // Update the properties of the calender event with the parameters of the preset.
                eventToUpdate.title = eventCreationPreset.title
                eventToUpdate.startDate = eventCreationPreset.date
                eventToUpdate.endDate = eventCreationPreset.date.addingTimeInterval(EventCreationPreset.twoHourTimeInterval!)
                
                // Save the updated event to the store or react to errors that might occure.
                do {
                    try self.store.save(eventToUpdate, span: .thisEvent, commit: true)
                    print("Edited EKEvent with identifier: \(String(describing: eventID))")
                } catch let error as NSError {
                    return completion(EventHelperError.unexpectedError(error: error))
                }
                
            case .denied:
                completion(EventHelperError.authorisationDenied)
            case .restricted:
                completion(EventHelperError.authorisationRestricted)
            case .notDetermined:
                print("WHoopsieee!!!!!")
            }
        }
    }

    
    func resetStore() {
        store.reset()
    }


    // MARK: Privat Methods
    /**
     Requests the authorisation to the event store from a user if it is not determined yet and lets all other cases be handled by a completion handler.
     */
    private func determinAuthorisation(for entityType: EKEntityType, completion: @escaping (EKAuthorizationStatus) -> Void) {
        let status = EKEventStore.authorizationStatus(for: entityType)
        
        switch status {
        case .notDetermined:
            store.requestAccess(to: entityType) { _, _ in
                DispatchQueue.main.async {
                    completion(EKEventStore.authorizationStatus(for: entityType))
                }
            }
        default:
           completion(status)
        }
    }

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

    // MARK: Re

//    /// This checks weather an preset needs to be uptdated, since the event created with it got changes outside of the app.
//    func needsToUpdate(_ preset: EventCreationPreset, completion: @escaping (Bool?, EventHelperError?) -> (Void)) {
//        
//        guard let identifier = preset.identifierForEvent else {
//            return completion(nil, EventHelperError.unableToRetrieveEventID)
//        }
//        
//        determinAuthorisation(for: .event) { status in
//            guard let event = self.store.event(withIdentifier: identifier) else {
//                return completion(nil, EventHelperError.unableToRetrieveEvent(identifier: identifier))
//            }
//        
//            // If either title or date does not match its counterpart, return true
//            if (preset.title != event.title) || (preset.date != event.startDate) {
//                print("Preset \(preset) needs update.")
//                return completion(true, nil)
//            } else {
//                // If both are the same return false
//                print("Preset \(preset) is up to date.")
//                return completion(false, nil)
//            }
//        }
//    }

    // Updates a preset if the event that was created from it changed outside of the app.
    func updateIfNeeded(_ preset: EventCreationPreset, completion: @escaping (EventHelperError?) -> (Void)) {
        guard let identifier = preset.identifierForEvent else {
            return completion(EventHelperError.unableToRetrieveEventID)
        }
        
        determinAuthorisation(for: .event) { status in
            guard let event = self.store.event(withIdentifier: identifier) else {
                return completion(EventHelperError.unableToRetrieveEvent(identifier: identifier))
            }
            
            // If either title or date does not match its counterpart, update them
            if (preset.title != event.title) || (preset.date != event.startDate) {
                // Update the fields of the preset.
                preset.title = event.title
                preset.date = event.startDate
                return completion(nil)
            } else {
                // If both are the same dont update
                print("Preset \(preset) is up to date.")
                return completion(nil)
            }
        }
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
    /// If something unexpected happens
    case unexpectedError(error: NSError?)
}
