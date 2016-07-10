//  CloudInteractionHandler.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 7/9/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Class that handles interactions between app & cloud backup of projects.

import Foundation

class CloudInteractionHandler {
    
    // MARK: - Initializers
    
    init() {
        //
    }
    
    // MARK: - Interaction Logic
    
    func createCloudRepresentationForProject(project: Project, success: (Bool) -> Void) {
        let url = NSURL(string: "http://192.168.1.10:8000/backup-project")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = nil //
    }
    
    func reconstructProjectsFromCloud() { //gets all active projects for the current user
        if let email = NSUserDefaults.standardUserDefaults().stringForKey(EMAIL_KEY) {
            let url = NSURL(string: "http://192.168.1.10:8000/get-projects-for-user")!
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
            request.HTTPBody = nil //
        }
    }
    
}