//
//  RegisterViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 6/15/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import DropDown
import DatePickerDialog

import MicroBlink

class RegisterViewController: UIViewController, UITextFieldDelegate, PPScanningDelegate {

    
    @IBOutlet weak var firstNameTxtField: PaddingTextField!
    @IBOutlet weak var lastNameTxtField: PaddingTextField!
    @IBOutlet weak var confirmEmailTxtField: PaddingTextField!
    @IBOutlet weak var emailTxtField: PaddingTextField!
    @IBOutlet weak var phoneTxtField: PaddingTextField!
    @IBOutlet weak var confirmPhoneTxtField: PaddingTextField!
    @IBOutlet weak var birthDateTxtField: PaddingTextField!

    @IBOutlet weak var retailerDropDownBtn: DropDownButton!
    @IBOutlet weak var photoIdCodeTxtField: PaddingTextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var scanBtn: UIButton!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    var config = GTStorage.sharedGTStorage
    var appDelegate = UIApplication.shared.delegate! as! AppDelegate
    var userAccessToken : String = ""
    
    var retailerListDropDown = DropDown()
    var i_wasBorn : Int = 0
    var str_wasBorn : String = ""
    
    var originalConstantTxtField : CGFloat! = 0.0
    
    lazy var dropDowns: [DropDown] = {
        return [
            self.retailerListDropDown
        ]
    }()
    
