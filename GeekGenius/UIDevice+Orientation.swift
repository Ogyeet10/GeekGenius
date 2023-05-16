//
//  UIDevice+Orientation.swift
//  GeekGenius
//
//  Created by Aidan Leuenberger on 5/6/23.
//

import UIKit

extension UIDevice {
    static func setOrientation(_ orientation: UIInterfaceOrientation) {
        guard self.current.responds(to: #selector(setValue(_:forKey:))) else {
            return
        }
        self.current.setValue(orientation.rawValue, forKey: "orientation")
    }
}

