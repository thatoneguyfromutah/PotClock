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
    var time: Time
    
    // MARK: - Initialization
    
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
    
    // MARK: - Coding
    
    public func encode(with coder: NSCoder) {
        coder.encode(amount, forKey: "amount")
        coder.encode(time.encoded, forKey: "time")
    }
}
