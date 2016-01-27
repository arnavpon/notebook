//  CustomSlider.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom slider item for CreateProjectVC's endpoint selection. We want to make this as generic as possible in terms of configuration (colors, number/positioning of data points, & labels for the data points). The artwork making up the controls & the slider track along w/ the animation for slider movement should be consistent. At its essence, we want a slider w/ FIXED points where the control can reside (as opposed to a continuous slider).

import UIKit
import QuartzCore

class CustomSlider: UIControl {
    
    private let minValue = 0.0 //minimum value along track
    private let maxValue = 1.0 //maximum value along track
    var currentValue = 0.0 { //current position of control on slider track (starts @ 0)
        didSet {
            updateLayerFrames() //update control's frame when 'currentValue' is changed (updateFrames() is invoked for properties that affect the control's layout)
        }
    }
    let fixedSelectionPoints: [String] //list of selection options for slider (create 1 label for each)
    var colorScheme: (UIColor, UIColor, Int) //color scheme for the slider track - lowColor is the bottom-most color in the gradient, highColor is the top-most color in the gradient, 'startPoint' is the data point @ which to begin gradienting (everything before the startPoint will be the lowColor).
    var controlTintColor = UIColor.blueColor() {
        didSet {
            controlLayer.setNeedsDisplay() //call setNeedsDisplay for any affected layers if they are changed by the setting of a property
        }
    }
    let trackLayer = CustomSliderTrackLayer() //drawing layer for the track
    let controlLayer = CustomSliderControlLayer() //drawing layer for the slider control
    var previousLocation = CGPoint() //tracks last touch point
    
    override var frame: CGRect { //updates slider visuals when frame is changed
        didSet {
            updateLayerFrames()
        }
    }
    
    var controlWidth: CGFloat { //width/height of control
        return 25
    }
    
    init(frame: CGRect, selectionPoints: [String], scheme: (UIColor, UIColor, Int)) {
        self.fixedSelectionPoints = selectionPoints
        self.colorScheme = scheme
        super.init(frame: frame)
        
        self.layer.borderWidth = 1 //*
        self.layer.borderColor = UIColor.blackColor().CGColor //*
        
        trackLayer.customSlider = self
        trackLayer.contentsScale = UIScreen.mainScreen().scale //ensures visuals are crisp on retina disp
        trackLayer.backgroundColor = UIColor.whiteColor().CGColor
        trackLayer.borderColor = UIColor.blackColor().CGColor
        trackLayer.borderWidth = 0.5
        self.layer.addSublayer(trackLayer)
        
        controlLayer.customSlider = self
        controlLayer.contentsScale = UIScreen.mainScreen().scale
        //controlLayer.backgroundColor = UIColor.redColor().CGColor
        self.layer.addSublayer(controlLayer)
        
        createPointsForOptions() //create points & labels
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Custom Slider fatal error")
    }
    
    func createPointsForOptions() { //creates a point on the track & a label for each option
        var counter = 0
        for point in self.fixedSelectionPoints {
            //Create mark on the track:
            let pointLayer = CustomSliderFixedOptionLayer() //have to add as sublayer -> super layer before specifying coordinates (so that coords are in the super layer's system)
            //CustomSliderFixedOptionLayer(centerPosition: CGPoint(x: 0 + counter*40, y: 35))
            trackLayer.addSublayer(pointLayer)
            pointLayer.frame = CGRect(x: 0 + counter * 40, y: 0, width: 15, height: 15)
            pointLayer.backgroundColor = UIColor.blackColor().CGColor
            pointLayer.customSlider = self
            pointLayer.setNeedsDisplay()
            
            //Create corresponding label:
            let label = UILabel(frame: CGRect(x: 0 + counter*45, y: 55, width: 45, height: 25))
            label.text = point
            label.adjustsFontSizeToFitWidth = true
            self.addSubview(label)
            counter += 1
        }
    }
    
    func updateLayerFrames() { //updates layer frames to fit
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        trackLayer.frame = CGRect(x: 0, y: 25, width: self.frame.width, height: 15) //center in frame (or slide it towards the top more to give room on the bottom)
        trackLayer.setNeedsDisplay() //updates the view for this layer
        
        let controlLayerCenter = CGFloat(positionForValue(currentValue)) //gets center point of control???
        controlLayer.frame = CGRect(x: (controlLayerCenter - controlWidth)/2, y: 0, width: controlWidth, height: controlWidth) //square controlLayer
        controlLayer.setNeedsDisplay()
        
        CATransaction.commit() //CATransaction code wraps the entire frame update into 1 transaction so the transitions are smooth & disables animations on the layer
    }
    
