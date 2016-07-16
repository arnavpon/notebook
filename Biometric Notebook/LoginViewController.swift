//  LoginViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/21/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles login logic

import UIKit

protocol LoginViewControllerDelegate {
    var loggedIn: Bool {get set}
    var userJustLoggedIn: Bool {get set}
    func didLoginSuccessfully(email: String) //store account email in defaults
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityIndicatorLabel: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var emailCompletionIndicator: UIImageView! //checkbox
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var passwordErrorLabel: UILabel!
    @IBOutlet weak var passwordCompletionIndicator: UIImageView! //checkbox
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    var passwordIsComplete: Bool = false { //adjusts views based on completion status
        didSet {
            dispatch_async(dispatch_get_main_queue()) { 
                if (self.passwordIsComplete) { //reveal completion indicator
                    self.passwordCompletionIndicator.hidden = false
                } else { //remove completion indicator
                    self.passwordCompletionIndicator.hidden = true
                }
                self.adjustButtonsForStatusChange()
            }
        }
    }
    var emailIsComplete: Bool = false { //adjusts views based on completion status
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                if (self.emailIsComplete) { //reveal completion indicator
                    self.emailCompletionIndicator.hidden = false
                } else { //remove completion indicator
                    self.emailCompletionIndicator.hidden = true
                }
                self.adjustButtonsForStatusChange()
            }
        }
    }
    var delegate: LoginViewControllerDelegate? //delegate stored property
    
    // MARK: - View Configuration
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configure VC:
        activityIndicator.hidesWhenStopped = true
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        //Register for error message notifications:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.serviceDidReportError(_:)), name: BMN_Notification_DataReportingErrorProtocol_ServiceDidReportError, object: nil) //errors
    }
    
    override func viewDidAppear(animated: Bool) {
        //***Temp (until IP issue is resolved) -
        if (NSUserDefaults.standardUserDefaults().valueForKey(IP_VALUE) == nil) {
            let alert = UIAlertController(title: "IP Addr", message: "Enter current IP end value", preferredStyle: UIAlertControllerStyle.Alert)
            let ok = UIAlertAction(title: "Enter", style: .Default, handler: { (let action) in
                if let text = alert.textFields?.first?.text {
                    if !(text.isEmpty) {
                        if let num = Int(text) {
                            NSUserDefaults.standardUserDefaults().setInteger(num, forKey: IP_VALUE)
                        }
                    }
                }
            })
            alert.addTextFieldWithConfigurationHandler({ (let textField) in
                textField.keyboardType = .NumberPad
            })
            alert.addAction(ok)
            self.presentViewController(alert, animated: false, completion: nil)
        }
        //***
    }
    
    override func viewWillDisappear(animated: Bool) { //clear notification observer
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func serviceDidReportError(notification: NSNotification) {
        print("[LoginVC serviceDidReportError] Firing...")
        if let info = notification.userInfo, service = info[BMN_DataReportingErrorProtocol_ServiceTypeKey] as? String, erroredService = ServiceTypes(rawValue: service) {
            if (erroredService == ServiceTypes.Internet) { //throw an error
                let message = "Could not obtain an internet connection. Please check your internet connection and then retry."
                let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert.addAction(ok)
                dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                    self.presentViewController(alert, animated: false, completion: nil)
                })
            } else if (erroredService == ServiceTypes.Localhost) { //***TEMPORARY error - must be deleted after DB is housed on website!
                let message = "**Could not access the server on localhost. Make sure server is running.**"
                let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .Alert)
                let ok = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
                alert.addAction(ok)
                dispatch_async(dispatch_get_main_queue(), { //*present alert on main thread*
                    self.presentViewController(alert, animated: false, completion: nil)
                })
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true) //dismiss keyboard on tap
    }
    
    // MARK: - TextField Delegate
    
    var beganEditing: Bool = false //indicator var
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if (textField == passwordTextField) {
            beganEditing = true //set indicator that TF has just begun editing
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if let currentText = textField.text {
            let finalString = (currentText as NSString).stringByReplacingCharactersInRange(range, withString: string)
            let strippedString = finalString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if (textField == emailTextField) { //check entry to ensure it is properly formatted
                let formatIsCorrect = LoginHandler.checkEmailFormat(strippedString)
                if (formatIsCorrect) { //proper format
                    emailIsComplete = true
                } else { //improper format
                    emailIsComplete = false
                }
            } else if (textField == passwordTextField) { //make sure password is not blank
                if (strippedString.characters.count > 0) {
                    passwordIsComplete = true
                } else {
                    passwordIsComplete = false
                }
                
                if (beganEditing) && (range.length == 1) { //check for clear signal
                    passwordIsComplete = false //indicate that pwd cell is incomplete
                }
                beganEditing = false //reset indicator
            }
        }
        displayEmailError(nil) //reset error lbls when characters are entered
        displayPasswordError(nil) //reset
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (loginButton.enabled) { //loginBtn is enabled - check username & pwd
            self.view.endEditing(true)
            loginButtonClick(true)
        } else { //NOT enabled - dismiss keyboard only
            self.view.endEditing(true)
        }
        return true
    }
    
    func adjustButtonsForStatusChange() {
        if (passwordIsComplete) && (emailIsComplete) { //enable login
            loginButton.enabled = true
            createAccountButton.enabled = true
        } else { //disable login
            loginButton.enabled = false
            createAccountButton.enabled = false
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func loginButtonClick(sender: AnyObject) {
        updateActivityIndicatorVisuals("Authenticating user...")
        if let emailRaw = emailTextField.text, passwordRaw = passwordTextField.text {
            let email = emailRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let password = passwordRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let loginHandler = LoginHandler(email: email, password: password, type: .Login)
            loginHandler.authenticateUser({ (success, failureType) in
                if (success) { //successful login
                    dispatch_async(dispatch_get_main_queue(), { //*update delegate on main thread*
                        self.view.endEditing(true) //*dismiss keyboard*
                        self.delegate?.userJustLoggedIn = true
                        self.delegate?.didLoginSuccessfully(email)
                    })
                } else { //failed login - check error type
                    self.updateActivityIndicatorVisuals(nil) //stop AI
                    if let type = failureType {
                        switch type {
                        case .UnknownEmail:
                            self.displayEmailError("unknown email")
                            self.emailIsComplete = false
                        case .IncorrectPassword:
                            self.displayPasswordError("incorrect password")
                            self.passwordIsComplete = false
                        default:
                            break
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func createAccountButtonClick(sender: AnyObject) { //**need a CONFIRM PWD textField
        updateActivityIndicatorVisuals("Creating new experimenter...")
        if let emailRaw = emailTextField.text, passwordRaw = passwordTextField.text {
            let email = emailRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let password = passwordRaw.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            let loginHandler = LoginHandler(email: email, password: password, type: .CreateUser)
            loginHandler.createNewUser({ (success, failureType) in
                if (success) { //successful login
                    self.view.endEditing(true)
                    self.delegate?.userJustLoggedIn = true
                    self.delegate?.didLoginSuccessfully(email)
                } else { //failed user creation - check error type
                    self.updateActivityIndicatorVisuals(nil) //stop AI
                    if let type = failureType {
                        switch type {
                        case .DuplicateEmail:
                            self.displayEmailError("email already exists")
                            self.emailIsComplete = false
                        default:
                            break
                        }
                    }
                }
            })
        }
    }
    
    @IBAction func forgotPasswordButtonClick(sender: AnyObject) {
        //handle resetting password
    }
    
    private func displayEmailError(message: String?) {
        dispatch_async(dispatch_get_main_queue()) { 
            if let msg = message {
                self.emailErrorLabel.text = msg
                self.emailErrorLabel.hidden = false
            } else { //hide label
                self.emailErrorLabel.hidden = true
            }
        }
    }
    
    private func displayPasswordError(message: String?) {
        dispatch_async(dispatch_get_main_queue()) {
            if let msg = message { //reveal label
                self.passwordErrorLabel.text = msg
                self.passwordErrorLabel.hidden = false
                self.passwordTextField.text = "" //clear TF
            } else { //hide label
                self.passwordErrorLabel.hidden = true
            }
        }
    }
    
    private func updateActivityIndicatorVisuals(message: String?) { //shows/hides AI & its label
        dispatch_async(dispatch_get_main_queue()) {
            if let msg = message { //msg exists - start animation/reveal lbl
                self.activityIndicator.startAnimating()
                self.activityIndicatorLabel.text = msg
                self.activityIndicatorLabel.hidden = false
                
                //Disable button presses while AI is active:
                self.loginButton.userInteractionEnabled = false
                self.forgotPasswordButton.userInteractionEnabled = false
                self.createAccountButton.userInteractionEnabled = false
            } else { //no msg - stop animation/hide lbl
                self.activityIndicator.stopAnimating()
                self.activityIndicatorLabel.hidden = true
                
                //Enable buttons:
                self.loginButton.userInteractionEnabled = true
                self.forgotPasswordButton.userInteractionEnabled = true
                self.createAccountButton.userInteractionEnabled = true
            }
        }
    }
    
}
