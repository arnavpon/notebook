//  LoginViewController.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/21/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Handles login logic

import UIKit

protocol LoginViewControllerDelegate {
    var loggedIn: Bool {get set}
    var userJustLoggedIn: Bool {get set}
    func didLoginSuccessfully(username: String, email: String?) //don't need to keep password in user defaults b/c it will be matched against an online DB
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    var delegate: LoginViewControllerDelegate? //delegate stored property
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configure VC:
        activityIndicator.hidesWhenStopped = true
        errorMessageLabel.text = "Oops! Incorrect username or password."
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    // MARK: - TextField Delegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        errorMessageLabel.hidden = true
        return true
    }
    
    // MARK: - Button Actions
    
    @IBAction func loginButtonClick(sender: AnyObject) {
        activityIndicator.startAnimating()
        let username = usernameTextField.text
        let password = passwordTextField.text
        if (username == "arnav") && (password == "pass") {
            delegate?.userJustLoggedIn = true
            delegate?.didLoginSuccessfully(username!, email: nil)
        } else {
            activityIndicator.stopAnimating()
            errorMessageLabel.hidden = false
            passwordTextField.text = ""
        }
    }
    
    @IBAction func forgotPasswordButtonClick(sender: AnyObject) {
        //handle resetting password
    }

    @IBAction func createAccountButtonClick(sender: AnyObject) {
        //handle creating account
    }
}
