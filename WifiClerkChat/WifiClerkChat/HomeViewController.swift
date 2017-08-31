//
//  HomeViewController.swift
//  WifiClerkChat
//
//  Created by Swayam Agrawal on 30/08/17.
//  Copyright © 2017 Avviotech. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    let bonjourService = ServiceManager.sharedServiceManager
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    @IBAction func start(_ sender: Any) {
        
        bonjourService.startAdvertising(uuid: UUID().uuidString)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier :"clientList") as! ViewController
        
        self.navigationController?.pushViewController(viewController, animated: false)
    }
}
