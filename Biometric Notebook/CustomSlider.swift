//  CustomSlider.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Custom slider item for CreateProjectVC's endpoint selection. We want to make this as generic as possible in terms of configuration (colors, number/positioning of data points, & labels for the data points). The artwork making up the controls & the slider track along w/ the animation for slider movement should be consistent. At its essence, this is a slider w/ FIXED points where the control can reside (as opposed to a continuous slider).

import UIKit
import QuartzCore

class CustomSlider: UIControl {
    
    private let minValue = 0.0 //minimum value along track
    private let maxValue = 1.0 //maximum value along track
    var currentValue: Double = 0.0 { //current position of control on track (starts @ node0)
        didSet {
            if (currentValue == 0.0) { //make sure crownLayerValue is clear if currentVal = 0
                crownLayerValue = nil
            }
            updateLayerFrames() //update control's frame when 'currentValue' is changed (updateFrames() is invoked for properties that affect the control's layout)
        }
    }
    
    private let fixedSelectionPointNames: [String] //list of selection options for slider
    var fixedSelectionPointNumbers: [Double] { //assigns # between 0 & 1 to fixedSelections
        var array: [Double] = []
        let numberOfPoints = Double(fixedSelectionPointNames.count)
        let distance: Double = 1/(numberOfPoints - 1)
        var counter: Double = 0
        for _ in fixedSelectionPointNames { //split range from 0 - 1 into n evenly spaced segments
            array.append(0.0 + counter * distance)
            counter += 1
        }
        return array
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
    private var lockedToNode: Bool = true { //indicate whether control is locked -> node, default = locked
        didSet {
            if !(lockedToNode) { //hide checkmark when ctrlLayer is NOT on a node
                thirdSuccessIndicator?.hidden = true
            } else {
                if (currentValue == fixedSelectionPointNumbers[0]) { //reveal on locking node -> 'none'
                    thirdSuccessIndicator?.hidden = false
                }
            }
        }
    }
    var controlLayerOriginY: CGFloat { //bottom of control touches bottom of track (trackLayerMaxY)
        return trackLayerMaxY - controlLayerSize.height
    }
    private var controlLayerPositionY: CGFloat { //sets Y position depending on whether ctrl is locked
        if (lockedToNode) { //position is same as originY if the frame is locked
            return controlLayerOriginY
        } else { //unique position (shifted upwards) when frame is moving
            return (controlLayerOriginY - controlFrameshift) //* might need to adjust for rotation
        }
    }
    private let controlFrameshift: CGFloat = 3 //amount frame shifts up on click
    var controlLayerCenter: CGFloat { //center X value for control
        return CGFloat(positionForValue(currentValue)) //get control center pt
    }
    var controlLayerOriginX: CGFloat { //left-most x value for control
        return controlLayerCenter - controlLayerSize.width/2
    }
    
    var controlLayerSize: CGSize { //width & height of control object (matched to asset)
        return CGSize(width: 20, height: 24)
    }
    var nodeSize: CGSize { //width & height for each node (match to asset)
        return CGSize(width: 8, height: 16)
    }
    
    private var nodes: [CustomSliderNodeLayer] = [] //so we can refer back to nodes
    private var nodeLabels: [UILabel] = [] //so we can refer back to labels
    private var currentlySelectedNode: CustomSliderNodeLayer?
    private let crownLayer = CustomSliderCrownLayer() //crown for controlLayer
    private var crownLayerHeight: CGFloat {
        return 0
    }
    var crownLayerValue: Int? {
        didSet {
            if let value = crownLayerValue { //reveal crown & set label
                crownLayer.value = value
                crownLabel.text = "\(value)"
                crownLabel.hidden = false
                controlLayer.valueIsSet = true
                thirdSuccessIndicator?.hidden = false
            } else { //hide crown & label if value is removed
                crownLayer.value = nil
                crownLabel.text = nil
                crownLabel.hidden = true
                controlLayer.valueIsSet = false
            }
        }
    }
    private var crownLabel = UILabel() //should be hidden if crownLayer is hidden
    private var crownLabelHeight: CGFloat {
        return 20
    }
    private var nodeLabelFontSize: CGFloat = 11.5
    
    var colorScheme: (UIColor, UIColor) //color scheme for the slider track - lowColor is the bottom-most color in the gradient, highColor is the top-most color in the gradient, 'startPoint' is the data point @ which to begin gradienting (everything before the startPoint will be the lowColor).
    var previousLocation = CGPoint() //tracks last touch point
    weak var thirdSuccessIndicator: UIView? 
    
    // MARK: - Init
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Custom Slider fatal error")
    }
    
