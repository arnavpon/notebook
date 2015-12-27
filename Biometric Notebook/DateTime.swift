//  DateTime.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Obtains reference to current date & time

import Foundation

class DateTime {
    let month: Int //current month (MM format)
    let day: Int //current day (DD format)
    let year: Int //current year (YYYY format)
    let hours: Int //current time (hours)
    let minutes: Int //current time (minutes)
    let seconds: Int //current time (seconds)
    private var dateString: String {
        get {
            return "\(month)/\(day)/\(year)"
        }
    }
    private var timeString: String {
        get {
            return "\(hours):\(minutes):\(seconds)"
        }
    }
    
    init() {
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let timeZone = calendar.timeZone
        let components = calendar.componentsInTimeZone(timeZone, fromDate: currentDate)
        month = components.month
        day = components.day
        year = components.year
        hours = components.hour
        minutes = components.minute
        seconds = components.second
        
        //let formattedDate = NSDateFormatter.localizedStringFromDate(currentDate, dateStyle: .LongStyle, timeStyle: .LongStyle) //current date formatted for user's timezone
    }
    
    func getCurrentDateString() -> String {
        return dateString
    }
    
    func getCurrentTimeString() -> String {
        return timeString
    }
}