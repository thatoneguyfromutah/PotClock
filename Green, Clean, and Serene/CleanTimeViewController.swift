//
//  CleanTimeViewController.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 4/16/24.
//

import UIKit
import CoreData

class CleanTimeViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CleanDate")
    
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var context: NSManagedObjectContext {
        return appDelegate.context
    }
    
    var selectedDate: Date?
    var initialDate: Date?
    
    var limitsTableViewController: LimitsTableViewController!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dates
        
        updateDates()
        initialDate = selectedDate
    }

    // MARK: - Dates
    
    func updateDates() {
        
        var dates: [Date] = []
        
        guard let cleanDates = try? context.fetch(fetchRequest) else { return }
        
        for cleanDate in cleanDates {
            let date = cleanDate.value(forKeyPath: "date") as? Date
            if date != nil { dates.append(date!) }
        }
        
        if dates.last == nil {
            
            guard let entity = NSEntityDescription.entity(forEntityName: "CleanDate", in: context) else { return }
            
            let storedCleanDate = NSManagedObject(entity: entity, insertInto: context)
            storedCleanDate.setValue(Date(), forKey: "date")
            
            do {
                
                try context.save()
                updateDates()
                return
                
            } catch let error {
                
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            
                let cancelAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(cancelAction)
            
                self.present(alertController, animated: true)
                
                return
            }
        }
                
        selectedDate = dates.last
        
        updateLabel(withDate: selectedDate!)
        updateDatePicker(withDate: selectedDate!)
    }
    
    // MARK: - Labels
    
    func updateLabel(withDate date: Date) {
        let time = Calendar.current.dateComponents([.month, .day, .year, .hour, .minute], from: date)
        dateLabel.text = "\(time.month!)/\(time.day!)/\(time.year!)"
    }
    
    // MARK: - Date Picker
    
    func updateDatePicker(withDate date: Date) {
        datePicker.date = date
    }
    
    // MARK: - Actions

    @IBAction func datePickerDidPickDate(sender: UIDatePicker) {
        selectedDate = sender.date
        saveBarButtonItem.isEnabled = selectedDate != initialDate
        updateLabel(withDate: selectedDate!)
        updateDatePicker(withDate: selectedDate!)
    }
    
    @IBAction func cancelButtonTapped(sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        
        if selectedDate! > Date() {
            
            let alertController = UIAlertController(title: "Error", message: "Unable to set future clean dates. Why not start today?", preferredStyle: .alert)
        
            let cancelAction = UIAlertAction(title: "Done", style: .default)
            alertController.addAction(cancelAction)
        
            present(alertController, animated: true)
            
            return
        }
        
        present(limitsTableViewController!.loadingViewController, animated: true) {
            
            guard let entity = NSEntityDescription.entity(forEntityName: "CleanDate", in: self.context) else { return }
            
            let storedCleanDate = NSManagedObject(entity: entity, insertInto: self.context)
            storedCleanDate.setValue(self.selectedDate, forKey: "date")
            
            do {
                
                try self.context.save()
                
                self.limitsTableViewController.updateGame()
                self.limitsTableViewController!.loadingViewController.dismiss(animated: true) {
                    self.dismiss(animated: true)
                }
                
            } catch let error {
                
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            
                let cancelAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(cancelAction)
            
                self.present(alertController, animated: true)
            }
        }
    }
}
