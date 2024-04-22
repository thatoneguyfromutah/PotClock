//
//  Tip.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 11/23/23.
//

import UIKit
import CoreData

class Tip: NSObject, Codable {
    
    // MARK: - Initialization
    
    init(managedObject: NSManagedObject, context: NSManagedObjectContext, amount: Decimal, date: Date) {
        self.managedObject = managedObject
        self.context = context
        self.amount = amount
        self.date = date
    }

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
    
    // MARK: - Properties
    
    public static var supportsSecureCoding: Bool = true
    
    @NotCoded var managedObject: NSManagedObject?
    @NotCoded var context: NSManagedObjectContext?
    
    var amount: Decimal {
        didSet {
            managedObject?.setValue(amount, forKey: "amount")
            try? context?.save()
        }
    }
    
    var date: Date {
        didSet {
            managedObject?.setValue(date, forKey: "date")
            try? context?.save()
        }
    }
    
    // MARK: - Coding
    
    public func encode(with coder: NSCoder) {
        coder.encode(amount, forKey: "amount")
        coder.encode(date, forKey: "date")
    }
}