    init(frame: CGRect, selectionPoints: [String], scheme: (UIColor, UIColor)) {
        self.fixedSelectionPointNames = selectionPoints
        self.colorScheme = scheme
        super.init(frame: frame)
        
        trackLayer.customSlider = self
        trackLayer.contentsScale = UIScreen.mainScreen().scale //ensures visuals are crisp on retina disp
        self.layer.addSublayer(trackLayer)
        
        controlLayer.customSlider = self
        controlLayer.image = UIImage(named: "slider_control_empty")
        self.addSubview(controlLayer)
        
        crownLayer.customSlider = self
        crownLayer.hidden = true //hide until crownValue is set
        crownLayer.contentsScale = UIScreen.mainScreen().scale
        self.layer.addSublayer(crownLayer)
        
        crownLabel.hidden = true //hide until crownValue is set
        crownLabel.layer.cornerRadius = 5
        crownLabel.backgroundColor = UIColor.greenColor()
        crownLabel.textColor = UIColor.whiteColor()
        crownLabel.textAlignment = .Center
        crownLabel.font = UIFont.systemFontOfSize(12, weight: 1.5)
        self.addSubview(crownLabel)
        
        createNodesAndLabelsForOptions() //create nodes & labels
        setNodeAsSelected() //highlights first nodeLabel @ start
    }
    
    // MARK: - Visual Configuration
    
    func createNodesAndLabelsForOptions() { //for each option, creates point on track + matching label
        var counter = 0
        for point in self.fixedSelectionPointNames {
            //Determine center position of each node (used to align the nodeLabel) - the CENTER of the node should be @ each numerical interval value (in this case 0, 0.25, 0.5, 0.75, 1).
            let nodeWidth: CGFloat = nodeSize.width
            let nodeHeight: CGFloat = nodeSize.height
            let nodeOriginX = CGFloat(fixedSelectionPointNumbers[counter]) * trackLayerWidth - nodeWidth/2 //X origin of the curent node
            let nodeCenterX = nodeOriginX + nodeWidth / 2 //center X position of node
            let nodeFrame = CGRect(x: nodeOriginX, y: trackLayerMaxY, width: nodeWidth, height: nodeHeight) //y position is @ bottom of the track
            let nodeLayer = CustomSliderNodeLayer(frame: nodeFrame, positionInNodeArray: counter)
            self.addSubview(nodeLayer) //add subview -> self instead of the layer
            nodes.append(nodeLayer) //add node -> array
            nodeLayer.customSlider = self
            nodeLayer.setNeedsDisplay()
            
            //Create corresponding label (centered @ the node's center but shifted down so there is a little space below the node):
            let labelHeight: CGFloat = 30
            let nodeBottomY: CGFloat = trackLayerMaxY + nodeLayer.frame.height + 3 //get the point for the bottom of the node & then add an offset (distance between node & lbl)
            let labelY: CGFloat = nodeBottomY + labelHeight/2
            let centerPoint = CGPoint(x: nodeCenterX, y: labelY) //label horizontal center = node's centerX; vertical center is around a point 6 + half lbl height from bottom of node
            let labelSize = CGSize(width: 55, height: labelHeight)
            let labelFrame = createRectAroundCenter(centerPoint, size: labelSize)
            let label = UILabel(frame: labelFrame)
            label.font = UIFont.systemFontOfSize(nodeLabelFontSize)
            label.text = point
            label.textAlignment = .Center
            nodeLabels.append(label) //add label -> array
            self.addSubview(label)
            
            counter += 1 //increment counter
        }
    }
    
