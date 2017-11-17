//
//  Style.swift
//  VALotteryPlay
//
//  Created by Yuriy Berdnikov on 1/11/17.
//  Copyright © 2017 ATM. All rights reserved.
//

import Foundation
import UIKit

struct Style {
    struct Colors {
        static let blackSemiTransparentColor = UIColor(white: 0, alpha: 0.7)
        static let blackBlueColor = UIColor.rgb(31, green: 33, blue: 36)
        static let pureYellowColor = UIColor.rgb(255, green: 249, blue: 0)
        static let darkLimeGreenColor = UIColor.rgb(0, green: 151, blue: 7)
        static let salemColor = UIColor.rgb(31, green: 123, blue: 76)
        static let softYellowColor = UIColor.rgb(244, green: 233, blue: 182)
        
        static let mainOrangeColor = UIColor(hexString: "#FF6600")
        static let mainLightOrangeColor = UIColor.rgb(242, green: 163, blue: 58)
    }
    
    struct Font {
        static func boldFontWithSize(size: CGFloat) -> UIFont {
            return UIFont(name:"HelveticaNeue-Bold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
        }
        
        static func fontWithSize(size: CGFloat) -> UIFont {
            return UIFont(name:"HelveticaNeue", size: size) ?? UIFont.systemFont(ofSize: size)
        }
    }
}
