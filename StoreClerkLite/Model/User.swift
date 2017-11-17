//
//  User.swift
//  StoreClerkLite
//
//  Created by Administrator on 10/19/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

public class User: NSObject {
    let firstname: String?
    let lastname: String?
    let base64QRCode: String?
    
    struct UserKey {
        static let firstnameKey = "nameFirst"
        static let lastnameKey = "nameLast"
        static let base64QRCodeKey = "qrCodeBase64"
    }
    
    init?(_ json: JSON) {
        firstname = json["user"][UserKey.firstnameKey].stringValue
        lastname = json["user"][UserKey.lastnameKey].stringValue
        base64QRCode = json[UserKey.base64QRCodeKey].stringValue
        
        super.init()
    }
}

