//
//  RoundedTextField.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/21/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit

class RoundedTextField: UITextField {
    
    var textRectOffset: CGFloat = 20

    override func awakeFromNib() {
        setUpViews()
    }
    
    func setUpViews() {
        
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 0)
    }
    
    // Editable text
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: 10, dy: 0)
    }

}
