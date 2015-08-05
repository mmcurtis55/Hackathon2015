//
//  IOS7SiteNavSearchTableViewController.swift
//  Intapp
//
//  Created by ra3571 on 5/20/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit

class IOS7SiteNavSearchTableViewController: UITableViewController, Selectable, UISearchBarDelegate, UISearchDisplayDelegate {

    // String array of conference rooms used for searching
    var tableData = [String]()
    
    // data structure that contains the building-floor to conference rooms
    var tableData2 = [String:AnyObject]()
    
    // String array of conference rooms that match the search criteria
    var filteredTableData = [String]()
    
    // when a table cell is clicked we set the value
    var selectedValue: AnyObject?


    @IBOutlet var headerCell: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
         populateTableData()
 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        if (tableView == self.tableView) {
            return tableData2.count
        } else {
            // only one section for searching
            return 1
        }
        
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        
        if (tableView == self.tableView) {
            let buildings = sorted(tableData2.keys)
            let key = buildings[section]
            if let items = tableData2[key] as? NSArray {
                return items.count
            } else {
                return 0
            }
        } else {
            DLog("filteredTableData.count \(filteredTableData.count)")
            return filteredTableData.count
        }
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        // Configure the cell...
        if (tableView == self.tableView) {
            let buildings = sorted(tableData2.keys)
            let key = buildings[indexPath.section]
            
            if let items = tableData2[key] as? NSArray {
                var sortedItems = sortItems(items)
                cell.textLabel?.text = sortedItems[indexPath.row] as? String
                cell.detailTextLabel?.text = ""
            }
        } else {
            cell.textLabel?.text = filteredTableData[indexPath.row]
            cell.detailTextLabel?.text = ""
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        var selectedItem = ""
        
        if (tableView == self.tableView) {
            let buildings = sorted(tableData2.keys)
            let key = buildings[indexPath.section]
            
            if let items = tableData2[key] as? NSArray {
                var sortedItems = sortItems(items)
                selectedItem = sortedItems[indexPath.row] as! String
            }
        } else {
            selectedItem = filteredTableData[indexPath.row]
        }
        
        // get the building data from the IndoorNavigationService
        let building = IndoorNavigationService.sharedInstance.getBuilding(selectedItem)
        selectedValue = building["dataURL"]
        
        // call the close seque
        performSegueWithIdentifier("unwindSegue", sender: self)
        
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerCell = self.tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! SiteNavTableSearchHeaderCell
        if (tableView == self.tableView) {
            headerCell.backgroundColor = UIColor(rgba: "#666666")
            let buildings = sorted(tableData2.keys)
            
            headerCell.headerLabel.text = buildings[section]
            headerCell.headerLabel.textColor = UIColor(rgba: "#ffffff")
             return headerCell
        } else  {
            headerCell.backgroundColor = UIColor(rgba: "#666666")
            let buildings = sorted(tableData2.keys)
            
            headerCell.headerLabel.text = "Results"
            headerCell.headerLabel.textColor = UIColor(rgba: "#ffffff")
            return headerCell
        }
       
    }
    
    // Mark: - Selectable
    func getSelectedValue() -> AnyObject? {
        return selectedValue
    }
    
    // Mark: - UISearchDisplayDelegate
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        filteredTableData.removeAll(keepCapacity: false)
        
        let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchString)
        let array = (tableData as NSArray).filteredArrayUsingPredicate(searchPredicate)
        filteredTableData = array as! [String]
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, didLoadSearchResultsTableView tableView: UITableView) {
        tableView.rowHeight = 44
        
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
    private func populateTableData() {
        
        IndoorNavigationService.sharedInstance.getDataModel() {(results, error) -> Void in
            
            // TODO: check for error
            
            // reload the data since we have new data model
//            self.dataModel = results
            
            // process the dataModel by putting all the items in a map
            // where the key is a string like OHT D1
            var data = [String: [AnyObject]]()
            self.tableData = []
            // location array
            if let locations = results?["locations"] as? [AnyObject] {
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
