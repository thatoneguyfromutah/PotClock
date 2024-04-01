//
//  PlacesViewController.swift
//  PotClock
//
//  Created by Chase Angelo Giles on 3/31/24.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager: CLLocationManager?

    var limitsTableViewController: LimitsTableViewController {
        return (tabBarController!.viewControllers!.first as! UINavigationController).viewControllers.first as! LimitsTableViewController
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestLocationAccess()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.mapView.removeAnnotations(self.mapView.annotations)
        centerUserLocation()
    }
    
    // MARK: - Core Location
    
    func requestLocationAccess() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    // MARK: - Maps
    
    func centerUserLocation() {
        
        let coordinates = locationManager?.location?.coordinate
        
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: coordinates?.latitude ?? 0, longitude: coordinates?.longitude ?? 0), span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 180))

        mapView.setRegion(region, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func didTapList(_ sender: UIBarButtonItem) {
        
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
                            
                            let annotation = MKPointAnnotation()

                            annotation.title = limit.name
                            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                            annotations.append(annotation)
                        }
                    }
                }
                
                self.mapView.addAnnotations(annotations)
                
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
