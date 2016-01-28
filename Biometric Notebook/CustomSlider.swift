//  CustomSlider.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom slider item for CreateProjectVC's endpoint selection. We want to make this as generic as possible in terms of configuration (colors, number/positioning of data points, & labels for the data points). The artwork making up the controls & the slider track along w/ the animation for slider movement should be consistent. At its essence, we want a slider w/ FIXED points where the control can reside (as opposed to a continuous slider).
// When 'touchesEnded' is called, check which node the slider is closest to & lock it there.

import UIKit
import QuartzCore

class CustomSlider: UIControl {
    
    private let minValue = 0.0 //minimum value along track
    private let maxValue = 1.0 //maximum value along track
    var currentValue = 0.0 { //current position of control on slider track (starts @ 0 = continuous)
        didSet {
            updateLayerFrames() //update control's frame when 'currentValue' is changed (updateFrames() is invoked for properties that affect the control's layout)
        }
    }
    
    let fixedSelectionPoints: [String] //list of selection options for slider (create 1 label for each)
    private var selectionPointNumericalAnalogue: [Double] { //assigns # between 0 & 1 to fixedSelections
        var array: [Double] = []
        let numberOfPoints = Double(fixedSelectionPoints.count)
        let distance: Double = 1/(numberOfPoints - 1)
        var counter: Double = 0
        for _ in fixedSelectionPoints { //split range from 0 - 1 into n evenly spaced segments
            array.append(0.0 + counter * distance)
            counter += 1
        }
        return array
    }
    
    var colorScheme: (UIColor, UIColor, Int) //color scheme for the slider track - lowColor is the bottom-most color in the gradient, highColor is the top-most color in the gradient, 'startPoint' is the data point @ which to begin gradienting (everything before the startPoint will be the lowColor).
    var controlTintColor = UIColor.blueColor() {
        didSet {
            controlLayer.setNeedsDisplay() //call setNeedsDisplay for any affected layers if they are changed by the setting of a property
        }
    }
    
    override var frame: CGRect { //updates slider visuals when frame is changed
        didSet {
            updateLayerFrames()
        }
    }
    private var customSliderViewHeight: CGFloat { //total height for the view
        return self.frame.height
    }
    
    private let trackLayer = CustomSliderTrackLayer() //drawing layer for the track
    private var trackLayerHeight: CGFloat {
        return trackLayer.frame.height
    }
    private var trackLayerWidth: CGFloat { //TRUE width that should be used for calculations (ignores the bleeding edge that we added for visual purposes)
        return trackLayer.frame.width - nodeSize.width
    }
    private var trackLayerMaxY: CGFloat { //bottom-most Y value for the track
        return trackLayer.frame.maxY
    }
    
    let controlLayer = CustomSliderControlLayer() //drawing layer for the slider control
    var controlWidth: CGFloat { //width & height of control object (match to asset)
        return 16
    }
    var nodeSize: CGSize { //width & height for each node (match to asset)
        return CGSize(width: 6, height: 10)
    }
    
    var previousLocation = CGPoint() //tracks last touch point
    
    //Externally available variable for location to transition background colors (defined by the color scheme's int #):
    var colorChangePoint: CGFloat = 0
    
    // MARK: - Init
    
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
        self.layer.addSublayer(controlLayer)
        
