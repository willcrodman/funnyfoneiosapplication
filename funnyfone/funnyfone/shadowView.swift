//
//  shadowView.swift
//  funnyfone
//
//  Created by William Rodman on 6/12/17.
//  Copyright © 2017 William Rodman. All rights reserved.
//

import UIKit

class shadowView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.shadowRadius = 2.0
        layer.shadowOffset = CGSize(width: 0, height: 1.5)
        layer.shadowOpacity = 0.75
    }
}
