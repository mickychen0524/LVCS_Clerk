//
//  ApplyAmountViewController.swift
//  StoreClerkLite
//
//  Created by Administrator on 8/14/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Toast_Swift

class ApplyAmountViewController: UIViewController {
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var appliedAmountLabel: UILabel!
    
    var correlationRefId: String!
    var claimLicenseCode: String!
    var appliedAmount: Float!
    
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()

        appliedAmountLabel.text = String(format: "$%.2f", appliedAmount)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func accept(_ sender: Any) {
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
        loadingNotification?.labelText = "Accepting..."
        AlamofireRequestAndResponse.sharedInstance.acceptAppliedAmount(correlationRefId, params: params, success: { (response) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.view.makeToast("accepted successfully")
            for controller in self.navigationController!.viewControllers {
                if controller is MainViewController {
                    self.navigationController!.popToViewController(controller, animated: true)
                    break
                }
            }
        }) { (error) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Accepting amount failed. \n Please try again.", style: AlertStyle.error)
        }

    }

    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
