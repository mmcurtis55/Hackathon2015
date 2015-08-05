//
//  FSLCalendarService.swift
//  Intapp
//
//  Created by ra3571 on 3/4/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import Foundation

/*
* This service is used to access events from the MS Office 365 REST API
* Referencing MS docus
* https://msdn.microsoft.com/office/office365/api/calendar-rest-operations
*/
public class FSLCalendarService {
    
    var authenticatedUser: String?
    var rstToken: String?
    var samlData: NSMutableDictionary?
    
    // MARK: Shared Instance
    public class var sharedInstance: FSLCalendarService  {
        struct Singleton {
            static let instance = FSLCalendarService()
        }
        return Singleton.instance
        
        //
        
    }
}
