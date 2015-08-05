//
//  MenuDetailTableViewController.swift
//  Internator
//
//  Created by ra3571 on 1/12/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit
import QuartzCore

/*!
* This class is used to display a table when an icon is selected from the main menu.
*/
class MenuDetailTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {

    required init(coder aDecoder: NSCoder) {
        refreshLoadingView = UIView()
        super.init(coder: aDecoder)
    }

    // an array of table data
    var tableData = []
    
    // an array of table RSS feed data
    var feeds = []
    
    // the URL of the data source
    var dataUrl = ""
    
    @IBOutlet weak var menuDetailTableView: UITableView!
    
    var refreshLoadingView: UIView
    
    var isRefreshAnimating: Bool = false
    
    var alert:BPCompatibleAlertController?
    

    override func viewDidLoad() {
        DLog("viewDidLoad called")
        super.viewDidLoad()
        setupRefreshControl()
        populateTableData()
    }
    
    // set up that area that the user sees when the pulldown on the table
    func setupRefreshControl() {
        self.refreshControl = UIRefreshControl()
 
        // Creating the graphic image view
        var imageView = UIImageView(image: UIImage(named: "appicon-Bar@3x"))
        // make this view the same size
        let r :CGRect = imageView.bounds
        self.refreshLoadingView = UIView(frame: r)
        let centerPt : CGPoint = self.refreshControl!.center
        self.refreshLoadingView.center = centerPt
        
        self.refreshLoadingView.addSubview(imageView)
        self.refreshLoadingView.clipsToBounds = true
        
        // hide the orginal with this call
        self.refreshLoadingView.tintColor = UIColor.clearColor()
        
        self.refreshControl?.addSubview(self.refreshLoadingView)
        
        // Init flags
        isRefreshAnimating = false
        
        // when activated, invoke the "refresh" method (see below)
        self.refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
    }
    
    // detect how far the user has pulled the table
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        // get the current size of the controller
        let refreshBounds :CGRect = self.refreshControl!.bounds
     
        // Distance the table has been pulled >= 0
        let pullDistance = max(0.0, -self.refreshControl!.frame.origin.y);
        
        // Calculate the pull ratio, between 0.0-1.0
        let pullRatio = min( max(pullDistance, 0.0), 100.0) / 100.0;
        DLog("pullRatio \(pullRatio)")
        
