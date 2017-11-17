//
//  MainViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 3/27/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import Refresher
import LocalAuthentication
import HockeySDK

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AKFViewControllerDelegate {

    @IBOutlet weak var refundBtn: UIButton!
    @IBOutlet weak var checkoutBtn: UIButton!
    @IBOutlet weak var reportBtn: UIButton!
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var chatBtn: UIButton!
    @IBOutlet weak var claimBtn: UIButton!
    @IBOutlet weak var ticketBtn: UIButton!

    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activateBtn: UIButton!
    
    var gameList : NSArray!
    var config = GTStorage.sharedGTStorage
    
    var accountKit: AKFAccountKit!
    
    lazy var refreshControl: UIRefreshControl! = UIRefreshControl()
    
    let serviceManager = ServiceManager.getManager(t: "clerk")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameList = NSArray()
        getGameData()
        
        tableView.tableFooterView = UIView(frame: .zero)
        
        // initialize Account Kit
        if accountKit == nil {
            // may also specify AKFResponseTypeAccessToken
            self.accountKit = AKFAccountKit(responseType: AKFResponseType.authorizationCode)
        }
        
        // add table view refresher
        if let customSubview = Bundle.main.loadNibNamed("CustomPullToRefreshView", owner: self, options: nil)?.first as? CustomPullToRefreshView {
            tableView.addPullToRefreshWithAction({
                OperationQueue().addOperation {
                    //                    sleep(2)
                    OperationQueue.main.addOperation {
                        MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                        self.getGameData()
                        self.tableView.stopPullToRefresh()
                    }
                }
            }, withAnimator: customSubview)
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.config.getValue("activateState", fromStore: "settings") as! Bool {
            self.activateBtn.isHidden = true
            self.registerBtn.isHidden = false
            if self.config.getValue("loginState", fromStore: "settings") as! Bool &&
                self.config.getValue("registerState", fromStore: "settings") as! Bool {
                self.registerBtn.setTitle("Sign out",for: .normal)
            } else {
                if self.config.getValue("registerState", fromStore: "settings") as! Bool {
                    self.registerBtn.setTitle("Sign In",for: .normal)
                } else {
                    self.registerBtn.setTitle("Register",for: .normal)
                }
            }
        } else {
            if self.config.getValue("loginState", fromStore: "settings") as! Bool &&
                self.config.getValue("registerState", fromStore: "settings") as! Bool {
                self.activateBtn.isHidden = false
                self.registerBtn.isHidden = true
            } else {
                self.activateBtn.isHidden = true
                self.registerBtn.isHidden = false
            }
            if self.config.getValue("registerState", fromStore: "settings") as! Bool {
                self.registerBtn.setTitle("Sign In",for: .normal)
            } else {
                self.registerBtn.setTitle("Register",for: .normal)
            }
        }
        
        if self.config.getValue("activateState", fromStore: "settings") as! Bool &&
            self.config.getValue("loginState", fromStore: "settings") as! Bool &&
            self.config.getValue("registerState", fromStore: "settings") as! Bool {
            self.checkoutBtn.isHidden = false
            self.refundBtn.isHidden = false
            self.reportBtn.isHidden = false
            self.scanBtn.isHidden = false
            self.chatBtn.isHidden = false
            self.claimBtn.isHidden = false
            self.ticketBtn.isHidden = false
        } else {
            self.checkoutBtn.isHidden = true
            self.refundBtn.isHidden = true
            self.reportBtn.isHidden = true
            self.scanBtn.isHidden = true
            self.chatBtn.isHidden = true
            self.claimBtn.isHidden = true
            self.ticketBtn.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playSound()
    }
    
    func playSound() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { 
            if self.serviceManager.getClientList().count > 0 {
                self.serviceManager.playSound()
            } else {
                self.serviceManager.stopSound()
            }
            
            self.playSound()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: table helper functions
    /**************************************************************************************
     *
     *  UITable View Delegate Functions
     *
     **************************************************************************************/
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gameList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "mainTableViewCell") as! MainTableViewCell
        cell.selectionStyle = .none
        if let sampleData: [String : Any] = self.gameList[indexPath.row] as? [String : Any] {
            cell.configWithData(item: sampleData)
        }
        
        return cell
    }
    
    //MARK: AKViewController delegate functions
    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWith accessToken: AKFAccessToken!, state: String!) {
        if (self.config.getValue("devEndpoint", fromStore: "settings") as! Bool) {
            self.config.writeValue(accessToken.tokenString as AnyObject, forKey: "fbBearerTokenDev", toStore: "settings")
            self.config.writeValue(true as AnyObject, forKey: "loginState", toStore: "settings")
        } else {
            self.config.writeValue(accessToken.tokenString as AnyObject, forKey: "fbBearerTokenDemo", toStore: "settings")
            self.config.writeValue(true as AnyObject, forKey: "loginState", toStore: "settings")
        }
        
        print("Login succcess with AccessToken : " + accessToken.tokenString)
    }
    
    func viewController(_ viewController: (UIViewController & AKFViewController)!, didCompleteLoginWithAuthorizationCode code: String!, state: String!) {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        let data : [String : Any] = [String : Any]()
        AlamofireRequestAndResponse.sharedInstance.verifyFBAuthCode(data, authCode: code, success: { (res: [String : Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            if let resData = res["data"] as? String {
                if (self.config.getValue("devEndpoint", fromStore: "settings") as! Bool) {
                    self.config.writeValue(code as AnyObject, forKey: "fbBearerTokenDev", toStore: "settings")
                    self.config.writeValue(resData as AnyObject, forKey: "fbAccessTokenDev", toStore: "settings")
                    self.config.writeValue(true as AnyObject, forKey: "loginState", toStore: "settings")
                    
                } else {
                    self.config.writeValue(code as AnyObject, forKey: "fbBearerTokenDemo", toStore: "settings")
                    self.config.writeValue(resData as AnyObject, forKey: "fbAccessTokenDemo", toStore: "settings")
                    self.config.writeValue(true as AnyObject, forKey: "loginState", toStore: "settings")
                }
            }
            
            if self.config.getValue("registerState", fromStore: "settings") as! Bool == false {
                if let vc : RegisterViewController = self.storyboard?.instantiateViewController(withIdentifier: "registerViewController") as? RegisterViewController {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
            
            self.viewWillAppear(false)
        },
          failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error", message: "Oops! FBAuthocode verify error, try back later.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        })
        print("Login succcess with AuthorizationCode : " + code)
    }
    
    func viewController(_ viewController: (UIViewController & AKFViewController)!, didFailWithError error: Error!) {
        self.config.writeValue(false as AnyObject, forKey: "loginState", toStore: "settings")
        print("We have an error \(error)")
    }
    
    func viewControllerDidCancel(_ viewController: (UIViewController & AKFViewController)!) {
        self.config.writeValue(false as AnyObject, forKey: "loginState", toStore: "settings")
        print("The user cancel the login")
    }
    
    func prepareLoginViewController(_ l_viewController: AKFViewController) {
        
        l_viewController.delegate = self
        l_viewController.setAdvancedUIManager(nil)
        
        //Costumize the theme
        let theme:AKFTheme = AKFTheme.default()
        theme.headerBackgroundColor = Style.Colors.mainOrangeColor
        theme.headerTextColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        theme.iconColor = UIColor(red: 0.325, green: 0.557, blue: 1, alpha: 1)
        theme.inputTextColor = UIColor(white: 0.4, alpha: 1.0)
        theme.statusBarStyle = .default
        theme.textColor = UIColor(white: 0.3, alpha: 1.0)
        theme.titleColor = UIColor(red: 0.247, green: 0.247, blue: 0.247, alpha: 1)
        l_viewController.setTheme(theme)
        
    }
    
    func getGameData() {
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        let data : [String : Any] = [String : Any]()
        AlamofireRequestAndResponse.sharedInstance.getAllGameList(data, success: { (res: [String : Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            if let serverArr = res["data"] as? NSArray {
                let resData: NSArray = serverArr
                if (resData.count != 0) {
                    self.gameList = resData
                    self.tableView.reloadData()
                }
            }
            
        },
          failure: { (error: Error!) -> Void in
            let alert = UIAlertController(title: "Error", message: "Oops! Our services are not responding, try back later.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                UIAlertAction in
                
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
        })
    }
    
    func moveToScan(_ sender: UIButton!) {
        let authContext:LAContext = LAContext()
        var error:NSError?
        
        //Is Touch ID hardware available & configured?
        if(authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error:&error)) {
            //Perform Touch ID auth
            authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Store Clerk Lite") {(success, evaluateError) in
                DispatchQueue.main.async {
                    //User authenticated
                    if(success) {
                        if sender == self.checkoutBtn {
                            if let vc : CheckoutViewController = self.storyboard?.instantiateViewController(withIdentifier: "checkoutViewController") as? CheckoutViewController {
                                vc.gameDataArr = self.gameList
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        } else if sender == self.refundBtn {
                            if let vc : RefundViewController = self.storyboard?.instantiateViewController(withIdentifier: "refundViewController") as? RefundViewController {
                                self.navigationController?.pushViewController(vc, animated: true)
                            }
                        } else if sender == self.scanBtn {
                            if let scanViewController = self.storyboard?.instantiateViewController(withIdentifier: "ScanViewController") as? ScanViewController {
                                self.navigationController?.pushViewController(scanViewController, animated: true)
                            }
                        } else if sender == self.claimBtn {
                            if let claimViewController = self.storyboard?.instantiateViewController(withIdentifier: "ClaimViewController") as? ClaimViewController {
                                self.navigationController?.pushViewController(claimViewController, animated: true)
                            }
                        } else if sender == self.ticketBtn {
                            if let ticketViewController = self.storyboard?.instantiateViewController(withIdentifier: "TicketViewController") as? TicketViewController {
                                self.navigationController?.pushViewController(ticketViewController, animated: true)
                            }
                        }
                    } else {
                        //There are a few reasons why it can fail, we'll write them out to the user in the label
                        _ = SweetAlert().showAlert("Warning!", subTitle: "Touch ID error. \n Please make sure the fingerprint.", style: AlertStyle.warning)
                    }
                }
            }
            
        } else {
            //Missing the hardware or Touch ID isn't configured
            if sender == self.checkoutBtn {
                if let vc : CheckoutViewController = storyboard?.instantiateViewController(withIdentifier: "checkoutViewController") as? CheckoutViewController {
                    vc.gameDataArr = self.gameList
                    navigationController?.pushViewController(vc, animated: true)
                }
            } else if sender == self.refundBtn {
                if let vc : RefundViewController = storyboard?.instantiateViewController(withIdentifier: "refundViewController") as? RefundViewController {
                    navigationController?.pushViewController(vc, animated: true)
                }
            } else if sender == self.scanBtn {
                if let scanViewController = storyboard?.instantiateViewController(withIdentifier: "ScanViewController") as? ScanViewController {
                    navigationController?.pushViewController(scanViewController, animated: true)
                }
            } else if sender == self.claimBtn {
                if let claimViewController = self.storyboard?.instantiateViewController(withIdentifier: "ClaimViewController") as? ClaimViewController {
                    self.navigationController?.pushViewController(claimViewController, animated: true)
                }
            } else if sender == self.ticketBtn {
                if let ticketViewController = self.storyboard?.instantiateViewController(withIdentifier: "TicketViewController") as? TicketViewController {
                    self.navigationController?.pushViewController(ticketViewController, animated: true)
                }
            }
        }
    }
    
    @IBAction func activateBtnAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if let vc : ActivateViewController = mainStoryboard.instantiateViewController(withIdentifier: "activateViewController") as? ActivateViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func offerFeedbackBtnAction(_ sender: Any) {
        BITHockeyManager.shared().feedbackManager.showFeedbackComposeView()
    }
    
    @IBAction func checkoutBtnAction(_ sender: Any) {
        moveToScan(sender as! UIButton)
    }
    
    @IBAction func refundBottomBtnAction(_ sender: Any) {
        moveToScan(sender as! UIButton)
    }
    
    @IBAction func reportBtnAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if let vc : ReportViewController = mainStoryboard.instantiateViewController(withIdentifier: "reportViewController") as? ReportViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func scanBtnSAction(_ sender: Any) {
        moveToScan(sender as! UIButton)
    }
    
    @IBAction func claimBtnAction(_ sender: Any) {
        moveToScan(sender as! UIButton)
    }
    
    @IBAction func ticketBtnAction(_ sender: Any) {
        moveToScan(sender as! UIButton)
    }
    
    @IBAction func chatBtnAction(_ sender: Any) {
        if let pendingViewController = storyboard?.instantiateViewController(withIdentifier: "PendingViewController") as? PendingViewController {
            navigationController?.pushViewController(pendingViewController, animated: true)
        }
    }
    
    @IBAction func registerBtnAction(_ sender: Any) {
        if self.config.getValue("registerState", fromStore: "settings") as! Bool {
            if self.config.getValue("activateState", fromStore: "settings") as! Bool {
                if self.config.getValue("loginState", fromStore: "settings") as! Bool {
                    self.accountKit.logOut()
                    self.config.writeValue(false as AnyObject, forKey: "loginState", toStore: "settings")
                    self.viewWillAppear(false)
                } else {
                    let viewController:AKFViewController = accountKit.viewControllerForPhoneLogin()
                    viewController.enableSendToFacebook = true
                    self.prepareLoginViewController(viewController)
                    self.present(viewController as! UIViewController, animated: true, completion: nil)
                }
            }
        } else {
            if self.config.getValue("loginState", fromStore: "settings") as! Bool {
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: "registerViewController") as? RegisterViewController {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                let viewController:AKFViewController = accountKit.viewControllerForPhoneLogin()
                viewController.enableSendToFacebook = true
                self.prepareLoginViewController(viewController)
                self.present(viewController as! UIViewController, animated: true, completion: nil)
            }
        }
    }

    @IBAction func saveLicenseCodeBtnAction(_ sender: Any) {
        if let inactiveUsersViewController = storyboard?.instantiateViewController(withIdentifier: "InactiveUsersViewController") as? InactiveUsersViewController {
            present(inactiveUsersViewController, animated: true, completion: nil)
        }
    }
    
    func createUserLicenseDlg() {
        // Create custom Appearance Configuration
        let appearance = SCLAlertView.SCLAppearance(
            kTitleFont: UIFont(name: "HelveticaNeue", size: 20)!,
            kTextFont: UIFont(name: "HelveticaNeue", size: 14)!,
            kButtonFont: UIFont(name: "HelveticaNeue-Bold", size: 14)!,
            showCloseButton: false,
            showCircularIcon: false,
            contentViewColor : UIColor.white,
            contentViewBorderColor : UIColor.white
        )
        
        // Initialize SCLAlertView using custom Appearance
        let alert = SCLAlertView(appearance: appearance)
        
        // Creat the subview
        let subview = UIView(frame: CGRect(x: 0,y: 0,width: 216,height: 180))
        let x = (subview.frame.width - 180) / 2
        
        // Add label
        let labelCaption = UILabel(frame: CGRect(x: x, y: 0, width: 180,height: 35))
        labelCaption.textColor = Style.Colors.mainOrangeColor
        labelCaption.textAlignment = .center
        labelCaption.font = UIFont.systemFont(ofSize: 20.0)
        labelCaption.text = "Enter User License"
        subview.addSubview(labelCaption)
        
        // Add number label
        let licenseTextView = UITextView(frame: CGRect(x: x, y: labelCaption.frame.maxY + 2, width: 180,height: 120))
        licenseTextView.textColor = UIColor.black
        licenseTextView.textAlignment = .left
        licenseTextView.layer.borderWidth = 1
        licenseTextView.layer.borderColor = Style.Colors.mainOrangeColor.cgColor
        licenseTextView.font = UIFont.systemFont(ofSize: 20.0)
        subview.addSubview(licenseTextView)

        
        // Add the subview to the alert's UI property
        alert.customSubview = subview
        _ = alert.addButton("Save", backgroundColor: UIColor.white, textColor: Style.Colors.mainOrangeColor) {

            if (self.config.getValue("devEndpoint", fromStore: "settings") as! Bool) {
                self.config.writeValue(licenseTextView.text as AnyObject, forKey: "devPlayToken", toStore: "settings")
            } else {
                self.config.writeValue(licenseTextView.text as AnyObject, forKey: "playToken", toStore: "settings")
            }
        }
        
        alert.showSuccess("", subTitle: "")
        
    }

    // shake motion detection part
    override var canBecomeFirstResponder: Bool { return true }
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake
        {
            debugPrint("SHAKE RECEIVED")
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            
            if let vc : CheckoutViewController = mainStoryboard.instantiateViewController(withIdentifier: "checkoutViewController") as? CheckoutViewController {
                vc.gameDataArr = self.gameList
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
