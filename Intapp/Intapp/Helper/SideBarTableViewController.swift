//
//  SideBarTableViewController.swift
//

import UIKit

protocol SideBarTableViewControllerDelegate{
    func sideBarControllerDidSelectRow(indexPath:NSIndexPath)
}

class SideBarTableViewController: UITableViewController {

    var delegate:SideBarTableViewControllerDelegate?
    
    var tableData:Array<String> = []
    var picData:Array<String> = []
    var types:Array<String> = []
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("SideBarCell") as? UITableViewCell

        if cell == nil{
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "SideBarCell")
            // Configure the cell...
            cell?.backgroundColor = UIColor.clearColor()
            cell?.textLabel?.textColor = UIColor.darkTextColor()
            
            let selectedCellView:UIView = UIView(frame: CGRectMake(0, 0, cell!.frame.size.width, cell!.frame.size.height))
            
            selectedCellView.backgroundColor = UIColor.darkGrayColor().colorWithAlphaComponent(0.3)
            cell?.selectedBackgroundView = selectedCellView
            
        }
        
        cell?.textLabel?.text = tableData[indexPath.row]
        cell?.detailTextLabel?.text = tableData[indexPath.row]
        cell?.detailTextLabel?.textColor = UIColor.blueColor()
        var icon = UIImage(named: picData[indexPath.row] as String)
        
        cell?.imageView?.image = icon


        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return  45.0
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        DLog("reached2 MC")
        
        let cell  = tableView.cellForRowAtIndexPath(indexPath)
         DLog("the Cell name  \(cell?.textLabel?.text)")
        delegate?.sideBarControllerDidSelectRow(indexPath)
        
    }

       
}
