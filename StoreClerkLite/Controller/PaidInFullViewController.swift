//
//  PaidInFullViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 3/27/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

class PaidInFullViewController: UIViewController {
    
    
    @IBOutlet weak var amountLbl: UILabel!
    var checkoutObj : [String : Any] = [String : Any]()

    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let amount : Double = Double(truncating: checkoutObj["amount"] as! NSNumber)
        amountLbl.text = String.init(format: "$%.2f", amount)
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
    @IBAction func paidInFulBtnAction(_ sender: Any) {
        checkoutPendingWithCode()
    }
    @IBAction func refuseBtnAction(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        if let vc : MainViewController = mainStoryboard.instantiateViewController(withIdentifier: "checkoutViewController") as? MainViewController {
            self.appDelegate.qrcodeScanFlg = false
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    @IBAction func cancelBtnAction(_ sender: Any) {
        self.appDelegate.qrcodeScanFlg = false
        _ = navigationController?.popViewController(animated: true)
    }

    
    // checkout pending section with string code
    func checkoutPendingWithCode() {
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
        
        middleData["licenseCypherText"] = self.checkoutObj["validateLicenseCode"] as! String
        middleData["amountPaid"] = self.checkoutObj["amount"] as! NSNumber
        if let retailerRefId = Store.stores?[0].retailerRefId {
            middleData["retailerRefId"] = retailerRefId
        }

        data["data"] = middleData
        
        print(JSONHelper.JSONStringify(data))
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Checking out..."
        
        AlamofireRequestAndResponse.sharedInstance.checkoutCompleteWithLicenseCode(data, success: { (res: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.view.makeToast("checkout complete")
            self.appDelegate.qrcodeScanFlg = false
            _ = self.navigationController?.popViewController(animated: true)
        },
        failure: { (error: [String: Any]) -> Void in
            
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Checkout failed. \n Please restart after exit.", style: AlertStyle.error)
            AudioServicesPlayAlertSound(SystemSoundID(1304))
        })
    }
    
    
}
