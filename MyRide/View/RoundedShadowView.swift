//
//  RoundedShadowView.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/19/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {
    
    override func awakeFromNib() {
        setUpView()
    }

    func setUpView(){
        self.layer.cornerRadius = 5.0
        self.layer.shadowOpacity = 0.3
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        
    }

}
