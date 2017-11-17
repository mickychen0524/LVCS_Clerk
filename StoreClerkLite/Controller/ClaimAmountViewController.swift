//
//  ClaimAmountViewController.swift
//  StoreClerkLite
//
//  Created by Administrator on 10/2/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class ClaimAmountViewController: UIViewController {
    
    @IBOutlet weak var amountLabel: UILabel!
    
    var correlationRefId: String!
    var claimLicenseCode: String!
    var amount: Float!

    override func viewDidLoad() {
        super.viewDidLoad()

        amountLabel.text = String(format: "$%.2f", amount)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func completeClaim(_ sender: Any) {
        let uuid = UUID().uuidString
        var params = [String: Any]()
        var data = [String: Any]()
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: currentDate)
        
        params["correlationRefId"] = correlationRefId
        params["uuid"] = uuid
        params["createdOn"] = convertedDate
        params["latitude"] = BeaconManager.shared.coordinate?.latitude
        params["longitude"] = BeaconManager.shared.coordinate?.longitude
        
        data["claimLicenseCode"] = claimLicenseCode
        
        params["data"] = data
        
        print(JSONHelper.JSONStringify(params))
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Completing..."
        AlamofireRequestAndResponse.sharedInstance.completeClaim(correlationRefId, params: params, success: { (response) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.view.makeToast("coupon claimed successfully")
            for controller in self.navigationController!.viewControllers {
                if controller is MainViewController {
                    self.navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
        }) { (error) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Completing claim failed. \n Please try again.", style: AlertStyle.error)
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

}
