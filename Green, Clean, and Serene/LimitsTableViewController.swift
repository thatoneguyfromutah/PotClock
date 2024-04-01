//
//  LimitsTableViewController.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/7/23.
//

import UIKit
import CoreData

class LimitsTableViewController: UITableViewController {

    // MARK: - Properties
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StoredLimit")
    
    var limits: [Limit] = []
    var foods: [Limit] = []
    var drugs: [Limit] = []
    var activities: [Limit] = []
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var gameBackgroundView: UIView!
    @IBOutlet weak var gameDaysTextView: UITextView!
    @IBOutlet weak var gamePointsTextView: UITextView!
    
    let defaults = UserDefaults.standard
    
    var appDelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    var context: NSManagedObjectContext? {
        return appDelegate?.context
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLimits()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateGame()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let userHasBeenNotified = defaults.bool(forKey: "UserAgreementAlert")
        
        if !userHasBeenNotified {
            
            let alertController = UIAlertController(title: "User Agreement", message: "I have read and agree to the content in the privacy policy (to be found on the App Store page listing and on the Tips page), I am above 13 years of age, and of age to consume medical cannabis in a country or region in which it is legal.", preferredStyle: .alert)
            
            let acceptAction = UIAlertAction(title: "Confirm", style: .default) { action in
                self.defaults.setValue(true, forKey: "UserAgreementAlert")
                self.defaults.synchronize()
            }
            alertController.addAction(acceptAction)
            
            let cancelAction = UIAlertAction(title: "Reject", style: .destructive) { action in
                fatalError()
            }
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
            
            return
        }
    }
    
    // MARK: - Game
    
    func updateGame() {
        
        var atLimitEnabled: Bool = false
        var overLimitEnabled: Bool = false
        
        for limit in limits {
            
            if limit.isAtLimitForCurrentDay {
                atLimitEnabled = true
            }
            
            if limit.isOverLimitForCurrentDay {
                overLimitEnabled = true
            }
        }
        
        gameDaysTextView.text = "# Days"
        gamePointsTextView.text = "You Have No Points"
            
        if (atLimitEnabled && overLimitEnabled || !atLimitEnabled && overLimitEnabled) {
            gameBackgroundView.backgroundColor = .systemRed
        } else if atLimitEnabled && !overLimitEnabled {
            gameBackgroundView.backgroundColor = .systemYellow
        } else {
            gameBackgroundView.backgroundColor = .systemGreen
        }
    }
    
    // MARK: - Limits
    
    func updateLimits() {
        
        // Clear Limits
        
        limits = []
        
        // Iterate Through Stored Limits
        
        guard let limitsInStorage = try? context?.fetch(fetchRequest) else { return }
        
        for limitInStorage in limitsInStorage {
            
            guard let creationDate = limitInStorage.value(forKeyPath: "creationDate") as? Date,
                  let categoryString = limitInStorage.value(forKeyPath: "categoryString") as? String,
                  let name = limitInStorage.value(forKeyPath: "name") as? String,
                  let unitsName = limitInStorage.value(forKeyPath: "unitsName") as? String,
                  let totalUnitsString = limitInStorage.value(forKeyPath: "totalUnits") as? String,
                  let totalUnits = Decimal(string: totalUnitsString),
                  let timingString = limitInStorage.value(forKeyPath: "timingString") as? String,
                  let daysData = limitInStorage.value(forKeyPath: "days") as? Data,
                  let days = try? JSONDecoder().decode([Day].self, from: daysData),
                  let iconName = limitInStorage.value(forKeyPath: "iconName") as? String
            else { return }

            var category: Categories
            switch categoryString {
            case "food":
                category = .food
            case "drug":
                category = .drug
            case "activity":
                category = .activity
            default:
                category = .food
            }
            
            var timing: Timing
            switch timingString {
            case "daily":
                timing = .daily
            case "weekly":
                timing = .weekly
            case "monthly":
                timing = .monthly
            case "yearly":
                timing = .yearly
            default:
                timing = .daily
            }
            
            let limit = Limit(creationDate: creationDate, managedObject: limitInStorage, context: context, category: category, name: name, unitsName: unitsName, totalUnits: totalUnits, timing: timing, days: days, iconName: iconName)
            limits.append(limit)
        }
        
        sortLimits()
    }
    
