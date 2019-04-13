//
//  Alertable.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/27/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit

protocol Alertable {}

extension Alertable where Self: UIViewController {
    
    func showAlert(_ msg: String) {
        let alertController = UIAlertController(title: "Error!", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        /*
        let action = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
            self.shouldDisplayLoadingView(false)
        }) */
        alertController.addAction(action)
        
        present(alertController, animated: true, completion: nil)
    }
}
