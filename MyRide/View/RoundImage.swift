//
//  RoundImage.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/19/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit

class RoundImage: UIImageView {

    override func awakeFromNib() {
        setUpView()
    }
    
    func setUpView(){
        self.layer.cornerRadius = self.frame.width/2
        self.clipsToBounds = true
    }

}