        // change the size of the image based on the pull ratio
        self.refreshLoadingView.transform = CGAffineTransformMakeScale(1 + pullRatio * 3.5, 1 + pullRatio * 3.5)
 
    }
    
    // refresh is called when user pulls down table cells
    func refresh() {
        DLog("refresh called")
        
        // get the data for the URL
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
        DLog("populateTableData with URL: '\(dataUrl)'")
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        self.menuDetailTableView?.addSubview(activityIndicator)
        activityIndicator.frame = self.menuDetailTableView!.bounds
        activityIndicator.startAnimating()
        self.refreshControl?.beginRefreshing()
        
        let mySession = NSURLSession.sharedSession()
        if let url = NSURL(string: dataUrl) {
            
            let networkTask = mySession.dataTaskWithURL(url) {
                data, response, error in
                
                // stop spinner
                dispatch_async(dispatch_get_main_queue(), {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                })
                DLog("response: \(response?.MIMEType)")
                
                // check if there is an error getting URL i.e. network error
                if (error != nil) {
                    // return?
                    DLog("ERROR: \(error)")
                    self.showErrorDialog(error!.localizedDescription)
                    return
                }
                
                if let mimeType = response.MIMEType {
                    switch mimeType {
                    case "application/json":
                        self.processJSONData(data)
                    case "application/rss+xml":
                        self.processRSSData(data)
                    default:
                        NSLog("Cannot handle mime type: \(mimeType)")
                        break
                    }
                } else {
                    NSLog("Cannot handle unknown mime types")
                }
                return
            }
            
            // start the task
            networkTask.resume()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        DLog("table count: \(tableData.count)")
        return tableData.count
    }

    /*!
    * This method is called by the table view to populate the cell as needed.
    * The controller references the information in the tableData array.  This array
    * is populated when the
    *
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MenuDetailCell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        let entry: NSMutableDictionary = self.tableData[indexPath.row] as! NSMutableDictionary
 
        // the entry will contain 
        // Feeds dictionary.
        //var dict : NSDictionary! = myFeed.objectAtIndex(indexPath.row) as NSDictionary
        
        // Set cell properties.
        //        cell.textLabel.text = myFeed.objectAtIndex(indexPath.row).objectForKey("title") as? String
        
        // It seems that cell.textLabel?.text is no longer an optionional.
        // If the above line throws an error then comment it out and uncomment the below line.
        //cell.textLabel?.text = myFeed.objectAtIndex(indexPath.row).objectForKey("title") as? String
        
        cell.textLabel?.text = entry["title"] as? String
        cell.detailTextLabel?.text = ""
       
        if let t = entry["thumbnail"] as? String {
            if let imgUrl = NSURL(string: t) {
                // get the NSData asynch...
                let request = NSURLRequest(URL: imgUrl)
                let placeHolderImage = UIImage(named: "appicon")
                
                weak var weakCell = cell
                cell.imageView?.setImageWithURLRequest(request, placeholderImage: placeHolderImage!,
                    success: {_,_,image in
                        // this code will force the thumbnails to be drawn in the default imageView
                        // to the height we want
                        let itemSize = CGSizeMake(50, 50)
                        UIGraphicsBeginImageContext(itemSize)
                        let imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
                        image.drawInRect(imageRect)
                        weakCell!.imageView!.image = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                    },
                    failure: {_,_,_ in })
            }
        }
        return cell
    }
    
    /**
    Create animation that will make it look like the text is zooming
    */
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        // this animation looks like the text in the cell is zooming in
        
        // scale to 10% in the x and y axes
        cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        
        // full size in a blink of an eye
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1,1,1)
        })
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let entry: NSMutableDictionary = self.tableData[indexPath.row] as! NSMutableDictionary

        if let link = entry["link"] as? String {
            //   let cleanLink = link.
            var cleanLink = link.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            
            // TODO: cache this controller?
            let webBrowser = KINWebBrowserViewController()
            webBrowser.actionButtonHidden = true
            let url = NSURL(string: cleanLink)
            webBrowser.loadURL(url)
            DLog("cleanLink: '\(cleanLink)' url: \(url)")
            self.navigationController?.pushViewController(webBrowser, animated: true)
        }
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
            let cell = tableView.cellForRowAtIndexPath(indexPath)
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
*/
    
    /////////////////////////////////////////
    // MARK: - Private
    private func processJSONData(data: NSData) {
        
        // place holder for any errors encountered while parsing the JSON data
        var err: NSError?
        
        var jsonData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as! NSMutableDictionary
        
        // TODO: check if there is an NSError
        if (err != nil) {
            
            showErrorDialog(err!.localizedDescription)
            return
        } else {
            if let dataDictionary = jsonData["data"] as? NSDictionary {
                if let results = dataDictionary["children"] as? NSArray {
                    // need to update table data w/ results in the main queue
                    dispatch_async(dispatch_get_main_queue(), {
                        self.tableData =  results
                        self.menuDetailTableView!.reloadData()
                        // stop the refresh control
                        self.refreshControl?.endRefreshing()
                    })
                }
            }
        }
    }
    
    private func processRSSData(data: NSData) { 
        DLog("processRSSData")
        // need to update table data w/ results in the main queue
        dispatch_async(dispatch_get_main_queue(), {
            var myParser = XmlParserManager.alloc().initWithData(data) as! XmlParserManager
            self.tableData =  myParser.feeds
            self.menuDetailTableView!.reloadData()
            self.refreshControl?.endRefreshing()
        })
    }
    
    /** convenience method to display alert dialog
    :msg: the localized message to display to the user
    */
    private func showErrorDialog(msg: String) {
        let title = NSLocalizedString("ERROR", comment:"Error")
        alert = BPCompatibleAlertController(title: title, message: msg as String, alertStyle: BPCompatibleAlertControllerStyle.Alert)
        alert?.alertViewStyle = UIAlertViewStyle.Default
        
        let ok = NSLocalizedString("OK", comment:"OK")
        alert?.addAction(BPCompatibleAlertAction.cancelActionWithTitle(ok, handler: { (action) in
            // no-op, the controller dismisses itself
        }))
        
        alert?.presentFrom(self.parentViewController, animated: true) {}
    }
    

}
