//
//  SiteNavViewController.swift
//  Intapp
//
//  Created by ra3571 on 2/13/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData


protocol Selectable {
    // func sideBarDidSelectMenuButtonAtIndex(index:Int)
    func getSelectedValue() -> AnyObject?
}

class SiteNavViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var beaconButton: UIBarButtonItem!
    @IBOutlet weak var testBeaconLabel: UILabel!
    
    //Responsible for the novification view and animation that covers/replaces the Status bar momentarily
    let notification = CWStatusBarNotification()
    
    
    
    var useLocationServices = true
    var locMan: CLLocationManager?
    var initialHeading: Double = 0
    
    @IBOutlet weak var clMessage: UILabel! // the label  used to display the heading
    @IBOutlet weak var webView: UIWebView! // the view that shows the pdf (rotatable?)
    @IBOutlet weak var beaconLabel: UILabel! // the label that shows beacon info "North V-Bldg"
    
    //allows use of CoreData
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        } else  {
            return nil
        }
        }()
    
    
    @IBAction func beaconFound(sender: UIBarButtonItem) {
        beaconButton.enabled = false
        loadMapForBeacon()
        
    }
    
    @IBAction func listClicked(sender: UIBarButtonItem) {
        beaconButton.enabled = true
        if UtilityService.isiOS8 {
            performSegueWithIdentifier("showListAsPopoverSegue", sender: self)
        } else  {
            performSegueWithIdentifier("showListModalSegue", sender: self)
        }
    }
    
    @IBAction func searchClicked(sender: UIBarButtonItem) {
        beaconButton.enabled = true
        if UtilityService.isiOS8 {
            performSegueWithIdentifier("navSearch", sender: self)
        } else {
            performSegueWithIdentifier("navSearchLegacy", sender: self)
        }
 
    }
    
    
    
    
    
    
    // TODO get from JSON file
   // let conferenceRooms = ["San Jacinto","Seneca","Waterloo","Trinity 1","Trinity 2","Trinity 3","San Gabriel","San Saba"]
    //var confRoomToBldg = [:] as NSMutableDictionary
    var searchResults = []
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //sets the notification looks
        //Branding
        // DD540B
        // E66A08
        // 230 106 8
        self.notification.notificationLabelBackgroundColor = UIColor(rgba: "#E66A08")
        self.notification.notificationLabelTextColor = UIColor.whiteColor()
        // notification animation style
        self.notification.notificationAnimationInStyle = CWNotificationAnimationStyle.Top
        self.notification.notificationAnimationOutStyle = CWNotificationAnimationStyle.Top
        
        
        
        //MC edits begin
        // Do any additional setup after loading the view.
        
        //begins fetch of coreData entity with name SiteNavMap
        let fetchReq = NSFetchRequest(entityName: "SiteNavMap")
        
        //sorts request by date // No longer needed
        //fetchReq.sortDescriptors = [NSSortDescriptor(key: "timeAdded", ascending: false)]
        
        //finalizes results as an array of type [SiteNavMap]?
        let fetchResults = managedObjectContext!.executeFetchRequest(fetchReq, error: nil) as? [SiteNavMap]
        
        //checks if the fetchedResults array object's mapPDF atribute has been set or is still nil. This is common when working with optionals
        // if not set uses known map pdf name
        var dataUrlStr = fetchResults?.first?.mapPDF ?? "H3.pdf"
        //MC edits end
        
        preview(dataUrlStr)
        
        
        // trying to get the web view to not overlap with nav bar when rotatating
        webView.sendSubviewToBack(self.view)
        
        // Do any additional setup after loading the view.
        if locManager != nil {
            locMan = locManager!
            locMan!.delegate = self
        }
    }
    
    // TODO: make sure this can will not cause error over long period of time.
    func preview(dataUrlStr: String) {
        var docUrl = NSURL(fileURLWithPath: dataUrlStr)
        // if scheme is "file", then the format is just the file name like foo.json or foo.png
        if docUrl?.scheme! == "file" {
            let fileNameWithoutExt = dataUrlStr.stringByDeletingPathExtension
            let ext = dataUrlStr.pathExtension
            docUrl = NSBundle.mainBundle().URLForResource(fileNameWithoutExt, withExtension: ext)
        }
        
        if (docUrl != nil) {
            let req = NSURLRequest(URL: docUrl!)
            webView.loadRequest(req)
         }
    }
    
   
    
    // Mark - UIView Lifecycle
    
    override func viewWillAppear(animated: Bool) {
        locMan!.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        locMan!.stopUpdatingHeading()
        locMan!.delegate = nil
    }

    
    // MARK: - exit segue
    // this is called by the modal dialog when a table cell is selected
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        //set nil to allow lastBeacon != lastBeaconDisplayed  to be true
        lastBeaconDisplayed = nil
        if let selectable = segue.sourceViewController as? Selectable {
            if let selectedVal = selectable.getSelectedValue() as? String {
                
                //begins fetch of coreData entity with name SiteNavMap
                let fetchReq = NSFetchRequest(entityName: "SiteNavMap")
                
                //sorts request by date
                fetchReq.sortDescriptors = [NSSortDescriptor(key: "timeAdded", ascending: false)]
                
                //finalizes results as an array of type [SiteNavMap]?
                let fetchResults = managedObjectContext!.executeFetchRequest(fetchReq, error: nil) as? [SiteNavMap]
                
                //checks if the fetchedResults array object's mapPDF atribute has been set or is still nil. This is common when working with optionals
               
                var bas: NSManagedObject!
                
                for bas: AnyObject in fetchResults!
                {
                    managedObjectContext!.deleteObject(bas as! NSManagedObject)
                }
                
                //time object is selected. Will be used for sorting in order by date and time to find most recently viewed map
                //var todaysDate:NSDate = NSDate()  // no longer needed
                
                //inserts a new SiteNavMap object
                var SNM = NSEntityDescription.insertNewObjectForEntityForName("SiteNavMap",
                    inManagedObjectContext: self.managedObjectContext!) as! SiteNavMap
                
                //sets mapPDF and timeAdded atributes.
                SNM.mapPDF = selectedVal.lastPathComponent
                //SNM.timeAdded = todaysDate
                //set nil to allow lastBeacon != lastBeaconDisplayed  to be true
                lastBeaconDisplayed = nil
                preview(selectedVal)
            }
        }
        
        // if the source controller is a SiteNavTableViewController and ios8, then we use a popup segue, so we have to dismiss manually
        if let sourceController = segue.sourceViewController as? SiteNavTableViewController {
            if UtilityService.isiOS8 {
                 dismissViewControllerAnimated(true) {}
            }
        }

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let id = segue.identifier {
            if (id == "showListAsPopoverSegue") {
                if let dvc = segue.destinationViewController as? SiteNavTableViewController {
                    // set the dvs as the delegate to the presentation popover
                    if let ppc = dvc.popoverPresentationController {
                        ppc.delegate = self
                    }
                }
            }
        }
    }
    
    /* Keeps the popover presentation controller from trying to show full screen on iPhone
    */
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
}

