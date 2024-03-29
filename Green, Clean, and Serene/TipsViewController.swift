//
//  TipsViewController.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/15/23.
//

import UIKit
import StoreKit
import CoreData
import MessageUI

class TipsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate, SKPaymentTransactionObserver {

    // MARK: - Properties
    
    @IBOutlet weak var tipsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    let instagramURL = URL(string: "instagram://user?username=utahpatient")
    var instagramButton: UIBarButtonItem!
    
    var emailBarButtonItem: UIBarButtonItem!
    
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "StoredTip")
    
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var context: NSManagedObjectContext {
        return appDelegate.context
    }
    
    let storeKitManager = StoreKitManager.sharedInstance
    
    var tips: [Tip] = []
    var transactionTipType: TipType = .one
    
    func updateTips() {
        
        tips = []
        
        guard let tipsInStorage = try? context.fetch(fetchRequest) else { return }
        
        for tipInStorage in tipsInStorage {
            
            guard let amountString = tipInStorage.value(forKeyPath: "amount") as? String,
                  let amount = Decimal(string: amountString),
                  let date = tipInStorage.value(forKeyPath: "date") as? Date
            else { return }

            let tip = Tip(managedObject: tipInStorage, context: context, amount: amount, date: date)
            tips.append(tip)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - View Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SKPaymentQueue.default().add(self)
        emailBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "envelope"), style: .plain, target: self, action: #selector(didTapContact))
        updateButtons()
        updateTips()
        storeKitManager.getProducts()
    }
    
    // MARK: - Instagram
    
    func updateButtons() {
                
        guard let instagramURL = instagramURL,
              UIApplication.shared.canOpenURL(instagramURL)
        else {
            navigationItem.leftBarButtonItems = [emailBarButtonItem]
            return
        }
        
        instagramButton = UIBarButtonItem(image: UIImage(systemName: "newspaper"), style: .plain, target: self, action: #selector(openInstagram))
        navigationItem.leftBarButtonItems = [emailBarButtonItem, instagramButton]
    }
    
    @objc func openInstagram() {
        
        guard let instagramURL = instagramURL,
              UIApplication.shared.canOpenURL(instagramURL)
        else { return }
        
        UIApplication.shared.open(instagramURL)
    }
    
    // MARK: - Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let totalTips = tips.map({ $0.amount }).reduce(0, +)
        let noTipsLabel = UILabel()
        noTipsLabel.textColor = .systemGray
        noTipsLabel.textAlignment = .center
        noTipsLabel.font = UIFont.systemFont(ofSize: 28)
        noTipsLabel.text = "No Tips"
        tableView.separatorStyle = tips.isEmpty ? .none : .singleLine
        tableView.backgroundView = tips.isEmpty ? noTipsLabel : nil
        tipsLabel.text = totalTips == 0 ? "No Tips... Yet!" : "$\(totalTips) Tipped, Thank You!"
        tipsLabel.textColor = totalTips > 0 ? .systemGreen : .label
        return tips.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tipCell", for: indexPath) as! TipTableViewCell
        let tip = tips[tips.count - indexPath.row - 1]
        let amountString = "$\(tip.amount)"
        let time = Calendar.current.dateComponents([.month, .day, .year, .hour, .minute], from: tip.date)
        let timeString = "\(time.month!)/\(time.day!)/\(time.year!) - \(time.hour == 0 ? 12 : time.hour! > 12 ? time.hour! - 12 : time.hour!):\(time.minute! < 10 ? "0" : "")\(time.minute!) \(time.hour! >= 12 ? "PM" : "AM")"
        cell.amountLabel.text = amountString
        cell.timeLabel.text = timeString
        return cell
    }
    
    // MARK: - Tips
    
    enum TipType {
        case one
        case five
        case ten
        case twenty
        case fifty
        case onehundred
    }
    
    func processTip(tipType: TipType) {
        
        if !SKPaymentQueue.canMakePayments() {
            
            let alertController = UIAlertController(title: "Error", message: "Unable to make payments.", preferredStyle: .alert)
        
            let cancelAction = UIAlertAction(title: "Done", style: .default)
            alertController.addAction(cancelAction)
        
            present(alertController, animated: true)
            
            return
        }
        
        guard let products = storeKitManager.products else { return }
        
        transactionTipType = tipType
        
        var oneDollarTip: SKProduct?
        var fiveDollarTip: SKProduct?
        var tenDollarTip: SKProduct?
        var twentyDollarTip: SKProduct?
        var fiftyDollarTip: SKProduct?
        var onehundredDollarTip: SKProduct?
        
        for product in products {
            
            if product.productIdentifier == "com.chaseangelogiles.PotClock.tips.one" {
                oneDollarTip = product
            }
            
            if product.productIdentifier == "com.chaseangelogiles.PotClock.tips.five" {
                fiveDollarTip = product
            }
            
            if product.productIdentifier == "com.chaseangelogiles.PotClock.tips.ten" {
                tenDollarTip = product
            }
            
            if product.productIdentifier == "com.chaseangelogiles.PotClock.tips.twenty" {
                twentyDollarTip = product
            }
            
            if product.productIdentifier == "com.chaseangelogiles.PotClock.tips.fifty" {
                fiftyDollarTip = product
            }
            
            if product.productIdentifier == "com.chaseangelogiles.PotClock.tips.onehundred" {
                onehundredDollarTip = product
            }
        }
                
        switch tipType {
        case .one:
            guard storeKitManager.purchase(product: oneDollarTip!) else { return }
        case .five:
            guard storeKitManager.purchase(product: fiveDollarTip!) else { return }
        case .ten:
            guard storeKitManager.purchase(product: tenDollarTip!) else { return }
        case .twenty:
            guard storeKitManager.purchase(product: twentyDollarTip!) else { return }
        case .fifty:
            guard storeKitManager.purchase(product: fiftyDollarTip!) else { return }
        case .onehundred:
            guard storeKitManager.purchase(product: onehundredDollarTip!) else { return }
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            
            switch transaction.transactionState {
            case .purchased:
                
                SKPaymentQueue.default().finishTransaction(transaction)

                let newTip: Tip?
                
                switch transactionTipType {
                case .one:
                    newTip = Tip(amount: 1, date: Date())
                case .five:
                    newTip = Tip(amount: 5, date: Date())
                case .ten:
                    newTip = Tip(amount: 10, date: Date())
                case .twenty:
                    newTip = Tip(amount: 20, date: Date())
                case .fifty:
                    newTip = Tip(amount: 50, date: Date())
                case .onehundred:
                    newTip = Tip(amount: 100, date: Date())
                }
                
                let managedContext = appDelegate.persistentContainer.viewContext
                
                guard let entity = NSEntityDescription.entity(forEntityName: "StoredTip", in: managedContext) else { return }
                
                let storedTip = NSManagedObject(entity: entity, insertInto: managedContext)
                storedTip.setValue(String(describing: newTip!.amount), forKey: "amount")
                storedTip.setValue(newTip!.date, forKey: "date")
                
                do {
                
                    try managedContext.save()
                    updateTips()
                
                } catch let error {
                
                    let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                
                    let cancelAction = UIAlertAction(title: "Done", style: .default)
                    alertController.addAction(cancelAction)
                
                    present(alertController, animated: true)
                }
                
                break
                
            case .purchasing:
                
                print("Purchasing...")
                break
            
            case .restored:
                
                print("Restored...")
                break
                
            case .deferred:
                
                print("Deferred...")
                break
                
            default:
                
                let alertController = UIAlertController(title: "Error", message: "Failed to purchase tip. Please try again.", preferredStyle: .alert)
            
                let cancelAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(cancelAction)
            
                present(alertController, animated: true)
                
                break
            }
        }
    }
    
    // MARK: - Mail
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if let error = error {
            
            let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Done", style: .default)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
            
            return
        }
        
        controller.dismiss(animated: true) {
            
            switch result {
            
            case .sent:
                let alertController = UIAlertController(title: "Email Sent", message: nil, preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true)
                
                return
                
            case .saved:
                
                let alertController = UIAlertController(title: "Email Saved", message: nil, preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true)
                
                return
                
            case .cancelled:
                
                print("Email was cancelled.")
                
//                let alertController = UIAlertController(title: "Email Cancelled", message: nil, preferredStyle: .alert)
//
//                let cancelAction = UIAlertAction(title: "Done", style: .default)
//                alertController.addAction(cancelAction)
//
//                self.present(alertController, animated: true)
                
                return
                
            case .failed:
                
                let alertController = UIAlertController(title: "Email Failed", message: nil, preferredStyle: .alert)
                
                let cancelAction = UIAlertAction(title: "Done", style: .default)
                alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true)
                
                return
                
            @unknown default:
                fatalError()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func didTapInfoButton(_ sender: UIBarButtonItem) {
        
        let alertController = UIAlertController(title: "What Information Are You Looking For?", message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        
        let privacyPolicyAction = UIAlertAction(title: "Privacy Policy", style: .default) { action in
            guard let url = URL(string: "https://www.iubenda.com/privacy-policy/15364850") else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        alertController.addAction(privacyPolicyAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @objc func didTapContact() {
        
        let helpEmail = "thatoneguyfromutah@gmail.com"
        
        let emailSubject = "It's About PotClock"
        let emailBody = ""
        
        let subjectEncoded = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = emailBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        if let url = URL(string: "mailto:\(helpEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)"),
                  UIApplication.shared.canOpenURL(url) {
            
            UIApplication.shared.open(url)
            
        } else {
            
            let alertController = UIAlertController(title: "No Emails Set Up", message: "Unable to send an email, please set one up in settings and try again, you can also reach out through another device where email is already set up at \(helpEmail).", preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "Done", style: .default)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true)
        }
    }
    
    @IBAction func didTapFirstTipButton(_ sender: UIButton) {
        processTip(tipType: .one)
    }
    
    @IBAction func didTapSecondTipButton(_ sender: UIButton) {
        processTip(tipType: .five)
    }
    
    @IBAction func didTapThirdTipButton(_ sender: UIButton) {
        processTip(tipType: .ten)
    }
    
    @IBAction func didTapFourthTipButton(_ sender: UIButton) {
        processTip(tipType: .twenty)
    }
    
    @IBAction func didTapFifthTipButton(_ sender: UIButton) {
        processTip(tipType: .fifty)
    }
    
    @IBAction func didTapSixthTipButton(_ sender: UIButton) {
        processTip(tipType: .onehundred)
    }

}
