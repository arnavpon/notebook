//  ProjectVariablesViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/21/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Page to create & display input variables, project action (e.g. sleep, eat, exercise) between the IV & OV, and outcome variables.

import UIKit

class ProjectVariablesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var tutorialDescriptionView: UIView!
    @IBOutlet weak var tutorialViewHeight: NSLayoutConstraint!
    @IBOutlet weak var tutorialDescriptionLabel: UILabel!
    
    @IBOutlet weak var inputVariablesView: UIView!
    @IBOutlet weak var inputVariablesTitleView: UIView!
    @IBOutlet weak var inputVariablesTitleLabel: UILabel!
    @IBOutlet weak var inputVariablesTV: UITableView!
    @IBOutlet weak var inputVariablesTVButton: UIButton!
    @IBOutlet weak var inputViewArrow: UIImageView!
    
    @IBOutlet weak var addActionButton: UIButton!
    @IBOutlet weak var actionButtonArrow: UIImageView!
    @IBOutlet weak var actionPicker: UIPickerView!
    
    @IBOutlet weak var outcomeVariablesView: UIView!
    @IBOutlet weak var outcomeVariablesTitleView: UIView!
    @IBOutlet weak var outcomeVariablesTitleLabel: UILabel!
    @IBOutlet weak var outcomeVariablesTV: UITableView!
    @IBOutlet weak var outcomeVariablesTVButton: UIButton!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    let userDefaults = NSUserDefaults.standardUserDefaults() //update defaults
    var tutorialDescriptionViewMode: Bool = true //handles display of tutorial description
    var tutorialIsOn: Bool = false
    var screenNumber: Int = 1 //determines what aspect of the tutorial is visible (starts @ first screen)
    var inputsTableDummyData: [String] = ["Input Variable 1", "Input Variable 2", "Input Variable 3"]
    var outcomesTableDummyData: [String] = ["Outcome Variable 1", "Outcome Variable 2"]
    
    var projectTitle: String? //title (obtained from CreateProject VC)
    var projectQuestion: String? //question for investigation (obtained from CreateProject VC)
    var projectEndpoint: Endpoint? //endpoint (obtained from CreateProjectVC)
    var variableName: String? //the name of the variable entered by the user
    var createdVariable: Module? //the completed variable created by the user
    var tableViewForVariableAddition: UITableView? //notes which TV a new variable is going to
    
    var inputVariableRows: [Module] = [] //data source for rows before the 'Action'
    var outcomeVariableRows: [Module] = [] //data source for rows after the 'Action'
    var actionPickerRowArray: [String] = ["", Actions.Eat.rawValue, Actions.Sleep.rawValue, Actions.Exercise.rawValue, "Custom"]
    var selectedAction: Action? //captures 'action' before segue
    
    private let viewBorderWidth: CGFloat = 5
    private let viewCornerRadius: CGFloat = 20
    private var interactionEnabled: Bool = true //blocks view interaction if picker is visible
    
    // MARK: - View Configuration
    
    override func viewWillAppear(animated: Bool) { //add borders for the views, button, & picker
        createCardForView(tutorialDescriptionView, color: UIColor.blackColor().CGColor, borderWidth: viewBorderWidth/2, radius: viewCornerRadius)
        createCardForView(inputVariablesView, color: UIColor.blackColor().CGColor, borderWidth: viewBorderWidth, radius: viewCornerRadius)
        createCardForView(outcomeVariablesView, color: UIColor.blackColor().CGColor, borderWidth: viewBorderWidth, radius: viewCornerRadius)
        createCardForView(addActionButton, color: UIColor.blackColor().CGColor, borderWidth: viewBorderWidth/2, radius: viewCornerRadius/2)
        createCardForView(actionPicker, color: UIColor.blackColor().CGColor, borderWidth: viewBorderWidth/2, radius: viewCornerRadius/2)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (tutorialDescriptionViewMode) { //dim background if descriptionView is visible
            tutorialIsOn = true //start interactive tutorial (so TV will show dummy variables)
            tutorialDescriptionLabel.font = UIFont.systemFontOfSize(16, weight: 0.2)
            setVisualsForTutorialDescription(tutorialViewIsShowing: tutorialDescriptionViewMode)
        } else { //hide description
            hideTutorialDescriptionView()
        }
        
        actionPicker.dataSource = self
        actionPicker.delegate = self
        inputVariablesTV.dataSource = self
        inputVariablesTV.delegate = self
        outcomeVariablesTV.dataSource = self
        outcomeVariablesTV.delegate = self
        
        let inputLongPress = UILongPressGestureRecognizer(target: self, action: #selector(ProjectVariablesViewController.inputLongPressRecognized(_:)))
        inputVariablesTV.addGestureRecognizer(inputLongPress)
        let outcomeLongPress = UILongPressGestureRecognizer(target: self, action: #selector(ProjectVariablesViewController.outcomeLongPressRecognized(_:)))
        outcomeVariablesTV.addGestureRecognizer(outcomeLongPress)
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tutorialIsOn) { //user is in tutorial
            if (tableView == inputVariablesTV) { //inputs TV
                return inputsTableDummyData.count
            } else if (tableView == outcomeVariablesTV) { //outcomes TV
                return outcomesTableDummyData.count
            }
        } else { //user is not in tutorial
            if (tableView == inputVariablesTV) { //inputs TV
                return inputVariableRows.count
            } else if (tableView == outcomeVariablesTV) { //outcomes TV
                return outcomeVariableRows.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if (tutorialIsOn) { //user is in tutorial
            cell.contentView.alpha = dimmedAlpha
            if (tableView == inputVariablesTV) { //inputs TV
                cell.textLabel?.text = inputsTableDummyData[indexPath.row]
                cell.detailTextLabel?.text = "<> Module" //*not working!
            } else if (tableView == outcomeVariablesTV) { //outcomes TV
                cell.textLabel?.text = outcomesTableDummyData[indexPath.row]
                cell.detailTextLabel?.text = "<> Module" //*
            }
        } else { //NOT in tutorial
            cell.contentView.alpha = 1
            if (tableView == inputVariablesTV) { //inputs TV
                cell = tableView.dequeueReusableCellWithIdentifier("input_cell")!
                cell.textLabel?.text = inputVariableRows[indexPath.row].variableName
                cell.detailTextLabel?.text = "\(inputVariableRows[indexPath.row].moduleTitle) Module"
            } else if (tableView == outcomeVariablesTV) { //outcomes TV
                cell = tableView.dequeueReusableCellWithIdentifier("outcome_cell")!
                cell.textLabel?.text = outcomeVariableRows[indexPath.row].variableName
                cell.detailTextLabel?.text = "\(outcomeVariableRows[indexPath.row].moduleTitle) Module"
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //if user taps a cell, allow them to edit a variable's config (segue -> ConfigModuleVC)
        if (!tutorialDescriptionViewMode) && !(tutorialIsOn) { //normal behavior
            if (tableView == inputVariablesTV) { //inputs TV
                //
            } else if (tableView == outcomeVariablesTV) { //outcomes TV
                //
            }
        } else { //tutorial behavior
            if (screenNumber == 4) {
                tableView.cellForRowAtIndexPath(indexPath)?.selected = false
                closeTutorialScreenNumber(4) //close screen
            }
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if !(tutorialDescriptionViewMode) {
            if (tutorialIsOn) { //special tutorial behavior
                if (screenNumber == 4) && (indexPath.row == 0) { //handle tutorial rendering
                    return true //allow highlight animation but don't go anywhere
                }
            } else { //normal behavior
                return true
            }
        }
        return false
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //user can delete variables from TV
        if (!tutorialDescriptionViewMode) && !(tutorialIsOn) { //not in tutorial, default behavior
            return UITableViewCellEditingStyle.Delete
        } else { //tutorial is on, only allow swipe to register on screen #5
            if (screenNumber == 5) && (indexPath.row == 1) {
                return UITableViewCellEditingStyle.Delete
            }
        }
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (!tutorialDescriptionViewMode) && !(tutorialIsOn) { //normal behavior
            if (editingStyle == .Delete) { //delete row from data source
                if (tableView == inputVariablesTV) { //inputs TV
                    inputVariableRows.removeAtIndex(indexPath.row)
                } else if (tableView == outcomeVariablesTV) { //outcomes TV
                    outcomeVariableRows.removeAtIndex(indexPath.row)
                }
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                if !(inputVariableRows.count > 0) || !(outcomeVariableRows.count > 0) {
                    doneButton.enabled = false
                }
            }
        } else { //tutorial behavior
            if (editingStyle == .Delete) { //delete row from fake data source
                if (tableView == inputVariablesTV) { //inputs TV
                    inputsTableDummyData.removeAtIndex(indexPath.row)
                } else if (tableView == outcomeVariablesTV) { //outcomes TV
                    outcomesTableDummyData.removeAtIndex(indexPath.row)
                }
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            closeTutorialScreenNumber(5) //close tutorial out
        }
    }
    
    // MARK: - Table View Row Movement Logic
    
    var snapshot: UIView?
    var sourceIndexPath: NSIndexPath?
    
    @IBAction func inputLongPressRecognized(longPress: UILongPressGestureRecognizer) {//called when inputsTV is longPressed
        if !(tutorialIsOn) { //normal behavior
            let state = longPress.state
            let location = longPress.locationInView(inputVariablesTV)
            let indexPath = inputVariablesTV.indexPathForRowAtPoint(location) //gets the indexPath of the row that was long pressed
            handleRowMovement(state, location: location, indexPath: indexPath, tableView: inputVariablesTV, tableViewDataSource: inputVariableRows) { (let newArray) -> Void in
                self.inputVariableRows = newArray as! [Module]
            }
        } else { //tutorial on, special behavior
            if (screenNumber == 3) {
                let state = longPress.state
                let location = longPress.locationInView(inputVariablesTV)
                let indexPath = inputVariablesTV.indexPathForRowAtPoint(location) //gets the indexPath of the row that was long pressed
                handleRowMovement(state, location: location, indexPath: indexPath, tableView: inputVariablesTV, tableViewDataSource: inputsTableDummyData) { (let newArray) -> Void in
                    self.inputsTableDummyData = newArray as! [String]
                }
            }
        }
    }
    
    @IBAction func outcomeLongPressRecognized(longPress: UILongPressGestureRecognizer) { //called when outcomesTV is longPressed
        if !(tutorialIsOn) { //normal behavior
            let state = longPress.state
            let location = longPress.locationInView(outcomeVariablesTV)
            let indexPath = outcomeVariablesTV.indexPathForRowAtPoint(location) //gets indxPath of touched row
            handleRowMovement(state, location: location, indexPath: indexPath, tableView: outcomeVariablesTV, tableViewDataSource: outcomeVariableRows) { (let newArray) -> Void in
                self.outcomeVariableRows = newArray as! [Module]
            }
        } else {
            if (screenNumber == 3) {
                let state = longPress.state
                let location = longPress.locationInView(outcomeVariablesTV)
                let indexPath = outcomeVariablesTV.indexPathForRowAtPoint(location) //gets indxPath of touched row
                handleRowMovement(state, location: location, indexPath: indexPath, tableView: outcomeVariablesTV, tableViewDataSource: outcomesTableDummyData) { (let newArray) -> Void in
                    self.outcomesTableDummyData = newArray as! [String]
                }
            }
        }
    }
    
    func customSnapshotFromView(inputView: UIView) -> UIView { //returns custom snapshot of given view
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        inputView.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        snapshot = UIImageView.init(image: image)
        snapshot?.layer.masksToBounds = false
        snapshot?.layer.cornerRadius = 0.0
        snapshot?.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
        snapshot?.layer.shadowRadius = 5.0
        snapshot?.layer.shadowOpacity = 0.4
        return snapshot!
    }
    
    func exchangeElements(array: [AnyObject], fromIndex index: Int, toIndex: Int) -> [AnyObject] {
        var newArray = array
        let fromObject = array[index]
        let toObject = array[toIndex]
        newArray[index] = toObject
        newArray[toIndex] = fromObject
        return newArray
    }
    
    func handleRowMovement(state: UIGestureRecognizerState, location: CGPoint, indexPath: NSIndexPath?, tableView: UITableView, tableViewDataSource: [AnyObject], completion: ([AnyObject]) -> Void) {
        switch state {
        case UIGestureRecognizerState.Began:
            if ((indexPath) != nil) {
                sourceIndexPath = indexPath
                let cell = tableView.cellForRowAtIndexPath(indexPath!)
                snapshot = customSnapshotFromView(cell!) //take snapshot of cell
                
                //Add the snapshot as a subview, centered at the cell's center:
                var cellCenter = cell?.center
                snapshot?.center = cellCenter!
                snapshot?.alpha = 0.0
                tableView.addSubview(snapshot!)
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    //offset for gesture location:
                    cellCenter?.y = location.y
                    self.snapshot!.center = cellCenter!
                    self.snapshot?.transform = CGAffineTransformMakeScale(1.05, 1.05)
                    self.snapshot!.alpha = 0.98
                    cell!.alpha = 0.0 //fade out
                    }, completion: { (let finished) -> Void in
                        cell?.hidden = true //hide the cell when the animation completes
                })
                break
            }
        case UIGestureRecognizerState.Changed: //tracks changes in touch
            var cellCenter = snapshot?.center
            cellCenter?.y = location.y
            snapshot?.center = cellCenter!
            
            //Check if destination is another TV row:
            if (indexPath != nil) && !(indexPath!.isEqual(sourceIndexPath)) {
                if !(tutorialIsOn) { //default behavior
                    let newDataSource = exchangeElements(tableViewDataSource, fromIndex: (sourceIndexPath?.row)!, toIndex: (indexPath?.row)!) as! [Module] //update data source
                    completion(newDataSource) //pass modified array back out
                } else { //tutorial on, special behavior
                    let newDataSource = exchangeElements(tableViewDataSource, fromIndex: (sourceIndexPath?.row)!, toIndex: (indexPath?.row)!) as! [String] //update fake data source
                    completion(newDataSource) //pass modified array back out
                }
                tableView.moveRowAtIndexPath(sourceIndexPath!, toIndexPath: indexPath!) //move the rows
                sourceIndexPath = indexPath //update sourceIndex
            }
            break
        default: //(when touch ends or is cancelled) remove the snapshot & revert the fade
            let cell = tableView.cellForRowAtIndexPath(sourceIndexPath!)
            cell?.hidden = false
            cell?.alpha = 0.0
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.snapshot?.center = (cell?.center)!
                self.snapshot?.transform = CGAffineTransformIdentity
                self.snapshot?.alpha = 0.0
                cell!.alpha = 1.0 //undo fade
                }, completion: { (let finished) -> Void in
                    self.sourceIndexPath = nil
                    self.snapshot?.removeFromSuperview()
                    self.snapshot = nil
            })
            if (tutorialIsOn) { //if tutorial is on, close this screen after rows are switched
                closeTutorialScreenNumber(3) //end this part of tutorial
            }
            break
        }
    }
    
    // MARK: - Picker View
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return actionPickerRowArray.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return actionPickerRowArray[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (row == (actionPickerRowArray.count - 1)) { //check if last item was selected
            print("Custom Action Set")
            let alert = UIAlertController(title: "Add Custom Action", message: "Please enter a custom action", preferredStyle: UIAlertControllerStyle.Alert)
            let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (let cancel) -> Void in
                self.actionPicker.selectRow(0, inComponent: 0, animated: true) //cycle picker to firstVal
            })
            let add = UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler: { (let add) -> Void in
                let input = alert.textFields?.first?.text
                if (input != "") { //create a custom action from the input
                    self.selectedAction = Action(action: Actions.Custom, actionName: input)
                    self.shouldShowPickerView(showPicker: false, actionName: self.selectedAction?.customAction)
                } else { //incomplete entry, keep picker visible & cycle picker to start
                    self.actionPicker.selectRow(0, inComponent: 0, animated: true)
                    self.selectedAction = nil
                }
            })
            alert.addTextFieldWithConfigurationHandler({ (let textField) -> Void in })
            alert.addAction(cancel)
            alert.addAction(add)
            presentViewController(alert, animated: true, completion: nil)
        } else if (row == 0) { //first item in the picker (the blank) was selected
            selectedAction = nil
        } else { //if any other action is selected, set selectedAction & hide picker
            print("Normal Action Set")
            if let action = Actions(rawValue: actionPickerRowArray[row]) {
                selectedAction = Action(action: action, actionName: nil)
                shouldShowPickerView(showPicker: false, actionName: selectedAction?.action.rawValue)
            } else {
                print("error in pickerView didSelectRow() ELSE statement")
                self.actionPicker.selectRow(0, inComponent: 0, animated: true)
                selectedAction = nil
            }
        }
        if (selectedAction?.action == Actions.Custom) {
            print("Custom Action: \(selectedAction?.customAction)")
        } else {
            print("Normal Action: \(selectedAction?.action.rawValue)")
        }
        
    }
    
    func shouldShowPickerView(showPicker show: Bool, actionName: String?) { //controls picker display
        if (show) { //show picker
            actionPicker.hidden = false
            interactionEnabled = false
            for subview in view.subviews {
                if (subview != actionPicker) {
                    subview.hidden = true
                }
            }
        } else { //hide picker & set 'actionButton' title
            addActionButton.setTitleColor(UIColor.blackColor(), forState: .Normal)
            if let name = actionName {
                addActionButton.setTitle(name, forState: .Normal)
            } else {
                addActionButton.setTitle("Error, no actionName was set", forState: .Normal)
            }
            actionPicker.hidden = true
            interactionEnabled = true
            for subview in view.subviews {
                if (subview != actionPicker) {
                    subview.hidden = false
                }
            }
            if (self.inputVariableRows.count > 0) && (self.outcomeVariableRows.count > 0) && (self.selectedAction != nil) {
                self.doneButton.enabled = true
            }
        }
    }
    
    // MARK: - Tutorial
    
    let dimmedAlpha = CGFloat(0.3)
    var currentDrawingLayer1: TutorialCircleLayer?
    var currentDrawingLayer2: TutorialCircleLayer?
    var currentTextLayer: CATextLayer?
    var currentLineLayer1: LineLayer?
    var currentLineLayer2: LineLayer?
    
    func setVisualsForTutorialDescription(tutorialViewIsShowing showing: Bool) {
        if (showing) { //if box is visible, dim the view
            //Dim all items in the view:
            inputVariablesTitleLabel.alpha = dimmedAlpha
            inputVariablesTVButton.alpha = dimmedAlpha
            outcomeVariablesTitleLabel.alpha = dimmedAlpha
            outcomeVariablesTVButton.alpha = dimmedAlpha
            inputViewArrow.alpha = dimmedAlpha
            addActionButton.alpha = dimmedAlpha
            actionButtonArrow.alpha = dimmedAlpha
            
            inputVariablesTVButton.enabled = false
            addActionButton.enabled = false
            outcomeVariablesTVButton.enabled = false
            
        } else { //start the tutorial
            tutorialDescriptionViewMode = false //turn off tutorialView
            inputVariablesTVButton.superview?.alpha = 1
            inputVariablesTVButton.alpha = 1
            
            inputVariablesTVButton.enabled = true //enable & reveal button for tutorial part 1
            outcomeVariablesTVButton.alpha = 1
            outcomeVariablesTVButton.enabled = true //enable & reveal button for tutorial part 1
            setVisualsForTutorial(screenNumber) //bring up first part of tutorial
        }
    }
    
    func setVisualsForTutorial(screenToPresent: Int) { //drawing logic for tutorial layers
        //We need to transform the object (to be circled)'s frame rect from coordinates of object's superview -> VC view's coords! If object is already a subview of VC view, the transform has no effect, so it can still be applied. A subLayer of VC view draws IN THE VISIBLE AREA (point 0,0 corresponds to top left corner just BELOW the nav bar), so no adjustment is needed.
        if (screenToPresent > 5) {
            return //break function if number exceeds last tutorial screen (it shouldn't)
                print("Max tutorial screen exceeded")
        }
        switch screenToPresent {
        case 1: //adding variables
            getDrawingLayerForView(inputVariablesTVButton)
            getDrawingLayerForView(outcomeVariablesTVButton)
            let textForDisplay = "Click the + button when you want to add to the 'Input Variables' or 'Outcome Variables' tables."
            getTextLayerForDrawingLayer(textForDisplay, drawingLayer: currentDrawingLayer1!)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.TopMiddle, drawingLayer: currentDrawingLayer1!, drawingLayerCorner: Corners.LeftMiddle)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.BottomMiddle, drawingLayer: currentDrawingLayer2!, drawingLayerCorner: Corners.TopLeft)
        case 2: //adding Action
            getDrawingLayerForView(addActionButton)
            let textForDisplay = "Click here to add an action to your project. An action must be set for every project."
            getTextLayerForDrawingLayer(textForDisplay, drawingLayer: currentDrawingLayer1!)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.BottomLeft, drawingLayer: currentDrawingLayer1!, drawingLayerCorner: Corners.TopMiddle)
        case 3: //TV cell rearranging
            getDrawingLayerForView(inputVariablesTV)
            getDrawingLayerForView(outcomeVariablesTV)
            let textForDisplay = "You can rearrange the variables in a table by pressing and holding a row. The order you set here is the order in which data will be reported."
            getTextLayerForDrawingLayer(textForDisplay, drawingLayer: currentDrawingLayer1!)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.LeftMiddle, drawingLayer: currentDrawingLayer1!, drawingLayerCorner: Corners.Center)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.BottomMiddle, drawingLayer: currentDrawingLayer2!, drawingLayerCorner: Corners.TopMiddle)
        case 4: //editing a variable's configuration
            getDrawingLayerForView(inputVariablesTV.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!)
            getDrawingLayerForView(outcomeVariablesTV.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!)
            let textForDisplay = "Tapping on a variable in the table will allow you to edit its settings."
            getTextLayerForDrawingLayer(textForDisplay, drawingLayer: currentDrawingLayer1!)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.TopMiddle, drawingLayer: currentDrawingLayer1!, drawingLayerCorner: Corners.BottomMiddle)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.BottomMiddle, drawingLayer: currentDrawingLayer2!, drawingLayerCorner: Corners.TopMiddle)
        case 5: //TV cell deletion
            getDrawingLayerForView(inputVariablesTV.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!)
            getDrawingLayerForView(outcomeVariablesTV.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0))!)
            let textForDisplay = "If you no longer want a variable, swipe the right edge of its row in the table and tap 'Delete' to remove it."
            getTextLayerForDrawingLayer(textForDisplay, drawingLayer: currentDrawingLayer1!)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.TopLeft, drawingLayer: currentDrawingLayer1!, drawingLayerCorner: Corners.BottomMiddle)
            drawLineBetweenTextAndCircle(currentTextLayer!, textLayerCorner: Corners.BottomMiddle, drawingLayer: currentDrawingLayer2!, drawingLayerCorner: Corners.TopMiddle)
        default:
            print("error - setVisualsForTutorial switch default")
        }
    }
    
    func closeTutorialScreenNumber(number: Int) { //renders visuals @ end of each tutorial step
        if (number == 1) { //ready view for actionBtn tutorial
            inputVariablesTVButton.alpha = dimmedAlpha
            inputVariablesTVButton.enabled = false
            outcomeVariablesTVButton.alpha = dimmedAlpha
            outcomeVariablesTVButton.enabled = false
            addActionButton.alpha = 1
            addActionButton.enabled = true
        } else if (number == 2) { //ready view for TV rearranging tutorial
            addActionButton.alpha = dimmedAlpha
            addActionButton.enabled = false
            for cell in inputVariablesTV.visibleCells {
                cell.contentView.alpha = 1
            }
            for cell in outcomeVariablesTV.visibleCells {
                cell.contentView.alpha = 1
            }
        } else if (number == 3) { //ready view for tap cell tutorial
            for cell in inputVariablesTV.visibleCells {
                cell.contentView.alpha = dimmedAlpha
            }
            for cell in outcomeVariablesTV.visibleCells {
                cell.contentView.alpha = dimmedAlpha
            }
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            inputVariablesTV.cellForRowAtIndexPath(indexPath)!.contentView.alpha = 1
            outcomeVariablesTV.cellForRowAtIndexPath(indexPath)!.contentView.alpha = 1
        } else if (number == 4) { //ready view for swipe to delete tutorial
            let oldIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            let newIndexPath = NSIndexPath(forRow: 1, inSection: 0)
            inputVariablesTV.cellForRowAtIndexPath(oldIndexPath)!.contentView.alpha = dimmedAlpha
            outcomeVariablesTV.cellForRowAtIndexPath(oldIndexPath)!.contentView.alpha = dimmedAlpha
            inputVariablesTV.cellForRowAtIndexPath(newIndexPath)!.contentView.alpha = 1
            outcomeVariablesTV.cellForRowAtIndexPath(newIndexPath)!.contentView.alpha = 1
        } else if (number == 5) { //ready view for proper use
            inputVariablesTVButton.enabled = true
            addActionButton.enabled = true
            outcomeVariablesTVButton.enabled = true
            resetAlphaForAllSubviews(ofView: self.view)
            
            //Alert user that tutorial is over:
            let alert = UIAlertController(title: "Tutorial Complete!", message: "Great work! You have completed this tutorial. You're ready to set up your own projects.", preferredStyle: UIAlertControllerStyle.Alert)
            let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (let ok) -> Void in
                //Reload TVs & turn tutorial off:
                self.tutorialIsOn = false
                self.inputVariablesTV.reloadData()
                self.outcomeVariablesTV.reloadData()
            })
            alert.addAction(ok)
            presentViewController(alert, animated: true, completion: nil)
        }
        
        //Clear all layers after each run:
        currentDrawingLayer1?.removeFromSuperlayer()
        currentDrawingLayer1 = nil
        currentDrawingLayer2?.removeFromSuperlayer()
        currentDrawingLayer2 = nil
        currentTextLayer?.removeFromSuperlayer()
        currentTextLayer = nil
        currentLineLayer1?.removeFromSuperlayer()
        currentLineLayer1 = nil
        currentLineLayer2?.removeFromSuperlayer()
        currentLineLayer2 = nil
        
        screenNumber += 1
        setVisualsForTutorial(screenNumber) //open next screen in the tutorial
    }
    
    func resetAlphaForAllSubviews(ofView view: UIView) { //recursive function
        for subview in view.subviews { //sets alpha value to 1 for all views/subview
            //The following won't be called if 'subviews' is empty (ending recursion @ deepest nest):
            subview.alpha = 1
            resetAlphaForAllSubviews(ofView: subview)
        }
    }
    
    func getDrawingLayerForView(viewAtCenter: UIView) { //generates circle around a view
        let viewRect = viewAtCenter.frame
        let viewSuperview = viewAtCenter.superview
        let transformedRect = view.convertRect(viewRect, fromView: viewSuperview)
        if (currentDrawingLayer1 == nil) { //fill in 1st layer if it isn't drawn
            currentDrawingLayer1 = TutorialCircleLayer()
            currentDrawingLayer1!.contentsScale = UIScreen.mainScreen().scale
            self.view.layer.addSublayer(currentDrawingLayer1!)
            currentDrawingLayer1!.frame = getDrawingRectangleForFrame(transformedRect)
            currentDrawingLayer1!.setNeedsDisplay() //update visuals (calls layer's drawInContext method)
        } else { //1st layer was already drawn, fill in 2nd layer
            currentDrawingLayer2 = TutorialCircleLayer()
            currentDrawingLayer2!.contentsScale = UIScreen.mainScreen().scale
            self.view.layer.addSublayer(currentDrawingLayer2!)
            currentDrawingLayer2!.frame = getDrawingRectangleForFrame(transformedRect)
            currentDrawingLayer2!.setNeedsDisplay() //update visuals (calls layer's drawInContext method)
        }
    }
    
    func getDrawingRectangleForFrame(frame: CGRect) -> CGRect {
        //Takes in a view & generates the drawing frame for the tutorial layer. This needs to be OUTSIDE of the layer class b/c we can't generate the frame within the class & then update the frame in the same function b/c it won't get redrawn (& in order to redraw, we would need to call that same function again, which would again change the frame, causing a cycle).
        let objectHeight = frame.height
        let objectWidth = frame.width
        let objectX = frame.origin.x
        let objectY = frame.origin.y
        let objectCenter = CGPoint(x: (objectX + objectWidth/2), y: (objectY + objectHeight/2)) //find the centerPoint for the object to draw our frame around
        let frameOffset = CGFloat(16)
        let frameSize = CGSize(width: objectWidth + frameOffset, height: objectHeight + frameOffset)
        let centeredFrame = createRectAroundCenter(objectCenter, size: frameSize) //layer's frame
        return centeredFrame
    }
    
    func getTextLayerForDrawingLayer(text: String, drawingLayer: TutorialCircleLayer) { //renders txtLayer near the circle it is annotating
        currentTextLayer = CATextLayer()
        currentTextLayer!.string = text
        //currentTextLayer!.borderWidth = 1
        let fontName: CFStringRef = "Noteworthy-Light"
        currentTextLayer!.foregroundColor = UIColor.blueColor().CGColor
        currentTextLayer!.wrapped = true
        currentTextLayer!.alignmentMode = kCAAlignmentLeft
        currentTextLayer!.contentsScale = UIScreen.mainScreen().scale
        currentTextLayer!.font = CTFontCreateWithName(fontName, 4, nil)
        currentTextLayer!.fontSize = 16
        self.view.layer.addSublayer(currentTextLayer!)
        
        //Draw textLayer in relation to the drawingLayer:
        let drawingLayerX = drawingLayer.frame.origin.x
        let drawingLayerY = drawingLayer.frame.origin.y
        let drawingLayerWidth = drawingLayer.frame.width
        let drawingLayerHeight = drawingLayer.frame.height
        var textLayerWidth = CGFloat()
        var textLayerHeight = CGFloat()
        var textLayerOriginX = CGFloat()
        var textLayerOriginY = CGFloat()
        if (screenNumber == 1) { //TV btns screen
            textLayerWidth = 158
            textLayerHeight = 115
            textLayerOriginX = drawingLayerX + drawingLayerWidth - textLayerWidth - 5
            textLayerOriginY = drawingLayerY + drawingLayerHeight + 10
        } else if (screenNumber == 2) { //addAction btn screen
            let viewTopMid = getPointForCorner(drawingLayer, corner: Corners.TopMiddle)
            textLayerWidth = 140
            textLayerHeight = 110
            textLayerOriginX = viewTopMid.x + 10
            textLayerOriginY = viewTopMid.y - textLayerHeight - 35
        } else if (screenNumber == 3) {
            textLayerWidth = 140
            textLayerHeight = 185
            textLayerOriginX = drawingLayerX + drawingLayerWidth - textLayerWidth - 10
            textLayerOriginY = drawingLayerY + drawingLayerHeight - textLayerHeight
        } else if (screenNumber == 4) {
            textLayerWidth = 140
            textLayerHeight = 90
            textLayerOriginX = drawingLayerX + drawingLayerWidth - textLayerWidth - 10
            textLayerOriginY = drawingLayerY + drawingLayerHeight + 10
        } else if (screenNumber == 5) {
            textLayerWidth = 140
            textLayerHeight = 130
            textLayerOriginX = drawingLayerX + drawingLayerWidth - textLayerWidth - 10
            textLayerOriginY = drawingLayerY + drawingLayerHeight + 3
        }
        currentTextLayer!.frame = CGRect(x: textLayerOriginX, y: textLayerOriginY, width: textLayerWidth, height: textLayerHeight) //set relative to circleLayer's frame depending on the object
        currentTextLayer!.setNeedsDisplay() //update visuals
    }
    
    func drawLineBetweenTextAndCircle(textLayer: CATextLayer, textLayerCorner: Corners, drawingLayer: TutorialCircleLayer, drawingLayerCorner: Corners) { //connects txtLyr & circleLyr
        let fromPoint = getPointForCorner(textLayer, corner: textLayerCorner)
        let toPoint = getPointForCorner(drawingLayer, corner: drawingLayerCorner)
        if (currentLineLayer1 == nil) { //first line is NOT set
            currentLineLayer1 = LineLayer(viewToDrawIn: self.view, fromPoint: fromPoint, toPoint: toPoint)
            currentLineLayer1!.lineColor = UIColor.greenColor().CGColor
            self.view.layer.addSublayer(currentLineLayer1!)
            currentLineLayer1!.setNeedsDisplay()
        } else { //1st line is set, draw in 2nd object
            currentLineLayer2 = LineLayer(viewToDrawIn: self.view, fromPoint: fromPoint, toPoint: toPoint)
            currentLineLayer2!.lineColor = UIColor.greenColor().CGColor
            self.view.layer.addSublayer(currentLineLayer2!)
            currentLineLayer2!.setNeedsDisplay()
        }
    }
    
    // MARK: - Button Actions
    
    func hideTutorialDescriptionView() {
        for subview in tutorialDescriptionView.subviews { //clear tutorialView from VC
            let constraints = subview.constraints
            subview.removeConstraints(constraints)
            subview.hidden = true
            subview.removeFromSuperview()
        }
        tutorialViewHeight.constant = 0 //hide view AFTER constraints are removed
        
        self.view.layoutSubviews() //updates the frames after tutorialView is hidden
        outcomeVariablesView.layoutSubviews() //update subview frames after resizing
        inputVariablesView.layoutSubviews() //update subview frames after resizing
    }
    
    @IBAction func closeTutorialViewButtonClick(sender: AnyObject) { //hides tutorialView
        hideTutorialDescriptionView()
        setVisualsForTutorialDescription(tutorialViewIsShowing: false)
        userDefaults.setBool(true, forKey: "SHOW_VARS_TUTORIAL") //set 'showVars' key -> false to block VC
    }
    
    @IBAction func addActionButtonClick(sender: AnyObject) { //reveal actionPicker & set to first value
        if (tutorialIsOn) { //special behavior when tutorial is present
            closeTutorialScreenNumber(2) //transition -> screen 3
        } else { //normal behavior
            actionPicker.selectRow(0, inComponent: 0, animated: false)
            shouldShowPickerView(showPicker: true, actionName: nil)
        }
    }
    
    @IBAction func inputVariablesAddButtonClick(sender: AnyObject) {
        if (tutorialIsOn) { //special tutorial behavior - remove previous layers & draw part 2
            if (screenNumber == 1) { //only works on first screen
                closeTutorialScreenNumber(1)
            }
        } else { //normal behavior
            addVariable(inputVariablesTV) //transition to second tutorial screen
        }
    }
    
    @IBAction func outcomeVariablesAddButtonClick(sender: AnyObject) {
        if (tutorialIsOn) { //special tutorial behavior
            if (screenNumber == 1) { //only works on first screen
                closeTutorialScreenNumber(1) //transition to second tutorial screen
            }
        } else { //normal behavior
            addVariable(outcomeVariablesTV)
        }
    }
    
    var showDescription: Bool = false //indicates whether to show descriptionView in attachModuleVC
    
    func addVariable(sender: UITableView) {
        tableViewForVariableAddition = sender //clear this after the variable is added
        let alert = UIAlertController(title: "New Variable", message: "Type the name of the variable you wish to add. Two variables should not have the same name.", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (let field) -> Void in
            field.autocapitalizationType = .Words //auto-capitalize words
        }
        let cancel = UIAlertAction(title: "Cancel", style: .Default) { (let cancel) -> Void in }
        let done = UIAlertAction(title: "Add", style: .Default) { (let ok) -> Void in
            let input = alert.textFields?.first?.text
            if (input != "") {
                var error: Bool = false
                for variable in self.inputVariableRows { //make sure name is unique
                    if (input?.lowercaseString == variable.variableName.lowercaseString) {
                        print("Error. Duplicate Name.")
                        error = true
                        break
                    }
                }
                for variable in self.outcomeVariableRows { //make sure name is unique
                    if (input?.lowercaseString == variable.variableName.lowercaseString) {
                        print("Error. Duplicate Name.")
                        error = true
                        break
                    }
                }
                if !(error) { //make sure the variable is not a duplicate
                    self.variableName = input?.capitalizedString
                    if let show = self.userDefaults.valueForKey("SHOW_ATTACH_DESCRIPTION") as? Bool { //check for description show key
                        if (show) { //key is set to true, show description
                            self.showDescription = true
                        }
                    } else { //key is not set (1st time going to view), show description
                        self.showDescription = true
                    }
                    self.performSegueWithIdentifier("showAttachModule", sender: nil)
                }
            }
        }
        alert.addAction(cancel)
        alert.addAction(done)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func doneButtonClick(sender: AnyObject) {
        performSegueWithIdentifier("showSummary", sender: nil)
    }

    // MARK: - Navigation
    
    @IBAction func unwindToVariablesVC(sender: UIStoryboardSegue) { //unwind segue -> variable VC
        //Note: requires the '@IBAction' in the beginning to enable the click & drag from a button to the VC's 'Exit' button on the top-most bar.
        if let configureModuleVC = sender.sourceViewController as? ConfigureModuleViewController {
            //If sender is configureModuleVC, grab the input/outcome selection & module information:
            createdVariable = configureModuleVC.createdVariable
            if (tableViewForVariableAddition == inputVariablesTV) {
                inputVariableRows.append(createdVariable!)
                inputVariablesTV.reloadData()
            } else if (tableViewForVariableAddition == outcomeVariablesTV) {
                outcomeVariableRows.append(createdVariable!)
                outcomeVariablesTV.reloadData()
            }
        }
        if let configOptionsVC = sender.sourceViewController as? ConfigurationOptionsViewController {
            //If sender is configOptionsVC, grab the input/outcome selection & module information:
            createdVariable = configOptionsVC.createdVariable
            if (tableViewForVariableAddition == inputVariablesTV) {
                inputVariableRows.append(createdVariable!)
                inputVariablesTV.reloadData()
            } else if (tableViewForVariableAddition == outcomeVariablesTV) {
                outcomeVariableRows.append(createdVariable!)
                outcomeVariablesTV.reloadData()
            }
        }
        if (inputVariableRows.count > 0) && (outcomeVariableRows.count > 0) && (selectedAction != nil) { //enable button when 1 of each var is added & action is set, disable if a variable is deleted or moved & there is no longer 1 of each
            doneButton.enabled = true
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSummary") {
            let destination = segue.destinationViewController as! ProjectSummaryViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectEndpoint = self.projectEndpoint
            destination.projectAction = self.selectedAction
            destination.inputVariables = self.inputVariableRows
            destination.outcomeVariables = self.outcomeVariableRows
        } else if (segue.identifier == "showAttachModule") { //send name of new variable
            let destination = segue.destinationViewController as! UINavigationController
            let attachModuleVC = destination.topViewController as! AttachModuleViewController
            attachModuleVC.variableName = self.variableName
            attachModuleVC.showDescriptionView = showDescription
        }
    }

}
