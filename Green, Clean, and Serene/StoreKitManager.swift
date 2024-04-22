//
//  StoreKitManager.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 11/15/23.
//

import StoreKit

class StoreKitManager: NSObject {
    
    // MARK: - Properties
    
    static let sharedInstance = StoreKitManager()
    
    var oneDollarTip = "com.chaseangelogiles.PotClock.tips.one"
    var fiveDollarTip = "com.chaseangelogiles.PotClock.tips.five"
    var tenDollarTip = "com.chaseangelogiles.PotClock.tips.ten"
    var twentyDollarTip = "com.chaseangelogiles.PotClock.tips.twenty"
    var fiftyDollarTip = "com.chaseangelogiles.PotClock.tips.fifty"
    var oneHundredDollarTip = "com.chaseangelogiles.PotClock.tips.onehundred"
    
    var products: [SKProduct]?
    
    // MARK: - Products
    
    func getProducts() {
        let request = SKProductsRequest(productIdentifiers: [oneDollarTip, fiveDollarTip, tenDollarTip, twentyDollarTip, fiftyDollarTip, oneHundredDollarTip])
        request.delegate = self
        request.start()
    }
    
    // MARK: - Actions
    
    func purchase(product: SKProduct) -> Bool {
        guard let products = products, !products.isEmpty else { return false }
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        return true
    }
}

extension StoreKitManager: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func requestDidFinish(_ request: SKRequest) {
        print("StoreKit request is finished.")
    }
}
