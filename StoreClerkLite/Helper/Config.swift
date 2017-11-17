//
//  Config.swift
//  VALotteryPlay
//
//  Created by Yuriy Berdnikov on 1/10/17.
//  Copyright © 2017 ATM. All rights reserved.
//

import Foundation

struct Config {
    struct APIEndpoints {
        static let getAllChannelsUrl = "https://dev2lngmstr.blob.core.windows.net/templates/channels.json"
        static let playerRegisterUrl = "https://dev2lngmstr.blob.core.windows.net/templates/playerregister.json"
        static let vaLotteryAppImageStr = "http://www.brandsoftheworld.com/sites/default/files/styles/logo-thumbnail/public/062011/virginia_lottery.png?itok=2fnKR4aZ"
    }
    
    struct Share {
        static let appURL = "http://www.playlazlo.com"
    }
    
    struct Google {
        struct Maps {
            static let apiKey = "AIzaSyCKa1dyoX5tunZL_YG6g809xB_2VTXCNPc"
        }
    }
    
    struct Proximity {
        static let beaconUDID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
        static let beaconUDID1 = "87cdbbc3-c802-4570-a5a7-1a3bc87a143a"
    }
    
    struct License {
        static let cypherKey = "ca7eca1c-921f-486a-be25-552f0be14465"
    }
}
