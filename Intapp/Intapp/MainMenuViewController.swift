//
//  MainMenuViewController.swift
//  Internator
//
//  Created by ra3571 on 1/6/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit
import CoreData
import QuartzCore
import QuickLook

let reuseIdentifier = "MenuIconCell"

/*!
* This class is used to display the menuItems configured
*/
class MainMenuViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, SideBarDelegate, QLPreviewControllerDataSource, KINWebBrowserDelegate, UIGestureRecognizerDelegate{
    
    
    // constants
    struct MenuConstants {
        static let NUMBER_OF_CELLS_PER_ROW = CGFloat(3)  // change this to be the number of cells you want on a row
        static let SIGNIN = "Sign In"
        static let SIGNOUT = "Sign Out"
        static let INTERCELL_SPACE = CGFloat(22)
        static let SIDE_MARGIN = CGFloat(22)
        static let TB_MARGIN = CGFloat(10)
    }

    lazy var managedObjectContext : NSManagedObjectContext? = {
       let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        } else  {
            return nil
        }
    }()
    

    
    // this controller bridges iOS7 lack of a UIAlertController.  This needs to be an instance variable to work properly
    var alert: BPCompatibleAlertController?
    
    // this is a SideBar that slides out
    var sidebar:SideBar?
    
    // this the dataModel for the collection view
    var dataModel = [MenuItem]()
    
    // this is the data model for the quick look component
    var quickLookDataModel = [NSURL]()
    
    // get the singleton, this will replace the flickr var soon
    let menuItemService = MenuItemService.sharedInstance
    
    // this is the icon image displayed in each collectionViewCell
    @IBOutlet weak var iconImage: UIImageView!
    
    //
    @IBOutlet var beaconInfo: UILabel!
    
    
    
    // TODO: lazy inst
    var bgView = UIView()

    var fslBarButton: UIBarButtonItem

    func showLogOut() {
        
        let signOutStr = NSLocalizedString(MenuConstants.SIGNOUT, comment: "")
        let alertController = UIAlertController(title: signOutStr, message: "Are you sure?", preferredStyle: UIAlertControllerStyle.Alert)
        
        // set up the logout button
        let logoutAction = UIAlertAction(title: signOutStr, style: .Default) { (_) in
            self.logout()
            
        }
        
        // add the logout button
        alertController.addAction(logoutAction)
        
        // add the cancel button
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        // show the controller
        self.presentViewController(alertController, animated: true, completion: nil)
    }
