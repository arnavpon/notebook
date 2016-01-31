//  ProjectVariablesViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/21/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Page to create & display input variables, project action (e.g. sleep, eat, exercise) between the IV & OV, and outcome variables.

import UIKit

class ProjectVariablesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var inputVariablesView: UIView!
    @IBOutlet weak var inputVariablesTV: UITableView!
    @IBOutlet weak var addActionButton: UIButton!
    @IBOutlet weak var outcomeVariablesView: UIView!
    @IBOutlet weak var outcomeVariablesTV: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var actionPicker: UIPickerView!
    
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
    
    override func viewWillAppear(animated: Bool) { //round the view (& button) edges:
        inputVariablesView.layer.borderColor = inputVariablesView.backgroundColor?.CGColor
        inputVariablesView.layer.borderWidth = viewBorderWidth
        inputVariablesView.layer.cornerRadius = viewCornerRadius
        outcomeVariablesView.layer.borderColor = outcomeVariablesView.backgroundColor?.CGColor
        outcomeVariablesView.layer.borderWidth = viewBorderWidth
        outcomeVariablesView.layer.cornerRadius = viewCornerRadius
        addActionButton.layer.cornerRadius = viewCornerRadius/2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        actionPicker.dataSource = self
        actionPicker.delegate = self
        inputVariablesTV.dataSource = self
        inputVariablesTV.delegate = self
        outcomeVariablesTV.dataSource = self
        outcomeVariablesTV.delegate = self
        
        let inputLongPress = UILongPressGestureRecognizer(target: self, action: "inputLongPressRecognized:")
        inputVariablesTV.addGestureRecognizer(inputLongPress)
        let outcomeLongPress = UILongPressGestureRecognizer(target: self, action: "outcomeLongPressRecognized:")
        outcomeVariablesTV.addGestureRecognizer(outcomeLongPress)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == inputVariablesTV) { //inputs TV
            return inputVariableRows.count
        } else if (tableView == outcomeVariablesTV) { //outcomes TV
            return outcomeVariableRows.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if (tableView == inputVariablesTV) { //inputs TV
            cell = tableView.dequeueReusableCellWithIdentifier("input_cell")!
            cell.textLabel?.text = inputVariableRows[indexPath.row].variableName
            cell.detailTextLabel?.text = "\(inputVariableRows[indexPath.row].moduleTitle) Module"
        } else if (tableView == outcomeVariablesTV) { //outcomes TV
            cell = tableView.dequeueReusableCellWithIdentifier("outcome_cell")!
            cell.textLabel?.text = outcomeVariableRows[indexPath.row].variableName
            cell.detailTextLabel?.text = "\(outcomeVariableRows[indexPath.row].moduleTitle) Module"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //if user taps a cell, allow them to edit a variable's config (segue -> ConfigModuleVC)
        if (tableView == inputVariablesTV) { //inputs TV
            //
        } else if (tableView == outcomeVariablesTV) { //outcomes TV
            //
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if (interactionEnabled) {
            return true
        }
        return false
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle { //user can delete variables from TV
        if (interactionEnabled) {
            return UITableViewCellEditingStyle.Delete
        }
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
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
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        //Support movement of variables in inputTV & outcome TV:
        if (interactionEnabled) {
            return true
        }
        return false
    }
    
    // MARK: - Table View Row Movement Logic
    
    var snapshot: UIView?
    var sourceIndexPath: NSIndexPath?
    
    @IBAction func inputLongPressRecognized(longPress: UILongPressGestureRecognizer) {//called when inputsTV is longPressed
        let state = longPress.state
        let location = longPress.locationInView(inputVariablesTV)
        let indexPath = inputVariablesTV.indexPathForRowAtPoint(location) //gets the indexPath of the row that was long pressed
        handleRowMovement(state, location: location, indexPath: indexPath, tableView: inputVariablesTV, tableViewDataSource: inputVariableRows) { (let newArray) -> Void in
            self.inputVariableRows = newArray
        }
    }
    
    @IBAction func outcomeLongPressRecognized(longPress: UILongPressGestureRecognizer) { //called when outcomesTV is longPressed
        let state = longPress.state
        let location = longPress.locationInView(outcomeVariablesTV)
        let indexPath = outcomeVariablesTV.indexPathForRowAtPoint(location) //gets indxPath of touched row
        handleRowMovement(state, location: location, indexPath: indexPath, tableView: outcomeVariablesTV, tableViewDataSource: outcomeVariableRows) { (let newArray) -> Void in
            self.outcomeVariableRows = newArray
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
    
    func exchangeElements(var array: [AnyObject], fromIndex index: Int, toIndex: Int) -> [AnyObject] {
        for item in array {
            let name = (item as! CustomModule).variableName
            print("Old Array: \(name)")
        }
        var newArray = array
        let fromObject = array[index]
        let toObject = array[toIndex]
        newArray[index] = toObject
        newArray[toIndex] = fromObject
        for item in newArray {
            let name = (item as! CustomModule).variableName
            print("New Array: \(name))")
        }
        return newArray
    }
    
    func handleRowMovement(state: UIGestureRecognizerState, location: CGPoint, indexPath: NSIndexPath?, tableView: UITableView, var tableViewDataSource: [Module], completion: ([Module]) -> Void) {
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
                let newDataSource = exchangeElements(tableViewDataSource, fromIndex: (sourceIndexPath?.row)!, toIndex: (indexPath?.row)!) as! [Module] //update data source
                completion(newDataSource) //pass modified array back out
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
    
    // MARK: - Button Actions
    
    @IBAction func addActionButtonClick(sender: AnyObject) { //reveal actionPicker & set to first value
        actionPicker.selectRow(0, inComponent: 0, animated: false)
        shouldShowPickerView(showPicker: true, actionName: nil)
    }
    
    @IBAction func inputVariablesAddButtonClick(sender: AnyObject) {
        addVariable(inputVariablesTV)
    }
    
    @IBAction func outcomeVariablesAddButtonClick(sender: AnyObject) {
        addVariable(outcomeVariablesTV)
    }
    
    func addVariable(sender: UITableView) {
        tableViewForVariableAddition = sender //clear this after the variable is added
        let alert = UIAlertController(title: "New Variable", message: "Type the name of the variable you wish to add.", preferredStyle: .Alert)
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
        }
    }

}
