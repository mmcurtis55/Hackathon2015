//
//  UtilityService.swift
//  Intapp
//
//  Created by ra3571 on 5/22/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import Foundation

/**
Simple service to check if app is running in iOS8 env
*/
class UtilityService {

//    class var sharedInstance: UtilityService  {
//        struct Singleton {
//            static let instance = UtilityService()
//        }
//        return Singleton.instance
//    }
    
    class var isiOS8: Bool {
        get {
            return objc_getClass("UIAlertController") != nil
        }
    }
}
