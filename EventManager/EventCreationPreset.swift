//
//  Event.swift
//  EventManager
//
//  Created by BSH on 29.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import Foundation
import os.log


/// A class that stores All information neccesary to create and identify events in the event store.
class EventCreationPreset: NSObject, NSCoding {
    
    // MARK: Properties
    /// The title for the event
    var title: String
    
    /// The start date of the event
    var date: Date
    
    /// The identifier of the calendar event that was created with the event creation preset.
    /// - Note: As long as no calender event has been created whith the preset it should be nil
    /// - TODO: change this to a dictionary: Key DeviceID, Value EventID
    var identifierForEvent: String?
    
    
    // MARK: Archiving Paths
    static let DocumentDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentDirectory.appendingPathComponent("eventCreationPresets")
    
    // MARK: Time Interval
    /// A time interval of two ours
    static let twoHourTimeInterval = TimeInterval(exactly: 7200)
    
    
    
    // Mark: Types
    struct PropertyKey {
        static let title = "title"
        static let date = "date"
        static let identifierForEvent = "identifierForEvent"
    }
    
    // MARK: Initialization
    /**
     Creates an `EventCreationPreset` object with the given title and date; returns nil if the title argument is empty
     
     - Parameters:
        - title: The title of the event to create
        - date: The date of the event to create
        - identifierForEvent: The identifier of the created calender event; at initialization probably nil
     */
    init?(title: String, date: Date, identifierForEvent: String? = nil) {
        
        // Initialization should fail if the provided title string is empty
        guard !title.isEmpty else {
            print("Faile to create EventCreationPreset. Name string was empty")
            return nil
        }
        
        // Initialize the stored properties
        self.title = title
        self.date = date
        self.identifierForEvent = identifierForEvent
        
        super.init()
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: PropertyKey.title)
        aCoder.encode(date, forKey: PropertyKey.date)
        aCoder.encode(identifierForEvent, forKey: PropertyKey.identifierForEvent)
    }
    
    // - TODO: Should the identifier be required for the initialization from coder?
    required convenience init?(coder aDecoder: NSCoder) {
        // The title, date and identifier are required. If we can not decode one, the initalizer should fail.
        guard let name = aDecoder.decodeObject(forKey: PropertyKey.title) as? String else {
            os_log("Unable to decode the title of the event object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let date = aDecoder.decodeObject(forKey: PropertyKey.date) as? Date else {
            os_log("Unable to decode the date of the event object", log: OSLog.default, type: .debug)
            return nil
        }
        
        let id = aDecoder.decodeObject(forKey: PropertyKey.identifierForEvent) as? String
//        // Also it is important, that if the id is not nil, its string is a valid uuid string.
//        if id != nil {
//            guard (UUID(uuidString: id!) != nil) else {
//                os_log("Unable to decode the id string, or it is not a valid uuid string.", log: OSLog.default, type: .debug)
//                return nil
//            }
//        }
        
        // Must call designated initializer
        self.init(title: name, date: date, identifierForEvent: id)
    }
}
