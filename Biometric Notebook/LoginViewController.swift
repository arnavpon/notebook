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
            if (passwordIsComplete) { //reveal completion indicator
                passwordCompletionIndicator.hidden = false
            } else { //remove completion indicator
                passwordCompletionIndicator.hidden = true
            }
            adjustButtonsForStatusChange()
        }
    }
    var emailIsComplete: Bool = false { //adjusts views based on completion status
        didSet {
            if (emailIsComplete) { //reveal completion indicator
                emailCompletionIndicator.hidden = false
            } else { //remove completion indicator
                emailCompletionIndicator.hidden = true
            }
            adjustButtonsForStatusChange()
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
            }
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
            let loginHandler = LoginHandler(email: email, password: password, url: "http://192.168.1.10:8000/login")
            loginHandler.authenticateUser({ (success, failureType) in
                if (success) { //successful login
                    self.view.endEditing(true) //dismiss keyboard
                    self.delegate?.userJustLoggedIn = true
                    self.delegate?.didLoginSuccessfully(email)
                } else { //failed login - check error type
                    self.updateActivityIndicatorVisuals(nil) //stop AI
                    if let type = failureType {
                        switch type {
                        case .UnknownEmail:
                            self.displayEmailError("email was not found")
                        case .IncorrectPassword:
                            self.displayPasswordError("email and password don't match")
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
            let loginHandler = LoginHandler(email: email, password: password, url: "http://192.168.1.10:8000/create-user")
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
