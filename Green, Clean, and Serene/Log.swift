//
//  LimitLog.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/13/23.
//

import UIKit
import CoreData

public class Log: NSObject, Codable {

    // MARK: - Properties
    
    public static var supportsSecureCoding: Bool = true
    
    var amount: Decimal
    var date: Date
    
    // MARK: - Initialization
    
    init(amount: Decimal, date: Date) {
        self.amount = amount
        self.date = date
    }
    
    required convenience public init?(coder: NSCoder) {
                
        guard let amountString = coder.decodeObject(forKey: "amount") as? String,
              let amount = Decimal(string: amountString),
              let date = coder.decodeObject(forKey: "date") as? Date
        else { return nil }
        
        self.init(amount: amount, date: date)
    }
    
    // MARK: - Coding
    
    public func encode(with coder: NSCoder) {
        coder.encode(amount, forKey: "amount")
        coder.encode(date, forKey: "date")
    }
}