//    // for now we'll just have to add each new segue mapping
//    if cell.segue == nil || cell.segue == "table" {
//    performSegueWithIdentifier("showMenuDetailTable", sender: menuItem)
//    }else if cell.segue == "map" {
//    
//    performSegueWithIdentifier("showMap", sender: menuItem)
//    } else if cell.segue == "signin" {
//    showLogin()
//    // this is a special
//    } else if cell.segue == "viewer" {
//    doPreviewMultipleUsingQuickLook(menuItem)
//    // this is special, we push the view programatically so a segue is not defined
//    
//    } else if cell.segue == "web" {
//    
//    let webBrowser = KINWebBrowserViewController()
//    let url = NSURL(string: menuItem.segueUrl)
//    webBrowser.tintColor = UIColor.yellowColor()
//    webBrowser.delegate = self
//    webBrowser.loadURL(url)
//    self.navigationController?.pushViewController(webBrowser, animated: true)
//    } else if cell.segue == "qr" {
//    performSegueWithIdentifier("showQR", sender: menuItem)
//    } else if cell.segue == "nav" {
//    
//    performSegueWithIdentifier("showSiteNav", sender: menuItem)
//    } else if cell.segue == "rss" {
//    performSegueWithIdentifier("showRSS", sender: menuItem)
//    } else if cell.segue == "about" {
//    performSegueWithIdentifier("showAbout", sender: menuItem)
//    } else {
//    // default to show web if we do not recoginize the segue value
//    performSegueWithIdentifier("showMenuDetailTable", sender: menuItem)
//    }
//    
    
    
    // show the login dialog for the user to login
    func showLogin() {
        DLog("Show Login called")
        
        let alertController = UIAlertController(title: "Login", message: "Please login with your Freescale user ID and password", preferredStyle: UIAlertControllerStyle.Alert)

        // set up the login
        let loginAction = UIAlertAction(title: "Login", style: .Default) { (_) in
            let loginTextField = alertController.textFields![0] as! UITextField
            let passwordTextField = alertController.textFields![1] as! UITextField
            
            self.login(loginTextField.text, password: passwordTextField.text)
        }
        // do not enable the login action until the user types in something in the user ID field
        loginAction.enabled = false
        
        alertController.addTextFieldWithConfigurationHandler({ (textField:UITextField!) -> Void in
            textField.placeholder = "User ID"
            
            // when the user types something enable the login
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                loginAction.enabled = textField.text != ""
            }
        })
        
        alertController.addTextFieldWithConfigurationHandler({ (textField:UITextField!) -> Void in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
        })

        // add the login button
        alertController.addAction(loginAction)
        
        // add the cancel button
        alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        // show the controller
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    /*!
    * show the side bar programmatically
    */
    func showSideBar() {
        sidebar?.showSideBar(true)
    }
    
    /*!
    * show the side bar programmatically
    */
    func hideSideBar() {
        sidebar?.showSideBar(false)
        DLog("tried to close")
        }
    
    
    /*!
    * This method will login with passed in user name and password.
    * If the user authenticates against the system, the app will
    * get the menu items for authenticated users and update the data model
    */
    func login(userID: String, password: String) {
        
        securityManager?.login(userID, passwd: password) {
            results, error in
            
            if (error != nil) {
                // show an alert...
                let msg = "User authentication failed"
                var alert = UIAlertController(title: "ERROR", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                DLog("error: \(error!.localizedDescription)\n\n\n")
            } else {
                // check the results
                DLog("res: \(results)\n\n\n")
                self.updateMenuItemsAfterLogin()
                self.updateSideBarMenuItemsAfterLogin()
            }
            
        }
    }
    
    /*!
    * If user accepts prompt this method will be called
    */
    func logout() {
        // do real logout activity
        // update the UI based on the logout action
        updateMenuItemsAfterLogout()
        updateSideBarMenuItemsAfterLogout()
        //self.sidebar.sideBarTableViewController.tableData = ["Sign In", "About"]
    }
    
    // this method is required because all instance variables must be initialized to something
    // this is the init called when instaniated from a StoryBoard
    required init(coder aDecoder: NSCoder) {
        var image = UIImage(named: "navIcon")
        image?.imageWithRenderingMode(.AlwaysOriginal)
        // TODO add an action to open the side menu besides the swipe gesture
        fslBarButton = UIBarButtonItem(image: image, landscapeImagePhone: image, style: UIBarButtonItemStyle.Plain, target: nil, action: "showSideBar")

        super.init(coder: aDecoder)
    }
    
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setToolbarHidden(true, animated: false)
        
//        if bgView.frame != self.view.frame {
//            bgView.frame = self.view.frame
////            blurEffectView.frame = self.view.frame
//        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
//        if blurEffectView.alpha == 0 {
////            UIView.animateWithDuration(1.25, animations: {
////                self.blurEffectView.alpha  = 1.0
////            })
////            self.blurEffectView.alpha  = 1.0
//        }
//        UIView.animateWithDuration(1.25,
//            delay: 0.0,
//            options: .CurveEaseInOut | .AllowUserInteraction,
//            animations: {
//                self.blurEffectView.layer.transform = CATransform3DMakeScale(1,1,1)
//            },
//            completion: {success in
//        })
        super.viewDidAppear(animated)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

       
        //hidesBottomBarWhenPushed = true
        
        // add the image to
        if let bgImg = UIImage(named: "bgImage") {

            bgView = UIImageView(image: bgImg)
            bgView.contentMode = UIViewContentMode.ScaleAspectFill
            bgView.frame = self.view.frame
            
 
            
            self.collectionView?.backgroundView = bgView
        }
        // set up the FSL button to open the tray with more options
        fslBarButton.target = self
        
        let leftSideButtons = [fslBarButton]
        self.navigationItem.leftBarButtonItems = leftSideButtons
        
        // Register cell classes
        //        self.collectionView!.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        updateMenuItemsAfterLogout()
        
    }

    
    // implement the collection view delegate methods
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // the main menu will only show one section
        return 1
    }

    // another table view delegate method
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // the number of items is the number of MenuItems in dataModel
        DLog("MC1 \(self.dataModel.count)")
        return self.dataModel.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        DLog("cellForItemAtIndexPath \(indexPath.row)\n\n\n")
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
        let menuItem = menuItemForIndexPath(indexPath)

        cell.objectId = menuItem.objectID
        cell.imageView.clipsToBounds = true
       
        // get the icon image from the NSData
        let image = UIImage(data: menuItem.thumbnail)
        cell.imageView.image = image
        
        cell.imageView.image = cell.imageView.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        cell.imageView.tintColor = UIColor(rgba: menuItem.tint)

        cell.label.textColor =  UIColor(rgba: menuItem.tint)        // value like table, map, pdf?, quickview?
        cell.segue = menuItem.type
        
        // get the cell label text to the menu item label
        // TODO: internationalize the label
        cell.label.text = menuItem.label
        
        // TODO: replace with config or NSUserDefaults
        cell.selectedBackgroundView = UIView(frame: cell.frame)
        cell.selectedBackgroundView.backgroundColor = UIColor.darkGrayColor()
        cell.backgroundColor = UIColor(rgba: menuItem.color)

        cell.layer.cornerRadius = 16
        cell.clipsToBounds = true
        
        let menuItems = dataModel//["About"]
        
        
        sidebar = SideBar(sourceView: self.navigationController!.view, menuItems: menuItems)
        sidebar!.delegate = self
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        // this animation looks like the text in the cell is zooming in
        
        // scale to 10% in the x and y axes
        cell.layer.transform = CATransform3DMakeScale(0.1,0.1,1)
        cell.layer.opacity = 0
        
        // random from =.5 to 1.5 sec
        let randomDuration = Double(arc4random()) / Double(UINT32_MAX) + 0.5
       
        let delay :NSTimeInterval = 0.0
        let damping : CGFloat = 0.5
        let initialSpringVelocity : CGFloat = 0
        
        UIView.animateWithDuration(randomDuration,
            delay: delay,
            usingSpringWithDamping: damping,
            initialSpringVelocity: initialSpringVelocity,
            options: .CurveEaseInOut,
            animations: {
                cell.layer.transform = CATransform3DMakeScale(1,1,1)
                cell.layer.opacity = 1
            },
            completion: {success in
            })
    }
    
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let h = collectionView.layer.frame.height
        
            // by default assume 3 cells per row
        let numOfCells = MenuConstants.NUMBER_OF_CELLS_PER_ROW
        let marginBetweenCells = MenuConstants.INTERCELL_SPACE
            // this margin will govern the size of the width
        let margin = (numOfCells - 1) * marginBetweenCells
        let effectiveWidth = (collectionView.layer.frame.width - sectionInsets.left - sectionInsets.right - margin)
        let w = effectiveWidth/numOfCells

        return CGSize(width: w, height: w)
    }

   // private let sectionInsets = UIEdgeInsets(top: 10.0, left: 20.0, bottom: 50.0, right: 20.0)
     private let sectionInsets = UIEdgeInsets(top: MenuConstants.TB_MARGIN,
        left: MenuConstants.SIDE_MARGIN, bottom: MenuConstants.TB_MARGIN, right: MenuConstants.SIDE_MARGIN)
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return sectionInsets
    }
    

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let rect = CGRect(x: 0,y: 0, width: size.width, height: size.height)
                bgView.frame = rect
