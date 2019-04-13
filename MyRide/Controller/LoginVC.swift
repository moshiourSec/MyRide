//
//  LoginVC.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/21/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController, UITextFieldDelegate, Alertable {

    @IBOutlet weak var loginBackground: UIImageView!
    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var emailTextField: RoundedTextField!
    @IBOutlet weak var passwordTextField: RoundedTextField!
    
    @IBOutlet weak var signUpLoginBtn: RoundedShadowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self

        // Do any additional setup after loading the view.
        view.bindToKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(screenTap(sender:)))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func screenTap(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func signUpLoginBtnwasPressed(_ sender: Any) {
        
        if emailTextField.text != nil && passwordTextField.text != nil {
            signUpLoginBtn.animateButton(shouldLoad: true, withMessage: nil)
            //shouldDisplayLoadingView(true)
            self.view.endEditing(true)
            
            
            /// this is the function that logs in a urrently existing user
            if let email = emailTextField.text , let password = passwordTextField.text {
                // this is basically if we pass an email and pass if we get an error back if there is an issue completion hanlder can handle it
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    // if user already exist
                    if error == nil {
                        if let user = user {
                            if self.segmentedControl.selectedSegmentIndex == 0 {
                                let userData = ["provider": user.user.providerID] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.user.uid , userData: userData, isDriver: false)
                            }
                            else {
                               // when user is a driver
                                let userData = ["provider": user.user.providerID, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false] as [String: Any]
                                DataService.instance.createFirebaseDBUser(uid: user.user.uid, userData: userData, isDriver: true)
                            }
                        }
                        print("\n\n\n\n*******Email authentication successful*******\n\n\n")
                        self.dismiss(animated: true, completion: nil)
                    }
                    // if there is no existing user found then it can create a user
                    else {
                        /*
                        let errorCode = AuthErrorNameKey
                        switch errorCode {
                        case "errorCodeEmailAlreadyInUse":
                            print("Email address already exist")
                        case "errorCodeWrongPassword":
                            print("Invalid Password")
                            
                        default:
                            print("An unexpected error occured")
                        }
                         */
                        
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                //self.shouldDisplayLoadingView(true)
                                self.showAlert("Invalid username or password! please try again!!!")

                                
                            }
                            // if there is no error
                            
                            else {
                                if let user = user {
                                    if self.segmentedControl.selectedSegmentIndex == 0 {
                                        let userData = ["provider": user.user.providerID] as [String: Any]
                                        DataService.instance.createFirebaseDBUser(uid: user.user.uid, userData: userData, isDriver: false)
                                    }
                                        // what if selected the driver
                                    else {
                                        let userData = ["provider": user.user.providerID, "userIsDriver": true, "isPickupModeEnabled": false, "driverIsOnTrip": false] as [String: Any]
                                         DataService.instance.createFirebaseDBUser(uid: user.user.uid, userData: userData, isDriver: true)
                                        
                                    }
                                }
                                
                                print("\n\n\n****Successfully created a new user with firebase account****\n\n\n")
                                self.dismiss(animated: true, completion: nil)
                            }
                            
                        })
                    }
                })
                /// end
                
            }
            
        }
        
        else {
            print("One of them is null")
        }
        
    }
    

}