extension SiteNavViewController: CLLocationManagerDelegate {
    
// updateUI(beacon: CLBeacon)
    
    func beaconIdent()->String{
        //if nearestBeaconDidChange(){
            lastBeaconDisplayed = lastBeacon
            let beacon  = lastBeacon!
            switch lastBeacon!.minor.integerValue {
            case 10472:
                let detailLabel:String = "Major: \(beacon.major.integerValue), " +
                    "Minor: \(beacon.minor.integerValue), " +
                    "RSSI: \(beacon.rssi as Int), " +
                "UUID: \(beacon.proximityUUID.UUIDString)"
                DLog("open map for \(detailLabel)")
                beaconLabel.text = "J1"
                
            case 44176:
                let detailLabel:String = "Major: \(beacon.major.integerValue), " +
                    "Minor: \(beacon.minor.integerValue), " +
                    "RSSI: \(beacon.rssi as Int), " +
                "UUID: \(beacon.proximityUUID.UUIDString)"
                DLog("open map for \(detailLabel)")
                
                beaconLabel.text = "E3"
            case 23996:
                let detailLabel:String = "Major: \(beacon.major.integerValue), " +
                    "Minor: \(beacon.minor.integerValue), " +
                    "RSSI: \(beacon.rssi as Int), " +
                "UUID: \(beacon.proximityUUID.UUIDString)"
                DLog("open map for \(detailLabel)")
                
                beaconLabel.text = "W1"
                
            case 33662:
                let detailLabel:String = "Major: \(beacon.major.integerValue), " +
                    "Minor: \(beacon.minor.integerValue), " +
                    "RSSI: \(beacon.rssi as Int), " +
                "UUID: \(beacon.proximityUUID.UUIDString)"
                DLog("open map for \(detailLabel)")
                
                beaconLabel.text = "W1"
                
            case 46621:
                let detailLabel:String = "Major: \(beacon.major.integerValue), " +
                    "Minor: \(beacon.minor.integerValue), " +
                    "RSSI: \(beacon.rssi as Int), " +
                "UUID: \(beacon.proximityUUID.UUIDString)"
                DLog("open map for \(detailLabel)")
                
                beaconLabel.text = "D1"
                
            default:
                // blank out
                beaconLabel.text = "Unrecognized"
                break
            }
            return beaconLabel.text!
        //}
   // return "WHAT HAPPENED"
    }
    
    
    
