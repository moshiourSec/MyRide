//
//  CircleView.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/19/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit

class CircleView: UIView {
    // like a variable and interface builder allow us to modify color
    @IBInspectable var borderColor: UIColor? {
        didSet{
            setUpView()
        }
    }
    
    override func awakeFromNib() {
        setUpView()
    }

    func setUpView(){
        self.layer.cornerRadius = self.frame.width/2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = borderColor?.cgColor
    }
}