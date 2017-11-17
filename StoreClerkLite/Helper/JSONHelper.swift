//
//  JSONHelper.swift
//  StoreClerkLite
//
//  Created by Micky on 8/17/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation

class JSONHelper {
    static func JSONStringify(_ value: Any,prettyPrinted:Bool = false) -> String {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        if JSONSerialization.isValidJSONObject(value) {
            do {
                let data = try JSONSerialization.data(withJSONObject: value, options: options)
                if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? {
                    return string
                }
            } catch {
                print("stringfy error")
            }
            
        }
        
        return ""
    }
    
    static func JSONParseArray(_ string: String) -> [String : Any] {
        if let data = string.data(using: String.Encoding.utf8) {
            do {
                if let array = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)  as? [String : Any] {
                    return array
                }
            } catch {
                print("parse array error")
            }
        }
        return [String : Any]()
    }
    
    static func JSONParseForSimpleArray(_ string: String) -> NSArray {
        if let data = string.data(using: String.Encoding.utf8) {
            do {
                if let array = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)  as? NSArray {
                    return array
                }
            } catch {
                print("simple array parse error")
            }
        }
        return NSArray()
    }
}
