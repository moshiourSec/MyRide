//
//  LeftSidePanelVC.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/20/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit
import Firebase

class LeftSidePanelVC: UIViewController {
    
    let appDelegate = AppDelegate.getAppDelegate()

    //let currentUserId = Auth.auth().currentUser?.uid
    @IBOutlet weak var loginOutBtn: UIButton!
    @IBOutlet weak var userAccountTypeLbl: UILabel!
    @IBOutlet weak var userEmailLbl: UILabel!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var pickupModeLbl: UILabel!
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pickupModeSwitch.isOn = false
        pickupModeSwitch.isHidden = true
        pickupModeLbl.isHidden = true

        observePassengersAndDrivers()
        
        // when there is no user or user dont signup or login

        if Auth.auth().currentUser == nil {
            
            userEmailLbl.text = ""
            userAccountTypeLbl.text = ""
            userImageView.isHidden = true
            loginOutBtn.setTitle("Sign Up / Login", for: .normal)
            
        }
        else {
            userEmailLbl.text = Auth.auth().currentUser?.email
            userAccountTypeLbl.text = ""
            userImageView.isHidden = false
            loginOutBtn.setTitle("Logout", for: .normal)

        }
        
    }
    
    // observe either a passenger or a driver
    func observePassengersAndDrivers() {
        
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "PASSENGER"
                        
                    }
                }
            }
        })
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountTypeLbl.text = "DRIVER"
                        self.pickupModeSwitch.isHidden = false
                        
                        let switchStatus = snap.childSnapshot(forPath: "isPickupModeEnabled").value as! Bool
                        self.pickupModeSwitch.isOn = switchStatus
                        if self.pickupModeSwitch.isOn == true{
                            self.pickupModeLbl.text = "PICKUP MODE ENABLED"
                        }else{
                            self.pickupModeLbl.text = "PICKUP MODE DISABLED"
                        }
                        self.pickupModeLbl.isHidden = false
                    }
                }
            }
        })
    }
    
    
    @IBAction func switchBtnToggled(_ sender: Any) {
        if pickupModeSwitch.isOn {
            pickupModeLbl.text = "PICKUP MODE ENABLED"
            //appDelegate.menuContainerVC.toggleLeftPanel()
       
            DataService.instance.REF_DRIVERS.child((Auth.auth().currentUser?.uid)!).updateChildValues(["isPickupModeEnabled": true])
            
        }
        else {
            pickupModeLbl.text = "PICKUP MODE DISABLED"
            appDelegate.menuContainerVC.toggleLeftPanel()
        DataService.instance.REF_DRIVERS.child((Auth.auth().currentUser?.uid)!).updateChildValues(["isPickupModeEnabled": false])
        }
    }
    
    
    @IBAction func signUpLoginButtonWasPressed(_ sender: Any) {
        
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
            
        }
        else {
            do {
                try Auth.auth().signOut()
                
                userEmailLbl.text = ""
                userAccountTypeLbl.text = ""
                userImageView.isHidden = true
                pickupModeLbl.text = ""
                pickupModeSwitch.isHidden = true
                loginOutBtn.setTitle("Sign Up / Login", for: .normal)
                
            }catch (let error) {
                print(error)
            }
        }
        

    }


}
