//  CellWithCustomSlider.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 4/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// TV cell for CreateProjectVC that contains a custom slider for setting the project endpoint.

import UIKit

class CellWithCustomSlider: BaseCreateProjectCell {
    
    private let endpoints = [Endpoints.Continuous.rawValue, Endpoints.Day.rawValue, Endpoints.Week.rawValue, Endpoints.Month.rawValue, Endpoints.Year.rawValue] //endpoints for slider, match -> endpoints in init()!!!
    private var selectedEndpoint: Endpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil) //current endpoint selection (default is 'Continuous' project)
    var secondColor: UIColor { //make sure this is the same as the color in the init()!!!
        return UIColor(red: 50/255, green: 163/255, blue: 216/255, alpha: 1)
    }
    var colorScheme: (UIColor, UIColor) { //slider track's color scheme L & R values, make sure it matches color in init()!!!
        return (UIColor.whiteColor(), secondColor)
    }
    let slider: CustomSlider
    let sliderBackground = CustomSliderBackgroundView(frame: CGRectZero)
    
    // MARK: - Initializers
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        let nodes = [Endpoints.Continuous.rawValue, Endpoints.Day.rawValue, Endpoints.Week.rawValue, Endpoints.Month.rawValue, Endpoints.Year.rawValue]
        let color = UIColor(red: 50/255, green: 163/255, blue: 216/255, alpha: 1)
        let scheme = (UIColor.whiteColor(), color)
        slider = CustomSlider(frame: CGRectZero, selectionPoints: nodes, scheme: scheme)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //Configure slider & background view:
        slider.backgroundColor = UIColor.clearColor()
        slider.addTarget(self, action: #selector(self.customSliderSelectedNodeHasChanged(_:)), forControlEvents: .ValueChanged)
        sliderBackground.customSlider = slider
        
        insetBackgroundView.addSubview(sliderBackground)
        sliderBackground.addSubview(slider)
        sliderBackground.bringSubviewToFront(slider)
        
        //Register for notifications to communicate w/ VC & slider:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.customSliderCrownValueWasSet(_:)), name: BMN_Notification_SliderCrownValueWasSet, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.customSliderControlIsMoving(_:)), name: BMN_Notification_SliderControlIsMoving, object: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { //unregister for notifications on deinit
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //(1) Configure Slider Background:
        sliderBackground.frame = getViewFrameForLevel(viewLevel: (2, HorizontalLevels.FullLevel, 4))
        
        //(2) Configure Slider: 
        let width = sliderBackground.frame.width
        let height = sliderBackground.frame.height
        let widthPercentage: CGFloat = 0.8
        let heightPercentage: CGFloat = 0.65
        let sliderWidth = widthPercentage * width
        let sliderHeight = heightPercentage * height
        let originX = (1 - widthPercentage)/2 * width
        let originY = sliderBackground.labelBottomY 
        let sliderFrame = CGRectMake(originX, originY, sliderWidth, sliderHeight)
        slider.frame = sliderFrame
        
        //(3) Set completionIndicator -> completed (default for cell w/ slider):
        configureCompletionIndicator(true)
    }
    
    // MARK: - Slider Logic
    
    func customSliderSelectedNodeHasChanged(customSlider: CustomSlider) { //if slider lands on a fixedPoint that is NOT 'none', create an alert for adding the amount
        if (customSlider.suppressAlert) { //check if alert should be allowed to appear
            customSlider.suppressAlert = false //reset suppression alert
            return //break function
        }
        
        //Match the selected value -> a node:
        let selectedValue = customSlider.currentValue
        if let index = customSlider.fixedSelectionPointNumbers.indexOf(selectedValue) {
            let selection = endpoints[index]
            if (selection != endpoints.first) { //make sure the 1st node WAS NOT selected
                //Post notification -> VC so that the user can configure the selected endpoint:
                let notification = NSNotification(name: BMN_Notification_SliderSelectedNodeHasChanged, object: nil, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
            } else { //user selected 'None', set endpoint -> Continuous
                selectedEndpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil)
                reportData() //manually fire notification -> VC
            }
        }
    }
    
    func customSliderCrownValueWasSet(notification: NSNotification) {
        if let dict = notification.userInfo, enteredVal = dict[BMN_CellWithCustomSlider_CrownValueKey] as? Int {
            if (enteredVal == -1) { //user pressed Cancel
                slider.currentValue = 0.0 //set slider back -> 'None'
                slider.setNodeAsSelected() //change highlighting to reflect currentNode
                self.selectedEndpoint = Endpoint(endpoint: Endpoints.Continuous, number: nil)
            } else { //set slider's crown w/ value & adjust cell's 'selectedEndpoint'
                slider.crownLayerValue = enteredVal
                var counter = 0
                var selection: String = ""
                for selectionPoint in slider.fixedSelectionPointNumbers {
                    if (slider.currentValue == selectionPoint) { //get node #
                        selection = self.endpoints[counter] //get node name
                        break
                    }
                    counter += 1
                }
                if let select: Endpoints = Endpoints(rawValue: selection) { //match -> endpoint
                    self.selectedEndpoint = Endpoint(endpoint: select, number: enteredVal)
                } else {
                    print("Error: selectedEndpoint does not match known endpoint!")
                }
            }
        }
    }
    
    func customSliderControlIsMoving(notification: NSNotification) {
        if let dict = notification.userInfo, sliderIsMoving = dict[BMN_CellWithCustomSlider_IsSliderMovingKey] as? Bool {
            if (sliderIsMoving) { //remove completionIndicator while slider is moving
                configureCompletionIndicator(false)
            } else { //reset indicator when slider locks -> node
                configureCompletionIndicator(true)
            }
        }
    }
    
    // MARK: - Report Data
    
    override func reportData() { //reports selectedEndpoint -> VC
        //We cannot directly report the endpoint, so we will send the # of days if it exists OR 0 if it does not; the 2nd Endpoint initializer can recreate the endpoint based on the # of days:
        let numberOfDays: Int
        if let endpoint = selectedEndpoint.endpointInDays {
            numberOfDays = endpoint
        } else {
            numberOfDays = 0
        }
        let notification = NSNotification(name: BMN_Notification_CellDidReportData, object: nil, userInfo: [BMN_ProjectEndpointID: numberOfDays]) //report # of days
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }
    
}