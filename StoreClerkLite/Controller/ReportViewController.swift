//
//  ReportViewController.swift
//  StoreClerkLite
//
//  Created by MyMac on 6/17/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Charts

class ReportViewController: UIViewController, ChartViewDelegate {

    @IBOutlet weak var barChartView: BarChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barChartView.delegate = self
        barChartView.drawBarShadowEnabled = false
        barChartView.drawValueAboveBarEnabled = false
        getReportChartData()
 
        // Do any additional setup after loading the view.
    }

    func setChart(dataPoints: [String], values: [Double]) {
        barChartView.noDataText = "You need to provide data for the chart."
        barChartView.chartDescription?.text = "My Sales History"

        barChartView.setBarChartData(xValues: dataPoints, yValues: values, label: "Monthly Sales")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func getReportChartData() {
        let data : [String : Any] = [String : Any]()
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.labelText = "Getting..."
        AlamofireRequestAndResponse.sharedInstance.getBarChartReport(data, success: { (res: [String : Any]) -> Void in
            MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
            var dates: [String]! = []
            var games: [Double]! = []
            if let reportArr = res["data"] as? NSArray {
                if (reportArr.count != 0) {
                    for item in reportArr {
                        var reportItem = item as! [String : Any]
                        dates.append(reportItem["key"] as! String)
                        games.append(Double(reportItem["value"] as! String)!)
                    }
                }
            }
            self.setChart(dataPoints: dates, values: games)
        },
        failure: { (error: Error!) -> Void in
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

}