        createNodesAndLabelsForOptions() //create nodes & labels
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Custom Slider fatal error")
    }
    
    // MARK: - Visual Configuration
    
    func createNodesAndLabelsForOptions() { //for each option, creates point on track + matching label
        var counter = 0
        for point in self.fixedSelectionPoints {
            //Determine center position of each node (used to align the text label). The CENTER of the node should be @ each numerical interval value (in this case 0, 0.25, 0.5, 0.75, 1).
            let nodeWidth: CGFloat = nodeSize.width
            let nodeHeight: CGFloat = nodeSize.height
            let nodeMinX = CGFloat(selectionPointNumericalAnalogue[counter]) * trackLayerWidth - nodeWidth/2 //minimum X position of the node
            let nodeCenterX = nodeMinX + nodeWidth / 2 //center X position of node
            let nodeLayer = CustomSliderNodeLayer() //have to add as sublayer -> super layer BEFORE specifying coordinates (so that coords are in the super layer's system)
            
            trackLayer.addSublayer(nodeLayer)
            nodeLayer.frame = CGRect(x: (nodeSize.width/2 + nodeMinX), y: trackLayerHeight, width: nodeWidth, height: nodeHeight) //y position is @ bottom of the track; need to add offset b/c we drew the track longer than its true frame
            nodeLayer.customSlider = self
            nodeLayer.setNeedsDisplay()
            
            //Create corresponding label (centered @ the node's center but shifted down so there is a little space below the node):
            let labelHeight: CGFloat = 25
            let nodeBottomY: CGFloat = trackLayerMaxY + nodeLayer.frame.height + 6 //get the point for the bottom of the node & then add 6 (distance between node & lbl)
            let labelY: CGFloat = nodeBottomY + labelHeight/2
            let centerPoint = CGPoint(x: nodeCenterX, y: labelY) //label horizontal center = node's centerX; vertical center is around a point 6 + half lbl height from bottom of node
            let labelSize = CGSize(width: 45, height: labelHeight)
            let labelFrame = createRectAroundCenter(centerPoint, size: labelSize)
            let label = UILabel(frame: labelFrame)
            label.font = UIFont.boldSystemFontOfSize(11)
            label.text = point
            label.textAlignment = .Center
            self.addSubview(label)
            
            counter += 1 //increment counter
        }
    }
    
    func updateLayerFrames() { //updates layer frames to fit
        CATransaction.begin()
        CATransaction.setDisableActions(true) //suppresses animations until transaction is committed
        
        trackLayer.frame = CGRect(x: -nodeSize.width/2, y: 25, width: self.frame.width + nodeSize.width, height: 8) //we drew the track beyond its true bounds b/c we need the track to cover the leading edge of node1 & trailing edge of node 2
        trackLayer.setNeedsDisplay() //updates the view for this layer
        
        let controlLayerCenter = CGFloat(positionForValue(currentValue)) //gets current center for control (should lock on center of a node); 'currentValue' is value between 0 & 1 (instead of 0 & 240)
        let controlLayerOriginY: CGFloat = trackLayerMaxY - controlWidth //bottom of control touches bottom of track (trackLayerMaxY)
        let controlLayerX = controlLayerCenter - controlWidth/2
        controlLayer.frame = CGRect(x: controlLayerX, y: controlLayerOriginY, width: controlWidth, height: controlWidth)
        controlLayer.setNeedsDisplay()
        
        CATransaction.commit() //CATransaction code wraps the entire frame update into 1 transaction so the transitions are smooth & disables animations on the layer
    }
    
    func positionForValue(value: Double) -> Double { //converts a numerical value into a position along the slider track for the control (offset so as to be centered around the node)
        let position = (Double(bounds.width) * (value - minValue) / (maxValue - minValue)) //sets the position -> a % of the total difference between min & max value
        print("Position: \(position)")
        return position
    }
    
    // MARK: - Interaction Logic
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        previousLocation = touch.locationInView(self) //translates touch event -> self's coordinate space
        
        if (controlLayer.frame.contains(previousLocation)) { //check if touch was in controlLayer's frame
            controlLayer.highlighted = true
        }
        return controlLayer.highlighted //informs UIControl whether subsequent touches should be tracked (tracking touch events continues only if the controlLayer is highlighted)
    }
    
    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double { //clamps the passed in value so it is > lowerValue & < upperValue
        return min(max(value, lowerValue), upperValue)
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        
        //Determine by how much the user dragged:
        let changeInPosition = Double(location.x - previousLocation.x)
        let changeInValue = (maxValue - minValue) * changeInPosition / Double(bounds.width - controlWidth) //gets the change in position as a % of the slider's width??? //* this is using the overall width of the view instead of the length of the track - the control should only be able to move along the track's width.
        previousLocation = location //set previous location -> new location
        
        //Update value of the controlLayer depending on where the user dragged it:
        if (controlLayer.highlighted) {
            currentValue += changeInValue
            currentValue = boundValue(currentValue, toLowerValue: minValue, upperValue: maxValue)
        }
        
        sendActionsForControlEvents(.ValueChanged) //notification code in Target Action pattern - notifies any subscribed targets that the slider's value has changed
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        //Lock the controlLayer onto whichever node it is closest to:
        if let locationX = touch?.locationInView(self).x {
            let locationAsPercentage: CGFloat = locationX / trackLayerWidth //convert abs location -> %
            print("End Location: \(locationAsPercentage)")
            
            if (locationAsPercentage <= 0.0) { //set lower bound
                print("Ended on first item")
            } else if (locationAsPercentage >= 1.0) { //set upper bound
                print("Ended on last item")
            } else { //somewhere in between 0 & 1
                let numberOfTwoPointRanges = selectionPointNumericalAnalogue.count - 1 //# of 2 point ranges (e.g. 0 - 0.25, 0.25 - 0.5, etc.) is 1 minus the total # of points
                for i in 0..<numberOfTwoPointRanges { //find the 2 surrounding points
                    let lowerPoint = CGFloat(selectionPointNumericalAnalogue[i])
                    let upperPoint = CGFloat(selectionPointNumericalAnalogue[i + 1])
                    if (locationAsPercentage >= lowerPoint) && (locationAsPercentage <= upperPoint) {
                        //Determine which of the two points the slider is closest to:
                        let distanceFromLower: CGFloat = locationAsPercentage - lowerPoint
                        let distanceToUpper: CGFloat = upperPoint - locationAsPercentage
                        if (distanceFromLower >= distanceToUpper) {
                            print("Closer to \(upperPoint)")
                            //Lock final location of controlLayer -> upperPoint
                        } else {
                            print("Closer to \(lowerPoint)")
                            //Lock final location of controlLayer -> lowerPoint
                        }
                        
                        break
                    }
                }
            }
        }
        
        controlLayer.highlighted = false //ends tracking event
    }
}

// MARK: - Control Layer

class CustomSliderControlLayer: CALayer { //class for slider's Control object
    var highlighted = false {
        didSet { //put tilt animation in here???
            setNeedsDisplay() //changes fill color slightly when touch event is active
        }
    }
    weak var customSlider: CustomSlider?
    
    override func drawInContext(ctx: CGContext) {
        if let slider = customSlider {
            let controlFrame = self.bounds
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

// MARK: - Track Layer

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

// MARK: - Node Layer

class CustomSliderNodeLayer: CALayer { //class for slider's fixed selection points
    
    weak var customSlider: CustomSlider?
    
    override func drawInContext(ctx: CGContext) {
        //draw each point as a black triangle just under the track, using the centerPosition as a guide
        //let rect = CGRect(x: centerPosition.x, y: centerPosition.y, width: 15, height: 15)
        let rect = bounds
        CGContextAddRect(ctx, rect)
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextStrokePath(ctx)
        CGContextSetFillColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextFillRect(ctx, rect)
    }
}
