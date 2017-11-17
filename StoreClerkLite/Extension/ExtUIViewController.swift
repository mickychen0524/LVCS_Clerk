//
//  ExtUIViewController.swift
//  VALotteryPlay
//
//  Created by Yuriy Berdnikov on 1/1/17.
//  Copyright © 2017 ATM. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
