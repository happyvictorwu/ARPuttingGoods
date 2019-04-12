//
//  CustomButton.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import UIKit

class CustomButton: UIButton {
    
    override var isSelected: Bool {
        
        didSet {
            if isSelected {
                layer.borderColor = UIColor.yellow.cgColor
                layer.borderWidth = 3
            } else {
                layer.borderWidth = 0
            }
        }
        
    }
}
