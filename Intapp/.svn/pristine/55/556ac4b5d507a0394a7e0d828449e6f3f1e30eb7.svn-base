//
//  IndoorNavigationService.swift
//  Intapp
//
//  Created by ra3571 on 4/12/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import Foundation
import CoreData

/**
* buildings.json
"items":[
{"label":"San Saba","type":"ConferenceRoom","hint":"Right behind north lobby security desk", "coords":[]},
{"label"
*
* Stored data as NSManagedObject for the app session (json file is
* always read at startup
*/
class IndoorNavigationService {
    
    
    
    var isInitialized = false
    var locations = [AnyObject]()
    
    // MARK: Shared Instance
    class var sharedInstance: IndoorNavigationService  {
        struct Singleton {
            static let instance = IndoorNavigationService()
        }
        return Singleton.instance
    }
    
    // constructor
    
    // create instance variable to hold the nscontext
    lazy var managedObjectContext : NSManagedObjectContext? = {
        
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        } else  {
            return nil
        }
    
    }()

    
    var tableData: NSDictionary?
    var itemToBuildingMap = [String:NSDictionary]()
    
    init() {
        // read in any stored properties like building json file
        let defaults = NSUserDefaults.standardUserDefaults()
        
        DLog("init called", function: "IndoorNavigationService")
 
    }
    
    /** returns the building an item is in
    */
//    func getBuilding(item: String) -> String  {
//        if let val = itemToBuildingMap[item] {
//            return val
//        } else {
//            return ""
//        }
//    }
    
    func getBuilding(item: String) -> NSDictionary  {
        if let val = itemToBuildingMap[item] {
            return val
        } else {
            return [:]
        }
    }
    
    /** This function will returns the sites (locations from the building js file) in a callback function
*/
    func getSites(callback: (results: [AnyObject]?, error: NSError?) -> Void) {
        
        if (locations.count > 0) {
             callback(results: locations, error: nil)
        } else {
            getDataModel() {
                tableData, err in
                
                if (err != nil) {
                    callback(results:self.locations, error: err)
                   
                } else {
                    // locations is set in the getDataModel
                    callback(results: self.locations, error: nil)
                }
            }
 
        }
    }
    
    func getDataModel(callback: (results: NSDictionary?, error : NSError?) -> Void) {
        if (tableData != nil) {
            callback(results: tableData, error: nil)
        } else {
            let fileName = "buildings"
            let url = NSBundle.mainBundle().URLForResource(fileName, withExtension: "json")!
            // results is called from the main queue
            getDataFromURL(url) {results, error in
                // check if there is an error getting URL i.e. network error
                if (error != nil) {
                    DLog("ERROR: \(error)")
                    callback(results: nil, error: error)
                    return
                }
                // set the results
                self.tableData = results
                self.isInitialized = true

                callback(results: self.tableData, error: nil)
            
            }
        }
    }

   
    
    // returns a list of points of interests that match
    // the query criteria
    func findAll(string: String) -> [String] {
        
        var ret_val = [""]
        
        // use the NSManagedObject to search
         
        return ret_val
    }
    
 
    
    /////////////////////////////////////////
    // MARK: - Private
    /*!
    reads in a json file from URL returns building items.
    sideeffect is that the menu items are added back in
    */
    private func getDataFromURL(url: NSURL, callback: (results: NSDictionary?, error : NSError?) -> Void) {
        
        DLog("getDataFromURL url: \(url)")
        clearNSManagedObjects()
        
        let mySession = NSURLSession.sharedSession()
        // get the json task in the background
        let networkTask = mySession.dataTaskWithURL(url) {
            data, response, error -> Void in
            
            // check if there is an error getting URL i.e. network error
            if (error != nil) {
                DLog("ERROR: \(error)")
                return
            }
            let jsonData = self.processJSONData(data)
            
            // now that we have the MenuItems call the function passed in by the user
            dispatch_async(dispatch_get_main_queue(), {
                callback(results: jsonData, error: nil)
            })
        }
        // important start the task or code in closure will not run
        networkTask.resume()
        
    }

    private func clearNSManagedObjects() {
        clearBuildings()
        clearBuildingEntities()
    }
    
    private func clearBuildings() {
        clearNSManagedObject("Building")
    }
    
    private func clearBuildingEntities() {
        clearNSManagedObject("BuildingEntity")
    }

    private func clearNSManagedObject(entityName:String) {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        // execute the request, if it worked check the count
        if let objects = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [NSManagedObject] {
            for o in objects {
                managedObjectContext!.deleteObject(o)
            }
            var error = NSErrorPointer()
            managedObjectContext!.save(error)
        }
    }

    // process the data returned from a URL (web service or file)
    private func processJSONData(data: NSData) -> NSDictionary {
        
        // place holder for any errors encountered while parsing the JSON data
        var err: NSError?
        
        var jsonData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSMutableDictionary
        
        // TODO: check if there is an NSError
        if (err != nil) {
            return ["locations":[]] as NSDictionary
        } else {
            
            // update the mapping
            // location array
            itemToBuildingMap = [String:NSDictionary]()

            if let locs = jsonData["locations"] as? [AnyObject] {
                
                for loc in locs {
                    if let label = loc["label"] as? String {
                        // buildings array
                       
                        locations.append(label)
                        if let buildings = loc["buildings"] as? NSArray {
                            for b in buildings {
                                if let name = b["label"] as? String {

                                    // create the Building
                                    let building = NSEntityDescription.insertNewObjectForEntityForName("Building", inManagedObjectContext: self.managedObjectContext!) as! Building
                                    building.name = name
                                    building.location = label

                                    // for each item...
                                    
                                    var buildingItems = building.valueForKeyPath("items") as! NSMutableOrderedSet
                                    
                                    if let items = b["items"] as? NSArray {
                                        for i in items {
                                            if let label = i["label"] as? String {
                                                
                                                let buildingItem = NSEntityDescription.insertNewObjectForEntityForName("BuildingEntity", inManagedObjectContext: self.managedObjectContext!) as! BuildingEntity
                                                buildingItem.name = name
                                                buildingItem.building = building
                                                
                                                buildingItems.addObject(buildingItem)
                                                itemToBuildingMap[label] = b as? NSDictionary
                                            }
                                        } // for each item
                                    } // if items
                                } // if label
                                
                                // save the building object
                                var error = NSErrorPointer()
                                managedObjectContext!.save(error)
                                
                            } // for each building
                        } // if buildings
                    } // if alias
                } // for
            }
            
            return jsonData
            
        }
    }

    
}


