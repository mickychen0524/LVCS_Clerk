//
//  AppDelegate.swift
//  StoreClerkLite
//
//  Created by MyMac on 3/27/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import UserNotifications
import HockeySDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, RPKManagerDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var proximityKitManager : RPKManager?

    var qrcodeScanFlg : Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Beacon
        if (GTStorage.sharedGTStorage.getValue("locationPermissionState", fromStore: "settings") as! Bool) {
            BeaconManager.shared.initialize()
        }
        
        // HockeyApp
        getAndSetHockeyAppID()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        UserDefaults.standard.set(deviceTokenString, forKey: "deviceTokenForPush")
        print(deviceTokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        print("i am not available in simulator \(error)")
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Push info \(userInfo)")
        
        if let aps = userInfo["aps"] as? [String : Any] {
            if let content = aps["content-available"] as? Int, let operationType = userInfo["operationType"] as? Int {
                if content == 1 {
                    if operationType == 65536 {
                        BeaconManager.shared.getProximityUrl()                        
                    }
                }
            }
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print(url.scheme ?? "nil")
        print(url.query ?? "nil")
        if ((url.scheme == "valotteryplay") && (url.query == "checkout")) {
            
        } else {
            
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: background service part
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: get hockey app id and set
    func getAndSetHockeyAppID() {
        let data: [String : Any] = [:]
        
        AlamofireRequestAndResponse.sharedInstance.getHockeyAppID(data, success: { (res: [String : Any]) -> Void in
            if let resData = res["data"] as? [String : Any], let hockeyAppId = resData["hockeyAppIdIos"] as? String {
                BITHockeyManager.shared().configure(withIdentifier: hockeyAppId)
                BITHockeyManager.shared().authenticator.authenticateInstallation()
                BITHockeyManager.shared().crashManager.crashManagerStatus = BITCrashManagerStatus.autoSend
                BITHockeyManager.shared().start()
            }
        },
          failure: { (error: Error!) -> Void in
            print("hockey app error")
        })
    }
}

