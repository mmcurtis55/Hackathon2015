//
//  MenuItemService.swift
//  Internator
//
//  Created by ra3571 on 1/14/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import Foundation
import CoreData
import UIKit

/**
* Service class to get MenuItems from CoreData or to init from JSON URL (local/remote/both!)
*/
class MenuItemService {

    // MARK: Shared Instance
    class var sharedInstance: MenuItemService  {
        struct Singleton {
            static let instance = MenuItemService()
        }
        return Singleton.instance
    }
    
    // create instance variable to hold the nscontext
    lazy var managedObjectContext : NSManagedObjectContext? = {

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        } else  {
            return nil
        }
    }()
    
 
    // get the menu items for users that are logged and authorized to view
    func getAuthenticatedMenuItems(fileName: String, completion : (results: [MenuItem]?, error : NSError?) -> Void){
        // get the local file as a URL so that we can replace with remote URLs
        let url = NSBundle.mainBundle().URLForResource("loginMenuItems", withExtension: "json")!
        getMenuItemsFromURL(url, callback: completion)
    }
    
    // get the menu items from a file in the application
    // calls the completion callback on the main thread when the results are
    func getMenuItems(fileName: String, completion: (results: [MenuItem]?, error : NSError?) -> Void) {
        let url = NSBundle.mainBundle().URLForResource("menuItems", withExtension: "json")!
        getMenuItemsFromURL(url, callback: completion)
    }
    
    /////////////////////////////////
    // private methods
    
    /*!
    reads in a json file from URL returns MenuItem.
    sideeffect is that the menu items are added back in
    */
    private func getMenuItemsFromURL(url: NSURL, callback: (results: [MenuItem]?, error : NSError?) -> Void) {
        
        DLog("getMenuItemsFromURL url: \(url)")
        clearMenuItems()
        
        let mySession = NSURLSession.sharedSession()
        // get the json task in the background
        let networkTask = mySession.dataTaskWithURL(url, completionHandler: {
            data, response, error -> Void in
            
            // check if there is an error getting URL i.e. network error
            if (error != nil) {
                DLog("ERROR: \(error)")
                return
            }
            let menuItems = self.processMenuItemJSON(data)
            // now that we have the MenuItems call the function passed in by the user
            dispatch_async(dispatch_get_main_queue(), {
                callback(results: menuItems, error: nil)
            })
        })
        // important start the task or code in closure will not run
        networkTask.resume()

    }
    
    /*!
    * This method takes the JSON information as NSData and returns an array of MenuItem
    * data is a NSData object in JSON format.
    * assume that JSON file looks like:
    * {"items":
    [
    {"label":"Map", "iconURL":"map_white_96.png","type":"map","dataURL":"sites.json"},
    {"label":"Menu 2", "iconURL":"https://placekitten.com/g/82/82","type":"table","dataURL":"http://www.reddit.com/.json"},
    .
    .
    ]
    }
    */
    private func processMenuItemJSON(data: NSData) -> [MenuItem] {
        // place holder for any errors encountered while parsing the JSON data
        var err: NSError?
        if var jsonData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as? NSMutableDictionary {
            // get all the children array from the response
            return processData(jsonData["items"]! as! NSArray)
        } else {
            return []
        }
        
    }
    
    /*!
    * Used to process the menuItem JSON format
    * if that file changes then this one must too.
    *
    * from menuitem.json
    
    *  {"label":"Menu 1", "iconURL":"map_white_96","type":"table","dataURL":"http://www.restserver.com/json, "size":"72x72"},
    
    * iconURL will either be remote or local. Local files are specified
    * relative to the application root.
    *
    * @params menuItems
    *
    */
    private func processData(array: NSArray) -> [MenuItem] {
 
        
        var menuItems = [MenuItem]()
        
        // for each JSON menu object...
        for obj in array {
            // create the menu item core data objects from the JSON array
            DLog("obj: \(obj)")
            var menuItem = obj as! NSMutableDictionary
            
            // create a new menu item
            let newMenuItem = NSEntityDescription.insertNewObjectForEntityForName("MenuItem", inManagedObjectContext: self.managedObjectContext!) as! MenuItem
            
            // these are mandatory fields
            newMenuItem.label = menuItem["label"] as! String
            newMenuItem.iconUrl = menuItem["iconURL"] as! String
            newMenuItem.segueUrl = menuItem["dataURL"] as! String
            newMenuItem.type = menuItem["type"] as! String
            
            // these are optional so we check for them and provide a sensible default val
            if let color = menuItem["color"] as? String {
                newMenuItem.color = color
            } else {
                if let bgcolor = NSUserDefaults.standardUserDefaults().valueForKey("menuview.bgcolor") as? String {
                    newMenuItem.color = bgcolor
                } else {
                    newMenuItem.color = "#666666"
                }
            }
            
            if let tint = menuItem["tint"] as? String {
                newMenuItem.tint = tint
            } else {
                if let tint = NSUserDefaults.standardUserDefaults().valueForKey("menuview.tint") as? String {
                    newMenuItem.tint = tint
                } else {
                    newMenuItem.tint = "#FFFFFF"
                }
            }
            
            // newMenuItem.size = setMenuItemField(newMenuItem, jsonMenuItem, "96x96"
            if let size = menuItem["size"] as? String {
                newMenuItem.size = size
            } else {
                if let size = NSUserDefaults.standardUserDefaults().valueForKey("menuview.size") as? String {
                    newMenuItem.size = size
                } else {
                    newMenuItem.size = "96x96"
                }
            }
            

            // this will allow to get in the order the were created bu sorting on this field
            newMenuItem.created = NSDate()
            
            // get the NSData from the URL provided
            let icon = UIImage(named: newMenuItem.iconUrl)
            
            // store as PNG
            var imageData = UIImagePNGRepresentation(icon)

            // last resort use a default image that should be locally available
            if (imageData == nil) {
                // use this to get the correct image file for retina displays etc.
                let defaultIcon = UIImage(named: "appicon.png")
                imageData = UIImagePNGRepresentation(defaultIcon)
            }
            
            // image data should never be nil because we default to local image (make sure it exists)
            newMenuItem.thumbnail = imageData!
            // add to the array
            menuItems.append(newMenuItem)

        }
        
        var error = NSErrorPointer()
        managedObjectContext!.save(error)
        
        return menuItems
    }
    
    private func clearMenuItems() {
        let fetchRequest = NSFetchRequest(entityName: "MenuItem")
        
        // execute the request, if it worked check the count
        if let menuItems = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [MenuItem] {
            DLog("calling executeFetchRequest, found \(menuItems.count)")
            for menuItem in menuItems {
                managedObjectContext!.deleteObject(menuItem)
            }
            var error = NSErrorPointer()
            managedObjectContext!.save(error)
            
        }
        
        if let menuItems2 = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [MenuItem] {
            if (menuItems2.count > 0) {
                 DLog("Calling executeFetchRequest after delete, found \(menuItems2.count)")
            }
        }

    }
    
    
}
