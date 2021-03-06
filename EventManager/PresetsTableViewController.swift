//
//  PresetsTableViewController.swift
//  EventManager
//
//  Created by BSH on 29.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import UIKit
import os.log

/// An object that manages an array of event creation presets and a helper object, that supplies methods to communicate with the event store.
class PresetsTableViewController: UITableViewController {

    // MARK: Properties
    /// An array of event creation presets.
    var presets = [EventCreationPreset]()
    /// An helper object that manages the comunication with the event store.
    var eventHelper: EventHelper!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use the edit bar buttonItem provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem
        
        // Load any saved event creation presets
        if let savedPresets = loadEventCreationPresets() {
            presets += savedPresets
        
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(PresetsTableViewController.storeChanged), name: .EKEventStoreChanged, object: eventHelper.store)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "EventCreationPresetCell"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let preset = presets[indexPath.row]
        
        cell.textLabel?.text = preset.date.description
        cell.detailTextLabel?.text = preset.title
        
        return cell
    }
 
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the event from the event store
            do {
                try eventHelper.removeCalenderEventCorrspondingTo(presets[indexPath.row])
            } catch {
                print("An error occured while deleting an event: \(error)")
            }
            // Delete the row from the data source.
            presets.remove(at: indexPath.row)
            saveEventCreationPresets()
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    /// Depending on de segue maybe prepare a EventCreationPreset object to be displayed
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        switch (segue.identifier ?? "") {
            
        case "AddEvent":
            os_log("Adding a new event.", log: OSLog.default, type: .debug)
            
        case "ShowDetail":
            guard let eventDetailViewController = segue.destination as? EventCreationPresetViewController else {
                fatalError("Unexpected destination: \(segue.destination)")
            }
            
            guard let selectedEventCell = sender as? UITableViewCell else {
                fatalError("Unexpected sender: \(String(describing: sender))")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedEventCell) else {
                fatalError("The cell selected is not beein displayed by the table.")
            }
            
            let selectedPreset = presets[indexPath.row]
            eventDetailViewController.eventCreationPreset = selectedPreset
            
        default:
            fatalError("Unexpected segue Identifier: \(String(describing: segue.identifier))")
        }
    }
    
    
    // MARK: - Actions
    
    /**
     This is the place where new event creation presets get stored or changed in the calender through the help of the event helper object.
     - Parameter sender:
    */
    @IBAction func unwindToPresetsList(sender: UIStoryboardSegue) {
        var newCalendarEventIdentifier: String? = nil
        
        if let sourceViewControler = sender.source as? EventCreationPresetViewController, let preset = sourceViewControler.eventCreationPreset {
            
            // If one of the table view rows is selected
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                // Update an existing calender event with the information from the preset.
                do {
                    try eventHelper.editCalenderEventCorrespondingTo(preset)
                    
                    // And update the preset in the array.
                    presets[selectedIndexPath.row] = preset
                    tableView.reloadRows(at: [selectedIndexPath], with: .none)
                    
                } catch EventHelperError.unableToRetrieveEvent(let unrecognizedID) {
                    print("The event could not be updated. No event found with the ID: \(unrecognizedID)")
                } catch {
                    print(error)
                }
            }
            else {
                // If no table view row is selected create a new calendar event that corresponds to the preset.
                do  {
                    newCalendarEventIdentifier = try eventHelper.createCalendarEvent(for: preset)
                } catch EventHelperError.authorisationDenied {
                    print("Access to the EKEventStore was denied.")
                    // TODO: Let the user know, we need permission to acces the calender for the app to work.
                } catch EventHelperError.authorisationRestricted {
                    print("Users Access to calender is restricted.")
                    // TODO: Let the user know the app can not work since his access to the calendar is restricted and what that means.
                } catch {
                    print("Unexpected error \(error).")
                }
                
                // If the retruned identifier is nil, we will have an orphan calender entry, which is not good
                guard newCalendarEventIdentifier != nil else {
                    fatalError("Could not retrieve event id.")
                }
                // TODO: The event helper should assure, that he always returns a string.

                
                // Assing the EKevent identifier to the preset.
                preset.identifierForEvent = newCalendarEventIdentifier
                
                // Add the new event creation preset to the preset array.
                let newIndexPath = IndexPath(row: presets.count, section: 0)
                
                presets.append(preset)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            // Save the presets.
            saveEventCreationPresets()
        }
    }
    
    /// - NOTE: I found the explanation to trigger a unwind segue entirely from code [here](https://www.andrewcbancroft.com/2015/12/18/working-with-unwind-segues-programmatically-in-swift/#trigger)
    /// Ofcourse the concrete implementation is mine.
    @IBAction func unwindToPresetListAndDelete(sender: UIStoryboardSegue) {
        var calendarEventIdentifier: String? = nil
        
        // Gehe sicher das die segue von einerm EventCreationPresetViewController kommt, und bekomme eine referenz fpr das preset object.
        if let sourceViewControler = sender.source as? EventCreationPresetViewController, let preset = sourceViewControler.eventCreationPreset {
            
            // Make shure one of the table view rows is selected
            guard let selectedIndexPath = tableView.indexPathForSelectedRow else {
                print("No row was selected. Presets view controller is not expecting any editing")
                return
            }
            
            // Make shure the selected preset matches the preset from sender
            guard presets[selectedIndexPath.row].identifierForEvent == preset.identifierForEvent else {
                print("The view controller is expecting a different preset to be edited.")
                return
            }
            
            do {
                // Delete the event from the calender.
                try eventHelper.removeCalenderEventCorrspondingTo(preset)
                
                // Remove the preset from the array and reload the table view row
                presets.remove(at: selectedIndexPath.row)
                tableView.reloadData()//reloadRows(at: [selectedIndexPath], with: .none)
            } catch {
                print(error)
            }
        }
        

    }
    
    
    // MARK: - Private Methods
    /// Fills the event creation presets array with three event creation presets and creates corresponding calender events.
    private func loadSampleEventCreationPresets() {
        
        // Create some time Intervals for three dates for three sample Events
        if let dateInterval1 = TimeInterval(exactly: 3600),
           let dateInterval2 = TimeInterval(exactly: 86400),
            let  dateInterval3 = TimeInterval(exactly: 172.800) {
            let date = Date()
            let date1 = Date(timeInterval: dateInterval1, since: date)
            let date2 = Date(timeInterval: dateInterval2, since: date)
            let date3 = Date(timeInterval: dateInterval3, since: date)
            
            guard let event1 = EventCreationPreset(title: "Geheimes Haus", date: date1) else {
                fatalError("unable to initalize EventCreationPreset 1")
            }
            
            guard let event2 = EventCreationPreset(title: "Die größte Gemeinheit Der Welt", date: date2) else {
                fatalError("unable to initalize EventCreationPreset 2")
            }
            
            guard let event3 = EventCreationPreset(title: "Like Me, Hotzenplotz", date: date3) else {
                fatalError("unabel to initalize EventCreationPreset 3")
            }
            
            presets += [event1, event2, event3]
            
            // Create events for all presets
            for preset in presets {
                do {
                    let newIdentifier = try eventHelper.createCalendarEvent(for: preset)
                    preset.identifierForEvent = newIdentifier
                } catch {
                    print("Unable to create event \"\(preset.title)\": \(error)")
                }
            }
        }
    }
    
    private func saveEventCreationPresets() {
        let isSuccsessfullSave = NSKeyedArchiver.archiveRootObject(presets, toFile: EventCreationPreset.ArchiveURL.path)//archivedDataWithRootObject:requiringSecureCoding:error:
        
        if isSuccsessfullSave {
            os_log("Events succsessfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save events... ", log: OSLog.default, type: .debug)
        }
    }

    private func loadEventCreationPresets() -> [EventCreationPreset]? {
        return NSKeyedUnarchiver.unarchiveObject(withFile: EventCreationPreset.ArchiveURL.path) as? [EventCreationPreset]
    }
    
    /// Reacts to Notifications about changes to the event store by checking which event creation preset must be updated.
    @objc func storeChanged() {
        print("HURRAR!")
        
        for preset in presets {
            do {
                if try eventHelper.needsToUpdate(preset) {
                   try eventHelper.update(preset)
                }
            } catch EventHelperError.unableToRetrieveEvent(_) {
                // If the evnet could not be retrieved with the identifier stored in the preset, the event probably has been deleted.
                // Mark the preset as deleted by adding a suffix
                let deletSuffix = " - deleted!"
                if !preset.title.hasSuffix(deletSuffix) {
                    preset.title += " - deleted!"
                    // TODO: Move the preset to a garbage destinatiion where it could be reviewed and accessed by the user.
                }
            } catch {
                print(error)
            }
        }
        saveEventCreationPresets()
        tableView.reloadData()
    }
}