    func sortLimits() {
        
        // Sort Limits
        
        limits = limits.sorted { $0.name < $1.name }
        
        // Filter Categories
        
        foods = limits.filter { $0.category == .food }
        drugs = limits.filter { $0.category == .drug }
        activities = limits.filter { $0.category == .activity }
    }
    
    func addNewLimit(newLimit: Limit) {
        
        guard let context = context,
              let entity = NSEntityDescription.entity(forEntityName: "StoredLimit", in: context)
        else { return }
        
        let storedLimit = NSManagedObject(entity: entity, insertInto: context)
        storedLimit.setValue(newLimit.creationDate, forKey: "creationDate")
        storedLimit.setValue(newLimit.categoryString, forKey: "categoryString")
        storedLimit.setValue(newLimit.name, forKey: "name")
        storedLimit.setValue(newLimit.unitsName, forKey: "unitsName")
        storedLimit.setValue(newLimit.currentUnitsProgressString, forKey: "unitsLogged")
        storedLimit.setValue(newLimit.totalUnitsString, forKey: "totalUnits")
        storedLimit.setValue(newLimit.timingString, forKey: "timingString")
        storedLimit.setValue(newLimit.encodedDays, forKey: "days")
        storedLimit.setValue(newLimit.iconName, forKey: "iconName")
        
        do {
            
            try context.save()
            updateLimits()
            tableView.reloadData()
            updateGame()
            
        } catch let error {
            
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Done", style: .default)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
        }
    }
    
    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let emptyLabel = UILabel()
        emptyLabel.textColor = .systemGray
        emptyLabel.font = UIFont.systemFont(ofSize: 28)
        emptyLabel.textAlignment = .center
                
        switch segmentedControl.selectedSegmentIndex {
        
        case 0:
            
            emptyLabel.text = foods.isEmpty ? "No Foods" : nil
            tableView.backgroundView = foods.isEmpty ? emptyLabel : nil
            
            gameBackgroundView.alpha = foods.isEmpty ? 0.5 : 1
            editBarButtonItem.isEnabled = !limits.isEmpty
            
            if limits.isEmpty {
                
                DispatchQueue.main.async(execute: {
                   tableView.setEditing(false, animated: true)
                })
                
                editBarButtonItem.title = "Edit"
            }
            
            return foods.count
            
        case 1:
            
            emptyLabel.text = drugs.isEmpty ? "No Drugs" : nil
            tableView.backgroundView = drugs.isEmpty ? emptyLabel : nil
            
            gameBackgroundView.alpha = drugs.isEmpty ? 0.5 : 1
            editBarButtonItem.isEnabled = !limits.isEmpty

            if limits.isEmpty {
                
                DispatchQueue.main.async(execute: {
                   tableView.setEditing(false, animated: true)
                })
                
                editBarButtonItem.title = "Edit"
            }

            return drugs.count
            
        case 2:
            
            emptyLabel.text = activities.isEmpty ? "No Activities" : nil
            tableView.backgroundView = activities.isEmpty ? emptyLabel : nil
            
            gameBackgroundView.alpha = activities.isEmpty ? 0.5 : 1
            editBarButtonItem.isEnabled = !limits.isEmpty
            
            if limits.isEmpty {
                
                DispatchQueue.main.async(execute: {
                   tableView.setEditing(false, animated: true)
                })
                
                editBarButtonItem.title = "Edit"
            }
            
            return activities.count
            
        default:
            
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "limitCell", for: indexPath) as! LimitTableViewCell
        
