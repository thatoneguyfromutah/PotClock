//
//  Day.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 12/3/23.
//

import UIKit
import CoreData

public class Day: NSObject, Codable {

    // MARK: - Properties
    
    public static var supportsSecureCoding: Bool = true
    
    var date: Date = Date()
    var logs: [Log] = []
    var limit: Decimal?
    
    var units: Decimal {
        return logs.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Initialization
    
    init(date: Date, logs: [Log], limit: Decimal) {
        self.date = date
        self.logs = logs
        self.limit = limit
    }
    
    required convenience public init?(coder: NSCoder) {
                
        guard let date = coder.decodeObject(forKey: "date") as? Date,
              let encodedLogs = coder.decodeObject(forKey: "logs") as? Data,
              let logs = try? JSONDecoder().decode([Log].self, from: encodedLogs),
              let limitString = coder.decodeObject(forKey: "limit") as? String,
              let limit = Decimal(string: limitString)
        else { return nil }
        
        self.init(date: date, logs: logs, limit: limit)
    }
    
    // MARK: - Coding
    
    var encodedLogs: Data? {
        let jsonEncoder = JSONEncoder()
        return try? jsonEncoder.encode(logs)
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(date, forKey: "date")
        coder.encode(encodedLogs, forKey: "logs")
        coder.encode(limit, forKey: "limit")
    }
}

extension Date {
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    }
    
    var yesterday: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: startOfDay)!
    }
    
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar,.yearForWeekOfYear, .weekOfYear], from: self).date!
    }
    
    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year,.month], from: self)
        return Calendar.current.date(from: components)!
    }
    
    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }
}
