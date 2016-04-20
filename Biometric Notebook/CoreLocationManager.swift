//  CoreLocationManager.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/18/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Central manager for all CoreLocation-related tasks. This object is called @ data gathering time to pull in current location information (a SINGLE time), before terminating the task.
// Also handles iBeacons (when we start using them)!

import Foundation
import CoreLocation

class CoreLocationManager: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        locationManager.delegate = self //set delegate
    }
    
    // MARK: - External Access
    
    func startStandardUpdates() { //call fx when ready to access location (DELAY START until needed)
        let enabled = CLLocationManager.locationServicesEnabled()
        print("Location Access Available?: \(enabled).")
        if (enabled) { //need to shoot reminder -> user to access
            
        } else {
            
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer //set accuracy -> w/in 1 km
        locationManager.distanceFilter = 500 //set movement threshold for new events [meters]
        locationManager.requestWhenInUseAuthorization() //asks user for permission to use location
        locationManager.startUpdatingLocation() //begin listening for location update
    }
    
    // MARK: - Delegate Methods
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        print("CoreLocation authorization did change...")
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            print("App is now AUTHORIZED for location services! Starting updates...")
            locationManager.startUpdatingLocation()
        default: //access is Undetermined, Denied, or Restricted
            print("Access was denied for location services! Stopping updates...")
            locationManager.stopUpdatingLocation() //stop updating location (no access)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location: CLLocation = locations.last { //get most recent location
            //Make sure the timeStamp of the location is recent (< 30 seconds old):
            let eventDate: NSDate = location.timestamp
            let timeDifference = eventDate.timeIntervalSinceNow
            if (abs(timeDifference)) < 30 { //set limit to < 30 seconds
                let latitude = location.coordinate.latitude
                let longitude = location.coordinate.longitude
                print("Latitude: [\(latitude)]. Longitude: [\(longitude)].")
                let notification = NSNotification(name: BMN_Notification_CoreLocationManager_LocationDidChange, object: nil, userInfo: [BMN_CoreLocationManager_LatitudeKey: latitude, BMN_CoreLocationManager_LongitudeKey: longitude]) //pass latitude & longitude -> observer
                NSNotificationCenter.defaultCenter().postNotification(notification)
                locationManager.stopUpdatingLocation() //end updating after receiving 1 location!
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("[locationManager] Did fail w/ error! Error: \(error).")
    }
    
}