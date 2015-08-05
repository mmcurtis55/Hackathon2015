//
//  SiteNavSearchTableViewController.swift
//  Intapp
//
//  Created by ra3571 on 4/14/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//
//

import UIKit

class SiteNavSearchTableViewController: UITableViewController, UISearchResultsUpdating, Selectable {
    
    // replace with lazy call to load from the IndoorNavigationService
    var tableData2 = [String:AnyObject]()
    var dataModel:NSDictionary?
    var tableData = [String]()
    var filteredTableData = [String]()
    var resultSearchController = UISearchController()
    var selectedValue: AnyObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.sizeToFit()
            
            self.tableView.tableHeaderView = controller.searchBar
    
            return controller
        })()
        
        populateTableData()
    }
    
    /*!
    * This function will populate the table with data from a URL
    *  Right now this can handle rss data and JSON data with the following format.
    *
    * JSON Format to display data in a
    * {"data":
    "children":[
    "data":{"title":"some title", "thumbnail":"http://someserver/image.jpg"}
    ]
    }
    *
    */
    func populateTableData() {
        
        IndoorNavigationService.sharedInstance.getDataModel() {(results, error) -> Void in
            
            // TODO: check for error
            
            // reload the data since we have new data model
            self.dataModel = results
            
            // process the dataModel by putting all the items in a map
            // where the key is a string like OHT D1
            var data = [String: [AnyObject]]()
            self.tableData = []
            // location array
            if let locations = self.dataModel?["locations"] as? [AnyObject] {
                for loc in locations {
                    if let label = loc["label"] as? String {
                        // buildings array
                        if let buildings = loc["buildings"] as? NSArray {
                            for b in buildings {
                                if let name = b["label"] as? String {
                                    data["\(label) \(name)"] = []
                                    var arr = data["\(label) \(name)"]!
                                    // for each item...
                                    if let items = b["items"] as? NSArray {
                                        for i in items {
                                            if let label = i["label"] as? String {
                                                arr.append(label)
                                                self.tableData.append(label)
                                            }
                                        } // for each item
                                    } // if items
                                    data["\(label) \(name)"] = arr
                                } // if label
                            } // for each building
                        } // if buildings
                    } // if alias
                } // for
            }
            self.tableData2 = data
            self.tableView.reloadData()
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Selectable
    func getSelectedValue() -> AnyObject? {
        return selectedValue
    }
    
    // MARK: - Table view data source
    
    /**
    {"locations":[{
    "locationCode":"TX30",
    "label":"OHT",
    "dataUrl":"OHT.pdf"
    "buildings":
    [
    */
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if (self.resultSearchController.active) {
            return 1
        } else  {
            return tableData2.count
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.resultSearchController.active) {
            return self.filteredTableData.count
        } else {
            let buildings = sorted(tableData2.keys)
            let key = buildings[section]
            if let items = tableData2[key] as? NSArray {
                return items.count
            } else {
                return 0
            }
        }
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        if (self.resultSearchController.active) {
            cell.textLabel?.text = filteredTableData[indexPath.row]
            cell.detailTextLabel?.text = ""
            return cell
        }
        else {
            let buildings = sorted(tableData2.keys)
            let key = buildings[indexPath.section]
            
            if let items = tableData2[key] as? NSArray {
                var sortedItems = sortItems(items)
                cell.textLabel?.text = sortedItems[indexPath.row] as? String
                cell.detailTextLabel?.text = ""
            }
            
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // if we are
        var selectedItem = ""
        if (self.resultSearchController.active) {
            // get the selected value from the filteredTableData
            selectedItem = filteredTableData[indexPath.row]
            
        } else {
            let buildings = sorted(tableData2.keys)
            let key = buildings[indexPath.section]
            
            if let items = tableData2[key] as? NSArray {
                var sortedItems = sortItems(items)
                selectedItem = sortedItems[indexPath.row] as! String
            }

        }
        
        // get the building data from the IndoorNavigationService
        let building = IndoorNavigationService.sharedInstance.getBuilding(selectedItem)
        selectedValue = building["dataURL"]

        // call the close seque
        performSegueWithIdentifier("unwindSegue", sender: self)
        
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if (self.resultSearchController.active) {
            return super.tableView(tableView, viewForHeaderInSection: section)
        } else  {
            let  headerCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! SiteNavTableSearchHeaderCell
//        headerCell.tintColor = UIColor(rgba: "#ffffff")
            headerCell.backgroundColor = UIColor(rgba: "#666666")
            let buildings = sorted(tableData2.keys)
       
            headerCell.headerLabel.text = buildings[section]
            headerCell.headerLabel.textColor = UIColor(rgba: "#ffffff")

            return headerCell
        }
        
    }
    
    /**
    */
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        filteredTableData.removeAll(keepCapacity: false)
        
        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text)
        let array = (tableData as NSArray).filteredArrayUsingPredicate(searchPredicate)
        filteredTableData = array as! [String]
        
        self.tableView.reloadData()
    }
    
    private func sortItems(items:NSArray) -> NSArray {
        
        var sortedItems = items.sortedArrayUsingComparator {
        (obj1, obj2) -> NSComparisonResult in
            let s1 = obj1 as! String
            let s2 = obj2 as! String
            let result = s1.compare(s2)
            return result
        }
        return sortedItems
    }

    

}
