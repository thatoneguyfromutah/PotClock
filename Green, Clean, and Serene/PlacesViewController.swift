//
//  PlacesViewController.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 3/31/24.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, MKMapViewDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    
    var limitsTableViewController: LimitsTableViewController {
        return (tabBarController!.viewControllers!.first as! UINavigationController).viewControllers.first as! LimitsTableViewController
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        centerUserLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.mapView.removeAnnotations(self.mapView.annotations)
    }

    // MARK: - Maps
    
    func centerUserLocation() {
        
        let coordinates = limitsTableViewController.locationManager?.location?.coordinate
        
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinates?.latitude ?? 0, longitude: coordinates?.longitude ?? 0), span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180))

        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func didTapList(_ sender: UIBarButtonItem) {
        
        if limitsTableViewController.limits.isEmpty {
            
            let alertController = UIAlertController(title: "No Limits", message: "There are no limits saved to view.", preferredStyle: .alert)

            let doneAction = UIAlertAction(title: "Done", style: .cancel)
            alertController.addAction(doneAction)
            
            present(alertController, animated: true)
            
            return
        }
        
        let alertController = UIAlertController(title: "Which Limit Would You Like To View?", message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        
        for limit in limitsTableViewController.limits {
            
            let alertAction = UIAlertAction(title: "\(limit.name) - \(limit.categoryString.capitalized)", style: .default) { _ in
                
                self.mapView.removeAnnotations(self.mapView.annotations)
                
                var annotations: [MKPointAnnotation] = []
                
                for day in limit.days {
                    for log in day.logs {
                        if let latitude = log.latitude,
                           let longitude = log.longitude {
                            
                            let time = Calendar.current.dateComponents([.month, .day, .year, .hour, .minute], from: log.date)
                            let annotation = MKPointAnnotation()
                            annotation.title = limit.name
                            annotation.subtitle = "\(time.month!)/\(time.day!)/\(time.year!) - \(time.hour == 0 ? 12 : time.hour! > 12 ? time.hour! - 12 : time.hour!):\(time.minute! < 10 ? "0" : "")\(time.minute!) \(time.hour! >= 12 ? "PM" : "AM")"
                            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            
                            annotations.append(annotation)
                        }
                    }
                }
                
                self.mapView.addAnnotations(annotations)
                
                if annotations.count == 0 {
                    
                    let noItemsAlertController = UIAlertController(title: "No Locations", message: "\(limit.name) does not have any location data.", preferredStyle: .alert)
                    
                    let okayAction = UIAlertAction(title: "Done", style: .default)
                    noItemsAlertController.addAction(okayAction)
                    
                    self.present(noItemsAlertController, animated: true)
                    
                    return
                }
            }
            alertAction.setValue(UIImage(systemName: limit.iconName), forKey: "image")
            alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            alertController.addAction(alertAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @IBAction func didTapUserLocation(_ sender: UIBarButtonItem) {
        centerUserLocation()
    }
}
