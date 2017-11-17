//
//  AppPermissionViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 3/27/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class AppPermissionViewController: UIViewController, CLLocationManagerDelegate {

    
    @IBOutlet weak var cameraStateImg: UIImageView!
    @IBOutlet weak var locationStateImg: UIImageView!
    @IBOutlet weak var notificationStateImg: UIImageView!
    @IBOutlet weak var microphoneStateImg: UIImageView!
    
    var cameraFlg = false
    var locationFlg = false
    var notificationFlg = false
    var microphoneFlag = false
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var config = GTStorage.sharedGTStorage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gotoMainView()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func cameraPermissionBtnAction(_ sender: Any) {
        checkCameraPermisison()
    }
    @IBAction func locationPermissionBtnAction(_ sender: Any) {
        checkLocationPermission()
    }
    @available(iOS 10.0, *)
    @IBAction func notificationPermissionBtnAction(_ sender: Any) {
        checkNotificationPermission()
    }
    
    @IBAction func microphonePermissionBtnAction(_ sender: Any) {
        checkMicrophonePermission()
    }
    
    
    @IBAction func mainbtnAction(_ sender: Any) {
//        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
//        if let vc : MainViewController = mainStoryboard.instantiateViewController(withIdentifier: "mainViewController") as? MainViewController {
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
    func checkCameraPermisison() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized
        {
            self.config.writeValue(true as AnyObject, forKey: "cameraPermissionState", toStore: "settings")
            DispatchQueue.main.async {
                self.gotoMainView()
            }
        }
        else
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted :Bool) -> Void in
                if granted == true
                {
                    self.config.writeValue(true as AnyObject, forKey: "cameraPermissionState", toStore: "settings")
                    DispatchQueue.main.async {
                        self.gotoMainView()
                    }
                    // User granted
                }
                else
                {
                    self.config.writeValue(false as AnyObject, forKey: "cameraPermissionState", toStore: "settings")
                    DispatchQueue.main.async {
                        self.gotoMainView()
                    }
                    // User Rejected
                }
            });
        }
    }
    
    func checkLocationPermission() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."

        BeaconManager.shared.initialize()
        if CLLocationManager.locationServicesEnabled() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined, .restricted, .denied:
                    self.config.writeValue(false as AnyObject, forKey: "locationPermissionState", toStore: "settings")
                    DispatchQueue.main.async {
                        self.gotoMainView()
                    }
                    print("No access")
                case .authorizedAlways, .authorizedWhenInUse:
                    self.config.writeValue(true as AnyObject, forKey: "locationPermissionState", toStore: "settings")
                    DispatchQueue.main.async {
                        self.gotoMainView()
                    }
                    print("Access")
                }
            }
        } else {
            config.writeValue(false as AnyObject, forKey: "locationPermissionState", toStore: "settings")
            DispatchQueue.main.async {
                self.gotoMainView()
            }
        }

    }
    
    func checkNotificationPermission(){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        if #available(iOS 10.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                    if (granted == true) {
                        self.config.writeValue(true as AnyObject, forKey: "notificationPermissionState", toStore: "settings")
                        DispatchQueue.main.async {
                            self.gotoMainView()
                        }
                    } else {
                        if (!(self.config.getValue("notificationPermissionState", fromStore: "settings") as! Bool)) {
                            self.config.writeValue(true as AnyObject, forKey: "notificationPermissionState", toStore: "settings")
                        }
                        DispatchQueue.main.async {
                            self.gotoMainView()
                        }
                    }
                    // Enable or disable features based on authorization.
                }
            }
        } else {
            self.config.writeValue(true as AnyObject, forKey: "notificationPermissionState", toStore: "settings")
            self.gotoMainView()
            // Fallback on earlier versions
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func checkMicrophonePermission() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        self.view.isUserInteractionEnabled = false
        loadingNotification?.labelText = "Loading..."
        if AVAudioSession.sharedInstance().recordPermission() == AVAudioSessionRecordPermission.granted {
            self.config.writeValue(true as AnyObject, forKey: "microphonePermissionState", toStore: "settings")
            DispatchQueue.main.async {
                self.gotoMainView()
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    self.config.writeValue(true as AnyObject, forKey: "microphonePermissionState", toStore: "settings")
                    DispatchQueue.main.async {
                        self.gotoMainView()
                    }
                } else {
                    self.config.writeValue(false as AnyObject, forKey: "microphonePermissionState", toStore: "settings")
                    DispatchQueue.main.async {
                        self.gotoMainView()
                    }
                }
            })
        }
    }
    
    func gotoMainView() {
        
        cameraFlg = self.config.getValue("cameraPermissionState", fromStore: "settings") as! Bool
        locationFlg = self.config.getValue("locationPermissionState", fromStore: "settings") as! Bool
        notificationFlg = self.config.getValue("notificationPermissionState", fromStore: "settings") as! Bool
        microphoneFlag = self.config.getValue("microphonePermissionState", fromStore: "settings") as! Bool
        
        if cameraFlg {
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.cameraStateImg.isHidden = false
        } else {
            self.cameraStateImg.isHidden = true
        }
        if locationFlg {
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.locationStateImg.isHidden = false
        } else {
            self.locationStateImg.isHidden = true
        }
        if notificationFlg {
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.notificationStateImg.isHidden = false
        } else {
            self.notificationStateImg.isHidden = true
        }
        if microphoneFlag {
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.microphoneStateImg.isHidden = false
        } else {
            self.microphoneStateImg.isHidden = true
        }
        
        if (notificationFlg && cameraFlg && locationFlg && microphoneFlag) {
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc : MainViewController = mainStoryboard.instantiateViewController(withIdentifier: "mainViewController") as? MainViewController {
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }

    }
    
    // MARK: all delegate functions
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (status == .denied) {
            config.writeValue(false as AnyObject, forKey: "locationPermissionState", toStore: "settings")
        } else if (status == .authorizedAlways) {
            config.writeValue(true as AnyObject, forKey: "locationPermissionState", toStore: "settings")
        }
    }
    
}
