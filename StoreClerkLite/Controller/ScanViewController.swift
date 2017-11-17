//
//  ScanViewController.swift
//  StoreClerkLite
//
//  Created by Administrator on 8/14/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController {
    
    @IBOutlet weak var preview: QRCodePreview!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        preview.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension ScanViewController: QRCodePreviewDelegate {
    func didScanFinished(success: Bool!, code: String?) {
        if success == true {
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.labelText = "Applying..."

            AlamofireRequestAndResponse.sharedInstance.getAppliedAmountWithLicenseCode(code, success: { (response) in
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.view.makeToast("applied successfully")
                if let applyAmountViewController = self.storyboard?.instantiateViewController(withIdentifier: "ApplyAmountViewController") as? ApplyAmountViewController {
                    if let correlationRefId = response["correlationRefId"] as? String, let data = response["data"] as? [String: Any] {
                        applyAmountViewController.correlationRefId = correlationRefId
                        applyAmountViewController.claimLicenseCode = data["claimLicenseCode"] as! String
                        applyAmountViewController.appliedAmount = data["appliedAmount"] as! Float
                        self.navigationController?.pushViewController(applyAmountViewController, animated: true)
                    }
                }
            }, failure: { (error) in
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                _ = SweetAlert().showAlert("Error!", subTitle: "Oops Appling amount failed. \n Please try again.", style: AlertStyle.error, buttonTitle: "OK", action: { (isOtherButton) in
                    if isOtherButton == true {
                        self.preview.prepare()
                    }
                })
            })
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(1304))
            view.makeToast("INVALID SCAN")
        }
    }
}
