//
//  LogLimitViewController.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/7/23.
//

import UIKit
import CoreData

class LogLimitViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Properties
    
    var limit: Limit! {
        didSet {
            limit.selectedDate = Date()
        }
    }
    
    @IBOutlet weak var currentUnitsTextField: UITextField!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var loadingIndicatorBackgroundView: UIView!
    @IBOutlet weak var loadingIndicatorProgressView: UIView!
    @IBOutlet weak var logTableView: UITableView!
    @IBOutlet weak var loadingIndicatorProgressViewWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftPercentageLabel: UILabel!
    @IBOutlet weak var rightPercentageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var previousDayButton: UIButton!
    @IBOutlet weak var nextDayButton: UIButton!
    
    var changeInProgress = false
    var didReturnChange = false
    
    var selectedDate = Date() {
        didSet {
            limit.selectedDate = selectedDate
        }
    }
    
    var limitsTableViewController: LimitsTableViewController!
    var context: NSManagedObjectContext? {
        return limitsTableViewController.context
    }
    
    var lastLogDifference: Decimal = 0.0
    var isLoggingReduction: Bool = false
    
    var alertController: UIAlertController? {
        didSet {
            self.alertController?.addTextField()
            self.alertControllerTextField?.keyboardType = .decimalPad
            self.alertControllerTextField?.delegate = self
        }
    }

    var alertControllerTextField: UITextField? {
        return alertController?.textFields?.first
    }
    
    func saveCurrentLog() {
        let log = Log(amount: lastLogDifference, date: Date())
        if log.amount == 0 { return }
        limit.addLogToSelectedDay(log: log)
        logTableView.reloadData()
    }
    
    var unitsLogged: Decimal {
        return limit.selectedDay.units
    }
    
    var unitsLoggedString: String {
        return "\(unitsLogged)"
    }
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let name = limit?.name {
            navigationItem.title = name
        }
        
        if let unitsName = limit?.unitsName {
            currentUnitsTextField.placeholder = unitsName
        }
        
        currentUnitsTextField.delegate = self
        
        updateLabels()
        updateTiming()
        updateButtons()
    }
    
    func updateButtons() {
        previousDayButton.isEnabled = limit.creationDate.tomorrow <= limit.selectedDate
        nextDayButton.isEnabled = limit.selectedDate.tomorrow <= Date()
    }
    
    func updateLabels() {
        currentUnitsTextField.text = String(describing: limit.selectedUnits)
        currentUnitsTextField.isUserInteractionEnabled = false
        progressLabel.text = limit.selectedUnitsProgressPercentageString
    }
    
    func updateTiming() {
        let date = Calendar.current.dateComponents([.month, .day, .year], from: selectedDate)
        let dateString = "\(date.month!)/\(date.day!)/\(date.year!)"
        timeLabel.text = dateString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateLoadingIndicatorProgress()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateLoadingIndicatorProgress()
        }
    }
    
    // MARK: - Loading Indicator
    
    func updateLoadingIndicatorProgress() {
                               
        if limit.selectedUnitsProgressPercentage < 1 {
            loadingIndicatorProgressView.backgroundColor = .systemGreen
        } else if limit.selectedUnitsProgressPercentage == 1 {
            loadingIndicatorProgressView.backgroundColor = .systemYellow
        } else {
            loadingIndicatorProgressView.backgroundColor = .systemRed
        }
        
        if limit.selectedUnitsProgressPercentage < 0.5 {
            rightPercentageLabel.text = String(describing: round(1000 * Double(truncating: NSDecimalNumber(decimal: limit.selectedUnitsProgressPercentage))) / 10) + "%"
            leftPercentageLabel.text = nil
        } else {
            leftPercentageLabel.text = String(describing: round(1000 * Double(truncating: NSDecimalNumber(decimal: limit.selectedUnitsProgressPercentage))) / 10) + "%"
            rightPercentageLabel.text = nil
        }
            
        UIView.animate(withDuration: 0.5) {
            self.loadingIndicatorProgressViewWidthLayoutConstraint.constant = self.loadingIndicatorBackgroundView.bounds.width * CGFloat((self.limit.selectedUnitsProgressPercentage <= 1 ? NSDecimalNumber(decimal: self.limit.selectedUnitsProgressPercentage) : 1).floatValue)
            self.loadingIndicatorBackgroundView.setNeedsUpdateConstraints()
            self.loadingIndicatorBackgroundView.layoutIfNeeded()
        }
    }
    
    // MARK: - Text Field

    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField === alertControllerTextField, changeInProgress == true, didReturnChange == true {
            
            self.changeInProgress = false
            self.didReturnChange = false
            
            guard let textField = self.alertControllerTextField,
                  let text = textField.text,
                  text != "",
                  let decimal = Decimal(string: text)
            else {
                return
            }
            
            textField.delegate = self
            
            self.lastLogDifference = isLoggingReduction ? (self.unitsLogged - decimal < 0 ? -((self.unitsLogged - decimal) + decimal) : -decimal) : decimal
                        
            self.saveCurrentLog()
            self.updateLabels()
            self.updateTiming()
            self.updateLoadingIndicatorProgress()
        }
        
        alertController?.dismiss(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didReturnChange = true
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if let text = textField.text as NSString?, textField === currentUnitsTextField || textField === alertControllerTextField {
            
            let isNumber = CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string))
            let withDecimal = (
                string == NumberFormatter().decimalSeparator &&
                textField.text?.contains(string) == false
            )
            return (isNumber || withDecimal) && (text.replacingCharacters(in: range, with: string).count <= 5)
        }
        
        return true
    }
    
    // MARK: - Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let emptyLabel = UILabel()
        emptyLabel.textColor = .systemGray
        emptyLabel.font = UIFont.systemFont(ofSize: 28)
        emptyLabel.textAlignment = .center
        emptyLabel.text = "No Logs"
        
        guard let limit = limit else {
            tableView.backgroundView = emptyLabel
            return 0
        }
        
        if limit.days.isEmpty {
            limit.days = []
        }
        
        if !limit.days.contains(where: { $0.date.startOfDay == selectedDate.startOfDay }) {
            limit.addDayToDays(day: Day(date: selectedDate.startOfDay, logs: [], limit: limit.totalUnits, unitsName: limit.unitsName))
        }
        
        tableView.backgroundView = limit.selectedLogs.isEmpty ? emptyLabel : nil
        tableView.separatorStyle = limit.selectedLogs.isEmpty ? .none : .singleLine
        
        return limit.selectedLogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! LimitLogTableViewCell
        let log = limit!.selectedLogs[limit!.selectedLogs.count - indexPath.row - 1]
        let time = Calendar.current.dateComponents([.month, .day, .year, .hour, .minute], from: log.date)
        let dateString = "\(time.month!)/\(time.day!)/\(time.year!) - \(time.hour == 0 ? 12 : time.hour! > 12 ? time.hour! - 12 : time.hour!):\(time.minute! < 10 ? "0" : "")\(time.minute!) \(time.hour! >= 12 ? "PM" : "AM")"
        cell.timeLabel.text = dateString
        cell.amountLabel.text = "\(log.amount) \(limit!.unitsName)"
        return cell
    }
    
    // MARK: - Date Picker
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        selectedDate = sender.date
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "editLimit", let editLimitViewController = segue.destination as? EditLimitViewController {
            editLimitViewController.limitToEdit = limit
            editLimitViewController.limitsTableViewController = limitsTableViewController
        }
    }
    
    // MARK: - Actions

    @IBAction func didTapReduce(_ sender: UIButton) {
        
        guard let unitsName = limit?.unitsName else { return }
        alertController = UIAlertController(title: "Reduce By How Many \(unitsName)?", message: nil, preferredStyle: .alert)
        isLoggingReduction = true
        changeInProgress = true
        
        let submitAction = UIAlertAction(title: "Done", style: .default) { _ in
                        
            if self.changeInProgress != true { return }
            
            self.changeInProgress = false
            
            guard let textField = self.alertControllerTextField,
                  let text = textField.text,
                  text != "",
                  let decimal = Decimal(string: text)
            else {
                return
            }
            
            textField.delegate = self
            
            if self.unitsLogged - decimal < 0 {
                self.lastLogDifference = -((self.unitsLogged - decimal) + decimal)
            } else {
                self.lastLogDifference = -decimal
            }
                        
            self.saveCurrentLog()
            self.updateLabels()
            self.updateTiming()
            self.updateLoadingIndicatorProgress()
        }
        alertController!.addAction(submitAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController!.addAction(cancelAction)
        
        present(alertController!, animated: true)
    }
    
    @IBAction func didTapIncrease(_ sender: UIButton) {
        
        guard let unitsName = limit?.unitsName else { return }
        alertController = UIAlertController(title: "Increase By How Many \(unitsName)?", message: nil, preferredStyle: .alert)
        isLoggingReduction = false
        changeInProgress = true
        
        let submitAction = UIAlertAction(title: "Done", style: .default) { _ in
                        
            if self.changeInProgress != true { return }
            
            self.changeInProgress = false
            
            guard let textField = self.alertControllerTextField,
                  let text = textField.text,
                  text != "",
                  let decimal = Decimal(string: text)
            else {
                return
            }
            
            textField.delegate = self
                        
            self.lastLogDifference = decimal
            self.saveCurrentLog()
            self.updateLabels()
            self.updateTiming()
            self.updateLoadingIndicatorProgress()
        }
        alertController!.addAction(submitAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController!.addAction(cancelAction)
        
        present(alertController!, animated: true)
    }
    
    @IBAction func didTapLastPeriod(_ sender: UIButton) {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
        updateLabels()
        updateTiming()
        updateLoadingIndicatorProgress()
        logTableView.reloadData()
        updateButtons()
    }
    
    @IBAction func didTapNextPeriod(_ sender: UIButton) {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
        updateLabels()
        updateTiming()
        updateLoadingIndicatorProgress()
        logTableView.reloadData()
        updateButtons()
    }
    
    @IBAction func didTapSelectDate(_ sender: UILabel) {
//        let datePicker = UIDatePicker()
//        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
//        datePicker.timeZone = .current
//        datePicker.backgroundColor = .white
//        datePicker.tintColor = .systemGreen
//        present(datePicker, animated: true)
    }
}
