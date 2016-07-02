//  DateTime.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/27/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// Obtains reference to current date & time

import Foundation

class DateTime {
    private let month: Int //current month (MM format)
    private let day: Int //current day (DD format)
    private let year: Int //current year (YYYY format)
    private let hours: Int //current time (hours)
    private let minutes: Int //current time (minutes)
    private let seconds: Int //current time (seconds)
    private var dateString: String { //YYYY-MM-DD (matches MySQL DATE obj format)
        get {
            var formattedMonth = "\(month)"
            if (month < 10) { //apply formatting to single digits
                formattedMonth = "0\(month)"
            }
            var formattedDay = "\(day)"
            if (day < 10) { //apply formatting to single digits
                formattedDay = "0\(day)"
            }
            return "\(year)-\(formattedMonth)-\(formattedDay)"
        }
    }
    private var timeString: String { //HH:MM:SS.milliseconds (matches MySQL TIME obj format)
        get {
            var formattedHours = "\(hours)"
            if (hours < 10) { //apply formatting to single digits
                formattedHours = "0\(hours)"
            }
            var formattedMinutes = "\(minutes)"
            if (minutes < 10) { //apply formatting to single digits
                formattedMinutes = "0\(minutes)"
            }
            var formattedSeconds = "\(seconds)"
            if (seconds < 10) { //apply formatting to single digits
                formattedSeconds = "0\(seconds)"
            }
            return "\(formattedHours):\(formattedMinutes):\(formattedSeconds)"
        }
    }
    
    init() { //empty initializer - sets date -> current date & time
        let currentDate = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let timeZone = calendar.timeZone //gets local timezone for user
        let components = calendar.componentsInTimeZone(timeZone, fromDate: currentDate)
        month = components.month
        day = components.day
        year = components.year
        hours = components.hour
        minutes = components.minute
        seconds = components.second
        
        //let formattedDate = NSDateFormatter.localizedStringFromDate(currentDate, dateStyle: .LongStyle, timeStyle: .LongStyle) //current date formatted for user's timezone
    }
    
    init(date: NSDate) { //custom init, takes as input a date
        let currentDate = date
        let calendar = NSCalendar.currentCalendar()
        let timeZone = calendar.timeZone
        let components = calendar.componentsInTimeZone(timeZone, fromDate: currentDate)
        month = components.month
        day = components.day
        year = components.year
        hours = components.hour
        minutes = components.minute
        seconds = components.second
    }
    
    func getDateString() -> String {
        return dateString
    }
    
    func getTimeString() -> String {
        return timeString
    }
    
    func getFullTimeStamp() -> String {
        return "\(dateString) \(timeString)"
    }
}