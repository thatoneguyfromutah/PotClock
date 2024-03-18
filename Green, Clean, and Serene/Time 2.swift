//
//  Time.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/26/23.
//

import UIKit

public class Time: NSObject, Codable {
    
    // MARK: - Initialization
    
    init(date: Date) {
        let calendar = NSCalendar.current
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
        self.day = calendar.component(.day, from: date)
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
        self.second = calendar.component(.second, from: date)
        self.nanosecond = calendar.component(.nanosecond, from: date)
    }
    
    init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int, nanosecond: Int) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.nanosecond = nanosecond
    }
    
    
    public required convenience init?(coder: NSCoder) {
        
        guard let year = coder.decodeObject(forKey: "year") as? Int,
              let month = coder.decodeObject(forKey: "month") as? Int,
              let day = coder.decodeObject(forKey: "day") as? Int,
              let hour = coder.decodeObject(forKey: "hour") as? Int,
              let minute = coder.decodeObject(forKey: "minute") as? Int,
              let second = coder.decodeObject(forKey: "second") as? Int,
              let nanosecond = coder.decodeObject(forKey: "nanosecond") as? Int
        else { return nil }
        
        self.init(year: year, month: month, day: day, hour: hour, minute: minute, second: second, nanosecond: nanosecond)
    }
    
    // MARK: - Properties
        
    public static var supportsSecureCoding: Bool = true
    
    var year: Int
    var month: Int
    var day: Int
    var hour: Int
    var minute: Int
    var second: Int
    var nanosecond: Int
    
    var encoded: Data {
        return try! JSONEncoder().encode(self)
    }
    
    // MARK: - Encoding
    
    func encode(with coder: NSCoder) {
        coder.encode(year, forKey: "year")
        coder.encode(month, forKey: "month")
        coder.encode(day, forKey: "day")
        coder.encode(hour, forKey: "hour")
        coder.encode(minute, forKey: "minute")
        coder.encode(second, forKey: "second")
        coder.encode(nanosecond, forKey: "nanosecond")
    }
}
