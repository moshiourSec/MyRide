//
//  ContainerVC.swift
//  MyRide
//
//  Created by MOSHIOUR on 3/20/19.
//  Copyright © 2019 moshiour. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState{
    case collapsed
    case leftPanelExpanded
}

enum ShowWhichVC{
    case homeVC
}

var showVC: ShowWhichVC = .homeVC



class ContainerVC: UIViewController {
    
    var homeVC: HomeVC!
    var leftVC: LeftSidePanelVC!
    var centerController: UIViewController!
    var currentState: SlideOutState = .collapsed {
        didSet {
            let showShadow = (currentState != .collapsed)
            
            ShowShadowForCenterViewController(status: showShadow)
        }
    }
    
    var isHidden = false
    let centerPanelExpandedOffset: CGFloat = 160
    
    var tap: UITapGestureRecognizer!
    var swipe: UISwipeGestureRecognizer!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initCenter(screen: showVC)
    }
    
    func initCenter(screen: ShowWhichVC){
        var presentingController: UIViewController
        
        showVC = screen
        
        if homeVC == nil {
            homeVC = UIStoryboard.homeVC()
            homeVC.delegate = self
        }
        presentingController = homeVC
        
        if let con = centerController{
            con.view.removeFromSuperview()
            con.removeFromParent()
            
        }
        centerController = presentingController
        view.addSubview(centerController.view)
        addChild(centerController)
        centerController.didMove(toParent: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return isHidden
    }

}


extension ContainerVC: CenterVCDelegate {
    func toggleLeftPanel() {
        let notAlreadyExpanded = (currentState != .leftPanelExpanded)
        
        if notAlreadyExpanded {
            addLeftPanelViewController()
        }
        animateLeftPanel(shouldExpand: notAlreadyExpanded)
    }
    
    func addLeftPanelViewController() {
        if leftVC == nil {
            leftVC = UIStoryboard.leftViewController()
            
            addChildSidePanelViewController(leftVC!)
        }
    }
    
    func addChildSidePanelViewController(_ sidePanelController: LeftSidePanelVC) {
        view.insertSubview(sidePanelController.view, at: 0)
        addChild(sidePanelController)
        sidePanelController.didMove(toParent: self)
    }
    
    @objc func animateLeftPanel(shouldExpand: Bool) {
        //
        if shouldExpand {
            isHidden = !isHidden
            animateStatusBar()
            setUpWhiteCoverView()
            
            currentState = .leftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandedOffset)
        }
        else {
            isHidden = !isHidden
            animateStatusBar()
            hideWhiteCoverView()

            animateCenterPanelXPosition(targetPosition: 0) { (finished) in
                self.currentState = .collapsed
                self.leftVC = nil
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
            
        }, completion: completion)
    }
    
    func animateStatusBar() {
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func setUpWhiteCoverView() {
        
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        
        self.centerController.view.addSubview(whiteCoverView)
        
        whiteCoverView.fadeTo(alphaValue: 0.75, withDuration: 0.2)
        /*
        UIView.animate(withDuration: 0.2) {
            whiteCoverView.alpha = 0.75
        }
        */
        swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExpand:)))
        swipe.direction = .left
        self.centerController.view.addGestureRecognizer(swipe)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExpand:)))
        tap.numberOfTapsRequired = 1
        
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func ShowShadowForCenterViewController(status: Bool ) {
        
        if status == true {
            centerController.view.layer.shadowOpacity = 0.6
        }
        else{
            centerController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func hideWhiteCoverView() {
        
        centerController.view.removeGestureRecognizer(tap)
        
        for subView in self.centerController.view.subviews {
            if subView.tag == 25 {
                
                UIView.animate(withDuration: 0.2, animations: {
                    subView.alpha = 0.0
                }, completion: { (finished) in
                    subView.removeFromSuperview()
                })
                
            }
        }
    }
    
    
}



private extension UIStoryboard {
    // using class because we want his to be able to be overridden and modified by this class
    class func mainStoryBoard() -> UIStoryboard{
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    class func leftViewController() -> LeftSidePanelVC?{
        return mainStoryBoard().instantiateViewController(withIdentifier: "LeftSidePanelVC") as? LeftSidePanelVC
    }
    
    class func homeVC() -> HomeVC? {
        return mainStoryBoard().instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
    }
}
