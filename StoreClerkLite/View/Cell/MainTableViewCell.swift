//
//  MainTableViewCell.swift
//  StoreClerkLite
//
//  Created by MyMac on 3/27/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import Kingfisher

class MainTableViewCell: UITableViewCell {

    
    @IBOutlet weak var gameTileImg: UIImageView!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var gameDateLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    // make table view cell using channel group data
    func configWithData(item: [String: Any]) {
        
        let prizesArr : NSArray = item["prizes"] as! NSArray
        
        self.gameTileImg.kf.setImage(with: URL(string: item["logoUrl"] as! String))
        self.gameTileImg.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth, .flexibleHeight]
        self.gameTileImg.contentMode = UIViewContentMode.scaleAspectFit
        
        var maxPrice = 0.0
        for item1 in prizesArr {
            var prizeItem = item1 as! [String : Any]
            let prize = prizeItem["amountAtOpen"] as! NSNumber
            if (maxPrice < Double(truncating: prize)) {
                maxPrice = Double(truncating: prize)
            }
        }
        
        self.priceLbl.text = String.init(format: "$%.2f", maxPrice)
        self.gameDateLbl.text = "3/25/2017"
        
    }
}
