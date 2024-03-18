//
//  Tip.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/23/23.
//

import UIKit
import CoreData

class Tip: NSObject, Codable {
    
    // MARK: - Initialization
    
    init(managedObject: NSManagedObject, context: NSManagedObjectContext, amount: Decimal, time: Time) {
        self.managedObject = managedObject
        self.context = context
        self.amount = amount
        self.time = time
    }

    init(amount: Decimal, time: Time) {
        self.amount = amount
        self.time = time
    }
    
    required convenience public init?(coder: NSCoder) {
                
        guard let amountString = coder.decodeObject(forKey: "amount") as? String,
              let amount = Decimal(string: amountString),
              let data = coder.decodeObject(forKey: "time") as? Data,
              let time = try? JSONDecoder().decode(Time.self, from: data)
        else { return nil }
        
        self.init(amount: amount, time: time)
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
    
    var time: Time {
        didSet {
            managedObject?.setValue(time.encoded, forKey: "time")
            try? context?.save()
        }
    }
    
    // MARK: - Coding
    
    public func encode(with coder: NSCoder) {
        coder.encode(amount, forKey: "amount")
        coder.encode(time.encoded, forKey: "time")
    }
}
