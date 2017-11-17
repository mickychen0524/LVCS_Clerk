//
//  BeaconManager.swift
//  StoreClerkLite
//
//  Created by Micky on 8/17/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation
import CoreLocation
import Gzip
import SwiftyJSON

public class BeaconManager: NSObject {
    
    private override init() { }
    
    static let shared = BeaconManager()
//    let tempLatitude = 42.129223
//    let tempLongitude = -80.085060
    
    var locationManager: CLLocationManager!
    
    var altitude : Double?
    var coordinate: CLLocationCoordinate2D?
    
    var beaconDistance = ""
    var beaconMajor = ""
    var beaconMinor = ""
    
    var mutableArr = NSMutableArray()
    var beaconArr = NSMutableArray()
    var globalRetailerArr = NSArray()
    var beaconsFromRetailer: [BeaconItem] = []
    var beaconsDetected: [CLBeacon] = []
    var significantUUID: String? = ""
    
    var uploadFlag = false
    var getRetailerListFlag = false
    var getRetailerBeaconFlag = false
    var enableStartScan = false
    var retailerRefIdStr = ""
    var closestRetailerItem: [String : Any]!
    
    var updateTimer: Timer?
    
    var backgroundTask = UIBackgroundTaskInvalid
    
    var locationMark : UIImageView = UIImageView(frame: CGRect(x: 100, y: 20, width: 40,height: 44))
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let config = GTStorage.sharedGTStorage
    
    func initialize() {
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = config.getValue("BLEDistanceFilter", fromStore: "settings") as! Double
            locationManager.allowsBackgroundLocationUpdates = true
            
            locationMark.image = UIImage(named: "location")
            UserDefaults.standard.set(false, forKey: "retailerExistFlag")
        }
        
        locationManager.startUpdatingLocation()
        registerBackgroundTask()
        
        startBeaconStuff()

