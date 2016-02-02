//  TutorialLayer.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/31/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Renders ProjectVariablesVC interface for tutorial

import UIKit
import QuartzCore

class TutorialCircleLayer: CALayer {
    
    private let frameInset: CGFloat = 4 //amount of space the tutorial circle is inset from the frame by
    private let lineWidth: CGFloat = 3 //thickness of stroke
    private let drawingCornerRadius: CGFloat = 50
    
    override func drawInContext(ctx: CGContext) {
        //Draws a frame centered around the center point of the object that we are circling. Create the drawing frame centered inside self's frame but IN THE COORDINATE SYSTEM OF SELF - so we use bounds to obtain the origin (0,0):
        let drawingFrame = CGRect(x: bounds.origin.x + frameInset, y: bounds.origin.y + frameInset, width: frame.width - frameInset * 2, height: frame.height - frameInset * 2)
        let color = UIColor.greenColor().CGColor //vivid green line for drawing
        let path = UIBezierPath(roundedRect: drawingFrame, cornerRadius: drawingCornerRadius)
        CGContextSetLineWidth(ctx, lineWidth)
        CGContextSetStrokeColorWithColor(ctx, color)
        CGContextAddPath(ctx, path.CGPath)
        CGContextStrokePath(ctx)
    }
    
}

class LineLayer: CALayer { //draws line from 1 point to another
    
    var lineColor: CGColorRef = UIColor.blackColor().CGColor
    private let fromPoint: CGPoint
    private let toPoint: CGPoint
    
    init(viewToDrawIn: UIView, fromPoint: CGPoint, toPoint: CGPoint) {
        self.fromPoint = fromPoint
        self.toPoint = toPoint
        super.init()
        self.frame = viewToDrawIn.frame
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawInContext(ctx: CGContext) {
        CGContextSetLineCap(ctx, CGLineCap.Round)
        CGContextSetLineWidth(ctx, 3)
        CGContextMoveToPoint(ctx, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(ctx, toPoint.x, toPoint.y)
        CGContextSetStrokeColorWithColor(ctx, self.lineColor)
        CGContextStrokePath(ctx)
    }
    
}