    var selectedStore: Store!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        dropDowns.forEach { $0.dismissMode = .onTap }
        dropDowns.forEach { $0.direction = .bottom }
        setupDefaultDropDown()
        
    }
    
    func setupDefaultDropDown() {
        DropDown.setupDefaultAppearance()
        dropDowns.forEach {
            $0.cellNib = UINib(nibName: "DropDownCell", bundle: Bundle(for: DropDownCell.self))
            $0.customCellConfiguration = nil
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RegisterViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        originalConstantTxtField = bottomConstraint.constant
        
        submitBtn.layer.cornerRadius = 3
        
        retailerDropDownBtn.layer.cornerRadius = 3
        retailerDropDownBtn.layer.borderWidth = 1
        retailerDropDownBtn.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
        
        scanBtn.layer.cornerRadius = 3
        scanBtn.layer.borderWidth = 1
        scanBtn.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
        
        firstNameTxtField.layer.borderWidth = 1
        firstNameTxtField.layer.cornerRadius = 3
        firstNameTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor

        hideKeyboardWhenTappedAround()
        
        firstNameTxtField.delegate = self
        lastNameTxtField.delegate = self
        emailTxtField.delegate = self
        confirmEmailTxtField.delegate = self
        phoneTxtField.delegate = self
        confirmPhoneTxtField.delegate = self
        birthDateTxtField.delegate = self
        photoIdCodeTxtField.delegate = self
        
        birthDateTxtField.addTarget(self, action: #selector(RegisterViewController.inputBirthDate(_:)), for: .editingDidBegin)
        
        setupRetailerDropDown()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // action function for the selecting of birthdate
    @objc func inputBirthDate(_ sender: Any) {
        view.endEditing(true)
        let textField = sender as! UITextField
        let currentDate = Date()
        var dateComponents = DateComponents()
        dateComponents.year = -100
        let hundredYearsAgo = Calendar.current.date(byAdding: dateComponents, to: currentDate)
        
        DatePickerDialog().show("Please choose birthdate", doneButtonTitle: "Done", cancelButtonTitle: "Cancel", minimumDate: hundredYearsAgo, maximumDate: currentDate, datePickerMode: .date) { (date) in
            
            if let dt = date {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let s = dateFormatter.string(from: dt)
                self.str_wasBorn = s
                
                let components = Calendar.current.dateComponents([.day , .month , .year], from: Date())
                let year =  components.year
                let birthDateArr = s.components(separatedBy: "-")
                let wasBorn: Int = Int(birthDateArr[0] as String)!
                self.i_wasBorn = (year! - wasBorn + 1)
                if (self.i_wasBorn > 17) {
                    textField.layer.borderColor = UIColor.blue.cgColor
                } else {
                    textField.layer.borderColor = UIColor.red.cgColor
                }
                textField.text = "\(s)"
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action
    
    @IBAction func submitBtnAction(_ sender: Any) {
        
        if (self.firstNameTxtField.text?.isEmpty)! {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops first name field is empty. \n Please enter first name.", style: AlertStyle.warning)
        } else if (self.lastNameTxtField.text?.isEmpty)! {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops last name field is empty. \n Please enter last name", style: AlertStyle.warning)
        } else if (self.phoneTxtField.text?.isEmpty)! {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops phone number field is empty. \n Please enter phone number", style: AlertStyle.warning)
        } else if (self.emailTxtField.text?.isEmpty)! {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops email address field is empty. \n Please enter email address", style: AlertStyle.warning)
        } else if (self.photoIdCodeTxtField.text?.isEmpty)! {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops photo id code field is empty. \n Please enter photo id code.", style: AlertStyle.warning)
        } else if (self.phoneTxtField.text != self.confirmPhoneTxtField.text) {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops don't match phone number. \n Please confirm phone number.", style: AlertStyle.warning)
        } else if (self.emailTxtField.text != self.confirmEmailTxtField.text) {
            _ = SweetAlert().showAlert("Warning!", subTitle: "Oops don't match email address. \n Please confirm email address.", style: AlertStyle.warning)
        } else if let email = emailTxtField.text, !email.validateEmail() {
            _ = SweetAlert().showAlert("Error", subTitle: "Please input valid email address.", style: AlertStyle.error)
            return
        } else  if let phone = phoneTxtField.text, !phone.validatePhone() {
            _ = SweetAlert().showAlert("Error", subTitle: "Please input valid phone number.", style: AlertStyle.error)
            return
        }else {
            registerUser()
        }
        
    }

    @IBAction func backBtnAction(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func retailerDropDownbtnAction(_ sender: Any) {
        self.retailerListDropDown.show()
    }
    
    @IBAction func scanAction(_ sender: Any) {
        
        /** Instantiate the scanning coordinator */
        let error: NSErrorPointer = nil
        let coordinator = self.coordinatorWithError(error: error)
        
        /** If scanning isn't supported, present an error */
        if coordinator == nil {
            let messageString: String = (error!.pointee?.localizedDescription) ?? ""
            let av = UIAlertController(title: "Warning", message: messageString, preferredStyle: .alert)
            present(av, animated: true, completion: nil)
            return
        }
        
        /** Allocate and present the scanning view controller */
        let scanningViewController: UIViewController = PPViewControllerFactory.cameraViewController(with: self, coordinator: coordinator!, error: nil)
        
        /** You can use other presentation methods as well */
        self.present(scanningViewController, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard
    
    @objc func keyboardWillShow(notification: NSNotification) {
        adjustingHeight(show: true, notification: notification)
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        adjustingHeight(show: false, notification: notification)
    }
    
    func adjustingHeight(show:Bool, notification:NSNotification) {

        var userInfo = notification.userInfo!

        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue

        let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        
        if (show && self.bottomConstraint.constant == self.originalConstantTxtField) {

            UIView.animate(withDuration: animationDurarion, animations: { () -> Void in
                self.bottomConstraint.constant = self.originalConstantTxtField + keyboardFrame.height + 40
            })
        } else if (!show && self.bottomConstraint.constant > self.originalConstantTxtField) {

            UIView.animate(withDuration: animationDurarion, animations: { () -> Void in
                self.bottomConstraint.constant = self.originalConstantTxtField
            })
        }

    }
    
    func setupRetailerDropDown() {
        
        let drawDropList : NSMutableArray = NSMutableArray()
        if let stores = Store.stores, stores.count > 0 {
            for store in stores {
                drawDropList.add(store.retailerName!)
            }
            
            self.retailerListDropDown.dataSource = drawDropList.copy() as! [String]
            self.retailerListDropDown.anchorView = self.retailerDropDownBtn
            self.retailerListDropDown.bottomOffset = CGPoint(x: 0, y: 30)
            
            self.retailerDropDownBtn.setTitle("  Store >  " + stores[0].retailerName!, for: .normal)
            selectedStore = stores[0]
            
            retailerListDropDown.selectionAction = {(index, item) in
                self.retailerDropDownBtn.setTitle("  Store >  " + item, for: .normal)
                self.selectedStore = Store.stores?[index]
            }
        } else {
            self.view.makeToast("there is no retailer yet")
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField.tag {
        case 1:
            firstNameTxtField.layer.borderWidth = 1
            firstNameTxtField.layer.cornerRadius = 3
            firstNameTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 2:
            firstNameTxtField.layer.borderWidth = 0
            lastNameTxtField.layer.cornerRadius = 3
            lastNameTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 1
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 3:
            firstNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.cornerRadius = 3
            emailTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 1
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 4:
            firstNameTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.cornerRadius = 3
            confirmEmailTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 1
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 5:
            firstNameTxtField.layer.borderWidth = 0
            phoneTxtField.layer.cornerRadius = 3
            phoneTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 1
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 6:
            firstNameTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.cornerRadius = 3
            confirmPhoneTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 1
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 7:
            firstNameTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.cornerRadius = 3
            birthDateTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 1
            photoIdCodeTxtField.layer.borderWidth = 0
            break
        case 8:
            firstNameTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.cornerRadius = 3
            photoIdCodeTxtField.layer.borderColor = Style.Colors.mainLightOrangeColor.cgColor
            lastNameTxtField.layer.borderWidth = 0
            emailTxtField.layer.borderWidth = 0
            confirmEmailTxtField.layer.borderWidth = 0
            phoneTxtField.layer.borderWidth = 0
            confirmPhoneTxtField.layer.borderWidth = 0
            birthDateTxtField.layer.borderWidth = 0
            photoIdCodeTxtField.layer.borderWidth = 1
            break
        default:
            break
        }
    }
    
    // register user to the server
    func registerUser() {
        if (self.config.getValue("devEndpoint", fromStore: "settings") as! Bool) {
            self.userAccessToken = config.getValue("fbAccessTokenDev", fromStore: "settings") as! String
        } else {
            self.userAccessToken = config.getValue("fbAccessTokenDemo", fromStore: "settings") as! String
        }
        
        let uuid = UUID().uuidString
        var data = [String: Any]()
        var middleData = [String: Any]()
        var endPointMiddleData = [String: Any]()
        var photoIdData = [String: Any]()
        
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.full
        let convertedDate = dateFormatter.string(from: currentDate)
        
        data["correlationRefId"] = "00000000-0000-0000-0000-000000000000"
        data["uuid"] = uuid
        data["createdOn"] = convertedDate
        data["latitude"] = BeaconManager.shared.coordinate?.latitude
        data["longitude"] = BeaconManager.shared.coordinate?.longitude
        
        photoIdData["photoIdCode"] = self.photoIdCodeTxtField.text
        
        endPointMiddleData["address"] = nil
        endPointMiddleData["isVerified"] = false
        endPointMiddleData["isDefault"] = false
        
        middleData["avatarBase64"] = ""
        middleData["photoId"] = photoIdData
        middleData["retailerRefId"] = BeaconManager.shared.retailerRefIdStr
        middleData["roles"] = ""
        middleData["simulationType"] = ""
        middleData["nameFirst"] = self.firstNameTxtField.text
        middleData["nameMiddle"] = ""
        middleData["nameLast"] = self.lastNameTxtField.text
        middleData["nameAlias"] = ""
        
        endPointMiddleData["address"] = self.emailTxtField.text
        middleData["endpointsEmail"] = [endPointMiddleData]
        
        endPointMiddleData["address"] = self.phoneTxtField.text
        middleData["endpointsVoice"] = [endPointMiddleData]
        
        endPointMiddleData["address"] = self.phoneTxtField.text
        middleData["endpointsText"] = [endPointMiddleData]
        
        
        if selectedStore != nil {
            middleData["addressLine1"] = selectedStore.addressLine1
            middleData["addressLine2"] = selectedStore.addressLine2
            middleData["addressCity"] = selectedStore.addressCity
            middleData["addressStateProvince"] = selectedStore.addressStateProvince
            middleData["addressCounty"] = selectedStore.addressCountry
            middleData["addressZipPostalCode"] = selectedStore.addressZipPostalCode
            middleData["addressCountryCode"] = selectedStore.addressCountryCode
            middleData["addressLocation"] = selectedStore.fullAddress()
        }
        middleData["age"] = 0
        middleData["languageCode"] = ""
        middleData["countryCode"] = ""
        
        data["data"] = middleData
        
        print(JSONHelper.JSONStringify(data))
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Registering..."
        
        AlamofireRequestAndResponse.sharedInstance.registerWithUserData(data, accessToken: self.userAccessToken, success: { (res: [String: Any]) -> Void in
            
            self.view.makeToast("user create success!")
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            self.config.writeValue(true as AnyObject, forKey: "registerState", toStore: "settings")
            let resData: [String: Any] = res["data"] as! [String: Any]
            _ = self.navigationController?.popViewController(animated: true)
            print(JSONHelper.JSONStringify(resData))
            
        },
         failure: { (error: [String: Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            _ = SweetAlert().showAlert("Error!", subTitle: "Oops Register failed. \n Please restart after exit.", style: AlertStyle.error)
            
        })
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: - MicroBlink
    
    func coordinatorWithError(error: NSErrorPointer) -> PPCameraCoordinator? {
        
        /** 0. Check if scanning is supported */
        
        if (PPCameraCoordinator.isScanningUnsupported(for: PPCameraType.back, error: error)) {
            return nil;
        }
        
        
        /** 1. Initialize the Scanning settings */
        
        // Initialize the scanner settings object. This initialize settings with all default values.
        let settings: PPSettings = PPSettings()
        
        
        /** 2. Setup the license key */
        
        // Visit www.microblink.com to get the license key for your app
        settings.licenseSettings.licenseKey = "DT7EUCXO-J5MUJX66-AZ4TKRAQ-WM23ZFNQ-JA5EASV3-4UYOPT33-BQYZ45R3-WUJB6LHQ"
        
        
        /**
         * 3. Set up what is being scanned. See detailed guides for specific use cases.
         * Remove undesired recognizers (added below) for optimal performance.
         */
        
        do {
            
            // To specify we want to perform USDL (US Driver's license) recognition, initialize the USDL recognizer settings
            let usdlRecognizerSettings : PPUsdlRecognizerSettings = PPUsdlRecognizerSettings()
            
            // Set this to YES to scan even barcode not compliant with standards
            // For example, malformed PDF417 barcodes which were incorrectly encoded
            // Use only if necessary because it slows down the recognition process
            // Default: NO
            usdlRecognizerSettings.scanUncertain = false;
            
            // Set this to YES to scan barcodes which don't have quiet zone (white area) around it
            // Disable if you need a slight speed boost
            // Default: YES
            usdlRecognizerSettings.allowNullQuietZone = true;
            
            // Add USDL Recognizer setting to a list of used recognizer settings
            settings.scanSettings.add(usdlRecognizerSettings)
        }
        
        do {
            
            // To specify we want to perform EUDL (EU Driving license) recognition, initialize the EUDL recognizer settings
            // Initializing with PPEudlCountryAny performs the scanning for all supported EU driver's licenses, while initializing with a specific EUDL country (i.e. PPEudlCountryGermany) performs the scanning only for UK dirver's licenses
            let eudlRecognizerSettings = PPEudlRecognizerSettings(eudlCountry: PPEudlCountry.unitedKingdom)
            
            // Add EUDL Recognizer setting to a list of used recognizer settings
            settings.scanSettings.add(eudlRecognizerSettings)
        }
        
        
        /** 4. Initialize the Scanning Coordinator object */
        
        let coordinator: PPCameraCoordinator = PPCameraCoordinator(settings: settings)
        
        return coordinator
    }
    
    // MARK: - PPScanningDelegate
    
    func scanningViewControllerUnauthorizedCamera(_ scanningViewController: UIViewController & PPScanningViewController) {
        // Add any logic which handles UI when app user doesn't allow usage of the phone's camera
    }
    
    func scanningViewController(_ scanningViewController: UIViewController & PPScanningViewController, didFindError error: Error) {
        // Can be ignored. See description of the method
    }
    
    func scanningViewControllerDidClose(_ scanningViewController: UIViewController & PPScanningViewController) {
        // As scanning view controller is presented full screen and modally, dismiss it
        scanningViewController.dismiss(animated: true, completion: nil)
    }
    
    func scanningViewController(_ scanningViewController: (UIViewController & PPScanningViewController)?, didOutputResults results: [PPRecognizerResult]) {
        
        let scanController : PPScanningViewController = scanningViewController as PPScanningViewController!
        
        // Here you process scanning results. Scanning results are given in the array of PPRecognizerResult objects.
        
        // first, pause scanning until we process all the results
        scanController.pauseScanning()
        
        // Collect data from the result
        for result in results {
            
            // Check if result is USDL result
            if (result.isKind(of: PPUsdlRecognizerResult.classForCoder())) {
                
                // Cast result to PPUsdlRecognizerResult
                let usdlResult : PPUsdlRecognizerResult = result as! PPUsdlRecognizerResult
                
                // Fields of the driver's license can be obtained by using keys defined in PPUsdlRecognizerResult.h header file
                
                self.firstNameTxtField.text = usdlResult.getField(kPPCustomerFirstName)
                self.lastNameTxtField.text = usdlResult.getField(kPPCustomerFamilyName)
                self.photoIdCodeTxtField.text = usdlResult.getField(kPPIssuerIdentificationNumber)
                self.birthDateTxtField.text = usdlResult.getField(kPPDateOfBirth)
                
                continue
                
            }
            
            if(result.isKind(of: PPEudlRecognizerResult.classForCoder())) {
                
                // Cast result to PPEudlRecognizerResult
                let eudlResult : PPEudlRecognizerResult = result as! PPEudlRecognizerResult
                
                // Fields of the driver's license can be obtained by using methods defined in PPUkdlRecognizerResult.h header file
                
                self.firstNameTxtField.text = eudlResult.ownerFirstName
                self.lastNameTxtField.text = eudlResult.ownerLastName
                self.photoIdCodeTxtField.text = eudlResult.driverNumber
                self.birthDateTxtField.text = eudlResult.ownerBirthData
                
                continue
            }
        }
        
        scanningViewController?.dismiss(animated: true, completion: nil)
    }
    
    
}
