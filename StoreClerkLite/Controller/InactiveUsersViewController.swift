//
//  InactiveUsersViewController.swift
//  StoreClerkLite
//
//  Created by Administrator on 10/19/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SCLAlertView
import QRCode

class InactiveUsersViewController: UIViewController {

    @IBOutlet weak var userTableView: UITableView!
    
    var inactiveUsers: [User] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userTableView.tableFooterView = UIView(frame: .zero)
        
        fetchInactiveUsers()
    }
    
    func fetchInactiveUsers() {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Loading..."
        
        AlamofireRequestAndResponse.sharedInstance.fetchInactiveUsers { (users, error) in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            
            if let users = users {
                self.inactiveUsers = users
                self.userTableView.reloadData()
            } else if let _ = error {
                self.view.makeToast("Failed to fetch inactive users")
            } else {
                self.view.makeToast("No inactive users")
            }
        }
    }

    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var back: UIButton!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension InactiveUsersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inactiveUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        if let firstname = inactiveUsers[indexPath.row].firstname, let lastname = inactiveUsers[indexPath.row].lastname {
            cell.nameLabel.text = firstname + " " + lastname
        } else if let firstname = inactiveUsers[indexPath.row].firstname {
            cell.nameLabel.text = firstname
        } else if let lastname = inactiveUsers[indexPath.row].lastname {
            cell.nameLabel.text = lastname
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let user = inactiveUsers[indexPath.row]
        
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: false,
            showCircularIcon: false,
            contentViewColor: UIColor.white,
            contentViewBorderColor: Style.Colors.mainOrangeColor,
            titleColor: Style.Colors.mainOrangeColor
        )
        
        let alert = SCLAlertView(appearance: appearance)
        
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: 216, height: 180))
        
        let qrCodeImageView = UIImageView(frame: CGRect(x: 18, y: 0, width: 180, height: 180))
        contentView.addSubview(qrCodeImageView)
        
        if let base64QRCode = user.base64QRCode, let data = Data(base64Encoded: base64QRCode) {
            qrCodeImageView.image = UIImage(data: data)
        }
        
        alert.customSubview = contentView
        _ = alert.addButton("Cancel", backgroundColor: UIColor.white, textColor: Style.Colors.mainOrangeColor) {
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.showInfo("Scan Activation Code", subTitle: "")
    }
}
