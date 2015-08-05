//
//  MapViewController.swift
//  Internator
//
//  Created by ra3571 on 1/12/15.
//  Copyright (c) 2015 Freescale. All rights reserved.
//
// TODO: add overlay of site image that is clickable 

import UIKit
import CoreLocation
import MapKit
import AddressBookUI
import CoreData


class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var annotationUrl: String?   // this is the URL that contains the annotations to display
    var annotationToImage: NSMutableDictionary?
    
    // use core data to get the data for a site
    var sites = [NSManagedObject]()
    
    var alert: BPCompatibleAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // add anotations to the map using annotationUrl as specified
        loadAnnotations()
    }
    
    
    // return a custom "pin" for Locations
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        // dont change the MKUserLocationView
        if annotation is MKUserLocation {
            return nil
        }
        
        // this will display a custom MKAnnotationView
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if pinView == nil {
            pinView = MKAnnotationView (annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
   
            // add a custom image TODO: use the icon as indicated in the json file
            if let imageURLStr: String = annotationToImage?[annotation.title!] as? String {
                var imageUrl = NSURL(fileURLWithPath: annotationUrl!)
                // if scheme is "file", then the format is just the file name like foo.json or foo.png
                if imageUrl?.scheme! == "file" {
                    let fileNameWithoutExt = imageURLStr.stringByDeletingPathExtension
                    let ext = imageURLStr.pathExtension
                    imageUrl = NSBundle.mainBundle().URLForResource(fileNameWithoutExt, withExtension: ext)
                }
                
                if imageUrl != nil {
                    var imageData = NSData(contentsOfURL: imageUrl!)
                    let image = UIImage(data: imageData!)
                    pinView!.image = image
                }
            }
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIView
        }
        
        return pinView
    }
    
    // when the annotation is clicked, open in maps so user can get to the location
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        
        // todo: use a custom annotation to store the address?
        let location = view.annotation
        let coord = location.coordinate
        // location.subtitle
        let str = location.subtitle!
        let mapDictionary = [kABPersonAddressStreetKey as NSString: str]
       
        let placemark = MKPlacemark(coordinate: coord, addressDictionary: mapDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        
        var launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving] as NSDictionary
        mapItem.openInMapsWithLaunchOptions(launchOptions as [NSObject : AnyObject])
        
       
    }
    
    func locationManager(_manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]! )
    {
        self.mapView.showsUserLocation = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: private methods
    func loadAnnotations() {
        
        // this will add the annotations async...
        if (annotationUrl != nil) {
                        var url = NSURL(fileURLWithPath: annotationUrl!)
            // if scheme is "file", then the format is just the file name like foo.json or foo.png
            if url?.scheme! == "file" {
                let fileNameWithoutExt = annotationUrl!.stringByDeletingPathExtension
                let ext = annotationUrl!.pathExtension
                url = NSBundle.mainBundle().URLForResource(fileNameWithoutExt, withExtension: ext)
            }
            
            if url != nil {
                annotationToImage = [:]
                // Do any additional setup after loading the view, typically from a nib.
                let manager = AFHTTPRequestOperationManager()
                manager.GET( url?.absoluteString,
                    parameters: nil,
                    success: {[weak self]
                        operation, responseObject in
                        
                        //responseObject will be a JSON object
                        for annotationMap in responseObject?.objectForKey("items") as! [NSDictionary] {
                            if let lat = annotationMap["latitude"] as? Double {
                                // we have a lat
                                if let lon = annotationMap["longitude"] as? Double {
                                    let annotation = MKPointAnnotation()
                                    let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                    annotation.coordinate = location
                                    annotation.title = annotationMap["title"] as! String
                                    annotation.subtitle = annotationMap["subtitle"] as! String
                                    self?.mapView.addAnnotation(annotation)
                                    self?.annotationToImage?[annotation.title] = annotationMap["iconURL"] as! String
                                }
                            }
                        }
                        
                        // For iOS 7 and above (Referring MKMapView.h) : // Position the map such that the provided array of annotations are all visible to the fullest extent possible.                                                
                        if self?.mapView.annotations?.count > 0 {
                            self?.mapView.showAnnotations(self?.mapView.annotations,
                                animated: false)
                        }
                    },
                    failure: {
                        operation, error in
                        self.showErrorDialog(error.localizedDescription)
                })
            } // if url != nil
            else {
                // error could not find the annotationURL
                let msg = NSString(format:NSLocalizedString("Unable to find %@", comment:""), annotationUrl!)
                showErrorDialog(msg as String)
            }
        } // if annotation != nil
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
