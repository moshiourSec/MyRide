//
//  ViewController.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/19/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RevealingSplashView
import Firebase
import SpriteKit

class HomeVC: UIViewController, Alertable {
    
    var tableViewActive: Bool = false
    var timer = Timer()
    var previous: String = ""
    
    @IBOutlet weak var viewForSwipe: UIView!
    var swipe: UISwipeGestureRecognizer!

    @IBOutlet weak var navigationView: RoundedShadowView!
    @IBOutlet weak var rounderShadowView: RoundedShadowView!
    @IBOutlet weak var destinationCircleView: CircleView!
    @IBOutlet weak var destinationTextField: UITextField!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionButton: RoundedShadowButton!
    @IBOutlet weak var centerMapButton: UIButton!
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    //var currentUserID = Auth.auth().currentUser?.uid
    var selectedItemPlacemark: MKPlacemark? = nil
    
    var route: MKRoute!
    

    var tableView = UITableView()

    var delegate: CenterVCDelegate?
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 10000
    
    //CLlocationManager manage locations. it can request authorization it can display the user location.

    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "carImagePng")!, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //var currentUserId = (Auth.auth().currentUser?.uid)!
        mapView.delegate = self
        destinationTextField.delegate = self
        checkLocationServices()
        
        DataService.instance.REF_DRIVERS.observe(.value, with: { (snapshot) in
            self.loadDriverAnnotationsFromFirebase()
        })
        
        
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(showMenu(sender:)))
        swipe.direction = .right
        viewForSwipe.addGestureRecognizer(swipe)
        
        
        // add lunchscreen animation
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        
        revealingSplashView.heartAttack = true // cancel animating
        
        UpdateService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripkey = tripDict["passengerKey"] as! String
                let acceptanceStatus = tripDict["tripIsAccepted"] as! Bool
                
                if acceptanceStatus == false {
                    if let currentuserId = Auth.auth().currentUser?.uid {
                        DataService.instance.isDriverAvailable(key: currentuserId, handler: { (available) in
                            if let available = available {
                                if available == true {
                                    let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                    let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                                    pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripkey)
                                    self.present(pickupVC!, animated: true, completion: nil)
                                    
                                }
                            }
                        })
                    }
                }
                
            }
        }
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let currentUserId = Auth.auth().currentUser?.uid {
            DataService.instance.isDriverAvailable(key: currentUserId, handler: { (status) in
                if status == false {
                    DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: "driverKey").value as? String == (Auth.auth().currentUser?.uid)! {
                                    let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                    let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                    
                                    // create a placemark
                                    let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                    
                                    self.dropPinFor(placemark: pickupPlacemark)
                                    self.Search_ARoute_forDestination_AndDrawApolyline(forMapItem: MKMapItem(placemark: pickupPlacemark))
                                }
                            }
                        }
                    })
                }
            })
            
            
        }

        
    }
    
    @objc func showMenu(sender: UISwipeGestureRecognizer) {
        delegate?.toggleLeftPanel()
    }
    
    // show slide menu
    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    @objc func update() {
        if destinationTextField.text == ""{
            animateTableView(shouldShow: false)
            print("Textfield empty")

        }
        else {
            performSearch()
            print("searching")
        }
    }
    
    
    func DisplayTableView(){
        if (destinationTextField != nil) {
            if Auth.auth().currentUser != nil {
                mapView.removeOverlays(mapView.overlays)
                
                tableView.frame = CGRect(x: 25, y: view.frame.height, width: rounderShadowView.frame.width, height: view.frame.height - ((navigationView.frame.height + rounderShadowView.frame.height) + 25))
                //tableView.backgroundColor = UIColor.white
                tableView.layer.cornerRadius = 5.0
                
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
                tableView.delegate = self
                tableView.dataSource = self
                
                tableView.tag = 18
                tableView.rowHeight = 60
                
                view.addSubview(tableView)
                animateTableView(shouldShow: true)
                
                // when start typing make destination circle view red color
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircleView.backgroundColor = UIColor.red
                    self.destinationCircleView.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
                })
                
                
            }
            
        }
    }

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            // Show alert instructing them how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // Show an alert letting them know what's up
            break
        case .authorizedAlways:
            break
        }
    }
    
    func loadDriverAnnotationsFromFirebase(){
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.hasChild("userIsDriver") {
                        if driver.hasChild("coordinate") {
                            if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                                if let driverDict = driver.value as? Dictionary<String, AnyObject> {
                                    let coordinateArray = driverDict["coordinate"] as! NSArray
                                    let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                    
                                    //print("\n \n \n \n Drivers lattitude \(coordinateArray[0]) and longitude \(coordinateArray[1])\n\n\n\n")
                                    
                                    let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                    
                                    var driverIsVisible: Bool {
                                        return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                            if let driverAnnotation = annotation as? DriverAnnotation {
                                                if driverAnnotation.key == driver.key {
                                                    driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                    return true
                                                }
                                            }
                                            return false
                                        })
                                    }
                                    
                                    if !driverIsVisible {
                                        self.mapView.addAnnotation(annotation)
                                    }
                                }
                            } else {
                                
                                for annotation in self.mapView.annotations {
                                    if annotation.isKind(of: DriverAnnotation.self) {
                                        if let annotation = annotation as? DriverAnnotation {
                                            if annotation.key == driver.key {
                                                self.mapView.removeAnnotation(annotation)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        })
    }

    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
    
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        // check if there is a trip coordinate to zoom or not 
                        if user.hasChild("tripCoordinate") {
                            self.zoom(fitAnnotationsFromMapView: self.mapView)
                            self.centerMapButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                        else {
                            self.centerViewOnUserLocation()
                            self.centerMapButton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })
        

        
    }
    @IBAction func actionButtonWasPressed(_ sender: Any) {
        UpdateService.instance.updateTripsWithCoordinatesUponRequest()
        actionButton.animateButton(shouldLoad: true, withMessage: nil)
        
        self.view.endEditing(true)
        destinationTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func menuButtonWasPressed(_ sender: Any) {
        
        delegate?.toggleLeftPanel()
    }


}



//// Extensions

extension HomeVC: CLLocationManagerDelegate {
    /*
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let region = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    */
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //annotation for driver
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        }
        // annotation for passenger address
        else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        }
            // annotation for destination address
        else if let annotation = annotation as? MKPointAnnotation {
            let identifier = "destination"
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
        return nil
    }
    
    // when the user/driver is in center the center button in hide 
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapButton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: self.route.polyline)
        lineRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 3
        
        shouldDisplayLoadingView(false)
        
        zoom(fitAnnotationsFromMapView: self.mapView)
        
        return lineRenderer
    }
    // Search places in mapkit
    
    func performSearch() {
        var current: String = ""
        current = destinationTextField.text!
        
        if previous != current {
            previous = current
            print("current value i: \(current)")
            print("previous  value i: \(previous)")
            matchingItems.removeAll()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = destinationTextField.text
            request.region = mapView.region  // it can search what is currently displayed on the map then other wards
            
            let search = MKLocalSearch(request: request)
            search.start { (response, error) in
                if error != nil {
                    self.showAlert(error.debugDescription)
                    print(error.debugDescription)
                }
                else if response!.mapItems.count == 0 {
                    self.showAlert("No results. Please try again with a valid address!!!")
                    print("no results")
                }
                else {
                    for mapItem in response!.mapItems {
                        self.matchingItems.append(mapItem as MKMapItem)
                        //self.textFieldDidBeginEditing(self.destinationTextField)
                        self.tableView.reloadData()
                        self.shouldDisplayLoadingView(false)
                        print("\n\n\n\n \(self.tableViewActive)\n\n\n")
                        if self.tableViewActive == false {
                            self.DisplayTableView()
                            self.tableViewActive = true
                            
                        }
                    }
                }
                
            }
        }
    }
    
    // give destination address annotation
    func dropPinFor(placemark: MKPlacemark) {
        
        selectedItemPlacemark = placemark
        
        for annotation in mapView.annotations{
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    // draw a line between current address and destination address
    
    func Search_ARoute_forDestination_AndDrawApolyline(forMapItem mapItem: MKMapItem) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapItem
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in // mkdirection response
            guard let response = response else {
                self.showAlert("no routes found!!")
                print(error.debugDescription)
                return
            }
            self.route = response.routes[0]
            //add polyline
            self.mapView.addOverlay(self.route!.polyline)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldDisplayLoadingView(false)
        }
    }
    
    // Zoom both current location and destination location
    
    func zoom(fitAnnotationsFromMapView mapView: MKMapView) {
        if mapView.annotations.count == 0 {
            return
        }
        
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
            
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0 , longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
}

