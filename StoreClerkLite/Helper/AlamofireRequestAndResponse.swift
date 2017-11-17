//
//  AlamofireRequestAndResponse.swift
//  VALotteryPlay
//
//  Created by Nyamsuren Enkhbold on 10/30/16.
//  Copyright © 2016 ATM. All rights reserved.
//

import UIKit
import Alamofire
import ReachabilitySwift
import SwiftyJSON

class AlamofireRequestAndResponse: NSObject {
    
    
    var serverBaseUrl = ""
    var specialId: Int!
    var shouldRestart = false
    var networkStatus = "Unknown"

//    var token: String = ""
//    var playToken : String = ""
//    var brandLicenseCode : String = ""
//    var FBAuthorizationCode : String = ""

    var userLicense: String = ""
    var authorityLicense : String = ""
    var fbBearerToken : String = ""
    var userAccessToken = ""

    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    let reachability = Reachability()!
    
    class var sharedInstance: AlamofireRequestAndResponse {
        struct Static {
            static let instance: AlamofireRequestAndResponse = AlamofireRequestAndResponse()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        self.getToken()
        self.startReachability()
        
//        AFNetworkReachabilityManager.shared().setReachabilityStatusChange { (status: AFNetworkReachabilityStatus) -> Void in
//            switch status {
//            case .unknown:          self.networkStatus = "Unknown"
//            case .notReachable:     self.networkStatus = "Not Connected"
//            case .reachableViaWWAN: self.networkStatus = "WWAN"
//            case .reachableViaWiFi: self.networkStatus = "WiFi"
//            }
//        }
//        AFNetworkReachabilityManager.shared().startMonitoring()
    }

