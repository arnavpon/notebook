//  HelperFunctions.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

import Foundation
import UIKit
import CoreData

// MARK: - Core Data

func saveManagedObjectContext() -> Bool {
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    do {
        try context.save()
        print("MOC was saved successfully.\n")
        return true
    } catch let error as NSError {
        print("Error saving context: \(error).\n")
        return false
    }
}

func deleteManagedObject(object: NSManagedObject) { //deletes the specified object
    print("\nDeleting managed object...")
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    context.deleteObject(object)
    saveManagedObjectContext()
}

func fetchObjectsFromCoreDataStore(entity: String, filterProperty: String?, filterValue: [AnyObject]?) -> [AnyObject] { //fetches objects for entity & predicate options
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let request = NSFetchRequest(entityName: entity)
    if let property = filterProperty, value = filterValue { //create predicate if filters were input
        let predicate = NSPredicate(format: "\(property) == %@", argumentArray: value)
        request.predicate = predicate
    }
    do {
        let results = try context.executeFetchRequest(request)
        print("[fetchObjectsFromStore] Fetched \(results.count) objects for '\(entity.uppercaseString)' entity.\n")
        return results
    } catch let error as NSError {
        print("Error fetching stored projects: \(error).")
    }
    return []
}

func clearCoreDataStoreForEntity(entity entity: String) {
    print("Clearing data store...")
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let request = NSFetchRequest(entityName: entity)
    do {
        let results = try context.executeFetchRequest(request)
        for result in results {
            context.deleteObject(result as! NSManagedObject)
            print("Deleting object.")
        }
        if (saveManagedObjectContext()) { //persist changes -> store
            print("Deleted \(results.count) object(s).\n")
        } else { //save was unsuccessful
            print("ERROR - could note save changes (deletion) to store!")
        }
    } catch let error as NSError {
        print("Error fetching stored projects: \(error)")
    }
}

func reconstructModuleObjectFromCoreDataDict(variableName: String, configurationDict: [String: AnyObject]) -> Module { //creates a Module obj using the variable's name & config dict
    //Determine the var's Module type, then pass the var's name & dictionary -> that module's CoreData initializer, which will re-create the variable (complete w/ all configuration):
    var object: Module = Module(name: variableName)
    if let moduleRaw = configurationDict[BMN_ModuleTitleKey] as? String, module = Modules(rawValue: moduleRaw) {
        switch module {
        case .CustomModule:
            object = CustomModule(name: variableName, dict: configurationDict)
        case .EnvironmentModule:
            object = EnvironmentModule(name: variableName, dict: configurationDict)
        case .FoodIntakeModule:
            object = FoodIntakeModule(name: variableName, dict: configurationDict)
        case .ExerciseModule:
            object = ExerciseModule(name: variableName, dict: configurationDict)
        case .BiometricModule:
            object = BiometricModule(name: variableName, dict: configurationDict)
        case .CarbonEmissionsModule:
            object = CarbonEmissionsModule(name: variableName, dict: configurationDict)
        case .RecipeModule:
            object = RecipeModule(name: variableName, dict: configurationDict)
        }
    }
    return object
}

// MARK: - Centered Rectangle

func centerFrameInRect(subviewSize: CGSize, superviewFrame: CGRect) -> CGRect { //centers a SUBVIEW's frame in its superview's frame (ONLY works if view is SUBVIEW, otherwise coordinates will be off!)
    let superviewCenter = CGPoint(x: superviewFrame.width/2, y: superviewFrame.height/2)
    let originX = superviewCenter.x - subviewSize.width/2
    let originY = superviewCenter.y - subviewSize.height/2
    return CGRectMake(originX, originY, subviewSize.width, subviewSize.height)
}

func createRectAroundCenter(centerPoint: CGPoint, size: CGSize) -> CGRect { //creates a rectangle of the given size situated evenly around the given center point
    let width = size.width
    let height = size.height
    let originX = centerPoint.x - width/2
    let originY = centerPoint.y - height/2
    let rectangle: CGRect = CGRect(x: originX, y: originY, width: width, height: height)
    return rectangle
}

func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double { //clamps the passed in value so it is > lowerValue & < upperValue
    return min(max(value, lowerValue), upperValue)
}

func createCardForView(view: UIView, color: CGColor, borderWidth: CGFloat, radius: CGFloat) { //creates a card-like appearance w/ a view
    view.layer.borderColor = color
    view.layer.borderWidth = borderWidth
    view.layer.cornerRadius = radius
}

// MARK: - UIView Corners/Edges

enum Corners { //represents corners/edges of a rectangle
    case TopLeft
    case TopRight
    case BottomLeft
    case BottomRight
    case LeftMiddle
    case TopMiddle
    case RightMiddle
    case BottomMiddle
    case Center //views center point
}

func getPointForCorner(layer: CALayer, corner: Corners) -> CGPoint { //returns point from a view's corner
    let originX = layer.frame.origin.x
    let originY = layer.frame.origin.y
    let width = layer.frame.width
    let height = layer.frame.height
    var pointForCorner = CGPoint()
    switch corner {
    case .TopLeft:
        pointForCorner = CGPoint(x: originX, y: originY)
    case .TopRight:
        pointForCorner = CGPoint(x: (originX + width), y: originY)
    case .BottomLeft:
        pointForCorner = CGPoint(x: originX, y: (originY + height))
    case .BottomRight:
        pointForCorner = CGPoint(x: (originX + width), y: (originY + height))
    case .TopMiddle:
        pointForCorner = CGPoint(x: (originX + width/2), y: originY)
    case .RightMiddle:
        pointForCorner = CGPoint(x: (originX + width), y: (originY + height/2))
    case .BottomMiddle:
        pointForCorner = CGPoint(x: (originX + width/2), y: (originY + height))
    case .LeftMiddle:
        pointForCorner = CGPoint(x: originX, y: (originY + height/2))
    case .Center:
        pointForCorner = CGPoint(x: (originX + width/2), y: (originY + height/2))
    }
    return pointForCorner
}

func drawLine(imageView: UIImageView, fromPoint: [CGPoint], toPoint: [CGPoint], lineColor: UIColor, lineWidth: CGFloat) { //accept an array of points so that multiple lines can be drawn. Make sure # fromPoints = # toPoints!
    //First, set up a context holding the image currently in the mainImageView:
    UIGraphicsBeginImageContext(imageView.frame.size)
    let context = UIGraphicsGetCurrentContext()
    imageView.image?.drawInRect(CGRect(x: 0, y: 0, width: imageView.frame.width, height: imageView.frame.height))
    
    //For each item in the array, get the current touch point & draw a line between points:
    for i in 0...(fromPoint.count - 1) {
        CGContextMoveToPoint(context, fromPoint[i].x, fromPoint[i].y)
        CGContextAddLineToPoint(context, toPoint[i].x, toPoint[i].y)
    }
    
    //Set the drawing parameters for line size & color:
    CGContextSetLineCap(context, .Square)
    CGContextSetLineWidth(context, lineWidth)
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor)
    CGContextSetBlendMode(context, .Normal)
    
    //Draw the path:
    CGContextStrokePath(context)
    
    //Wrap up the drawing context to render the new line:
    imageView.image = UIGraphicsGetImageFromCurrentImageContext()
    imageView.alpha = 1.0
    UIGraphicsEndImageContext()
}