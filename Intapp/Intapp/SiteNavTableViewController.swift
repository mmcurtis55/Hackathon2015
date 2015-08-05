//
//  SieNavTableViewController.swift
//  Intapp
//
//  Created by ra3571 on 2/19/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit

class SiteNavTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource, Selectable {

    var selectedValue: AnyObject?

    // an array of arrays, the first array are the sections
    // then for each section there is an array of items (rooms).
    var dataModel2 = [AnyObject]()

    override func viewDidLoad() {
        super.viewDidLoad()

        if (dataModel2.count == 0) {
            initDataModel()
        }
    }
    
    /** set up the data structure that backs the table view
    */
    func initDataModel() {
        
        IndoorNavigationService.sharedInstance.getDataModel() {
            indoorDataModel, error in
            
            if (error != nil) {
                // display error controller
            }
            
            if let locations = indoorDataModel?["locations"] as? [NSDictionary] {
                var sectionArray = [AnyObject]()
                var locationsArray = [NSDictionary]()
                sectionArray.append("SITES")
                let sortedLocs = sorted(locations) { ($0["label"] as! String) < ($1["label"] as! String)}
                for loc in sortedLocs {
                    if let label = loc["label"] as? String {
                        sectionArray.append(label)
                        locationsArray.append(loc)
                    }
                    
                    if let buildings = loc["buildings"] as? [NSDictionary] {
                        var buldingsArray = [NSDictionary]()
                        let sortedBuildings = sorted(buildings) { ($0["label"] as! String) < ($1["label"] as! String)}
                        for b in sortedBuildings {
                            buldingsArray.append(b)
                        }
                        self.dataModel2.append(buldingsArray)
                    }
                }
                
                self.dataModel2.insert(sectionArray, atIndex: 0)
                self.dataModel2.insert(locationsArray, atIndex: 1)
                self.tableView.reloadData()
            }
        }
        
    }
    
    // MARK: - Selectable
    func getSelectedValue() -> AnyObject? {
        return selectedValue
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // SITES, OHT, ATMC (these are the section headers), so get the count of the first array
        if dataModel2.count > 0 {
            return dataModel2[0].count
        } else {
            return 0
        }
        
    }

    /** get number of rows in a section by getting the array count
    */
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // The section data are in arrays in the elements after 0 (1-indexed)
        let sectionIndex = section + 1
        if let sectionArray = dataModel2[sectionIndex] as? NSArray {
            return sectionArray.count
        } else {
            return 0
        }
    }

    /**
    get the cell at given section and row
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        let sectionIndex = indexPath.section + 1
        
        // locations are stored in
        let sectionArray = dataModel2[sectionIndex] as! NSArray
        if let obj = sectionArray[indexPath.row] as? NSDictionary {
            cell.textLabel?.text = obj["label"] as? String
            cell.detailTextLabel?.text = ""
        }
      
        return cell
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as! SiteNavTableHeaderCell
        //        headerCell.tintColor = UIColor(rgba: "#ffffff")
        headerCell.backgroundColor = UIColor(rgba: "#666666")
        // sections are in the first array
        let sections = dataModel2[0] as! NSArray
        
        headerCell.headerLabel.text = sections[section] as? String
        headerCell.headerLabel.textColor = UIColor(rgba: "#ffffff")
        
        return headerCell
        
    }
    
    /** when an item is selected set the selected text value
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // get the value selected by the user
        let sectionIndex = indexPath.section + 1
        // the values in the section array are dictionariers
        let sectionArray = dataModel2[sectionIndex] as! NSArray
        if let val = sectionArray[indexPath.row] as? NSDictionary {
            selectedValue = val["dataURL"]
        }
        
        // call the close seque
        performSegueWithIdentifier("unwindSegue", sender: self)
    }
        

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    

}
