//
//  RoundedMapView.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/31/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit
import MapKit

class RoundedMapView: MKMapView {
    
    override func awakeFromNib() {
        setUpViews()
    }

    func setUpViews() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
        
        
    }

}
