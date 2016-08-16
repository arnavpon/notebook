//  SetupVariablesViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/5/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Controls navigation between the AddAction, InputVariables, & OutcomeMeasures VCs.

import UIKit

protocol SetupVariablesProtocol {
    
    var moduleBlocker: Module_DynamicConfigurationFramework {get set} //class that handles blocking
    var ghostVariables: [String: [GhostVariable]]? {get set} //KEY = parent computation, value = [Ghosts]
    
}

class SetupVariablesViewController: UITabBarController, UITabBarControllerDelegate {
    
    var doneButton: UIBarButtonItem? //segues -> SummaryVC
    
    var isCCProject: Bool = false //indicator for CC project
    var isEditProjectFlow: Bool = false //indicator for edit project flow
    var projectToEdit: Project? //for edit project flow
    var moduleBlocker: Module_DynamicConfigurationFramework? //ONLY set in edit project flow
    
    var projectTitle: String? //title (obtained from CreateProjectVC)
    var projectQuestion: String? //question for investigation (obtained from CreateProjectVC)
    var projectHypothesis: String? //hypothesis for project (obtained from CreateProjectVC)
    var projectEndpoint: Endpoint? //endpoint (obtained from CreateProjectVC)
    var projectType: ExperimentTypes? //type of project (IO vs. CC)
    var projectGroups: [(String, GroupTypes)]? //list of project group names (=1 for IO project)
    
    var projectAction: Action? { //update doneBtn whenever action is set
        didSet {
            configureDoneButton()
            if let item = self.tabBar.items?.first {
                if let _ = projectAction { //update tabBar item for configuration
                    item.badgeValue = nil //clear badge
                } else { //nil - update tabBar item
                    item.badgeValue = "?"
                }
            }
        }
    }
    var actionQualifiers: [Module]? //variables attached to action
    var inputVariables: [Module]?
    var outcomeMeasures: [Module]? { //update doneBtn when OM are set
        didSet {
            configureDoneButton()
            if let item = self.tabBar.items?.last {
                if let outcomes = outcomeMeasures { //update tabBar item
                    if !(outcomes.isEmpty) { //OM are set
                        item.badgeValue = nil //clear badge
                    } else { //NOT set
                        item.badgeValue = "?" //reset badge
                    }
                } else { //nil - update tabBar item
                    item.badgeValue = "?" //reset badge
                }
            }
        }
    }
    var ghostVariables: [String: [GhostVariable]]? //KEY = parent computation, value = [Ghost]
    
    // MARK: - View Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self //set the tabBarController's delegate to self
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: #selector(self.doneButtonClick(_:))) //set doneBtn @ top right
        doneButton!.enabled = false //disable button to start
        self.navigationItem.rightBarButtonItem = doneButton
        let backButton = UIBarButtonItem(title: "< Back", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.backButtonClick(_:)))
        self.navigationItem.leftBarButtonItem = backButton
        
        if (isCCProject) { //hide tabBar to prevent horizontal navigation in CC project
            self.tabBar.hidden = true
        } else { //IO project
            if let items = self.tabBar.items { //set tabBar items
                let addActionItem = items[0]
                let addVarsItem = items[1]
                
                tabBar.tintColor = UIColor.redColor() //adjusts the title txtColor for the item
                addActionItem.title = "Action"
                addActionItem.badgeValue = "?" //incompletion indicator
                addVarsItem.title = "Variables"
                addVarsItem.badgeValue = "?" //incompletion indicator
            }
        }
        
        if (isEditProjectFlow) { //match the existing variables to their appropriate VCs
            if let controllers = self.viewControllers, blocker = self.moduleBlocker {
                for viewController in controllers {
                    switch viewController {
                    case is AddActionViewController: //set action, qualifiers, & moduleBlocker
                        let addActionVC = (viewController as! AddActionViewController)
                        addActionVC.projectAction = self.projectAction
                        addActionVC.actionQualifiers = actionQualifiers
                        addActionVC.moduleBlocker = blocker
                        addActionVC.isEditProjectFlow = true //set indicator
                    case is AddVariablesViewController: //set variables
                        let addVariablesVC = (viewController as! AddVariablesViewController)
                        addVariablesVC.inputVariables = self.inputVariables
                        addVariablesVC.outcomeMeasures = self.outcomeMeasures
                        addVariablesVC.moduleBlocker = blocker
                        addVariablesVC.isEditProjectFlow = true //set indicator
                    default:
                        break
                    }
                }
            }
        }
    }

    private func configureDoneButton() { //enables/disables doneBtn
        dispatch_async(dispatch_get_main_queue()) {
            if let outcomes = self.outcomeMeasures, _ = self.projectAction { //must have action & outcomes
                if !(outcomes.isEmpty) {
                    self.doneButton?.enabled = true
                    return //break fx execution
                }
            }
            self.doneButton?.enabled = false //INCOMPLETE -> disable
        }
    }
    
    // MARK: - Transition Logic
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool { //function called BEFORE the transition takes place
        if !(isCCProject) { //IO project - allow free navigation between setup flows
            if let currentVC = tabBarController.selectedViewController as? SetupVariablesProtocol {
                var selectedVC = viewController as! SetupVariablesProtocol
                selectedVC.moduleBlocker = currentVC.moduleBlocker //pass blocker btwn VCs
                selectedVC.ghostVariables = self.ghostVariables //pass ghosts from self
            }
            return true
        }
        return false //block transitions for CC projects (show ONLY OMVC)
    }
    
    // MARK: - Button Actions
    
    @IBAction func doneButtonClick(sender: AnyObject?) { //segue -> SummaryVC
        performSegueWithIdentifier("showSummary", sender: nil)
    }
    
    @IBAction func backButtonClick(sender: AnyObject) {
        if !(isEditProjectFlow) { //default - return to CreateProjectVC
            performSegueWithIdentifier("unwindToCreateProject", sender: nil)
        } else { //EDIT PROJECT flow - dismiss VC & return -> ActiveProjects
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateInitialViewController()!
            presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showSummary") { //pass data in tabBarController -> SummaryVC
            let destination = segue.destinationViewController as! ProjectSummaryViewController
            destination.projectTitle = self.projectTitle
            destination.projectQuestion = self.projectQuestion
            destination.projectHypothesis = self.projectHypothesis
            destination.projectEndpoint = self.projectEndpoint
            destination.projectType = self.projectType
            destination.projectGroups = self.projectGroups
            destination.projectAction = self.projectAction
            destination.actionQualifiers = self.actionQualifiers
            destination.inputVariables = self.inputVariables
            destination.outcomeMeasures = self.outcomeMeasures
            destination.ghostVariables = self.ghostVariables
            destination.projectToEdit = self.projectToEdit
        }
    }

}