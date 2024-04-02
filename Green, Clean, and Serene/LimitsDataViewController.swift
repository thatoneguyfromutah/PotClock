//
//  LimitsDataViewController.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/16/23.
//

import UIKit
import UniformTypeIdentifiers
import CommonCrypto

class LimitsDataViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var selectDeselectAllButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var exportLimitsButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var openFilesBarButtonItem: UIBarButtonItem!
    var clearImportsBarButtonItem: UIBarButtonItem!

    var loadingViewController: UIViewController!
    
    var limitsTableViewController: LimitsTableViewController {
        return (tabBarController!.viewControllers!.first as! UINavigationController).viewControllers.first as! LimitsTableViewController
    }
    
    var allImportedLimits: [Limit] = []
    
    var allSavedLimits: [Limit] {
        return limitsTableViewController.limits
    }
    
    var limitsToImport: [Limit] {
        guard let selectedPaths = tableView.indexPathsForSelectedRows else { return [] }
        var importArray: [Limit] = []
        for selectedPath in selectedPaths {
            importArray.append(allImportedLimits[selectedPath.row])
        }
        return importArray
    }
    
    var limitsToExport: [Limit] {
        guard let selectedPaths = tableView.indexPathsForSelectedRows else { return [] }
        var exportArray: [Limit] = []
        for selectedPath in selectedPaths {
            exportArray.append(allSavedLimits[selectedPath.row])
        }
        return exportArray
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingViewController = storyboard!.instantiateViewController(identifier: "LoadingViewController")
        openFilesBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "folder"), style: .plain, target: self, action: #selector(presentDocumentPicker))
        clearImportsBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "clear"), style: .plain, target: self, action: #selector(didTapClearImports))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateButtons()
    }
    
    // MARK: - Buttons
    
    func updateButtons() {
        
        switch segmentedControl.selectedSegmentIndex {
        
        case 0:
            
            exportLimitsButton.isEnabled = !limitsToExport.isEmpty
            exportLimitsButton.alpha = limitsToExport.isEmpty ? 0.5 : 1.0
            exportLimitsButton.setImage(UIImage(systemName: "square.and.arrow.up.fill"), for: .normal)
            exportLimitsButton.setTitle(" Export Limits", for: .normal)

            selectDeselectAllButton.title = limitsToExport.count == allSavedLimits.count ? "Deselect All" : "Select All"
            selectDeselectAllButton.title = allSavedLimits.isEmpty ? "Select All" : selectDeselectAllButton.title
            selectDeselectAllButton.isEnabled = !allSavedLimits.isEmpty
                        
            navigationItem.rightBarButtonItems = []
            
        case 1:
            
            exportLimitsButton.isEnabled = allImportedLimits.isEmpty || !limitsToImport.isEmpty
            exportLimitsButton.alpha = allImportedLimits.isEmpty ? 1 : limitsToImport.isEmpty ? 0.5 : 1
            exportLimitsButton.setImage(allImportedLimits.isEmpty ? UIImage(systemName: "folder.fill") : UIImage(systemName: "square.and.arrow.down.fill"), for: .normal)
            exportLimitsButton.setTitle(allImportedLimits.isEmpty ? " Open Files" : " Save Limits", for: .normal)
            
            selectDeselectAllButton.title = limitsToImport.count == allImportedLimits.count ? "Deselect All" : "Select All"
            selectDeselectAllButton.title = allImportedLimits.isEmpty ? "Select All" : selectDeselectAllButton.title
            selectDeselectAllButton.isEnabled = !allImportedLimits.isEmpty
            
            clearImportsBarButtonItem.tintColor = .systemRed
            clearImportsBarButtonItem.isEnabled = !allImportedLimits.isEmpty

            openFilesBarButtonItem.isEnabled = !allImportedLimits.isEmpty
            
            navigationItem.rightBarButtonItems = [clearImportsBarButtonItem, openFilesBarButtonItem]
                        
        default:
            fatalError()
        }
    }
    
    // MARK: - File Encryption
    
    func encryptFileData(password: String, data: Data) -> Data? {
        return PotCryptionManager.sharedInstance.encrypt(data: data, key: password)
    }
    
    func decryptFileData(password: String, data: Data) -> Data? {
        return PotCryptionManager.sharedInstance.decrypt(data: data, key: password)
    }
    
    // MARK: - Printing
    
    @objc func didTapClearImports() {
        allImportedLimits = []
        tableView.reloadData()
        updateButtons()
    }
    
    // MARK: - Actions
    
    @IBAction func didChangeSelection(_ sender: UISegmentedControl) {
        tableView.reloadData()
        updateButtons()
    }
    
    @IBAction func didTapSelectDeselect(_ sender: UIBarButtonItem) {
        if sender.title == "Select All" {
            for row in 0..<tableView.numberOfRows(inSection: 0) {
                tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
            }
            sender.title = "Deselect All"
        } else {
            for row in 0..<tableView.numberOfRows(inSection: 0) {
                tableView.deselectRow(at: IndexPath(row: row, section: 0), animated: true)
            }
            sender.title = "Select All"
        }
        updateButtons()
    }
    
    @IBAction func didTapExportLimits(_ sender: UIButton) {
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            
            let fileNameAlertController = UIAlertController(title: "Set File Name", message: "Set a name for the file.", preferredStyle: .alert)
            fileNameAlertController.addTextField()
            
            let doneAction = UIAlertAction(title: "Done", style: .default) { action in
                
                guard let textField = fileNameAlertController.textFields?.first, let fileName = textField.text, fileName != "" else {
                    
                    let alertController = UIAlertController(title: "Error", message: "Try again and make sure to give the file a name with one or more characters.", preferredStyle: .alert)
                    
                    let doneAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(doneAction)
                    
                    self.present(alertController, animated: true)
                    
                    return
                }
                
                let encryptionAlertController = UIAlertController(title: "Set Password", message: "Set a secure password to keep your data safe from device to device, please be sure to remember it as there is no way to retrieve it if it is forgotten, it could be a good idea to write it down. It can be anything 8 characters and above, but keep in mind the data is only as secure as the password you set, so try to make sure it is complex.", preferredStyle: .alert)
                encryptionAlertController.addTextField()
                encryptionAlertController.addTextField()
                
                guard let firstTextField = encryptionAlertController.textFields?.first,
                      let secondTextField = encryptionAlertController.textFields?.last
                else { return }
                
                firstTextField.isSecureTextEntry = true
                secondTextField.isSecureTextEntry = true
                
                let doneAction = UIAlertAction(title: "Done", style: .default) { action in
                            
                    guard let firstText = firstTextField.text,
                          let secondText = secondTextField.text,
                          firstText == secondText,
                          firstText != "",
                          firstText.count >= 8
                    else {
                        let alertController = UIAlertController(title: "Password Requirements Not Met", message: "Try to export the data again with a more secure password as described in the Set Password alert. Also make sure you entered the same password twice.", preferredStyle: .alert)
                        let doneAction = UIAlertAction(title: "Done", style: .default)
                        alertController.addAction(doneAction)
                        self.present(alertController, animated: true) {
                            self.didTapExportLimits(sender)
                        }
                        return
                    }
                    
                    self.present(self.loadingViewController, animated: true) {
                        
                        let fileManager = FileManager.default
                        let encoded = try! JSONEncoder().encode(self.limitsToExport)
                        let encryptedData = self.encryptFileData(password: firstText, data: encoded)
                        
                        do {
                            
                            let fileURL = fileManager.temporaryDirectory.appendingPathComponent("\(fileName).potclockdata")
                            
                            try encryptedData?.write(to: fileURL)
                            
                            self.loadingViewController.dismiss(animated: true) {
                                
                                let controller = UIDocumentPickerViewController(forExporting: [fileURL], asCopy: true)
                                self.present(controller, animated: true)
                            }
                            
                            return
                            
                        } catch {
                            
                            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                            
                            let doneAction = UIAlertAction(title: "Done", style: .default)
                            alertController.addAction(doneAction)
                                       
                            self.loadingViewController.dismiss(animated: true) {
                                
                                self.present(alertController, animated: true)
                            }
                            
                            return
                        }
                    }
                }
                encryptionAlertController.addAction(doneAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                encryptionAlertController.addAction(cancelAction)
                
                self.present(encryptionAlertController, animated: true)
                
                return
            }
            fileNameAlertController.addAction(doneAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            fileNameAlertController.addAction(cancelAction)
            
            self.present(fileNameAlertController, animated: true)
            
            return
            
        case 1:
            
            if allImportedLimits.isEmpty {
                presentDocumentPicker()
                return
            }
            
            present(loadingViewController, animated: true) {
                
                var namesThatExist: [String] = []
                var alreadyExists: Bool {
                    return !namesThatExist.isEmpty
                }
                
                self.limitsToImport.forEach { limitToImport in
                    if self.allSavedLimits.contains(where: { savedLimit in
                        return limitToImport.name == savedLimit.name
                    }) {
                        namesThatExist.append(limitToImport.name)
                    } else {
                        self.limitsTableViewController.addNewLimit(newLimit: limitToImport)
                    }
                }
                
                if alreadyExists {
                    let alertController = UIAlertController(title: "\(namesThatExist.count == 1 ? "\(namesThatExist[0])" : "\(namesThatExist.joined(separator: ", "))") Already Exist\(namesThatExist.count == 1 ? "s" : "")", message: "Please rename \(namesThatExist.count == 1 ? "it" : "them") in your limits to save \(namesThatExist.count == 1 ? "it" : "them")\(namesThatExist.count == self.limitsToImport.count ? "" : ", all other limits have been saved successfully").", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)
                    
                    self.loadingViewController.dismiss(animated: true) {
                        
                        self.present(alertController, animated: true)
                    }
                    
                    return
                }
                
                let alertController = UIAlertController(title: "Limits Imported", message: "Your selected limits have all been imported successfully.", preferredStyle: .alert)
                
                let doneAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(doneAction)
                
                self.loadingViewController.dismiss(animated: true) {
                    
                    self.present(alertController, animated: true)
                }
                
                return
            }
            
        default:
            fatalError()
        }
    }
    
    @objc func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType(filenameExtension: "potclockdata")!, UTType(filenameExtension: "PotClockData")!, UTType(filenameExtension: "POTCLOCKDATA")!])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    func importLimits(fromURL url: URL) {
        
        _ = url.startAccessingSecurityScopedResource()
        
        let alertController = UIAlertController(title: "Enter Password For \(url.lastPathComponent)", message: "Enter the password you set for this file. Unfortunately there is no way to recover it if you lost it as it is not stored remotely.", preferredStyle: .alert)
        alertController.addTextField()
        
        guard let textField = alertController.textFields?.first else { return }
        textField.isSecureTextEntry = true
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { action in
            
            self.present(self.loadingViewController, animated: true) {
                
                guard let encryptedData = try? Data(contentsOf: url),
                      let text = textField.text,
                      let decryptedData = self.decryptFileData(password: text, data: encryptedData),
                      let decodedLimits = try? JSONDecoder().decode([Limit].self, from: decryptedData)
                else {
                    
                    let alertController = UIAlertController(title: "Error", message: "There was a problem decrypting the file. Please try again and make sure you enter the correct password.", preferredStyle: .alert)

                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)

                    self.loadingViewController.dismiss(animated: true) {
                        
                        self.present(alertController, animated: true)
                    }
                    
                    return
                }
                
                var importableLimits: [Limit] = []
                var namesThatExist: [String] = []
                var alreadyExists: Bool {
                    return !namesThatExist.isEmpty
                }
                
                for decodedLimit in decodedLimits {
                    if self.allImportedLimits.contains(where: { importedLimit in
                        return decodedLimit.name.lowercased() == importedLimit.name.lowercased()
                    }) {
                        namesThatExist.append(decodedLimit.name)
                    } else {
                        importableLimits.append(decodedLimit)
                    }
                }
                
                guard !alreadyExists else {
                    
                    let alertController = UIAlertController(title: "\(namesThatExist.count == 1 ? "\(namesThatExist[0])" : "\(namesThatExist.joined(separator: ", "))") \(namesThatExist.count == 1 ? "Has" : "Have") Already Been Imported", message: "Please remove \(namesThatExist.count == 1 ? "it" : "them") from your imports and try again\(importableLimits.isEmpty ? "" : ", all other limits have been imported and are ready to be saved").", preferredStyle: .alert)

                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)

                    self.loadingViewController.dismiss(animated: true) {
                        
                        self.present(alertController, animated: true) {
                            
                            importableLimits.forEach { self.allImportedLimits.append($0) }
                            
                            self.tableView.reloadData()
                            self.updateButtons()
                            
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    return
                }
                
                self.loadingViewController.dismiss(animated: true) {
                    
                    importableLimits.forEach { self.allImportedLimits.append($0) }
                    
                    self.tableView.reloadData()
                    self.updateButtons()
                    
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
        alertController.addAction(doneAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

extension LimitsDataViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        urls.forEach { importLimits(fromURL: $0) }
    }
}

extension LimitsDataViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            
            guard !allSavedLimits.isEmpty else {
                
                let emptyLabel = UILabel()
                emptyLabel.text = "No Limits"
                emptyLabel.textColor = .systemGray
                emptyLabel.font = UIFont.systemFont(ofSize: 28)
                emptyLabel.textAlignment = .center
                tableView.backgroundView = emptyLabel
                tableView.separatorStyle = .none
                
                return 0
            }
            
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            
            return allSavedLimits.count
            
        case 1:
            
            guard !allImportedLimits.isEmpty else {
                
                let emptyLabel = UILabel()
                emptyLabel.text = "No Limits"
                emptyLabel.textColor = .systemGray
                emptyLabel.font = UIFont.systemFont(ofSize: 28)
                emptyLabel.textAlignment = .center
                tableView.backgroundView = emptyLabel
                tableView.separatorStyle = .none
                
                return 0
            }
            
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            
            return allImportedLimits.count
            
        default:
            fatalError()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "exportLimitCell", for: indexPath) as! ExportLimitTableViewCell
        
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            
            let limit = allSavedLimits[indexPath.row]
            cell.limitImageView.image = UIImage(systemName: limit.iconName)
            cell.limitNameLabel.text = limit.name
            cell.limitCategoryLabel.text = limit.categoryString.capitalized
            
        case 1:
            
            let limit = allImportedLimits[indexPath.row]
            cell.limitImageView.image = UIImage(systemName: limit.iconName)
            cell.limitNameLabel.text = limit.name
            cell.limitCategoryLabel.text = limit.categoryString.capitalized
            
        default:
            fatalError()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return segmentedControl.selectedSegmentIndex == 1
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { action, view, success in
            self.allImportedLimits.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateButtons()
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        updateButtons()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        updateButtons()
    }
}
