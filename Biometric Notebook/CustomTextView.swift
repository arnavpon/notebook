//  CustomTextView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// TextView with placeholder functionality

import UIKit

class CustomTextView: UITextView {
    
    let notificationCenter = NSNotificationCenter.defaultCenter()
    private var placeholderLabel: LabelWithPadding? //label showing placeholder (we do this instead of modifying the existing text b/c it avoids changing the defined config)
    var placeholder: String? {
        didSet {
            if (placeholder != nil) { //add the placeholder (default setting)
                let insets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
                print(self.frame.width, self.frame.height)
                let labelFrame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
                placeholderLabel = LabelWithPadding(frame: labelFrame, inset: insets)
                placeholderLabel?.text = placeholder
                placeholderLabel?.lineBreakMode = .ByWordWrapping
                placeholderLabel?.numberOfLines = 2
                placeholderLabel?.sizeToFit() //resizes bounds to fit around text
                placeholderLabel?.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.50)
                if let fontName = self.font?.fontName, let fontSize = self.font?.pointSize {
                    let placeholderFontSize = fontSize - 2
                    placeholderLabel?.font = UIFont(name: fontName, size: placeholderFontSize)
                }
                self.addSubview(placeholderLabel!)
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) { //super.init() must be set if you are creating view from IB
        super.init(coder: aDecoder)
        notificationCenter.addObserver(self, selector: "textViewStartedEditing:", name: UITextViewTextDidBeginEditingNotification, object: self)
        notificationCenter.addObserver(self, selector: "textViewStoppedEditing:", name: UITextViewTextDidEndEditingNotification, object: self)
    }
    
    deinit { //unregister the notifications to this class
        notificationCenter.removeObserver(self)
    }
    
    func textViewStartedEditing(notification: NSNotification) {
        if (placeholder != nil) { //check if there is a placeholder
            placeholderLabel?.hidden = true
        }
    }
    
    func textViewStoppedEditing(notification: NSNotification) {
        if (placeholder != nil) { //check if there is a placeholder set
            if (self.text == "") { //textView is empty, show placeholder
                placeholderLabel?.hidden = false
            }
        }
    }
    
}