        NotificationCenter.default.addObserver(self, selector: #selector(reinstateBackgroundTask), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    fileprivate func startScan() {
        if self.significantUUID != "" && self.significantUUID != nil {
//        let uuid = UUID(uuidString: Config.Proximity.beaconUDID1)!
            let uuid = UUID(uuidString: self.significantUUID!)
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid!, identifier: "MyBeacon")
            
            locationManager.startMonitoring(for: beaconRegion)
            locationManager.startRangingBeacons(in: beaconRegion)
        }
    }
    
    fileprivate func updateDistance(_ distance: CLProximity) {
        UIView.animate(withDuration: 0.8) {
            switch distance {
            case .unknown:
                print("unknown")
            case .far:
                print("far")
            case .near:
                print("near")
            case .immediate:
                print("immediate")
            }
        }
    }
    
    func getProximityUrl() {
        if self.mutableArr.count > 0 && !self.uploadFlag {
            let value = [String: Any]()
            AlamofireRequestAndResponse.sharedInstance.getProximityUrlData(value as NSDictionary, success: { (res: [String: Any]) -> Void in
                if let resData = res["data"] as? String {
                    print(resData)
                    self.uploadBLEData(toStorage: resData)
                }
            }, failure: { (error: Error!) -> Void in
                let alert = UIAlertController(title: "Error", message: "BLE data upload error", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                    
                }
                alert.addAction(okAction)
                self.appDelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    fileprivate func uploadBLEData(toStorage : String) {
        appDelegate.window?.rootViewController?.view.addSubview(locationMark)
        
//        var compressedData = Data()
        var encryptedData = Data()
        
        beaconArr = self.mutableArr.copy() as! NSMutableArray
        
        var beaconUploadData : [String: Any] = [String: Any]()
        var locationInfo : [String: Any] = [String: Any]()
        var spatial : [String: Any] = [String: Any]()
        
        spatial["longitude"] = coordinate?.longitude
        spatial["latitude"] = coordinate?.latitude
        spatial["altitude"] = altitude
        
        if (config.getValue("devEndpoint", fromStore: "settings") as? Bool)! {
            locationInfo["playerLicenseCode"] = config.getValue("userLicenseDev", fromStore: "settings") as? String
        } else {
            locationInfo["playerLicenseCode"] = config.getValue("userLicenseDemo", fromStore: "settings") as? String
        }
        
        if (retailerRefIdStr == "") {
            locationInfo["retailerRefId"] = "00000000-0000-0000-0000-000000000000"
        } else {
            locationInfo["retailerRefId"] = retailerRefIdStr
        }
        locationInfo["spatial"] = spatial
        locationInfo["beaconEvents"] = mutableArr.copy()
        
        beaconUploadData["locationInfo"] = locationInfo
        beaconUploadData["brandLicenseCode"] = config.getValue("devBrandLicenseCode", fromStore: "settings") as? String
        
        print(JSON(beaconUploadData))
        
        if JSONSerialization.isValidJSONObject(beaconUploadData) {
            let file = "beaconFile.txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let path = dir.appendingPathComponent(file)
                let text = JSONHelper.JSONStringify(beaconUploadData)
                do {
                    try text.write(to: path, atomically: false, encoding: String.Encoding.utf8)
                } catch {
                    do {
                        encryptedData = try Data.init(contentsOf: path)
//                        compressedData = try! encryptedData.gzipped()
                    } catch let error1 as GzipError {
                        print(error1.localizedDescription)
                    } catch let error2 as NSError {
                        print(error2.localizedDescription)
                    }
                }
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: { self.locationMark.alpha = 1.0 }, completion: { Bool in
            AlamofireRequestAndResponse.sharedInstance.proximityUploadWithBLEBlobData(toStorage, data: encryptedData, success: { (res: [String: Any]) -> Void in
                self.beaconsDetected.removeAll()
                UIView.animate(withDuration: 0.3, animations: { self.locationMark.alpha = 0.0 }, completion: { Bool in
                    self.locationMark.removeFromSuperview()
                    self.mutableArr = NSMutableArray()
                    let currentDate = Date()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = DateFormatter.Style.full
                    let convertedDate = dateFormatter.string(from: currentDate)
                    UserDefaults.standard.set(convertedDate, forKey: "lastUploadedDate")
                })
            }, failure: { (error: Error!) -> Void in
                let alert = UIAlertController(title: "Error", message: "BLE data upload error", preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                    UIAlertAction in
                    
                }
                alert.addAction(okAction)
                self.mutableArr = NSMutableArray()
                self.appDelegate.window?.rootViewController?.present(alert, animated: true, completion: nil)
                UIView.animate(withDuration: 0.3, animations: { self.locationMark.alpha = 0.0 }, completion: { Bool in
                    self.locationMark.removeFromSuperview()
                })
            })
        })
    }
    
    fileprivate func setTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            self.uploadFlag = false
        }
    }
    
    @objc fileprivate func startBeaconStuff() {
        if (!self.getRetailerListFlag) {
            self.getAllRetailers()
        }
    }

    func getAllRetailers() {
        var userLicense = ""
        if (config.getValue("devEndpoint", fromStore: "settings") as? Bool)! {
            userLicense = config.getValue("userLicenseDev", fromStore: "settings") as! String
        } else {
            userLicense = config.getValue("userLicenseDemo", fromStore: "settings") as! String
        }
        
        if userLicense.length == 0 {
            return
        }

        let uuid = UUID().uuidString
        var fullData = [String: Any]()
        let middleData = [String: Any]()
        
        fullData["uuid"] = uuid
        fullData["data"] = middleData
        
        fullData["latitude"] = coordinate?.latitude
        fullData["longitude"] = coordinate?.longitude
//        fullData["latitude"] = tempLatitude
//        fullData["longitude"] = tempLongitude
        
        AlamofireRequestAndResponse.sharedInstance.getRetailersWithLocation(fullData as NSDictionary, success: { (res: [String: Any]) -> Void in
                guard let resData: NSArray = res["data"] as? NSArray else {
                    return
                }
            
                self.getRetailerListFlag = false
            
                print("Response Retailers \(JSON(resData))")
            
                if resData.count != 0 && self.coordinate != nil {
                    self.globalRetailerArr = resData
                    
                    self.beaconsFromRetailer.removeAll()
                    
                    var maxDistanceInMeters = 10000000.0
                    var retailerAddress : String = ""
                    let myCoordinate = CLLocation(latitude: (self.coordinate?.latitude)!, longitude: (self.coordinate?.longitude)!)
//                    let myCoordinate = CLLocation(latitude: self.tempLatitude, longitude: self.tempLongitude)
                    
                    for item in resData {
                        print ("ITEM \(item)")
                        if let retailerItem = item as? [String : Any] {
                            
                            //get location
                            self.retailerRefIdStr = retailerItem["retailerRefId"] as? String ?? ""
                            let addressLocation = retailerItem["addressLocation"] as? [String : Any]
                            if let retailerCoordsArr = addressLocation?["coordinates"] as? NSArray,
                                let latitude = retailerCoordsArr[1] as? CLLocationDegrees,
                                let longitude = retailerCoordsArr[0] as? CLLocationDegrees
                            {
                                let retailerCoordinates = CLLocation(latitude: latitude, longitude: longitude)
                                let distanceInMeters = myCoordinate.distance(from: retailerCoordinates)
                                
                                if (Double(distanceInMeters) < Double(maxDistanceInMeters)) {
                                    maxDistanceInMeters = Double(distanceInMeters)
                                    self.closestRetailerItem = retailerItem
                                }
                            }
                        }
                    }
                    
                    //get beacons data(closest retailer item)
                    if let beaconsArray: NSArray = self.closestRetailerItem?["beacons"] as? NSArray {
                        retailerAddress = String.init(format: "%@, %@, %@",
                                                      self.closestRetailerItem["retailerName"] as! String,
                                                      self.closestRetailerItem["addressLine1"] as! String,
                                                      self.closestRetailerItem["addressStateProvince"] as! String)
                        self.retailerRefIdStr = self.closestRetailerItem["retailerRefId"] as! String
                        
                        for beaconItem in beaconsArray {
                            let json = JSON(beaconItem)
                            let beacon = BeaconItem(json)
                            self.significantUUID = beacon!.beaconuuid
                            self.beaconsFromRetailer.append(beacon!)
                        }
                    }
                    
                    let closestRetailerRefId = UserDefaults.standard.string(forKey: "closestRetailerRefId")
                    if retailerAddress.length > 0 && closestRetailerRefId != self.retailerRefIdStr {
                        UserDefaults.standard.set(self.retailerRefIdStr, forKey: "closestRetailerRefId")
                        UserDefaults.standard.synchronize()
                        
                        let notification = UILocalNotification()
                        notification.fireDate = NSDate(timeIntervalSinceNow: 5) as Date
                        notification.alertTitle = "Store Clerk Lite"
                        notification.alertBody = String.init(format: "Play now at %@ ", retailerAddress)
                        notification.alertAction = "open"
                        notification.hasAction = true
                        UIApplication.shared.scheduleLocalNotification(notification)
                        UserDefaults.standard.set(true, forKey: "retailerExistFlag")
                        
                        self.getRetailerListFlag = false
                        if self.enableStartScan {
                            self.startScan()
                        }
                    }
                } else {
                    UserDefaults.standard.set(false, forKey: "retailerExistFlag")
                    self.getAllRetailers()
                }
            
        }, failure: { (error: Error!) -> Void in
            UserDefaults.standard.set(false, forKey: "retailerExistFlag")
            self.getAllRetailers()
        })
    }
    
    
    
    // MARK: background task
    
    @objc fileprivate func reinstateBackgroundTask() {
        if updateTimer != nil && (backgroundTask == UIBackgroundTaskInvalid) {
            registerBackgroundTask()
        }
    }
    
    fileprivate func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    fileprivate func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
}

extension BeaconManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            altitude = locations[0].altitude
            coordinate = locations[0].coordinate
            Store.loadStores()
            getAllRetailers()
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    self.enableStartScan = true
                    startScan()
                }
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if beacons.count > 0 {
            if (UserDefaults.standard.object(forKey: "retailerExistFlag") as! Bool) {
                
                if self.beaconsDetected.count == 0 {
                    appDelegate.window?.rootViewController?.view.makeToast("Beacon Discovered")
                    self.beaconsDetected = beacons
                } else {
                    for beacon in beacons {
                        var conflictFlag = false
                        for beaconDetected in self.beaconsDetected {
                            if ((beacon.major as! Int) == (beaconDetected.major as! Int)) && ((beacon.minor as! Int) == (beaconDetected.minor as! Int)) {
                                conflictFlag = true
                            }
                        }
                        
                        if !conflictFlag {
                            appDelegate.window?.rootViewController?.view.makeToast("Beacon Discovered")
                            self.beaconsDetected.append(beacon)
                        }
                    }
                }
                
                print ("BeaconsDetected Count \(self.beaconsDetected.count)")
                
                //add beacons
                for beacon in beacons {
                    print ("Detected Beacon Major:\(beacon.major)  Minor:\(beacon.minor)")
                    
                    for beaconFromRetailer in self.beaconsFromRetailer {
                        print ("COUNT \(self.beaconsFromRetailer.count)")
                        print ("BeaconFromRetailer Major:\(String(describing: beaconFromRetailer.beaconMajor))  Minor:\(String(describing: beaconFromRetailer.beaconMinor))")
                        if (beacon.major as! Int) != beaconFromRetailer.beaconMajor {
                            continue
                        }
                        
                        if (beacon.minor as! Int) != beaconFromRetailer.beaconMinor {
                            continue
                        }
                        
                        updateDistance(beacon.proximity)
                        self.beaconMajor = String(beacon.major as! Int)
                        self.beaconMinor = String(beacon.minor as! Int)
                        self.beaconDistance = String(beacon.accuracy)
                        
                        let currentDate = Date()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "MM/dd/YYYY hh:mm:ss a"
                        let convertedDate = dateFormatter.string(from: currentDate)
                        
                        var value = [String: Any]()
                      
                        value["beaconRefId"] = beacon.proximityUUID.uuidString
                        value["major"] = String(beacon.major as! Int)
                        value["minor"] = String(beacon.minor as! Int)
                        value["rssi"] = String(beacon.rssi as Int)
                        value["accuracy"] = String(beacon.accuracy as Double)
                        switch beacon.proximity{
                        case .unknown:
                            value["proximity"] = "unknown"
                        case .far:
                            value["proximity"] = "far"
                        case .near:
                            value["proximity"] = "near"
                            print("near")
                        case .immediate:
                            value["proximity"] = "immediate"
                        }
                        value["createdOn"] = convertedDate
                        
                        self.mutableArr.add(value)
                    }
                }
            }           
            
            print("BLE MutableArr Count \(self.mutableArr.count)")
            
        } else {
            updateDistance(.unknown)
        }
    }
}