    func updateLayerFrames() { //updates track, control, & crown layer visuals
        CATransaction.begin()
        CATransaction.setDisableActions(true) //suppresses animations until transaction is committed
        
        //Set frame for track:
        trackLayer.frame = CGRect(x: -nodeSize.width/2, y: 25, width: self.frame.width + nodeSize.width, height: 10) //we drew the track beyond its true bounds b/c we need the track to cover the leading edge of node1 & trailing edge of node2
        trackLayer.setNeedsDisplay() //updates the view for this layer
    
        //Set frame for control:
        controlLayer.frame = CGRect(x: controlLayerOriginX, y: controlLayerPositionY, width: controlLayerSize.width, height: controlLayerSize.height)
        
        //Set frame for crown (mounted on top of the control, to fill in empty arc):
        let crownLayerY = controlLayerOriginY - crownLayerHeight //shift the starting y point up by height
        crownLayer.frame = CGRect(x: controlLayerOriginX, y: crownLayerY, width: controlLayerSize.width, height: crownLayerHeight)
        
        //Set frame for label (mounted on top of the crown):
        let yValue = crownLayer.frame.origin.y - crownLabelHeight
        crownLabel.frame = CGRect(x: crownLayer.frame.origin.x, y: yValue, width: crownLayer.frame.width, height: crownLabelHeight)
        
        CATransaction.commit() //CATransaction code wraps the entire frame update into 1 transaction so the transitions are smooth & disables animations on the layer
    }
    
    func positionForValue(value: Double) -> Double { //converts a decimal value between 0 & 1 into an absolute position along the slider track for the control (used to position the controlLayer)
        let position = (Double(bounds.width) * (value - minValue) / (maxValue - minValue))
        return position
    }
    
    // MARK: - Interaction Logic
    
    private var nodeAtStartOfTouch: Int? //node where control was locked when user touched the control
    private var crownLayerValueAtStartOfTouch: Int? //crownValue when user touched the control
    var suppressAlert: Bool = false //used to stop alert in VC from appearing
    
    func getNodeForCurrentValue() -> Int? { //uses currentVal to obtain node's index
        let index = fixedSelectionPointNumbers.indexOf(currentValue)
        return index
    }
    
    func boundValue(value: Double, toLowerValue lowerValue: Double, upperValue: Double) -> Double { //clamps the passed in value so it is > lowerValue & < upperValue
        return min(max(value, lowerValue), upperValue)
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        previousLocation = touch.locationInView(self) //translates touch event -> self's coordinate space
        if (controlLayer.frame.contains(previousLocation)) { //check if touch was in controlLayer's frame
            controlLayer.currentlyHighlighted = true
            nodeAtStartOfTouch = getNodeForCurrentValue() //currentNode when the touch began
            crownLayerValueAtStartOfTouch = crownLayerValue //crownValue when the touch began
            
            //Remove highlighting from label & hide crownLayer until controlLayer locks on a node again:
            crownLayerValue = nil //unless it locks on the previous value?
            currentlySelectedNode?.selected = false
            
            //Movement Animation - (1) Detach control from node (shift frame up by 3 pt):
            lockedToNode = false
            controlLayer.frame = CGRect(x: controlLayerOriginX, y: controlLayerPositionY, width: controlLayerSize.width, height: controlLayerSize.height)
            controlLayer.setNeedsDisplay()
        }
        return controlLayer.currentlyHighlighted
    }
    
