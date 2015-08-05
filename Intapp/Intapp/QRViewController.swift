//
//  QRViewController.swift
//  Intapp
//
//  Created by ra3571 on 2/16/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//

import UIKit
import AVFoundation

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate {
    
 
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var lastQR:String?
    var actionPopoverController:UIPopoverController?
    
    //this recognizes the tap to open the WebView from the QRCode view
    var tapRec:UITapGestureRecognizer?
    
    
    let safariActivity = TUSafariActivity()
    
    // supported actions you can do with the captured QR
    
    // Added to support different barcodes
    let supportedBarCodes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeUPCECode, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeAztecCode]
    
    
    @IBAction func showLink(sender: UITapGestureRecognizer) {
        if let urlString = messageLabel.text {
            // 1 check if it is a URL first, if
            DLog("qr data is not nil")
            if let url = NSURL(string: urlString) {
                            DLog("qr data url")
                // TODO: cache this controller?
                let webBrowser = KINWebBrowserViewController()
                webBrowser.actionButtonHidden = true
                webBrowser.loadURL(url)
                
                self.navigationController?.pushViewController(webBrowser, animated: true)
            } else {
                            DLog("qr data is not a url")
                //let textView:UITextView = messageLabel.text
                
                return // maybe not a URL
            }
            
        } else {
                        DLog("qr is nil")
            return // no string set?
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if let url = sender as? NSURL {
            if let identifier = segue.identifier {
                switch identifier {
                case "showWeb":
                    let destView : KINWebBrowserViewController = segue.destinationViewController as! KINWebBrowserViewController
                    destView.loadURL(url)
                default:
                    break
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
        // as the media type parameter.
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        // Get an instance of the AVCaptureDeviceInput class using the previous device object.
        var error:NSError?
        let input: AnyObject! = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: &error)
        
        if (error != nil) {
            // If any error occurs, simply log the description of it and don't continue any more.
            NSLog("\(error?.localizedDescription)")
            return
        }
        
        // Initialize the captureSession object.
        captureSession = AVCaptureSession()
        // Set the input device on the capture session.
        captureSession?.addInput(input as! AVCaptureInput)
        
        // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)
        
        // Set delegate and use the default dispatch queue to execute the call back
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureMetadataOutput.metadataObjectTypes = supportedBarCodes
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        let bounds = videoView.layer.bounds

        videoPreviewLayer?.frame = bounds
        videoView.layer.addSublayer(videoPreviewLayer)

        // Start video capture.
        captureSession?.startRunning()
        // Move the message label to the top view
       // view.bringSubviewToFront(messageLabel)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView?.layer.borderWidth = 2
//        view.addSubview(qrCodeFrameView!)
//        view.bringSubviewToFront(qrCodeFrameView!)
        videoView.addSubview(qrCodeFrameView!)
       
        
        let recognizer = UITapGestureRecognizer(target: self, action:Selector("showLink:"))
        // 4
        recognizer.delegate = self
        view.addGestureRecognizer(recognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        captureSession?.startRunning()
        qrCodeFrameView?.frame = CGRectZero
    }
    
    override func viewWillDisappear(animated: Bool) {
        captureSession?.stopRunning()
        messageLabel.text = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if (videoPreviewLayer?.connection.supportsVideoOrientation != nil) {
            switch toInterfaceOrientation {
            case UIInterfaceOrientation.Portrait:
                videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
            case UIInterfaceOrientation.PortraitUpsideDown:
                videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
            case UIInterfaceOrientation.LandscapeLeft:
                videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
            case UIInterfaceOrientation.LandscapeRight:
                videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            default:
                videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait

            }
        }
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {

        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            // remove the green square
            qrCodeFrameView?.frame = CGRectZero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // Here we use filter method to check if the type of metadataObj is supported
        // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
        // can be found in the array of supported bar codes.
        if supportedBarCodes.filter({ $0 == metadataObj.type }).count > 0 {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds
            
            if metadataObj.stringValue != nil {
                lastQR = metadataObj.stringValue
                messageLabel.text = lastQR
            }
        }
    }
    
    @IBAction func actionButtonPressed(sender: UIBarButtonItem) {
        if let urlStr = lastQR {
            if let url = NSURL(string: urlStr) {
                // we have a URL...
                
                // show the activity controller to allow 
                let appActs = [safariActivity]
                let controller = UIActivityViewController(activityItems: [url], applicationActivities: appActs)

                if(UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                    if (self.actionPopoverController == nil) {
                        self.actionPopoverController = UIPopoverController(contentViewController: controller)
                    }
                    self.actionPopoverController?.presentPopoverFromBarButtonItem(sender, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
                } else {
                    self.presentViewController(controller, animated: true) {}
                }
            }
        }
        
        //let qrUrl = messageLabel.
    }
    
//    override func supportedInterfaceOrientations() -> Int {
//        return UIInterfaceOrientation.Portrait.rawValue
//    }
    
}