        var limit: Limit
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            limit = foods[indexPath.row]
        case 1:
            limit = drugs[indexPath.row]
        case 2:
            limit = activities[indexPath.row]
        default:
            fatalError()
        }
        
        if limit.currentUnitsProgressPercentage < 1 {
            cell.iconImageViewBackgroundView.backgroundColor = .systemGreen
        } else if limit.currentUnitsProgressPercentage == 1 {
            cell.iconImageViewBackgroundView.backgroundColor = .systemYellow
        } else {
            cell.iconImageViewBackgroundView.backgroundColor = .systemRed
        }
        
        cell.iconImageView.image = UIImage(systemName: limit.iconName)
        cell.limitNameLabel.text = limit.name
        cell.unitsLeftLabel.text = limit.currentUnitsProgressString
        
        return cell
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if tableView.isEditing {
            
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { action, view, success in
                
                var managedObject: NSManagedObject?
                switch self.segmentedControl.selectedSegmentIndex {
                case 0:
                    managedObject = self.foods[indexPath.row].managedObject
                    self.foods.remove(at: indexPath.row)
                case 1:
                    managedObject = self.drugs[indexPath.row].managedObject
                    self.drugs.remove(at: indexPath.row)
                case 2:
                    managedObject = self.activities[indexPath.row].managedObject
                    self.activities.remove(at: indexPath.row)
                default:
                    fatalError()
                }

                guard let managedObject = managedObject else { return }
                self.context?.delete(managedObject)
                try? self.context?.save()
                
                self.limits = self.foods + self.drugs + self.activities
                
                tableView.deleteRows(at: [indexPath], with: .automatic)

                self.updateGame()
                
                success(true)
            }
            deleteAction.image = UIImage(systemName: "trash.fill")
            
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
                                     
        return .none
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "createLimit", let navigationController = segue.destination as? UINavigationController, let editLimitViewController = navigationController.viewControllers.first as? EditLimitViewController {
            editLimitViewController.limitsTableViewController = self
            editLimitViewController.segmentedControl.selectedSegmentIndex = segmentedControl.selectedSegmentIndex
        }
        
        if segue.identifier == "showLimit", let logLimitViewController = segue.destination as? LogLimitViewController, let selectedIndex = tableView.indexPathForSelectedRow?.row {
            
            var limit: Limit
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                limit = foods[selectedIndex]
            case 1:
                limit = drugs[selectedIndex]
            case 2:
                limit = activities[selectedIndex]
            default:
                fatalError()
            }
            
            logLimitViewController.limit = limit
            logLimitViewController.limitsTableViewController = self
        }
    }

    // MARK: - Actions
    
    @IBAction func didChangeSelectedSegment(_ sender: UISegmentedControl) {
        tableView.reloadData()
        updateGame()
    }
    
    @IBAction func editButtonTapped(sender: UIBarButtonItem) {
        if sender.title == "Edit" {
            
            let alertController = UIAlertController(title: "Are You Sure?", message: "Deleting limits is permanent.", preferredStyle: .alert)
            
            let deleteAction = UIAlertAction(title: "Continue", style: .destructive) { _ in
                self.tableView.setEditing(true, animated: true)
                sender.title = "Done"
            }
            alertController.addAction(deleteAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true)
            
        } else{
            self.tableView.setEditing(false, animated: true)
            sender.title = "Edit"
        }
    }
    
    @IBAction func unwindFromCreateLimitViewController(_ sender: UIStoryboardSegue) {
        
        guard let newLimit = (sender.source as? EditLimitViewController)?.newLimit else { return }
                
        if newLimit.totalUnits <= 0 { newLimit.totalUnits = 1 }
        
        switch newLimit.category {
        case .food:
            segmentedControl.selectedSegmentIndex = 0
        case .drug:
            segmentedControl.selectedSegmentIndex = 1
        case .activity:
            segmentedControl.selectedSegmentIndex = 2
        }
        
        addNewLimit(newLimit: newLimit)
    }
}