// work with uitextfield
extension HomeVC: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if Auth.auth().currentUser != nil {
                startTimer()
                
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircleView.backgroundColor = UIColor.red
                    self.destinationCircleView.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
                })
                
            }
            else {
                view.endEditing(true)
                print("please log in or sign up to continue")
                let alert = UIAlertController(title: "MyRide", message: "Please signup or login to continue!!!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
/*
        if textField == destinationTextField {
            if Auth.auth().currentUser != nil {
                mapView.removeOverlays(mapView.overlays)
                
                tableView.frame = CGRect(x: 25, y: view.frame.height, width: rounderShadowView.frame.width, height: view.frame.height - ((navigationView.frame.height + rounderShadowView.frame.height) + 25))
                //tableView.backgroundColor = UIColor.white
                tableView.layer.cornerRadius = 5.0
                
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
                tableView.delegate = self
                tableView.dataSource = self
                
                tableView.tag = 18
                tableView.rowHeight = 60
                
                view.addSubview(tableView)
                animateTableView(shouldShow: true)
                
                // when start typing make destination circle view red color
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircleView.backgroundColor = UIColor.red
                    self.destinationCircleView.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
                })
                

            }
            else {
                view.endEditing(true)
                print("please log in or sign up to continue")
                let alert = UIAlertController(title: "MyRide", message: "Please signup or login to continue!!!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }

        }
        */
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            timer.invalidate()
            // perform search
            if textField.text == "" {
                view.endEditing(true)
                animateTableView(shouldShow: false)

            }
            else {
                performSearch()
                shouldDisplayLoadingView(true)
            }

            
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircleView.backgroundColor = UIColor.lightGray
                    self.destinationCircleView.borderColor = UIColor.darkGray
                })
            }
        }
        timer.invalidate()
    }
    
    /*
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == destinationTextField {
                animateTableView(shouldShow: true)
                //performSearch()
                print("Result is here")
            
        }

       return true
    }
    */
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        
    DataService.instance.REF_USERS.child((Auth.auth().currentUser?.uid)!).child("tripCoordinate").removeValue()
        
        mapView.removeOverlays(mapView.overlays)
        
        for annotation in mapView.annotations {
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
            else if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        
        centerViewOnUserLocation()
        return true
    }
    
    func animateTableView(shouldShow: Bool) {
        
        let statusBarHeight = UIApplication.shared.statusBarFrame.height

        if shouldShow {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 25, y: (self.navigationView.frame.height + self.rounderShadowView.frame.height) + 10 + statusBarHeight, width: self.rounderShadowView.frame.width, height: self.view.frame.height - ((self.navigationView.frame.height + self.rounderShadowView.frame.height) + 10))
            })
        }
        else {
            tableViewActive = false
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 25, y: self.view.frame.height, width: self.rounderShadowView.frame.width, height: self.view.frame.height - ((self.navigationView.frame.height + self.rounderShadowView.frame.height) + 10))
            }, completion: { (finished) in
                for subView in self.view.subviews {
                    if subView.tag == 18 {
                        
                        subView.removeFromSuperview()
                    }
                }
            })
        }
        
    }
 
    
}

// work with HomeVC table view

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title // MKplace mark, it has all information of address
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        shouldDisplayLoadingView(true)
        
        timer.invalidate()
        
        let passengerCoordinate =  locationManager.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: (Auth.auth().currentUser?.uid)!)
        mapView.addAnnotation(passengerAnnotation)
        
        // display address in the text field
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        // update destination coordinate into the firebase
        
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USERS.child((Auth.auth().currentUser?.uid)!).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
 
        //
        dropPinFor(placemark: selectedMapItem.placemark)
        Search_ARoute_forDestination_AndDrawApolyline(forMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
        destinationTextField.endEditing(true)
        print("selected")
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
        
    }
 
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)

        }
    }
    
}

