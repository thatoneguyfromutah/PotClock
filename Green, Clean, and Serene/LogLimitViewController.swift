//
//  LogLimitViewController.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/7/23.
//

import UIKit
import CoreData
import CoreLocation
import MapKit
import AVFoundation

class LogLimitViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

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
    
    var currentLogImage: UIImage?
    
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
                
        updateLabels()
        updateTiming()
        updateButtons()
        logTableView.reloadData()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentUnitsTextField.delegate = self
        
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.updateButtons()
            }
        }
        
        self.requestCameraAccess()
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
    
    // MARK: - Location Services
    
    func requestCameraAccess() {
        Task {
            await AVCaptureDevice.requestAccess(for: .video)
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

            changeInProgress = false
            didReturnChange = false

            guard let textField = self.alertControllerTextField,
                  let text = textField.text,
                  text != "",
                  let decimal = Decimal(string: text)
            else {
                return
            }

            textField.delegate = self

            lastLogDifference = isLoggingReduction ? (unitsLogged - decimal < 0 ? -((unitsLogged - decimal) + decimal) : -decimal) : decimal
            
            alertController?.dismiss(animated: true) {
                self.saveCurrentLog()
            }
        }

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
            limit.addDayToDays(day: Day(date: selectedDate.startOfDay, logs: [], limit: limit.totalUnits))
        }
        
        tableView.backgroundView = limit.selectedLogs.isEmpty ? emptyLabel : nil
        tableView.separatorStyle = limit.selectedLogs.isEmpty ? .none : .singleLine
        
        return limit.selectedLogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: LimitLogTableViewCell
        
        let log = limit!.selectedLogs[limit!.selectedLogs.count - indexPath.row - 1]
        
        if let image = log.image,
           let latitude = log.latitude,
           let longitude = log.longitude {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "logCellImageMap", for: indexPath) as! LimitLogTableViewCell
                        
            cell.logMapView.removeAnnotations(cell.logMapView.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            cell.logMapView.addAnnotation(annotation)
            
            let region = MKCoordinateRegion( center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), latitudinalMeters: CLLocationDistance(exactly: 100)!, longitudinalMeters: CLLocationDistance(exactly: 100)!)
            cell.logMapView.setRegion(cell.logMapView.regionThatFits(region), animated: true)
            
            cell.logImageView.image = image
                        
        } else if let image = log.image {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "logCellImage", for: indexPath) as! LimitLogTableViewCell
            
            cell.logImageView.image = image
            
        } else if let latitude = log.latitude,
           let longitude = log.longitude {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "logCellMap", for: indexPath) as! LimitLogTableViewCell
                        
            cell.logMapView.removeAnnotations(cell.logMapView.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            cell.logMapView.addAnnotation(annotation)
            
            let region = MKCoordinateRegion( center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), latitudinalMeters: CLLocationDistance(exactly: 100)!, longitudinalMeters: CLLocationDistance(exactly: 100)!)
            cell.logMapView.setRegion(cell.logMapView.regionThatFits(region), animated: true)
            
        } else {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath) as! LimitLogTableViewCell
            
        }
        
        let time = Calendar.current.dateComponents([.month, .day, .year, .hour, .minute], from: log.date)
        let dateString = "\(time.month!)/\(time.day!)/\(time.year!) - \(time.hour == 0 ? 12 : time.hour! > 12 ? time.hour! - 12 : time.hour!):\(time.minute! < 10 ? "0" : "")\(time.minute!) \(time.hour! >= 12 ? "PM" : "AM")"
        cell.logTimeLabel.text = dateString
        cell.logAmountLabel.text = "\(log.amount) \(limit!.unitsName)"
        
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
    
    // MARK: - Logs
        
    func saveCurrentLog() {
        
        if lastLogDifference == 0 { return }
            
        self.present(limitsTableViewController.loadingViewController, animated: true) {
            
            var log: Log

            if self.lastLogDifference > 0,
               let currentLogImage = self.currentLogImage,
               let coordinates = self.limitsTableViewController.locationManager?.location?.coordinate {
                
                log = Log(amount: self.lastLogDifference, date: Date(), image: currentLogImage, latitude: coordinates.latitude, longitude: coordinates.longitude)
                
            } else if self.lastLogDifference > 0,
                let currentLogImage = self.currentLogImage {
                
                log = Log(amount: self.lastLogDifference, date: Date(), image: currentLogImage)
                
            } else if self.lastLogDifference > 0,
                      let coordinates = self.limitsTableViewController.locationManager?.location?.coordinate {
                
                log = Log(amount: self.lastLogDifference, date: Date(), latitude: coordinates.latitude, longitude: coordinates.longitude)
                
            } else {
                
                log = Log(amount: self.lastLogDifference, date: Date())
            }
            
            self.limitsTableViewController.loadingViewController.dismiss(animated: true) {
                self.currentLogImage = nil
                self.limit.addLogToSelectedDay(log: log)
                self.logTableView.reloadData()
                self.updateLabels()
                self.updateTiming()
                self.updateLoadingIndicatorProgress()
            }
        }
    }
    
    func presentIncreaseUnitsAlert() {
        
        guard let unitsName = limit?.unitsName else { return }
        alertController = UIAlertController(title: "Increase By How Many \(unitsName)?", message: nil, preferredStyle: .alert)
        isLoggingReduction = false
        changeInProgress = true
        
        let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                        
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
        }
        alertController!.addAction(submitAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController!.addAction(cancelAction)
        
        present(alertController!, animated: true)
    }
    
    // MARK: - Image Picker
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage else {
            print("No Image Found")
            return
        }
        
        currentLogImage = image
    
        presentIncreaseUnitsAlert()
    }
    
    // MARK: - Actions

    @IBAction func didTapReduce(_ sender: UIButton) {
        
        guard let unitsName = limit?.unitsName else { return }
        alertController = UIAlertController(title: "Reduce By How Many \(unitsName)?", message: nil, preferredStyle: .alert)
        isLoggingReduction = true
        changeInProgress = true
        
        let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                        
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
        }
        alertController!.addAction(submitAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController!.addAction(cancelAction)
        
        present(alertController!, animated: true)
    }
    
    @IBAction func didTapIncrease(_ sender: UIButton) {
                        
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            self.presentIncreaseUnitsAlert()
            return
        }
        
        let askImageViewController = UIAlertController(title: "Take And Attach An Image?", message: nil, preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.delegate = self
            self.present(vc, animated: true)
        }
        askImageViewController.addAction(yesAction)
        
        let noAction = UIAlertAction(title: "No", style: .default) { _ in
            self.presentIncreaseUnitsAlert()
        }
        askImageViewController.addAction(noAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        askImageViewController.addAction(cancelAction)
        
        present(askImageViewController, animated: true)
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
}