    private func startReachability() {
        
        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    print("Reachable via WiFi")
                    self.networkStatus = "WiFi"
                }
                else if reachability.isReachableViaWWAN {
                    print("Reachable via WWAN")
                    self.networkStatus = "WWAN"
                }
                else {
                    print("Reachable via Cellular")
                    self.networkStatus = "Cellular"
                }
            }
        }
       
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            self.networkStatus = "Not Connected"
            DispatchQueue.main.async {
                print("Not reachable")
            }
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    fileprivate func getToken() {
        if (self.config.getValue("devEndpoint", fromStore: "settings") as! Bool) {
            self.userLicense = config.getValue("userLicenseDev", fromStore: "settings") as! String
            self.authorityLicense = config.getValue("authorityLicenseDev", fromStore: "settings") as! String
            self.serverBaseUrl = config.getValue("serverBaseURLDev", fromStore: "settings") as! String
            self.fbBearerToken = config.getValue("fbBearerTokenDev", fromStore: "settings") as! String
            self.userAccessToken = config.getValue("fbAccessTokenDev", fromStore: "settings") as! String
        } else {
            self.userLicense = config.getValue("userLicenseDemo", fromStore: "settings") as! String
            self.authorityLicense = config.getValue("authorityLicenseDemo", fromStore: "settings") as! String
            self.serverBaseUrl = config.getValue("serverBaseURLDemo", fromStore: "settings") as! String
            self.fbBearerToken = config.getValue("fbBearerTokenDemo", fromStore: "settings") as! String
            self.userAccessToken = config.getValue("fbAccessTokenDemo", fromStore: "settings") as! String
        }
    }
    
    // ********************************* //
    // get hockey app sdk id from server
    // ********************************* //
    
    func getHockeyAppID(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/admin/clerk/config"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Accept": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // facebook authorize code verify
    // ********************************* //
    
    func verifyFBAuthCode(_ params: [String : Any], authCode : String, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/user/fbaccountkit/login"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Authorization": "Bearer " + authCode,
            "Content-Type": "application/json",
            "Content-Length" : "0"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // facebook authorize code verify
    // ********************************* //
    
    func logoutFBFromServer(_ accessToken: String, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/user/fbaccountkit/logout"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Authorization": "Bearer " + accessToken,
            "Content-Type": "application/json",
            "Content-Length" : "0"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // refund with QRCode
    // ********************************* //
    
    func refundCompleteWithQRCode(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/shopping/entity/refund"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json",
            "Content-Length" : "0"
        ]
        
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // register api after login via FB
    // ********************************* //
    
    func registerWithUserData(_ params: [String : Any], accessToken : String, success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/user/clerk/create"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + accessToken,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // get game lists
    // ********************************* //
    
    func getAllGameList(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v2/games/display"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json",
            "Content-Length" : "0"
        ]
        
        Alamofire.request(url, method: .get, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // get bar chat data from server
    // ********************************* //
    
    func getBarChartReport(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/admin/v1/reports/user/panels/byday"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json",
            "Content-Length" : "0"
        ]
        
        Alamofire.request(url, method: .get, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // get retailer lists
    // ********************************* //
    
    func getRetailersWithLocation(_ params: NSDictionary, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/retailers/display/bylocation"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-PlayerLicenseCode": self.userLicense,
            "Lazlo-BrandLicenseCode": "n1oJ6u4cKeQwCvGg5ZrxHJaMOoQ=:LJBVQWSAQFD8CVEG386UZEV5HTR3ELUSA5E5EFHFYEV99YG68F3Q1EQH78MQ7DDQQZ1A7GRE6TFRUJRV6NRRGJUC6NTXTDJC6NWRS4VB6NRXYGFQ6GS3HARV6MERTA",
            "Content-Type": "application/json",
            "Content-Length" : "0"
        ]
        
        Alamofire.request(url, method: .post, parameters: params as? Parameters, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
            
        }
    }
    
    // ********************************* //
    // checkout pending api
    // ********************************* //
    
    func checkoutPendingWithCode(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/shopping/checkout/complete/pending/lite"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json"
        ]

        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
            
        }
        
    }
    
    // ********************************* //
    // checkout pending with qrcode value
    // ********************************* //
    
    func checkoutPendingWithQRCode(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v3/shopping/checkout/complete/pending"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json"
        ]

        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
            
        }
        
    }
    
    // ********************************* //
    // checkout complete api
    // ********************************* //
    
    func checkoutCompleteWithLicenseCode(_ params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping ([String: Any]) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v2/shopping/checkout/complete"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    failure(organisationInfo)
                }
                print(error)
                
            }
            
        }
        
    }
    
    // ********************************* //
    // get applied amount api
    // ********************************* /
    
    func getAppliedAmountWithLicenseCode(_ licenseCode: String?, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        guard let code = licenseCode else { return }
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/claim/giftcard/claim/pending/\(code)"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // accept applied amount api
    // ********************************* /
    
    func acceptAppliedAmount(_ correlationRefId: String!, params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/claim/giftcard/claim/complete"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Lazlo-CorrelationRefId": correlationRefId,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON { (response) in
            switch response.result {
            case .success:
                success([:])
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    
    
    // ********************************* //
    // proximity upload api
    // ********************************* //
    
    func getProximityUrlData(_ params: NSDictionary, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/shopping/proximity/upload/url"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }

    // ********************************* //
    // proximity upload using blob api
    // ********************************* //
    
    func proximityUploadWithBLEBlobData(_ toStorage: String, data: Data, success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        
        self.getToken()
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Content-Type": "gzip",
            "x-ms-blob-type": "BlockBlob"
        ]
        
        Alamofire.upload(data, to: toStorage, method: .put, headers: headers).validate(statusCode: 200..<300).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let utf8Text = String(data: data, encoding: .utf8) {
                    let organisationInfo = JSONHelper.JSONParseArray(utf8Text)
                    success(organisationInfo)
                }
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // store locator api
    // ********************************* //
    func loadStores(_ latitude: Double!, longitude: Double!, completionHandler: @escaping (_ stores: [Store]?, _ error: Error?) -> Void) {
        guard let latitude = latitude, let longitude = longitude else { return }
        
        self.getToken()
        let uuid = UUID().uuidString
        let url = self.serverBaseUrl + "/api/v2/retailers/display/bylocation/\(uuid)/\(latitude)/\(longitude)"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-PlayerLicenseCode": self.userLicense,
            "Content-Type": "application/json"
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200 ..< 300).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var stores: [Store] = []
                for (_, subJson) in json["data"] {
                    if let store = Store(subJson) {
                        stores.append(store)
                    }
                }
                completionHandler(stores, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    // ********************************* //
    // coupon claim api
    // ********************************* //
    
    func claimWithCode(_ code: String!, completionHandler: @escaping (_ correlationRefId: String?, _ licenseCode: String?, _ amount: Float?, _ error: Error?) -> Void) {
        guard let licenseCode = code else { return }
        
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/claim/coupon/claim/pending/\(licenseCode)"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.fbBearerToken,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let correlationRefId = json["correlationRefId"].stringValue
                let licesenCode = json["data"]["claimLicenseCode"].stringValue
                let amount = json["data"]["appliedAmount"].floatValue
                completionHandler(correlationRefId, licesenCode, amount, nil)
            case .failure(let error):
                print(error)
                completionHandler(nil, nil, nil, error)
            }
        }
    }
    
    // ********************************* //
    // complete claim api
    // ********************************* /
    
    func completeClaim(_ correlationRefId: String!, params: [String : Any], success: @escaping ([String: Any]) -> Void, failure: @escaping (NSError!) -> Void) {
        self.getToken()
        let url = self.serverBaseUrl + "/api/v1/claim/coupon/claim/complete"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Lazlo-CorrelationRefId": correlationRefId,
            "Content-Type": "application/json"
        ]
        
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200..<300).responseJSON { (response) in
            switch response.result {
            case .success:
                success([:])
            case .failure(let error):
                failure(error as NSError!)
                print(error)
                
            }
        }
    }
    
    // ********************************* //
    // user activation api
    // ********************************* //
    func activateUser(_ userLicenseCode: String!, completionHandler: @escaping (_ error: Error?) -> Void) {
        self.getToken()
        let url = serverBaseUrl + "/api/v1/user/activate"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": userLicenseCode,
            "Authorization": "Bearer " + self.userAccessToken,
            "Content-Type": "application/json"
        ]
        Alamofire.request(url, method: .put, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200 ..< 300).responseJSON { (response) in
            switch response.result {
            case .success:
                completionHandler(nil)
            case .failure(let error):
                completionHandler(error)
            }
        }
    }
    
    // ********************************* //
    // inactive user list api
    // ********************************* //
    func fetchInactiveUsers(_ completionHandler: @escaping (_ users: [User]?, _ error: Error?) -> Void) {
        self.getToken()
        let url = self.serverBaseUrl + "/api/admin/v1/users/inactive"
        let headers: HTTPHeaders = [
            "Lazlo-AuthorityLicenseCode": self.authorityLicense,
            "Lazlo-UserLicenseCode": self.userLicense,
            "Authorization": "Bearer " + self.userAccessToken,
            "Content-Type": "application/json"
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).validate(statusCode: 200 ..< 300).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                var users: [User] = []
                for (_, subJson) in json["data"] {
                    if let user = User(subJson) {
                        users.append(user)
                    }
                }
                completionHandler(users, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
}
