//
//  EditLimitViewController.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/2/23.
//

import UIKit
import CoreData

enum LimitUnitNames {
    case first
    case second
    case custom
}

class EditLimitViewController: UIViewController, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - Properies
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    
    var saveBarButtonItem: UIBarButtonItem!
    var deleteBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var limitNameTextField: UITextField!
    @IBOutlet weak var limitUnitsTextField: UITextField!
    
    @IBOutlet weak var firstMeasurementButton: UIButton!
    @IBOutlet weak var secondMeasurementButton: UIButton!
    @IBOutlet weak var customMeasurementButton: UIButton!
    
    @IBOutlet weak var dailyButton: UIButton!
    @IBOutlet weak var weeklyButton: UIButton!
    @IBOutlet weak var monthlyButton: UIButton!
    @IBOutlet weak var yearlyButton: UIButton!
    
    @IBOutlet weak var iconCollectionView: UICollectionView!
    
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    var limitsTableViewController: LimitsTableViewController!
    var logLimitViewController: LogLimitViewController!
    
    var isEditingLimit: Bool {
        return limitToEdit != nil
    }
    var limitToEdit: Limit?
        
    var newLimit = Limit(creationDate: Date(), managedObject: nil, context: nil, category: .food, name: "", unitsName: "Meals", totalUnits: Decimal(1), timing: .daily, days: [], iconName: "")
    
    var selectedMeasurementUnit: LimitUnitNames = .first
    var selectedDate: Timing = .daily {
        didSet {
            switch isEditingLimit {
            case true:
                limitToEdit?.timing = selectedDate
            default:
                newLimit.timing = selectedDate
            }
        }
    }
    var unitName: String = "Meals" {
        didSet {
            switch isEditingLimit {
            case true:
                limitToEdit?.unitsName = unitName
            default:
                newLimit.unitsName = unitName
            }
        }
    }
    
    var icons: [String] = []
    var selectedIconIndex = 0 {
        didSet {
            switch isEditingLimit {
            case true:
                limitToEdit?.iconName = selectedIconName
            default:
                newLimit.iconName = selectedIconName
            }
        }
    }
    var selectedIconName: String {
        if icons.isEmpty { return "" }
        return icons[selectedIconIndex]
    }
    
    enum ButtonForegroundColors {
        static let ActivatedColor = UIColor.systemBackground
        static let InactiveColor = UIColor.systemGreen
    }
    
    enum ButtonBackgroundColors {
        static let ActivatedColor = UIColor.systemGreen
        static let InactiveColor = UIColor.systemGray5
    }
    
    enum LimitNameTextFieldPlaceholders {
        static let foodNameTextFieldPlaceholder = "Food Name"
        static let drugNameTextFieldPlaceholder = "Drug Name"
        static let activityNameTextFieldPlaceholder = "Activity Name"
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        // Icons
        
        loadIcons()
        
        // Data Sources
        
        iconCollectionView.dataSource = self
        
        // Delegates
        
        limitNameTextField.delegate = self
        limitUnitsTextField.delegate = self
        iconCollectionView.delegate = self
        
        // Bar Button Items
        
        deleteBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(didTapDelete))
        deleteBarButtonItem.tintColor = .systemRed
        
        saveBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(didTapSave))
        
        switch isEditingLimit {
        case true:
            guard loadLimitToEditIfAvailable() else { fatalError() }
            navigationItem.leftBarButtonItems = nil
            navigationItem.rightBarButtonItems = [deleteBarButtonItem]
            visualEffectView.alpha = 0
            view.backgroundColor = .systemGray6
        default:
            navigationItem.rightBarButtonItems = [saveBarButtonItem]
            visualEffectView.alpha = 1
            view.backgroundColor = .clear
        }
        
        // Buttons
        
        updateDateButtons()
        updateSaveButton()
        
        // Text Fields
        
        addToolbarToTextFields()
        
        // Segmented Control
        
        updateSelection()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Limits
        
        switch isEditingLimit {
        case true:
            limitToEdit?.iconName = selectedIconName
        default:
            newLimit.iconName = selectedIconName
            limitNameTextField.becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Collection Views
        
        iconCollectionView.selectItem(at: IndexPath(item: selectedIconIndex, section: 0), animated: true, scrollPosition: .centeredHorizontally)
        iconCollectionView.scrollToItem(at: IndexPath(item: selectedIconIndex, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isEditingLimit {
            logLimitViewController.present(self.limitsTableViewController.loadingViewController, animated: true) {
                self.limitsTableViewController.updateLimits()
                self.logLimitViewController.limit = self.limitsTableViewController.limits.filter {
                    self.logLimitViewController.limit.name == $0.name }.first
                self.limitsTableViewController.loadingViewController.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Editing
    
    func loadLimitToEditIfAvailable() -> Bool {
        
        // Set value of limit
        
        guard let limitToEdit = limitToEdit else { return false }
        
        // Set category
        
        switch limitToEdit.category {
        case .food:
            segmentedControl.selectedSegmentIndex = 0
        case .drug:
            segmentedControl.selectedSegmentIndex = 1
        case .activity:
            segmentedControl.selectedSegmentIndex = 2
        }
        
        // Set name
        
        limitNameTextField.text = limitToEdit.name
        
        // Set unit names
        
        unitName = limitToEdit.unitsName
        
        // Set buttons
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            switch unitName {
            case "Meals":
                selectedMeasurementUnit = .first
            case "Drinks":
                selectedMeasurementUnit = .second
            default:
                selectedMeasurementUnit = .custom
            }
        case 1:
            switch unitName {
            case "Grams":
                selectedMeasurementUnit = .first
            case "Milligrams":
                selectedMeasurementUnit = .second
            default:
                selectedMeasurementUnit = .custom
            }
        case 2:
            switch unitName {
            case "Walks":
                selectedMeasurementUnit = .first
            case "Hikes":
                selectedMeasurementUnit = .second
            default:
                selectedMeasurementUnit = .custom
            }
        default:
            fatalError()
        }
        
        // Set number of units
        
        limitUnitsTextField.text = "\(limitToEdit.totalUnits)"
        
        // Set timing
        
        selectedDate = limitToEdit.timing
        
        // Set icon
        
        selectedIconIndex = icons.firstIndex(of: limitToEdit.iconName) ?? 0
        
        return true
    }
    
    // MARK - Icons
    
    func loadIcons() {
        
        guard let path = Bundle.main.path(forResource: "IconNames", ofType: "txt"),
              let data = try? String(contentsOfFile: path, encoding: .utf8)
        else {
            return
        }
        
        let unfilteredNames = data.components(separatedBy: .newlines)
        var names: [String] = []
        
        unfilteredNames.forEach { name in
            if UIImage(systemName: name) == nil { return }
            names.append(name)
        }
        
        icons = names
    }
    
    // MARK: - Keyboard
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! IconCollectionViewCell
        cell.iconImageView.image = UIImage(systemName: icons[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIconIndex = indexPath.row
    }
    
    // MARK: - Text Field
    
    func addToolbarToTextFields() {
        
        // Create toolbar and bar button items.
        
        let toolbar = UIToolbar()
        let flexibleSpaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([flexibleSpaceBarButtonItem,doneBarButtonItem], animated: true)
        toolbar.sizeToFit()
        
        // Add toolbar to keyboards.
        
        limitUnitsTextField.inputAccessoryView = toolbar
    }
    
    func setLimitNameTextFieldPlaceholder() {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            limitNameTextField.placeholder = LimitNameTextFieldPlaceholders.foodNameTextFieldPlaceholder
        case 1:
            limitNameTextField.placeholder = LimitNameTextFieldPlaceholders.drugNameTextFieldPlaceholder
        case 2:
            limitNameTextField.placeholder = LimitNameTextFieldPlaceholders.activityNameTextFieldPlaceholder
        default:
            fatalError()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField === limitNameTextField,
           let name = textField.text,
           name != "" {
            
            switch isEditingLimit {
                
            case true:
                                
                if limitToEdit?.name != name {
                    
                    if self.limitsTableViewController.limits.filter({ $0.name == name }).count > 0 {
                        
                        let alertController = UIAlertController(title: "Error", message: "\(name) already exists, please pick another name.", preferredStyle: .alert)
                        
                        let cancelAction = UIAlertAction(title: "Done", style: .default)
                        alertController.addAction(cancelAction)
                        
                        present(alertController, animated: true)
                        
                        self.limitNameTextField.text = self.limitToEdit?.name
                        
                    } else {
                        
                        limitToEdit?.name = name
                    }
                }
                
            case false:
                
                if self.limitsTableViewController.limits.filter({ $0.name == name }).count > 0 {
                    
                    let alertController = UIAlertController(title: "Error", message: "\(name) already exists, please pick another name.", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)
                    
                    present(alertController, animated: true)
                    
                    self.limitNameTextField.text = self.newLimit.name
                    
                } else {
                    
                    newLimit.name = name
                }
            }
        }
        
        if textField === limitUnitsTextField,
           let text = textField.text,
           let totalUnits = Decimal(string: text) {
            switch isEditingLimit {
            case true:
                
                if totalUnits == 0 {
                    
                    let alertController = UIAlertController(title: "Error", message: "Your limit amount per period must be more than zero.", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)
                    
                    present(alertController, animated: true)
                    
                    limitUnitsTextField.text = "\(limitToEdit!.totalUnits)"
                    
                } else {
                    
                    limitToEdit?.totalUnits = totalUnits
                    limitToEdit?.currentDay.limit = limitToEdit?.totalUnits
                }
                
            default:
                
                if totalUnits == 0 {
                    
                    let alertController = UIAlertController(title: "Error", message: "Your limit amount per period must be more than zero.", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)
                    
                    present(alertController, animated: true)
                    
                    limitUnitsTextField.text = "\(newLimit.totalUnits)"

                } else {
                    
                    newLimit.totalUnits = totalUnits
                    newLimit.currentDay.limit = newLimit.totalUnits
                }
            }
        }
        
        updateSaveButton()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField === limitUnitsTextField {
            let isNumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
            let withDecimal = (
                string == NumberFormatter().decimalSeparator &&
                textField.text?.contains(string) == false
            )
            return isNumber || withDecimal
        }
        
        return true
    }
    
    // MARK: - Buttons
    
    func updateButtonColors(button: UIButton, active: Bool) {
        button.backgroundColor = active ? ButtonBackgroundColors.ActivatedColor : ButtonBackgroundColors.InactiveColor
        button.tintColor = active ? ButtonForegroundColors.ActivatedColor : ButtonForegroundColors.InactiveColor
    }
    
    func updateSaveButton() {
        saveBarButtonItem?.isEnabled = (limitNameTextField.text != "" && limitUnitsTextField.text != "") && (limitNameTextField.text != nil && limitUnitsTextField.text != nil)
    }
    
    func updateMeasurementButtons() {
        
        switch selectedMeasurementUnit {
            
        case .first:
            
            updateButtonColors(button: firstMeasurementButton, active: true)
            updateButtonColors(button: secondMeasurementButton, active: false)
            updateButtonColors(button: customMeasurementButton, active: false)
            
            
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                firstMeasurementButton.setTitle("Meals", for: .normal)
                secondMeasurementButton.setTitle("Drinks", for: .normal)
                unitName = "Meals"
            case 1:
                firstMeasurementButton.setTitle("Grams", for: .normal)
                secondMeasurementButton.setTitle("Milligrams", for: .normal)
                unitName = "Grams"
            case 2:
                firstMeasurementButton.setTitle("Walks", for: .normal)
                secondMeasurementButton.setTitle("Hikes", for: .normal)
                unitName = "Walks"
            default:
                fatalError()
            }
            
            limitUnitsTextField.placeholder = "# of \(unitName)"
            
        case .second:
            
            updateButtonColors(button: firstMeasurementButton, active: false)
            updateButtonColors(button: secondMeasurementButton, active: true)
            updateButtonColors(button: customMeasurementButton, active: false)
            
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                firstMeasurementButton.setTitle("Meals", for: .normal)
                secondMeasurementButton.setTitle("Drinks", for: .normal)
                unitName = "Drinks"
            case 1:
                firstMeasurementButton.setTitle("Grams", for: .normal)
                secondMeasurementButton.setTitle("Milligrams", for: .normal)
                unitName = "Milligrams"
            case 2:
                firstMeasurementButton.setTitle("Walks", for: .normal)
                secondMeasurementButton.setTitle("Hikes", for: .normal)
                unitName = "Hikes"
            default:
                fatalError()
            }
            
            limitUnitsTextField.placeholder = "# of \(unitName)"
            
        case .custom:
            
            updateButtonColors(button: firstMeasurementButton, active: false)
            updateButtonColors(button: secondMeasurementButton, active: false)
            updateButtonColors(button: customMeasurementButton, active: true)
            
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                firstMeasurementButton.setTitle("Meals", for: .normal)
                secondMeasurementButton.setTitle("Drinks", for: .normal)
            case 1:
                firstMeasurementButton.setTitle("Grams", for: .normal)
                secondMeasurementButton.setTitle("Milligrams", for: .normal)
            case 2:
                firstMeasurementButton.setTitle("Walks", for: .normal)
                secondMeasurementButton.setTitle("Hikes", for: .normal)
            default:
                fatalError()
            }
            
            limitUnitsTextField.placeholder = "# of \(unitName)"
        }
    }
    
    func updateDateButtons() {
        switch selectedDate {
        case .daily:
            updateButtonColors(button: dailyButton, active: true)
            updateButtonColors(button: weeklyButton, active: false)
            updateButtonColors(button: monthlyButton, active: false)
            updateButtonColors(button: yearlyButton, active: false)
        case .weekly:
            updateButtonColors(button: dailyButton, active: false)
            updateButtonColors(button: weeklyButton, active: true)
            updateButtonColors(button: monthlyButton, active: false)
            updateButtonColors(button: yearlyButton, active: false)
        case .monthly:
            updateButtonColors(button: dailyButton, active: false)
            updateButtonColors(button: weeklyButton, active: false)
            updateButtonColors(button: monthlyButton, active: true)
            updateButtonColors(button: yearlyButton, active: false)
        case .yearly:
            updateButtonColors(button: dailyButton, active: false)
            updateButtonColors(button: weeklyButton, active: false)
            updateButtonColors(button: monthlyButton, active: false)
            updateButtonColors(button: yearlyButton, active: true)
        }
    }
    
    // MARK: - Actions
    
    func updateSelection() {
        switch isEditingLimit {
        case true:
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                limitToEdit?.category = .food
            case 1:
                limitToEdit?.category = .drug
            case 2:
                limitToEdit?.category = .activity
            default:
                fatalError()
            }
        default:
            switch segmentedControl.selectedSegmentIndex {
            case 0:
                newLimit.category = .food
            case 1:
                newLimit.category = .drug
            case 2:
                newLimit.category = .activity
            default:
                fatalError()
            }
        }
        
        setLimitNameTextFieldPlaceholder()
        updateMeasurementButtons()
        dismissKeyboard()
    }
    
    @IBAction func didChangeSelectedSegment(_ segmentedControl: UISegmentedControl) {
        updateSelection()
    }
    
    @objc func didTapSave() {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        if !(limitNameTextField.text == nil || limitNameTextField.text == "") && !(limitUnitsTextField.text == nil || limitUnitsTextField.text == "") {
            performSegue(withIdentifier: "saveLimit", sender: self)
            return
        }
    }
    
    @objc func didTapDelete() {
        
        let alertController = UIAlertController(title: "Are You Sure?", message: "Deleting a limit is permanent.", preferredStyle: .alert)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            
            self.present(self.limitsTableViewController.loadingViewController, animated: true) {
                
                guard let managedObject = self.limitToEdit?.managedObject else { return }
                self.limitsTableViewController.context?.delete(managedObject)
                try? self.limitsTableViewController.context?.save()
                self.limitsTableViewController.updateLimits()

                self.limitsTableViewController.loadingViewController.dismiss(animated: true) {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
        alertController.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @IBAction func didTapCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func didTapFirstMeasurement(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        selectedMeasurementUnit = .first
        updateMeasurementButtons()
    }
    
    @IBAction func didTapSecondMeasurement(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        selectedMeasurementUnit = .second
        updateMeasurementButtons()
    }
    
    @IBAction func didTapCustomMeasurement(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        let alertController = UIAlertController(title: "Units Name", message: "Type in a custom name for your units of measurement here.", preferredStyle: .alert)
        alertController.addTextField()
        
        let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
            
            guard let textField = alertController.textFields?.first,
                  let text = textField.text, text != ""
            else {
                return
            }
            
            self.unitName = text
            self.selectedMeasurementUnit = .custom
            self.updateMeasurementButtons()
        }
        alertController.addAction(submitAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @IBAction func didTapDaily(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        selectedDate = .daily
        updateDateButtons()
    }
    
    @IBAction func didTapWeekly(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        selectedDate = .weekly
        updateDateButtons()
    }
    
    @IBAction func didTapMonthly(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        selectedDate = .monthly
        updateDateButtons()
    }
    
    @IBAction func didTapYearly(_ sender: UIButton) {
        
        limitNameTextField.resignFirstResponder()
        limitUnitsTextField.resignFirstResponder()
        
        selectedDate = .yearly
        updateDateButtons()
    }
}
