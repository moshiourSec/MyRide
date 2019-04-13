//
//  PickupVC.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/31/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class PickupVC: UIViewController {

    @IBOutlet weak var pickupMapView: RoundedMapView!
    
    var pickupCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    
    var regionRadius: CLLocationDistance = 2000.0
    var pin: MKPlacemark? = nil
    var locationPlacemark: MKPlacemark!
    
   // var currentUserId = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        pickupMapView.delegate = self
        
        locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        
        hidePickupVCWithAcceptanceOrCancel()
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String) {
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    
    func hidePickupVCWithAcceptanceOrCancel() {
        DataService.instance.REF_TRIPS.child(passengerKey).observe(.value, with: { (tripSnapshot) in
            if tripSnapshot.exists() {
                // check for acceptance
                if tripSnapshot.childSnapshot(forPath: "tripIsAccepted").value as? Bool == true {
                    self.dismiss(animated: true, completion: nil)
                }
            }else {
                //dismiss the view
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func acceptTripButtonPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: (Auth.auth().currentUser?.uid)!)
        presentingViewController?.shouldDisplayLoadingView(true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}

//Extensions

extension PickupVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "destinationAnnotation")
        
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        
        pickupMapView.setRegion(coordinateRegion, animated: true)
        
        
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        
        pin = placemark
        
        for annotation in pickupMapView.annotations {
            pickupMapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        pickupMapView.addAnnotation(annotation)
    }
}
