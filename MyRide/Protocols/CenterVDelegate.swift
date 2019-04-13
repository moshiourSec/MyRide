//
//  CenterVDelegate.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/20/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool)
}
