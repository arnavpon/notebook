//  Helper Functions.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 12/26/15.
//  Copyright © 2015 Confluent Ideals. All rights reserved.

// General helper functions.

import Foundation

func getCurrentDateAndTime() -> (Int, Int, Int, Int, Int, Int) { //obtains current date & time
    let currentDate = NSDate() //current date in UTC format (+5 hours from EST)
    //let formattedDate = NSDateFormatter.localizedStringFromDate(currentDate, dateStyle: .LongStyle, timeStyle: .LongStyle) //current date formatted for user's timezone
    let calendar = NSCalendar.currentCalendar()
    let timeZone = calendar.timeZone
    let components = calendar.componentsInTimeZone(timeZone, fromDate: currentDate)
    let month = components.month //current month (MM format)
    let day = components.day //current day (DD format)
    let year = components.year //current year (YYYY format)
    let hours = components.hour //current time (hours)
    let minutes = components.minute //current time (minutes)
    let seconds = components.second //current time (seconds)
    print("Date: \(month)/\(day)/\(year)")
    print("Time: \(hours):\(minutes):\(seconds)")
    return (hours, minutes, seconds, day, month, year)
}