    func loadMapForBeacon(){
        preview("\(beaconIdent()).pdf")
        //begins fetch of coreData entity with name SiteNavMap
        let fetchReq = NSFetchRequest(entityName: "SiteNavMap")
        
        //sorts request by date
        fetchReq.sortDescriptors = [NSSortDescriptor(key: "timeAdded", ascending: false)]
        
        //finalizes results as an array of type [SiteNavMap]?
        let fetchResults = managedObjectContext!.executeFetchRequest(fetchReq, error: nil) as? [SiteNavMap]
        
        //checks if the fetchedResults array object's mapPDF atribute has been set or is still nil. This is common when working with optionals
        
        var bas: NSManagedObject!
        
        for bas: AnyObject in fetchResults!
        {
            managedObjectContext!.deleteObject(bas as! NSManagedObject)
        }
        
        //time object is selected. Will be used for sorting in order by date and time to find most recently viewed map
        //var todaysDate:NSDate = NSDate()  // no longer needed
        
        //inserts a new SiteNavMap object
        var SNM = NSEntityDescription.insertNewObjectForEntityForName("SiteNavMap",
            inManagedObjectContext: self.managedObjectContext!) as! SiteNavMap
        
        var path = "\(beaconIdent()).pdf"
        //sets mapPDF and timeAdded atributes.
        SNM.mapPDF = path
        //SNM.timeAdded = todaysDate
        
        
    }

    
    
// TODO: get this from a json
//    func loadMapForBeacon(beacon: CLBeacon) {
//         DLog("MC")
//        switch beacon.minor.integerValue {
//        case 10472:
//            let detailLabel:String = "Major: \(beacon.major.integerValue), " +
//                "Minor: \(beacon.minor.integerValue), " +
//                "RSSI: \(beacon.rssi as Int), " +
//            "UUID: \(beacon.proximityUUID.UUIDString)"
//            DLog("open map for \(detailLabel)")
//            beaconLabel.text = "W1"
//            preview("W1.pdf")
//        case 44176:
//            let detailLabel:String = "Major: \(beacon.major.integerValue), " +
//                "Minor: \(beacon.minor.integerValue), " +
//                "RSSI: \(beacon.rssi as Int), " +
//            "UUID: \(beacon.proximityUUID.UUIDString)"
//            DLog("open map for \(detailLabel)")
//
//            beaconLabel.text = "D2"
//            //preview("D2.pdf")
//        default:
//            // blank out
//            beaconLabel.text = "D1"
//            preview("D1.pdf")
//            break
//        }
//        //begins fetch of coreData entity with name SiteNavMap
//        let fetchReq = NSFetchRequest(entityName: "SiteNavMap")
//        
//        //sorts request by date
//        fetchReq.sortDescriptors = [NSSortDescriptor(key: "timeAdded", ascending: false)]
//        
//        //finalizes results as an array of type [SiteNavMap]?
//        let fetchResults = managedObjectContext!.executeFetchRequest(fetchReq, error: nil) as? [SiteNavMap]
//        
//        //checks if the fetchedResults array object's mapPDF atribute has been set or is still nil. This is common when working with optionals
//        
//        var bas: NSManagedObject!
//        
//        for bas: AnyObject in fetchResults!
//        {
//            managedObjectContext!.deleteObject(bas as! NSManagedObject)
//        }
//        
//        //time object is selected. Will be used for sorting in order by date and time to find most recently viewed map
//        //var todaysDate:NSDate = NSDate()  // no longer needed
//        
//        //inserts a new SiteNavMap object
//        var SNM = NSEntityDescription.insertNewObjectForEntityForName("SiteNavMap",
//            inManagedObjectContext: self.managedObjectContext!) as! SiteNavMap
//        
//        
//        //sets mapPDF and timeAdded atributes.
//        SNM.mapPDF = beaconLabel.text!
//        //SNM.timeAdded = todaysDate
//        
//
//    }
    
