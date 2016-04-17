//  RangeScaleView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/16/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// RangeScale custom view that is used in the CustomWithRangeScale DataEntry TV cell.

import UIKit

class RangeScaleView: UIView {
    
    override var frame: CGRect {
        didSet { //redraw subviews when frame changes
            setNeedsLayout()
        }
    }
    var parameters: (Int, Int, Int)? { //(min, max, increment) for scale
        didSet { //adjust currentValue when set
            if let params = parameters { //cast params -> Double so decimal calculation can be done
                let min = Double(params.0)
                let max = Double(params.1)
                let increment = Double(params.2)
                let trueCenter = (max - min)/2 + min //find mathematical center
                let remainder = (trueCenter - min) % increment //check if center fits on increment
                if (remainder != 0) { //adjust currentValue so it fits on an increment
                    self.currentValue = Int(trueCenter + remainder)
                } else { //trueCenter already fits on increment
                    self.currentValue = Int(trueCenter)
                }
                minimumValueLabel.text = "\(Int(min))" //initialize minLbl
                maximumValueLabel.text = "\(Int(max))" //initialize maxLbl
                trackLayer.rangeScaleParameters = params //reference for trackLayer
                trackLayer.inset = self.trackLayerInset //set inset
                setNeedsLayout() //update UI w/ parameters
            }
        }
    }
    var currentValue: Int? { //the current location of the selectionLayer (starts @ center)
        didSet { //send notification -> VC & update label
            if let value = currentValue {
                currentSelectionLabel.text = "\(value)" //update label when value changes
                let notification = NSNotification(name: BMN_Notification_RangeScaleValueDidChange, object: nil, userInfo: [BMN_CustomWithRangeScaleCell_RangeScaleValueKey: value])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    
    //Subviews & Sublayers:
    private let plusButton = UIButton(frame: CGRectZero)
    private let minusButton = UIButton(frame: CGRectZero)
    private let minimumValueLabel = UILabel(frame: CGRectZero) //@ beginning of trackLyr
    private let maximumValueLabel = UILabel(frame: CGRectZero) //@ end of trackLyr
    private let currentSelectionLabel = UILabel(frame: CGRectZero) //ALWAYS underneath selectionLayer
    private let trackLayer = RangeScaleTrackLayer() //track along which selectionLayer moves
    private let selectionLayerView = RangeScaleSelectionLayerView(frame: CGRectZero) //contains slctionLyr
    
    //Subview configuration properties:
    private let buttonWidth: CGFloat = 35 //width/height for +/- btns
    private let smallLabelWidth: CGFloat = 20 //width/height for min/max lbls
    private let largeLabelWidth: CGFloat = 30 //width/height for currentValueLbl
    private let selectionLayerWidth: CGFloat = 5
    
    //Visual layout offsets/spacers:
    private let horizontalOffset: CGFloat = 5 //distance from edges of btns to start/end of view
    private let horizontalSpacer: CGFloat = 10 //distance between btn edges & trackLayer
    private let verticalOffset: CGFloat = 5 //distance between top of btns/track & top of view
    private let verticalSpacer: CGFloat = 5 //distance between bottom of track & top of labels
    private let trackLayerInset: CGFloat = 5 //inset from track & edges of trackLyr frame
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //(1) Add trackLayer & selectionLayerView:
        self.layer.addSublayer(trackLayer)
        self.addSubview(selectionLayerView)
        
        //(2) Configure Subviews:
        plusButton.addTarget(self, action: #selector(self.plusButtonClick(_:)), forControlEvents: .TouchUpInside)
        plusButton.setImage(UIImage(named: "RangeScale_plus_icon"), forState: .Normal)
        self.addSubview(plusButton)
        
        minusButton.addTarget(self, action: #selector(self.minusButtonClick(_:)), forControlEvents: .TouchUpInside)
        minusButton.setImage(UIImage(named: "RangeScale_minus_icon"), forState: .Normal)
        minusButton.backgroundColor = UIColor.redColor()
        self.addSubview(minusButton)
        
        minimumValueLabel.textAlignment = .Center
        minimumValueLabel.font = UIFont.systemFontOfSize(13)
        self.addSubview(minimumValueLabel)
        
        maximumValueLabel.textAlignment = .Center
        maximumValueLabel.font = UIFont.systemFontOfSize(13)
        self.addSubview(maximumValueLabel)
        
        currentSelectionLabel.textColor = UIColor.redColor()
        currentSelectionLabel.textAlignment = .Center
        currentSelectionLabel.font = UIFont.boldSystemFontOfSize(17) //fontSize is > min/max fontSize
        self.addSubview(currentSelectionLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //(1) Draw +/- buttons & trackLayer (|-| minusBtn |--| trackLayer |--| plusBtn |-|):
        minusButton.frame = CGRectMake(horizontalOffset, verticalOffset, buttonWidth, buttonWidth)
        trackLayer.frame = CGRectMake((horizontalOffset + buttonWidth + horizontalSpacer), verticalOffset, (self.frame.width - 2 * (buttonWidth + horizontalOffset + horizontalSpacer)), buttonWidth)
        plusButton.frame = CGRectMake((trackLayer.frame.maxX + horizontalSpacer), verticalOffset, buttonWidth, buttonWidth)
        
        //(2) Center the minimum & maximum labels around the min & max nodes on the track (min @ the 0% mark & max @ the 100% mark of the track's LINE, NOT the full trackLayer):
        let minLblCenterX = trackLayer.frame.minX + trackLayerInset
        let maxLblCenterX = trackLayer.frame.maxX - trackLayerInset
        minimumValueLabel.frame = CGRectMake((minLblCenterX - smallLabelWidth/2), (verticalOffset + buttonWidth + verticalSpacer), smallLabelWidth, smallLabelWidth)
        maximumValueLabel.frame = CGRectMake((maxLblCenterX - smallLabelWidth/2), (verticalOffset + buttonWidth + verticalSpacer), smallLabelWidth, smallLabelWidth)
        
        //(3) Set the selectionLayer frame w/ the currentSelectionLbl underneath it:
        if let centerX = getCurrentValueAsPositionOnTrack() {
            let originX = centerX - selectionLayerWidth/2
            selectionLayerView.frame = CGRectMake(originX, trackLayer.frame.minY, selectionLayerWidth, buttonWidth)
            currentSelectionLabel.frame = CGRectMake((centerX - largeLabelWidth/2), (selectionLayerView.frame.maxY + verticalSpacer), largeLabelWidth, largeLabelWidth) //starts out @ currentValue position, CENTERED HORIZONTALLY underneath the selectionLayer
            checkForLabelOverlap() //check if starting point is @ min or max value
        }
    }
    
    private func getCurrentValueAsPositionOnTrack() -> CGFloat? { //returns currentVal as X coord on track
        let trueTrackWidth = trackLayer.frame.width - 2 * trackLayerInset
        if let params = parameters, value = currentValue {
            let min = CGFloat(params.0)
            let max = CGFloat(params.1)
            let percentage = (CGFloat(value) - min) / (max - min)
            let xCoordinate = trackLayer.frame.minX + trackLayerInset + (percentage * trueTrackWidth) //currentValue expressed as an X coordinate (CENTER_X for selectionLayer & its label)
            return xCoordinate
        }
        return nil
    }
    
    func adjustSelectionLayerPosition() { //moves selectionLayer & its label based on currentValue
        //Animate the centerX positions for selectionLayer & currentSelectionLabel:
        if let centerX = getCurrentValueAsPositionOnTrack() { //convert currentVal -> x coord on track
            UIView.animateWithDuration(0.65) { //run both animations simultaneously!
                self.currentSelectionLabel.center.x = centerX
                self.selectionLayerView.center.x = centerX
            }
        }
        checkForLabelOverlap() //check if currentVal is @ min or max value
    }
    
    func checkForLabelOverlap() { //if currentVal is @ min or max, hide associated label until val changes
        if let params = parameters, value = currentValue {
            if (value == params.0) { //currentVal is @ the MINIMUM
                minimumValueLabel.hidden = true
            } else { //reveal the lbl (in case it was previously hidden)
                minimumValueLabel.hidden = false
            }
            if (value == params.1) { //currentVal is @ the MAXIMUM
                maximumValueLabel.hidden = true
            } else { //reveal lbl (in case it was previously hidden)
                maximumValueLabel.hidden = false
            }
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func plusButtonClick(sender: UIButton) {
        if let params = parameters, value = currentValue {
            if !(value >= params.1) { //don't let currentValue go ABOVE the MAX
                currentValue = value + params.2 //increase by defined increment
                adjustSelectionLayerPosition() //adjust selectionLyr
            }
        }
    }
    
    @IBAction func minusButtonClick(sender: UIButton) {
        if let params = parameters, value = currentValue {
            if !(value <= params.0) { //don't let the currentValue fall BELOW the MIN
                currentValue = value - params.2 //decrease by defined decrement
                adjustSelectionLayerPosition() //adjust selectionLyr
            }
        }
    }
    
}

class RangeScaleSelectionLayerView: UIView { //container for selectionLayer (for animation purposes)
    
    private let selectionLayer = RangeScaleSelectionLayer() //layer indicating current selection on scale
    override var frame: CGRect {
        didSet { //update layer's frame when container's (view's) frame changes
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(selectionLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setNeedsLayout() {
        selectionLayer.frame = CGRectMake(0, 0, bounds.width, bounds.height) //layer fills ENTIRE view
    }
    
}

class RangeScaleSelectionLayer: CALayer { //layer containing the indicator for the currently selected pnt
    
    override var frame: CGRect {
        didSet { //redraw layer
            setNeedsDisplay()
        }
    }
    
    override func drawInContext(ctx: CGContext) {
        //Draw 1 vertical line that occupies the ENTIRE height & width of its frame:
        CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
        CGContextSetLineWidth(ctx, self.bounds.width)
        let centerX = (self.bounds.width / 2)
        CGContextMoveToPoint(ctx, centerX, 0) //start point for line is @ centerX
        CGContextAddLineToPoint(ctx, centerX, self.bounds.height) //end point for line
        CGContextStrokePath(ctx) //draw line
    }
    
}

class RangeScaleTrackLayer: CALayer { //layer containing the track displaying the range
    
    var rangeScaleParameters: (Int, Int, Int)? //reference to range scale parameters
    var inset: CGFloat? //reference to 'trackLayerInset' defined in RangeScale class; inset ensures that items drawn @ the edges of the view will be rendered in full (won't be cut off by frame)
    override var frame: CGRect {
        didSet { //redraw layer
            setNeedsDisplay()
        }
    }
    
    override func drawInContext(ctx: CGContext) {
        if let parameters = rangeScaleParameters, lineInset = inset {
            //(1) Draw main track - horizontal line across center of frame from inset -> (maxX - inset):
            CGContextSetStrokeColorWithColor(ctx, UIColor.blackColor().CGColor)
            let lineWidth: CGFloat = 3.5
            CGContextSetLineWidth(ctx, lineWidth)
            let centerY = self.bounds.height/2 //line will evenly distribute around centerY
            CGContextMoveToPoint(ctx, lineInset, centerY) //start drawing line @ offset
            CGContextAddLineToPoint(ctx, (self.bounds.width - lineInset), centerY) //end point for line
            CGContextStrokePath(ctx) //draw line
            
            //(2) For each node (start, increments, end), draw a small vertical line evenly distributed (horizontally) around the corresponding % value on the track:
            let min = CGFloat(parameters.0)
            let max = CGFloat(parameters.1)
            let increment = CGFloat(parameters.2)
            var nodes: [CGFloat] = []
            var currentValue: CGFloat = min
            var counter: CGFloat = 0
            while (currentValue < max) { //get all node values
                currentValue = min + (counter * increment)
                nodes.append(CGFloat(currentValue))
                counter += 1
            }
            let trackWidth = self.bounds.width - 2 * lineInset //true width of track
            for node in nodes { //for each node, draw vertical line a certain % along the track
                let nodeLineHeight: CGFloat = 10
                let nodeLineWidth: CGFloat = 1.5
                let percentage: CGFloat = (node - min) / (max - min) //node's centerValue (% along track)
                let nodeStartX: CGFloat = lineInset + (trackWidth * percentage) //evenly distribute line width around the % location
                CGContextSetLineWidth(ctx, nodeLineWidth)
                CGContextMoveToPoint(ctx, nodeStartX, (centerY - nodeLineHeight/2)) //evenly distribute line vertically above & below the track
                CGContextAddLineToPoint(ctx, nodeStartX, (centerY + nodeLineHeight/2))
                CGContextStrokePath(ctx) //draw line
            }
        }
    }
    
}