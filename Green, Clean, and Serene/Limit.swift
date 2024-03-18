//
//  Limit.swift
//  Green, Clean, and Serene
//
//  Created by Chase Angelo Giles on 11/13/23.
//

import UIKit
import CoreData

class Limit: NSObject, Codable {
    
    // MARK: - Initialization
    
    init(creationDate: Date, category: Categories, name: String, unitsName: String, totalUnits: Decimal, timing: Timing, days: [Day], iconName: String) {
        self.creationDate = creationDate
        self.category = category
        self.name = name
        self.unitsName = unitsName
        self.totalUnits = totalUnits
        self.timing = timing
        self.days = days
        self.iconName = iconName
    }
    
    init(creationDate: Date, managedObject: NSManagedObject?, context: NSManagedObjectContext?, category: Categories, name: String, unitsName: String, totalUnits: Decimal, timing: Timing, days: [Day], iconName: String) {
        self.creationDate = creationDate
        self.managedObject = managedObject
        self.context = context
        self.category = category
        self.name = name
        self.unitsName = unitsName
        self.totalUnits = totalUnits
        self.timing = timing
        self.days = days
        self.iconName = iconName
    }
    
    required convenience init?(coder: NSCoder) {
                
//        let unitsLoggedString = coder.decodeObject(forKey: "unitsLogged") as? String,
//        let unitsLogged = Decimal(string: unitsLoggedString),
        
        guard let creationDate = coder.decodeObject(forKey: "creationDate") as? Date,
              let categoryString = coder.decodeObject(forKey: "categoryString") as? String,
              let name = coder.decodeObject(forKey: "name") as? String,
              let unitsName = coder.decodeObject(forKey: "unitsName") as? String,
              let totalUnitsString = coder.decodeObject(forKey: "totalUnits") as? String,
              let totalUnits = Decimal(string: totalUnitsString),
              let timingString = coder.decodeObject(forKey: "timingString") as? String,
              let daysAsData = coder.decodeObject(forKey: "days") as? Data,
              let days = try? JSONDecoder().decode([Day].self, from: daysAsData),
              let iconName = coder.decodeObject(forKey: "iconName") as? String
        else { return nil }
                
        let category: Categories
        switch categoryString {
        case "food":
            category = .food
        case "drug":
            category = .drug
        case "activity":
            category = .activity
        default:
            category = .food
        }
                
        let timing: Timing
        switch timingString {
        case "daily":
            timing = .daily
        case "weekly":
            timing = .weekly
        case "monthly":
            timing = .monthly
        case "yearly":
            timing = .yearly
        default:
            timing = .daily
        }
        
        self.init(creationDate: creationDate, category: category, name: name, unitsName: unitsName, totalUnits: totalUnits, timing: timing, days: days, iconName: iconName)
    }
    
    // MARK: - Properties
    
    public static var supportsSecureCoding: Bool = true
    
    @NotCoded var managedObject: NSManagedObject?
    @NotCoded var context: NSManagedObjectContext?
    
    var selectedDate = Date()
    
    var creationDate: Date {
        didSet {
            managedObject?.setValue(creationDate, forKey: "creationDate")
            try? context?.save()
        }
    }
    var category: Categories = .food {
        didSet {
            managedObject?.setValue(categoryString, forKey: "categoryString")
            try? context?.save()
        }
    }
    var name: String = "" {
        didSet {
            managedObject?.setValue(name, forKey: "name")
            try? context?.save()
        }
    }
    var unitsName: String = "Meals" {
        didSet {
            managedObject?.setValue(unitsName, forKey: "unitsName")
            try? context?.save()
        }
    }
    var totalUnits: Decimal = 1.0 {
        didSet {
            managedObject?.setValue(totalUnitsString, forKey: "totalUnits")
            try? context?.save()
        }
    }
    var timing: Timing = .daily {
        didSet {
            managedObject?.setValue(timingString, forKey: "timingString")
            try? context?.save()
        }
    }
    var days: [Day] = [] {
        didSet {
            managedObject?.setValue(encodedDays, forKey: "days")
            try! context?.save()
        }
    }
    var iconName: String = "" {
        didSet {
            managedObject?.setValue(iconName, forKey: "iconName")
            try? context?.save()
        }
    }
    
