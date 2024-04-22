//
//  LimitLog.swift
//  PotClock
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
    var imageData: Data?
    var latitude: Double?
    var longitude: Double?
    
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    // MARK: - Initialization
    
    init(amount: Decimal, date: Date) {
        self.amount = amount
        self.date = date
    }
    
    init(amount: Decimal, date: Date, image: UIImage) {
        self.amount = amount
        self.date = date
        self.imageData = UIImage().resizeImage(image: image, newWidth: 1248).jpegData(compressionQuality: 0.42)
    }
    
    init(amount: Decimal, date: Date, imageData: Data) {
        self.amount = amount
        self.date = date
        self.imageData = imageData
    }
    
    init(amount: Decimal, date: Date, latitude: Double, longitude: Double) {
        self.amount = amount
        self.date = date
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(amount: Decimal, date: Date, image: UIImage, latitude: Double, longitude: Double) {
        self.amount = amount
        self.date = date
        self.imageData = UIImage().resizeImage(image: image, newWidth: 1248).jpegData(compressionQuality: 0.42)
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(amount: Decimal, date: Date, imageData: Data, latitude: Double, longitude: Double) {
        self.amount = amount
        self.date = date
        self.imageData = imageData
        self.latitude = latitude
        self.longitude = longitude
    }
    
    required convenience public init?(coder: NSCoder) {
                
        guard let amountString = coder.decodeObject(forKey: "amount") as? String,
              let amount = Decimal(string: amountString),
              let date = coder.decodeObject(forKey: "date") as? Date
        else { return nil }
        
        if let imageData = coder.decodeObject(forKey: "imageData") as? Data,
           let latitude = coder.decodeObject(forKey: "latitude") as? Double,
           let longitude = coder.decodeObject(forKey: "longitude") as? Double {
            
            self.init(amount: amount, date: date, imageData: imageData, latitude: latitude, longitude: longitude)
            
            return
        }
        
        if let imageData = coder.decodeObject(forKey: "imageData") as? Data {
            
            self.init(amount: amount, date: date, imageData: imageData)
            
            return
        }
        
        if let latitude = coder.decodeObject(forKey: "latitude") as? Double,
           let longitude = coder.decodeObject(forKey: "longitude") as? Double {
            
            self.init(amount: amount, date: date, latitude: latitude, longitude: longitude)
            
            return
        }
        
        self.init(amount: amount, date: date)
    }
    
    // MARK: - Coding
    
    public func encode(with coder: NSCoder) {
        coder.encode(amount, forKey: "amount")
        coder.encode(date, forKey: "date")
        coder.encode(imageData, forKey: "imageData")
        coder.encode(latitude, forKey: "latitude")
        coder.encode(longitude, forKey: "longitude")
    }
}

// MARK: - Extensions

extension UIImage {
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.draw(in: CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