    let tiltAngle: CGFloat = CGFloat(15.0 * M_PI / 180.0)
    let negativeTiltAngle: CGFloat = CGFloat(-15.0 * M_PI / 180.0)
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let location = touch.locationInView(self)
        let changeInPosition = Double(location.x - previousLocation.x) //determine how much user dragged
        let changeInValue = (maxValue - minValue) * changeInPosition / Double(bounds.width) //gets change in position as % of trackLayer width (so it can be added to currentValue, which is also a %)
        previousLocation = location //set previous location -> new location
        if (controlLayer.currentlyHighlighted) { //update ctrlLayer depending on where user dragged it
            currentValue += changeInValue
            currentValue = boundValue(currentValue, toLowerValue: minValue, upperValue: maxValue)
            
            //Movement Animation - (2) Tilt the control in the direction of motion:
            if (currentValue == 0.0) || (currentValue == 1.0) { //remove tilt @ edges
                controlLayer.transform = CGAffineTransformMakeRotation(0)
            } else {
                if (changeInValue > 0) { // positive change, tilt RIGHT
                    controlLayer.transform = CGAffineTransformMakeRotation(tiltAngle)
                } else if (changeInValue < 0) { // negative change, tilt LEFT
                    controlLayer.transform = CGAffineTransformMakeRotation(negativeTiltAngle)
                } else {
                    controlLayer.transform = CGAffineTransformMakeRotation(0)
                }
            }
        }
        return true
    }
    
    override func endTrackingWithTouch(touch: UITouch?, withEvent event: UIEvent?) {
        //Lock the controlLayer onto whichever node it is closest to:
        if let locationX = touch?.locationInView(self).x {
            controlLayer.transform = CGAffineTransformMakeRotation(0) //remove tilt
            let locationAsPercentage: CGFloat = locationX / trackLayerWidth //convert abs location -> %
            if !(locationAsPercentage <= 0.0) && !(locationAsPercentage >= 1.0) { //if control lies between 0 & 1, lock control -> node (auto-locks if value is outside this range)
                let numberOfTwoPointRanges = fixedSelectionPointNumbers.count - 1 //# of 2 point ranges (e.g. 0 - 0.25, 0.25 - 0.5, etc.) is 1 minus the total # of points
                for i in 0..<numberOfTwoPointRanges { //find the 2 surrounding points
                    let lowerPoint = CGFloat(fixedSelectionPointNumbers[i])
                    let upperPoint = CGFloat(fixedSelectionPointNumbers[i + 1])
                    if (locationAsPercentage >= lowerPoint) && (locationAsPercentage <= upperPoint) {
                        //Determine which of the two points the slider is closest to:
                        let distanceFromLower: CGFloat = locationAsPercentage - lowerPoint
                        let distanceToUpper: CGFloat = upperPoint - locationAsPercentage
                        var truePosition = Double()
                        if (distanceFromLower >= distanceToUpper) { //lock final location -> upperPoint
                            truePosition = Double(upperPoint)
                        } else { //Lock final location of controlLayer -> lowerPoint
                            truePosition = Double(lowerPoint)
                        }
                        lockedToNode = true //lock control -> node
                        currentValue = truePosition //set currentValue -> node center
                        if (nodeAtStartOfTouch == getNodeForCurrentValue()) {
                            //if user drops control on same node where it started, reset crownValue:
                            crownLayerValue = crownLayerValueAtStartOfTouch
                            suppressAlert = true //suppress the alert popup
                        }
                        setNodeAsSelected() //highlight the label for the selectedNode
                        break
                    }
                }
            } else { //if control is > 1 or < 0, we still need to lock -> node so it settles on track
                lockedToNode = true //lock control -> node
                updateLayerFrames() //update frame so control settles on track
                if (nodeAtStartOfTouch == getNodeForCurrentValue()) { //check for lastNode match
                    crownLayerValue = crownLayerValueAtStartOfTouch
                    suppressAlert = true //suppress the alert popup
                }
                setNodeAsSelected() //highlight label for the selectedNode
            }
        }
        sendActionsForControlEvents(.ValueChanged) //notification code in Target Action pattern - notifies any subscribed targets that the slider's value has changed
        controlLayer.currentlyHighlighted = false //end tracking event
    }
    
    func setNodeAsSelected() { //uses the current position of slider to determine which node is selected
        if let index = fixedSelectionPointNumbers.indexOf(currentValue) {
            let selectedNode = nodes[index]
            for node in nodes { //remove selection from other nodes
                node.selected = false
            }
            selectedNode.selected = true
            currentlySelectedNode = selectedNode
        }
    }
    
}

// MARK: - Control Layer

class CustomSliderControlLayer: UIImageView { //class for slider's Control object
    
    weak var customSlider: CustomSlider?
    var currentlyHighlighted = false
    override var frame: CGRect {
        didSet { //redraw view if the frame changes
            self.setNeedsDisplay()
        }
    }
    