//        blurEffectView.frame = rect
    }
    

    // MARK: - Navigation
    // this function allows the controller to determine which segue to call
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        DLog("collectionView didSelectItemAtIndexPath \(indexPath)\n\n\n")
        //this call hides the side bar when a collection view cell is tapped
        hideSideBar()
        
        // pass the menuItem as the sender so we can pass any data attributes to the destination controller
        let cell = self.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! CollectionViewCell
        
        let menuItem = menuItemForIndexPath(indexPath)

        // for now we'll just have to add each new segue mapping
        if cell.segue == nil || cell.segue == "table" {
            performSegueWithIdentifier("showMenuDetailTable", sender: menuItem)
        }else if cell.segue == "map" {
            
            performSegueWithIdentifier("showMap", sender: menuItem)
        } else if cell.segue == "signin" {
            showLogin()
            // this is a special
        } else if cell.segue == "viewer" {
            doPreviewMultipleUsingQuickLook(menuItem)
            // this is special, we push the view programatically so a segue is not defined
 
        } else if cell.segue == "web" {
            
            let webBrowser = KINWebBrowserViewController()
            let url = NSURL(string: menuItem.segueUrl)
            webBrowser.tintColor = UIColor.yellowColor()
            webBrowser.delegate = self
            webBrowser.loadURL(url)
            self.navigationController?.pushViewController(webBrowser, animated: true)
        } else if cell.segue == "qr" {  
            performSegueWithIdentifier("showQR", sender: menuItem)
        } else if cell.segue == "nav" {
            
            performSegueWithIdentifier("showSiteNav", sender: menuItem)
        } else if cell.segue == "rss" {
            performSegueWithIdentifier("showRSS", sender: menuItem)
        } else if cell.segue == "about" {
            performSegueWithIdentifier("showAbout", sender: menuItem)
        } else {
            // default to show web if we do not recoginize the segue value
            performSegueWithIdentifier("showMenuDetailTable", sender: menuItem)
        }
        
        // call the unselect
        
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    // This is called when the cell is clicked on
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        DLog("prepareForSegue \(segue.identifier! ) matching \(sender)\n\n\n")
    
       
        // get the menu item
        if let menuItem = sender as? MenuItem{
        
       // TODO: replace with switch
        
        // Pass the selected object to the new view controller.
        if segue.identifier! == "showMenuDetailTable" {
            // get the sender as an object that will eventually determine which segue to call
            let destView : MenuDetailTableViewController = segue.destinationViewController as! MenuDetailTableViewController
            destView.dataUrl = menuItem.segueUrl
        } else if segue.identifier! == "showMap" {
            let destView : MapViewController = segue.destinationViewController as! MapViewController
            destView.annotationUrl = menuItem.segueUrl
        }
        }
    }
    
    func showWebBrowser(urlString: String) {
        let webBrowser = KINWebBrowserViewController()
        let url = NSURL(string: urlString)
        webBrowser.loadURL(url)
        self.navigationController?.pushViewController(webBrowser, animated: true)

    }
 
    // MARK: - SideViewDelegate
    // implement the delegate methods
    func sideBarDidSelectMenuButton(tableView: UITableView, indexPath: NSIndexPath) {
        
        DLog("sideBarDidSelectMenuButtonAtIndex \(indexPath.section) \(indexPath.row)\n\n\n")
        
        // can I get the cell that was selected?
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            // TODO: cell will also have pointer to the menu item
            DLog("cell: \(cell.textLabel!)\n\n\n")
            switch cell.textLabel!.text! {
            case "Sign In":
                showLogin()
            case "Sign Out":
                showLogOut()
                
            case "Locations":
               performSegueWithIdentifier("showMap", sender: self)
                
            case "Site Maps":
                performSegueWithIdentifier("showSiteNav", sender: self)
                
            case "Events":
                showViewer(indexPath)
                
            case "Community":
                showWeb(indexPath)
                
            case "Car Pool":
                showWeb(indexPath)
                
            case "Café":
                showWeb(indexPath)
                
            case "QR Code":
                performSegueWithIdentifier("showQR", sender: self)
                
            case "FAQ":
                showWeb(indexPath)
                
            case "Support":
                showViewer(indexPath)
                
            case "About":
                performSegueWithIdentifier("showAbout", sender: self)
                
            default:
                break
            }
        }
    }

    
    func showRSS() {
        performSegueWithIdentifier("showRSS", sender: self)
    }
    
    func showWeb(indexPath: NSIndexPath) {
        let menuItem = menuItemForIndexPath(indexPath)
        let webBrowser = KINWebBrowserViewController()
        let url = NSURL(string: menuItem.segueUrl)
        webBrowser.tintColor = UIColor.yellowColor()
        webBrowser.delegate = self
        webBrowser.loadURL(url)
        self.navigationController?.pushViewController(webBrowser, animated: true)
    }
    func showViewer(indexPath: NSIndexPath) {
        let menuItem = menuItemForIndexPath(indexPath)
        doPreviewMultipleUsingQuickLook(menuItem)
    }

    

    // MARK: - QLPreviewControllerDataSource
    // todo: send will be a CollectionViewCell (MainMenuViewCell is better name)
    // the CollectionView will have reference to the object id that is represents in core data
    // we can get the menuItem entity and retrieve the dataURL attribute which will indicate where
    // to get the document URL from.
    @IBAction func doPreviewMultipleUsingQuickLook (sender:AnyObject!) {
        
        // the sender is the menu item in this case
        if let menuItem = sender as? MenuItem{
        
        // Start: get docUrl
        let dataUrlStr = menuItem.segueUrl
        
        var docUrl = NSURL(fileURLWithPath: dataUrlStr)
        // if scheme is "file", then the format is just the file name like foo.json or foo.png
        if docUrl?.scheme! == "file" {
            let fileNameWithoutExt = dataUrlStr.stringByDeletingPathExtension
            let ext = dataUrlStr.pathExtension
            docUrl = NSBundle.mainBundle().URLForResource(fileNameWithoutExt, withExtension: ext)
        } else {
            // just use the docUrl as is
        }
        // End: getDocUrl(menuItem)
        
        if (docUrl != nil) {
            // sender is a CollectionViewCell get dataUrls from that
            let exts = ["pdf"]
            quickLookDataModel.removeAll(keepCapacity: false)
            // check if we support the viewing of this data....
            if find(quickLookDataModel, docUrl!) == nil {
                if find(exts, docUrl!.pathExtension!) != nil {
                    if QLPreviewController.canPreviewItem(docUrl) {
                        quickLookDataModel.append(docUrl!)
                    }
                }
            }
        }

        if quickLookDataModel.count == 0 {
            return
        }
        
        //should this be class level?
        // show preview interface
        let preview = QLPreviewController()
        preview.dataSource = self
        preview.currentPreviewItemIndex = 0
        preview.navigationController?.setToolbarHidden(true, animated: true)
        preview.navigationItem.rightBarButtonItems = nil
        self.presentViewController(preview, animated: true, completion: nil)
        }
    }
    
    
    func numberOfPreviewItemsInPreviewController(controller: QLPreviewController!) -> Int {
        return self.quickLookDataModel.count
    }
    
    func previewController(controller: QLPreviewController!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        return self.quickLookDataModel[index]
    }
    
    // MARK: KINWebBrowserDelegate
    
    func webBrowser(webBrowser: KINWebBrowserViewController!, didFailToLoadURL URL: NSURL!, error: NSError!) {
        
        var msg = error.localizedDescription
    
        if let host = error.userInfo?[NSURLErrorFailingURLStringErrorKey] as? String {
            if let internalDomain = NSUserDefaults.standardUserDefaults().valueForKey("internalDomain") as? String {
                if host.rangeOfString(internalDomain) != nil {
                    msg +=  "\nAccess to internal network required to view \(host)"
                }
                
            }
        }
        
        alert = BPCompatibleAlertController(title: "ERROR", message: msg, alertStyle: BPCompatibleAlertControllerStyle.Alert)
        alert?.alertViewStyle = UIAlertViewStyle.Default
        
        alert?.addAction(BPCompatibleAlertAction.cancelActionWithTitle("OK", handler: { (action) in
            // no-op, the controller dismisses itself
        }))
        
        alert?.presentFrom(self.parentViewController, animated: true) {
            () in
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    /////////////////////////////////////////////////////////////////////////////
    // MARK: - Private Methods
    
    /*!
    * Get the menu item at the index path
    */
    private func menuItemForIndexPath(indexPath: NSIndexPath) -> MenuItem {
        DLog("dataModel \(dataModel)\n\n\n")
        return dataModel[indexPath.row]
    }

    
    
    private func updateSideBarMenuItemsAfterLogout() {
        self.sidebar?.sideBarTableViewController.tableData = ["About"] // if using login log out is required then you will have to change this to process json
        self.sidebar?.sideBarTableViewController.tableView.reloadData()

    }
    
    /*!
    * When a user logins successfully, we want to display a new set of menu items
    */
    private func updateMenuItemsAfterLogin() {
        // get the menu items from the MenuItemService, results is an Optional array of MenuItems
        
        menuItemService.getAuthenticatedMenuItems("menuItems") {
            results, error in
            
            // report error if one exists
            if error != nil {
                // TODO: replace with alert dialog
                DLog("Error getting menu items from service : \(error)\n\n\n")
            }
            
            if results != nil {
                self.dataModel = results!
                // tell collection view to show the menu items
                self.collectionView?.reloadData()
                
            }
        }
    }
    
    
    /*!
    * When a user logins successfully, we want to display a new set of menu items
    */
    private func updateMenuItemsAfterLogout() {
        // get the menu items from the MenuItemService, results is an Optional array of MenuItems
        
        menuItemService.getMenuItems("menuItems") {
            results, error in
            
            // report error if one exists
            if error != nil {
                // TODO: replace with alert dialog
                DLog("Error getting menu items from service : \(error)\n\n\n")
            }
            
            if results != nil {
                self.dataModel = results!
                
                // tell collection view to show the menu items
                
                self.collectionView?.reloadData()
            }
        }
        
    }
    
    
    /*!
    * When a user logins we also want to update the side bar menu items as appropiate (i.e. remove login and add logout, etc.)
    */
    private func updateSideBarMenuItemsAfterLogin() {
 
        menuItemService.getAuthenticatedMenuItems("menuItems") {
            results, error in
            
            // report error if one exists
            if error != nil {
                // TODO: replace with alert dialog
                DLog("Error getting menu items from service : \(error)\n\n\n")
            }
            
            if results != nil {
                //TODO hard coded get from a URL (local network)
                self.sidebar?.sideBarTableViewController.tableData = ["Sign Out", "About"]
                self.sidebar?.sideBarTableViewController.tableView.reloadData()
            }
        }
    }
    // MARK: - UIGesturerecognizerDelegate methods
    //if a further catagorization of touches use this and other delage methods for the UIGestureRecognizerDelagate
    func gestureRecognizer(UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
        DLog("reached gesture recognizer")
            return true
    }
}