    var currentDayUnitsLoggedString: String {
        return String(describing: currentDay.units)
    }
    
    var selectedDayUnitsLoggedString: String {
        return String(describing: selectedDay.units)
    }
    
    var totalUnitsString: String {
        return String(describing: totalUnits)
    }
    
    var currentDay: Day {

        for day in days {
            if day.date.startOfDay == Date().startOfDay {
                return day
            }
        }

        if days.isEmpty {
            days = []
        }

        addDayToDays(day: Day(date: selectedDate, logs: [], limit: totalUnits, unitsName: unitsName))
        return days[days.count - 1]
    }
    
    var selectedDay: Day {

        for day in days {
            if day.date.startOfDay == selectedDate.startOfDay {
                return day
            }
        }

        if days.isEmpty {
            days = []
        }

        addDayToDays(day: Day(date: selectedDate, logs: [], limit: totalUnits, unitsName: unitsName))
        return days[days.count - 1]
    }
    
    var totalPoints: Decimal {
        var toReturn: Decimal = 0
        for day in days {
            if isValidDayForPoints(day: day) { // TODO: -
                toReturn += unitsProgressLeftPercentageForDay(day: day) * 100
            }
        }
        return toReturn
    }
    
    var currentLogs: [Log] {
        return currentDay.logs
    }
    
    var selectedLogs: [Log] {
        return selectedDay.logs
    }
    
    var isAtLimitForCurrentDay: Bool {
        return currentDay.units == totalUnits
    }
    
    var isAtLimitForSelectedDay: Bool {
        return selectedDay.units == totalUnits
    }
    
    func isAtLimitForDay(day: Day) -> Bool {
        return day.units == totalUnits
    }
    
    var currentDayIsValidDayForPoints: Bool {
        return currentDay.units == totalUnits
    }
    
    var selectedDayIsValidDayForPoints: Bool {
        return selectedDay.units == totalUnits
    }
    
    func isValidDayForPoints(day: Day) -> Bool {
        return !day.logs.isEmpty && !isOverLimitForDay(day: day) && day.date < Date().startOfDay
    }
    
    var isOverLimitForCurrentDay: Bool {
        return currentDay.units > totalUnits
    }
    
    var isOverLimitForSelectedDay: Bool {
        return selectedDay.units > totalUnits
    }
    
    func isOverLimitForDay(day: Day) -> Bool {
        return day.units > totalUnits
    }
    
    var lastDateWentOverFromCurrent: Date? {
        for day in days {
            if isOverLimitForDay(day: day) {
                let dayDifference = Calendar.current.dateComponents([.day], from: day.date, to: currentDay.date).day!
                if !(dayDifference < 0) {
                    return day.date
                }
            }
        }
        return nil
    }
    
    var lastDateWentOverFromSelected: Date? {
        for day in days {
            if isOverLimitForDay(day: day) {
                let dayDifference = Calendar.current.dateComponents([.day], from: day.date, to: selectedDay.date).day!
                if !(dayDifference < 0) {
                    return day.date
                }
            }
        }
        return nil
    }
    
    var daysSinceRelapseFromCurrentDate: Decimal {
        guard let date = lastDateWentOverFromCurrent else { return Decimal(Calendar.current.dateComponents([.day], from: creationDate, to: currentDay.date).day!) }
        return Decimal(Calendar.current.dateComponents([.day], from: date, to: currentDay.date).day!)
    }
    