    var valueIsSet: Bool = false {
        didSet {
            if (valueIsSet) { //image is 'full' image
                self.image = UIImage(named: "slider_control_full")
            } else { //image is 'empty' image
                self.image = UIImage(named: "slider_control_empty")
            }
            setNeedsDisplay()
        }
    }
    
}

// MARK: - Track Layer

class CustomSliderTrackLayer: CALayer { //class for slider's Track object
    //We want a thin rectangular slider w/ gradient fill to indicate transition from low -> high. At each point along the track where there is an option, we want to draw the bottom aspect of the control.
    weak var customSlider: CustomSlider?
    
    override func drawInContext(ctx: CGContext) {
        if let slider = customSlider {
            //First path (from start -> node #2):
            let height = bounds.height
            let firstPathWidth = bounds.width/CGFloat(slider.fixedSelectionPointNumbers.count - 1) + slider.nodeSize.width/2
            let x = bounds.origin.x
            let y = bounds.origin.y
            let startRect = CGRect(x: x, y: y, width: firstPathWidth, height: height)
            let startPath = UIBezierPath(rect: startRect) //first path is up til 2nd node
            let firstColor = slider.colorScheme.0.CGColor
            CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
            CGContextAddPath(ctx, startPath.CGPath)
            CGContextStrokePath(ctx) //stroke
            CGContextSetFillColorWithColor(ctx, firstColor)
            CGContextAddPath(ctx, startPath.CGPath)
            CGContextFillPath(ctx) //fill
            
            //Second path (from node#2 -> end):
            let endRect = CGRect(x: (x + firstPathWidth), y: y, width: (bounds.width - firstPathWidth), height: height)
            let endPath = UIBezierPath(rect: endRect)
            CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
            CGContextAddPath(ctx, endPath.CGPath)
            CGContextStrokePath(ctx)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [slider.colorScheme.0.CGColor, slider.colorScheme.1.CGColor]
            let colorLocations: [CGFloat] = [0.0, 1.0] //sets gradient color change points
            let start = CGPoint(x: (x + firstPathWidth), y: y)
            let end = CGPoint(x: bounds.width, y: height)
            let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
            CGContextDrawLinearGradient(ctx, gradient, start, end, .DrawsAfterEndLocation)
        }
    }
}

// MARK: - Node Layer

class CustomSliderNodeLayer: UIImageView { //class for slider's fixed selection points
    weak var customSlider: CustomSlider?
    let positionInNodeArray: Int //number of this node in the nodeArray
    var selected: Bool = false { //checks if the controlLayer is currently locked on this node
        didSet {
            if (selected) {
                formatSelectedLabel()
            } else {
                removeSelectionFormatFromLabel()
            }
        }
    }
    var nodeLabel: UILabel? { //label associated w/ this node
        if let slider = customSlider {
            return slider.nodeLabels[positionInNodeArray]
        }
        return nil
    }
    
    init(frame: CGRect, positionInNodeArray: Int) {
        self.positionInNodeArray = positionInNodeArray
        super.init(frame: frame)
        self.image = UIImage(named: "node")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func formatSelectedLabel() { //if the current node is selected, highlight its label
        if let label = nodeLabel, slider = customSlider {
            label.textColor = UIColor.greenColor()
            label.font = UIFont.systemFontOfSize(slider.nodeLabelFontSize, weight: 1.9)
        }
    }
    
    func removeSelectionFormatFromLabel() { //if the node becomes unselected, remove lbl formatting
        if let label = nodeLabel, slider = customSlider {
            label.textColor = UIColor.grayColor()
            label.font = UIFont.systemFontOfSize(slider.nodeLabelFontSize, weight: 1.4)
        }
    }
}

// MARK: - Crown Layer

class CustomSliderCrownLayer: CALayer { //the crown controls the behavior of the number label
    weak var customSlider: CustomSlider?
    var value: Int? {
        didSet {
            if let slider = customSlider {
                if (value != nil) { //reveal crown/label if value is set
                    slider.crownLabel.text = String(value)
                    self.hidden = false
                } else { //hide crown/label if value is removed
                    slider.crownLabel.text = nil
                    self.hidden = true
                }
            }
        }
    }
}