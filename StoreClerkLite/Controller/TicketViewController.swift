//
//  TicketViewController.swift
//  StoreClerkLite
//
//  Created by Administrator on 10/2/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class TicketViewController: UIViewController {
    
    @IBOutlet weak var preview: QRCodePreview!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        preview.delegate = self
        hideKeyboardWhenTappedAround()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        preview.prepare()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func codeTextFieldDidChange(_ textField: UITextField) {
        errorLabel.isHidden = true
        codeTextField.layer.borderUIColor = UIColor.clear
    }
    
    @IBAction func next(_ sender: Any) {
        if codeTextField.text == "12345" {
            errorLabel.isHidden = true
            codeTextField.layer.borderUIColor = UIColor.clear
            claimWithCode(codeTextField.text)
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(1304))
            errorLabel.isHidden = false
            codeTextField.layer.borderUIColor = UIColor.red
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
}

extension TicketViewController {
    
    func claimWithCode(_ code: String!) {
        claim(code)
    }
    
    func claimWithQRCode(_ qrCode: String!) {
        claim(qrCode)
    }
    
    func claim(_ code: String!) {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Claiming..."
        
        AlamofireRequestAndResponse.sharedInstance.claimWithCode(code, completionHandler: { (correlationRefId, licenseCode, amount, error) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            if error != nil {
                self.view.endEditing(true)
                _ = SweetAlert().showAlert("Error!", subTitle: "Oops Claim failed. \n Please restart after exit.", style: AlertStyle.error, buttonTitle: "Ok")
                self.preview.prepare()
            } else {
                if let ticketAmountViewController = self.storyboard?.instantiateViewController(withIdentifier: "TicketAmountViewController") as? TicketAmountViewController {
                    ticketAmountViewController.correlationRefId = correlationRefId
                    ticketAmountViewController.claimLicenseCode = licenseCode
                    ticketAmountViewController.amount = amount
                    self.navigationController?.pushViewController(ticketAmountViewController, animated: true)
                }
            }
        })
    }
}

extension TicketViewController: QRCodePreviewDelegate {
    
    func didScanFinished(success: Bool!, code: String?) {
        if success == true {
            if let code = code, code.contains("[CC]") {
                claimWithQRCode(code)
            } else {
                AudioServicesPlayAlertSound(SystemSoundID(1304))
                view.makeToast("Oops! Invalid Scan Value. This is not a Coupon.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.preview.prepare()
                }
            }
        } else {
            AudioServicesPlayAlertSound(SystemSoundID(1304))
            view.makeToast("Oops! Invalid Scan Value. This is not a Coupon.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.preview.prepare()
            }
        }
    }
}
