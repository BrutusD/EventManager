//
//  ViewController.swift
//  EventManager
//
//  Created by BSH on 17.12.18.
//  Copyright © 2018 Bernhard Schmidt-Hackenberg. All rights reserved.
//

import UIKit
import os.log

/// A object that manages the presentation and edeting of information stored in a event creation preset.
class EventCreationPresetViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Properties
    /// A text field for the name of a event.
    @IBOutlet weak var titleTextField: UITextField!
    /// A date picker for the start date of the event.
    @IBOutlet weak var datePicker: UIDatePicker!
    /// A button that goes to the previeus view and orders its view controller to save the preset.
    @IBOutlet weak var saveButton: UIBarButtonItem!
    /// A toolbar that hods the delete button.
    @IBOutlet weak var deleteToolBar: UIToolbar!
    
    
    /**
     Holds the event that is currently displayed by the event view controller
     
     This value is eather passed by 'PresetsTableViewController' in 'prepare(for:sender:)'
     or contstructed as part of placing a new event.
    */
    var eventCreationPreset: EventCreationPreset?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Handle the text fields user input through delegate callbacks.
        titleTextField.delegate = self
        
        // Set up views if editing an existing event creation preset, else make the text field the first responder.
        if let currentEventCreationPreset = eventCreationPreset {
            navigationItem.title = currentEventCreationPreset.title
            titleTextField.text = currentEventCreationPreset.title
            datePicker.date = currentEventCreationPreset.date
        } else {
            // If in add new preset mode start by tiping title.
            titleTextField.becomeFirstResponder()
            // TODO: This should be handled by an property observer on a porperty called isInAddingPresetMode or something.
        }
        
        // Enable the save button only if the text field has a valid event title.
        updateSaveButtonState()
        
        // Show the toolbar only if view controller is in add preset mode.
        updateToolBarState()
        
    }
    
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Disable the save button while editing.
        saveButton.isEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Make the save button available and update the navigation bar title.
        updateSaveButtonState()
        navigationItem.title = textField.text
    }
    
    // MARK: - Actions
    /// Delet the currently viewd preset and its corresponding events.
    @IBAction func deletePreset(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        let deleteAction = UIAlertAction(title: "Delete Event", style: .destructive, handler: { (_) in
            self.performSegue(withIdentifier: "unwindAndDelete", sender: self)
        })
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation
    /// Dismisses the view without creating a new event creation preset or edeting an existing one.
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        // Depending on style of presentation (modal or push presentation), this view controller needs to be dismissed in two different ways.
        let isPresentinInAddPresetMode = presentingViewController is UINavigationController
        if isPresentinInAddPresetMode {
            dismiss(animated: true, completion: nil)
        }
        else if let owningNavigationController = navigationController {
            owningNavigationController.popViewController(animated: true)
        }
        else {
            fatalError("The event view controller is not inside a navigation controller.")
        }
    }
    
    // This method lets you configure a view controller before it's presented.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        /// The preparations that should be done in the right conditions
        func preparePreset() {
            // Grab all information about the preset.
            let title = titleTextField.text ?? "No Name"
            let date = datePicker.date
            let identifier = eventCreationPreset?.getIdentifier()
            
            // Set the EventCreationPreset to be passed to the PresetsTableViewController after the unwind segue.
            eventCreationPreset = EventCreationPreset(title: title, date: date, identifierForEvent: identifier)
        }
        
        // If the save button is pressed configure the destination view controller.
        if let button = sender as? UIBarButtonItem, button === saveButton {
            preparePreset()
        // If the delete button was pressed, the viewController is the sender and the destination view controller should be configured.
        } else if let viewController = sender as? UIViewController, viewController === self {
            preparePreset()
        } else {
            os_log("Neither the save or delete button was not pressed, cancelling.", log: OSLog.default, type: .debug)
            return
        }
    }
    
    // MARK: - Private Methods
    /// Ensures that the save button is not enabled if the text field is empty.
    private func updateSaveButtonState() {
        // Disable the save button if the text field is empty
        let text = titleTextField.text ?? ""
        saveButton.isEnabled = !text.isEmpty
    }
    
    /// Ensure that the toolbar is not enabled if the view controller is in creation mode.
    private func updateToolBarState() {
        // Hide the toolbar depending on presentation mode
        let isPresentingInCreationMode = presentingViewController is UINavigationController
        if isPresentingInCreationMode {
            deleteToolBar.isHidden = true
        }
        else {
            deleteToolBar.isHidden = false
        }
    }
    // TODO: Write this as a property observer for an general isPresentingInCreationMode property.
}

