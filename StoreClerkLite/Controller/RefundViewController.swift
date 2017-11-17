//
//  RefundViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 6/18/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Toast_Swift

class RefundViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var refundBtn: UIButton!
    @IBOutlet weak var qrcodeView: UIView!
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    var alertState:Bool?
    var refundLicenseCode : String? = ""
    
    // Added to support different barcodes
    let supportedBarCodes = [AVMetadataObject.ObjectType.qr, AVMetadataObject.ObjectType.code128, AVMetadataObject.ObjectType.code39, AVMetadataObject.ObjectType.code93, AVMetadataObject.ObjectType.upce, AVMetadataObject.ObjectType.pdf417, AVMetadataObject.ObjectType.ean13, AVMetadataObject.ObjectType.aztec]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refundBtn.layer.cornerRadius = 3
        refundBtn.layer.borderWidth = 1
        refundBtn.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
        refundBtn.isEnabled = false
        
        alertState = false
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
            videoPreviewLayer?.frame = self.qrcodeView.layer.bounds
            self.qrcodeView.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                self.qrcodeView.addSubview(qrCodeFrameView)
                self.qrcodeView.bringSubview(toFront: qrCodeFrameView)
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
    
    @IBAction func backBtnAction(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    @IBAction func refundBtnAction(_ sender: Any) {
        refundAction()
    }
    
    func refundAction() {
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
        
        middleData["refundLicenseCode"] = self.refundLicenseCode
        middleData["amountDue"] = 0

        data["data"] = middleData
        
        print(JSONHelper.JSONStringify(data))
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Refunding..."
        
        AlamofireRequestAndResponse.sharedInstance.refundCompleteWithQRCode(data, success: { (res: [String: Any]) -> Void in
            
            self.view.makeToast("refund success!")
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = self.navigationController?.popViewController(animated: true)
            
        },
        failure: { (error: NSError!) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Register failed. \n Please restart after exit.", style: AlertStyle.error)
            
        })
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
                    
                    let length: Int = (metadataObj.stringValue?.length)!
                    if (length > 120) {
                        self.refundLicenseCode = metadataObj.stringValue
                        refundBtn.isEnabled = true
                        self.view.makeToast("refund code captured \n" + metadataObj.stringValue!)
                        
                    } else {
                        // vibration and any sound
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.alertState = false
                            AudioServicesPlayAlertSound(SystemSoundID(1304))
                            self.view.makeToast("INVALID SCAN")
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
