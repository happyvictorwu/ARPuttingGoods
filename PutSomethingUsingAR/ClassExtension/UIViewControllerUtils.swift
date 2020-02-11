//
//  UIViewControllerUtils.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import UIKit

extension UIViewController {
    var viewCenter: CGPoint {
        let screenSize = view.bounds
        return CGPoint(x: screenSize.width / 2.0, y: screenSize.height / 2.0)
    }
}
