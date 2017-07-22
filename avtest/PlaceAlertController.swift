//
//  PlaceAlertController.swift
//  avtest
//
//  Created by vrqq on 30/05/2017.
//  Copyright © 2017 vrqq. All rights reserved.
//

import UIKit

class PlaceAlertController : UIAlertController {
    var projtext : UITextView
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        projtext = UITextView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        let controller = UIViewController()
        controller.view = projtext
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setValue(controller, forKey: "contentViewController")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
