//
//  CheckoutViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 3/27/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class CheckoutViewController: UIViewController, UITextFieldDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var qrcodePreview: UIView!
    @IBOutlet weak var playerCodeEditLbl: UITextField!
    @IBOutlet weak var playerCodeErrorLbl: UILabel!
   
    var config = GTStorage.sharedGTStorage
    var gameDataArr : NSArray = NSArray()
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var alertState:Bool?
    
    // Added to support different barcodes
    let supportedBarCodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.aztec]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.playerCodeErrorLbl.isHidden = true
        self.playerCodeEditLbl.layer.borderColor = UIColor.clear.cgColor
        self.playerCodeEditLbl.layer.borderWidth = 1.0
        
        alertState = false
        playerCodeEditLbl.delegate = self
        playerCodeEditLbl.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        setQRCodePreview()
        // Do any additional setup after loading the view.
    }
    
    func setQRCodePreview() {
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Detect all the supported bar code
            captureMetadataOutput.metadataObjectTypes = supportedBarCodes
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = self.qrcodePreview.layer.bounds
            self.qrcodePreview.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                self.qrcodePreview.addSubview(qrCodeFrameView)
                self.qrcodePreview.bringSubview(toFront: qrCodeFrameView)
            }
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }

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
    @IBAction func nextBtnAction(_ sender: Any) {
        if (playerCodeEditLbl.text == "12345") {
            self.playerCodeErrorLbl.isHidden = true
            self.playerCodeEditLbl.layer.borderColor = UIColor.clear.cgColor
            self.playerCodeEditLbl.layer.borderWidth = 1.0
            checkoutPendingWithCode(code: playerCodeEditLbl.text!)
            
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(1304))
            self.playerCodeErrorLbl.isHidden = false
            self.playerCodeEditLbl.layer.borderColor = UIColor.red.cgColor
            self.playerCodeEditLbl.layer.borderWidth = 1.0
        }
    }
    
    // checkout pending section with string code
    func checkoutPendingWithCode(code : String) {
        
        let uuid = UUID().uuidString
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: currentDate)
        
        data["correlationRefId"] = "00000000-0000-0000-0000-000000000000"
        data["uuid"] = uuid
        data["createdOn"] = convertedDate
        data["latitude"] = BeaconManager.shared.coordinate?.latitude
        data["longitude"] = BeaconManager.shared.coordinate?.longitude
        
        middleData["checkoutSessionShortCode"] = code
        data["data"] = middleData
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Checking out..."
        
        AlamofireRequestAndResponse.sharedInstance.checkoutPendingWithCode(data, success: { (res: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            let resData: [String: Any] = res["data"] as! [String: Any]
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc : PaidInFullViewController = mainStoryboard.instantiateViewController(withIdentifier: "paidViewController") as? PaidInFullViewController {
                vc.checkoutObj = resData
                self.appDelegate.qrcodeScanFlg = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
        },
         failure: { (error: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.view.endEditing(true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Checkout failed. \n Please restart after exit.", style: AlertStyle.error, buttonTitle:"Ok") { (isOtherButton) -> Void in
                if isOtherButton == true {
                    
                }
                
            }
            
            AudioServicesPlayAlertSound(SystemSoundID(1304))
        })
    }
    
    // checkout pending section with sacnned qr code
    func checkoutWithQRCodeValue(code : String) {
        
        let uuid = UUID().uuidString
        var data = [String: Any]()
        var middleData = [String: Any]()
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: currentDate)
        
        data["correlationRefId"] = "00000000-0000-0000-0000-000000000000"
        data["uuid"] = uuid
        data["createdOn"] = convertedDate
        data["latitude"] = BeaconManager.shared.coordinate?.latitude
        data["longitude"] = BeaconManager.shared.coordinate?.longitude
        
        middleData["checkoutSessionLicenseCode"] = code
        if let retailerId = Store.stores?[0].retailerRefId {
            middleData["retailerRefId"] = retailerId
        }
        data["data"] = middleData
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Checking out..."
        
        print(JSONHelper.JSONStringify(data))
        
        AlamofireRequestAndResponse.sharedInstance.checkoutPendingWithQRCode(data, success: { (res: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            let resData: [String: Any] = res["data"] as! [String: Any]
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            if let vc : PaidInFullViewController = mainStoryboard.instantiateViewController(withIdentifier: "paidViewController") as? PaidInFullViewController {
                vc.checkoutObj = resData
                self.navigationController?.pushViewController(vc, animated: true)
                self.appDelegate.qrcodeScanFlg = true
                self.alertState = false
            }
            
        },
       failure: { (error: [String: Any]) -> Void in

            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.view.endEditing(true)
            print(JSONHelper.JSONStringify(error))
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Checkout failed. \n Please restart after exit.", style: AlertStyle.error, buttonTitle:"Ok") { (isOtherButton) -> Void in
                if isOtherButton == true {
                    self.alertState = false
                }
                
            }
            AudioServicesPlayAlertSound(SystemSoundID(1304))
        })
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        self.playerCodeErrorLbl.isHidden = true
        self.playerCodeEditLbl.layer.borderColor = UIColor.clear.cgColor
        self.playerCodeEditLbl.layer.borderWidth = 1.0
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // Here we use filter method to check if the type of metadataObj is supported
        // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
        // can be found in the array of supported bar codes.
        if supportedBarCodes.contains(metadataObj.type) {
            //        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                if (!alertState! && !self.appDelegate.qrcodeScanFlg){
                    alertState = true
                    
                    if (metadataObj.stringValue?.contains("[CS]"))! {
                        self.checkoutWithQRCodeValue(code: metadataObj.stringValue!)
                    } else {
                        // vibration and any sound
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.alertState = false
                            AudioServicesPlayAlertSound(SystemSoundID(1304))
                            self.view.makeToast("Oops! Invalid Scan Value. This is not a Cart.")
                        }
                    }

                } else {
                    qrCodeFrameView?.frame = CGRect.zero
                    return
                }
            }
        }
    }
    
}