    func positionForValue(value: Double) -> Double { //converts a numerical value into a position along the slider track
        let position = (Double(bounds.width - controlWidth) * (value - minValue) / (maxValue - minValue)) + Double(controlWidth/2)
        return position
    }
    
    // MARK: - Interaction Logic
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        previousLocation = touch.locationInView(self) //translates touch event into the UIControl's coordinate space
        
        //Test if control has been touched (check if touch was in the control's frame):
        if (controlLayer.frame.contains(previousLocation)) {
            controlLayer.highlighted = true
        }
        return controlLayer.highlighted //informs UIControl whether subsequent touches should be tracked (tracking touch events continues if the controlLayer is highlighted)
    }
    
    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double { //clamps the passed in value so it is in the specified range
        return min(max(value, lowerValue), upperValue)
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        //Determine by how much the user dragged:
        let changeInPosition = Double(location.x - previousLocation.x)
        let changeInValue = (maxValue - minValue) * changeInPosition / Double(bounds.width - controlWidth) //gets the change in position as a % of the slider's width???
        previousLocation = location //set previous location -> new location
        
        //Update value of the controlLayer depending on where the user dragged it:
        if (controlLayer.highlighted) { //here we would add our logic to lock slider to specific points
            currentValue += changeInValue
            currentValue = boundValue(currentValue, toLowerValue: minValue, upperValue: maxValue)
        }
        
        sendActionsForControlEvents(.ValueChanged) //notification code in Target Action pattern - notifies any subscribed targets that the slider's value has changed
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        controlLayer.highlighted = false //ends tracking event
    }
}

class CustomSliderControlLayer: CALayer { //class for slider's Control object
    var highlighted = false {
        didSet { //does tilt animation go in here???
            setNeedsDisplay() //changes fill color slightly when touch event is active
        }
    }
    weak var customSlider: CustomSlider?
    
    override func drawInContext(ctx: CGContext) {
        if let slider = customSlider {
            let controlFrame = CGRect(x: 0, y: 15, width: slider.controlWidth, height: slider.controlWidth)
            let controlPath = UIBezierPath(rect: controlFrame)
            
            //Fill - w/ subtle shadow:
            let shadowColor = UIColor.grayColor().CGColor
            CGContextSetShadowWithColor(ctx, CGSize(width: 0.0, height: 1.0), 1.0, shadowColor)
            CGContextSetFillColorWithColor(ctx, slider.controlTintColor.CGColor)
            CGContextAddPath(ctx, controlPath.CGPath)
            CGContextFillPath(ctx)
            
            //Outline:
            CGContextSetStrokeColorWithColor(ctx, shadowColor)
            CGContextSetLineWidth(ctx, 0.5)
            CGContextAddPath(ctx, controlPath.CGPath)
            CGContextStrokePath(ctx)
            
            if (highlighted) { //add some visual effects if the control is highlighted
                CGContextSetFillColorWithColor(ctx, UIColor(white: 0.0, alpha: 0.1).CGColor)
                CGContextAddPath(ctx, controlPath.CGPath)
                CGContextFillPath(ctx)
            }
        }
    }
}

class CustomSliderTrackLayer: CALayer { //class for slider's Track object
    //We want a thin rectangular slider w/ gradient fill to indicate transition from low -> high. At each point along the track where there is an option, we want to draw the bottom aspect of the control.
    weak var customSlider: CustomSlider?
    
    override func drawInContext(ctx: CGContext) {
        if let slider = customSlider {
            let path = UIBezierPath(rect: bounds) //draw rectangle around bounds of the track
            CGContextAddPath(ctx, path.CGPath)
            
            //Fill the track (look up how to apply gradient fill):
            CGContextSetFillColorWithColor(ctx, UIColor.greenColor().CGColor)
            CGContextAddPath(ctx, path.CGPath)
            CGContextFillPath(ctx)
        }
    }
}

class CustomSliderFixedOptionLayer: CALayer { //class for slider's fixed selection points
    weak var customSlider: CustomSlider?
    var centerPosition: CGPoint? = nil //position of center
    
    override init() {
        super.init()
    }
    
    init(centerPosition: CGPoint) {
        self.centerPosition = centerPosition
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func drawInContext(ctx: CGContext) {
        //draw each point as a black triangle just under the track, using the centerPosition as a guide
        //let rect = CGRect(x: centerPosition.x, y: centerPosition.y, width: 15, height: 15)
        let rect = bounds
        CGContextAddEllipseInRect(ctx, rect)
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextStrokePath(ctx)
        CGContextSetFillColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextFillPath(ctx)
    }
}