    private func degreesToRadians(angle: Double) -> CGFloat {
        let rad = (angle) / 180.0 * M_PI
        let ret_val = CGFloat(rad)
        return ret_val
    }
    
    
    // from http://stackoverflow.com/questions/7490660/converting-wind-direction-in-angles-to-text-words
    private func degToCompass(num: Double) -> String {
        let directions = ["N","NNE","NE","ENE","E","ESE", "SE", "SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let index = Int((num/22.5) + 0.5) % 16
        return directions[index]
    }

    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        
        if initialHeading == 0 {
           // initialHeading = newHeading.trueHeading
        }
        // TODO: this will rotate the whole page but it is not working quite right
        //webView.transform = CGAffineTransformMakeRotation(degreesToRadians(initialHeading - newHeading.trueHeading));

        // add code here for heading info
        let compassStr = degToCompass(newHeading.trueHeading)
        let str = NSString(format: "%.1f", newHeading.trueHeading)
        clMessage?.text = "\(compassStr) (\(str))"
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        switch error.code {
        case CLError.Denied.rawValue:
            clMessage?.text = "Location Services Off"
            DLog("\(error)")
        case CLError.HeadingFailure.rawValue:
            clMessage?.text = "Compass Heading Failure"
        default:
            DLog("\(error)")
        }
        
    }
    
    func nearestBeaconDidChange() -> Bool{
        return lastBeacon != lastBeaconDisplayed

    }
    
    
    func nearestBeaconChanged(nearestBeacon: CLBeacon) {
        beaconButton.tintColor = UIColor.orangeColor()
        beaconButton.enabled = true
        lastBeacon = nearestBeacon
        //set nil to allow lastBeacon != lastBeaconDisplayed  to be true
        lastBeaconDisplayed = nil
        //loadMapForBeacon(nearestBeacon)
    }
    
    func nearestProximityChanged(nearestBeacon: CLBeacon) {
        lastProximity = nearestBeacon.proximity;
    }
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        
        //beaconLabel.text = beacons.first?.minor.description
        var message:String = ""
        
        // get the nearest beacon... this is the beacon with RSS closest to 0 but not zero
        if (beacons.count > 0) {
           
            var nearestBeacon:CLBeacon?
            for beacon in beacons as! [CLBeacon] {
                if beacon.rssi < 0 {
                    nearestBeacon = beacon
                    break
                }
            }
        
            // if we have a nearestbeacon
            if (nearestBeacon != nil) {
                if lastBeacon == nil {
                    nearestBeaconChanged(nearestBeacon!)
                    testBeaconLabel.text = "\(lastBeacon!.minor) : \(beaconIdent())"
                } else {
                    // not nil check the minor number
                    if lastBeacon?.minor == nearestBeacon!.minor {
                        if(nearestBeacon!.proximity == lastProximity || nearestBeacon!.proximity == CLProximity.Unknown) {
                           //testBeaconLabel.text = "\(lastBeacon!.minor) : \(beaconIdent())"
                            return  // same so return
                        } else {
                            // the beacon is changed
                            nearestProximityChanged(nearestBeacon!)
                        }
                        return
                    } else {
                        // different so the beacon must be different
                        lastBeaconDisplayed = nearestBeacon!
                        nearestBeaconChanged(nearestBeacon!)
                        self.notification.displayNotificationWithMessage("Entered \(beaconIdent()) Building. Beacon : \(lastBeacon!.minor)", duration: 2.0)
                        testBeaconLabel.text = "\(lastBeacon!.minor) : \(beaconIdent())"

                    }
             
                }
            }

        }
    }
    
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        if let clBeaconRegion = region as? CLBeaconRegion {
            clBeaconRegion
            self.notification.displayNotificationWithMessage("Hello, World!", duration: 1.0)
            DLog("You entered the region")
            testBeaconLabel.text = "Entered the region"
        }
    }
    
    func locationManager(manager: CLLocationManager!,
        didExitRegion region: CLRegion!) {
            DLog("You exited the region")
            beaconLabel.text = "Exited the region"
    }
    
    
}
