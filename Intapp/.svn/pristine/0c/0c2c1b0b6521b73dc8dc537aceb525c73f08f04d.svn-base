//
//  AboutViewController.swift
//  Intapp
//
//  Created by ra3571 on 4/23/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let dataUrlStr = "about.html"
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