    var daysSinceRelapseFromSelectedDate: Decimal? {
        guard let date = lastDateWentOverFromSelected else { return Decimal(Calendar.current.dateComponents([.day], from: creationDate, to: selectedDay.date).day!) }
        return Decimal(Calendar.current.dateComponents([.day], from: date, to: selectedDay.date).day!)
    }
    
    // MARK: - Add Days
    
    func addDayToDays(day: Day) {
        days.append(day)
        managedObject?.setValue(encodedDays, forKey: "days")
        try! context?.save()
    }
    
    func addLogToSelectedDay(log: Log) {
        selectedDay.logs.append(log)
        managedObject?.setValue(encodedDays, forKey: "days")
        try! context?.save()
    }
    
    func addLogToDay(day: Day, log: Log) {
        day.logs.append(log)
    }

    // MARK: - Category
    
    var categoryString: String {
        switch category {
        case .food:
            return "food"
        case .drug:
            return "drug"
        case .activity:
            return "activity"
        }
    }
    
    // MARK: - Timing
    
    var timingString: String {
        switch timing {
        case .daily:
            return "daily"
        case .weekly:
            return "weekly"
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        }
    }
    
    // MARK: - Coding
    
    func encode(with coder: NSCoder) {
        coder.encode(creationDate, forKey: "creationDate")
        coder.encode(categoryString, forKey: "categoryString")
        coder.encode(name, forKey: "name")
        coder.encode(unitsName, forKey: "unitsName")
        coder.encode(totalUnits, forKey: "totalUnits")
        coder.encode(timingString, forKey: "timingString")
        coder.encode(encodedDays, forKey: "days")
        coder.encode(iconName, forKey: "iconName")
    }
    
    // MARK: - Logs
    
    var encodedDays: Data? {
        let jsonEncoder = JSONEncoder()
        return try? jsonEncoder.encode(days)
    }
    
    // MARK: - Units
    
    var currentUnits: Decimal {
        return currentDay.units
    }
    
    var selectedUnits: Decimal {
        return selectedDay.units
    }
    
    func unitsForDay(day: Day) -> Decimal {
        return day.units
    }
    
    var currentUnitsLeft: Decimal {
        return -(currentDay.units - totalUnits)
    }
    
    var selectedUnitsLeft: Decimal {
        return -(selectedDay.units - totalUnits)
    }
    
    func unitsLeftForDay(day: Day) -> Decimal {
        return -(day.units - totalUnits)
    }

    var currentUnitsProgressPercentage: Decimal {
        return currentDay.units / totalUnits
    }
    
    var selectedUnitsProgressPercentage: Decimal {
        return selectedDay.units / totalUnits
    }
    
    func unitsProgressPercentageForDay(day: Day) -> Decimal {
        return day.units / totalUnits
    }
    
    var currentUnitsLeftProgressPercentage: Decimal {
        return currentDay.units != 0 ? currentDay.units / totalUnits : 1
    }
    
    var selectedUnitsLeftProgressPercentage: Decimal {
        return selectedDay.units != 0 ? selectedDay.units / totalUnits : 1
    }
    
    func unitsProgressLeftPercentageForDay(day: Day) -> Decimal {
        return day.units != 0 ? 1 - ( day.units / totalUnits ) : 1
    }

    var currentUnitsProgressString: String {

        if currentUnitsProgressPercentage == 1 {
            return "You Are At Your Limit"
        }

        return currentUnitsProgressPercentage < 1 ? "\(currentUnitsLeft) \(unitsName) Are Still Left" : "You Are Over By \(-currentUnitsLeft) \(unitsName)"
    }
    
    var selectedUnitsProgressPercentageString: String {

        if selectedUnitsProgressPercentage == 1 {
            return "You Are At Your Limit"
        }

        return selectedUnitsProgressPercentage < 1 ? "\(selectedUnitsLeft) \(unitsName) Are Still Left" : "You Are Over By \(-selectedUnitsLeft) \(unitsName)"
    }
}
