//  CustomTextView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 1/22/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// TextView with placeholder functionality

import UIKit

class CustomTextView: UITextView {
    
    private var placeholderLabel = UILabel(frame: CGRectZero) //label showing placeholder (do this instead of modifying existing text!!!)
    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            
            let inset = CGFloat(3)
            let labelFrame = CGRect(x: inset, y: 0, width: (frame.width - inset), height: frame.height)
            placeholderLabel.frame = labelFrame
            placeholderLabel.numberOfLines = 0 //unlimited # of lines, required for sizeToFit() to work
            placeholderLabel.sizeToFit() //resizes bounds to fit around text (prevents vertical centering)
            
            if let fontSize = self.font?.pointSize { //fontSize for placeholder = 2 less than txtView
                let placeholderFontSize = fontSize - 2
                placeholderLabel.font = UIFont.systemFontOfSize(placeholderFontSize)
            }
            if (self.text == "") { //check if there is any text currently
                placeholderLabel.hidden = false
            } else { //hide if there is txt in view
                placeholderLabel.hidden = true
            }
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configurePlaceholderLabel()
    }
    
    required init?(coder aDecoder: NSCoder) { //super.init() must be set if you are creating view from IB
        super.init(coder: aDecoder)
        configurePlaceholderLabel()
    }
    
    private func configurePlaceholderLabel() {
        //(1) Configure placeholder:
        placeholderLabel.lineBreakMode = .ByWordWrapping
        placeholderLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.50)
        self.addSubview(placeholderLabel)
        
        //(2) Add textView notifications to indicate editing is occurring:
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CustomTextView.textViewStartedEditing(_:)), name: UITextViewTextDidBeginEditingNotification, object: self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CustomTextView.textViewStoppedEditing(_:)), name: UITextViewTextDidEndEditingNotification, object: self)
    }
    
    deinit { //unregister the notifications to this class
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Delegate Methods
    
    func textViewStartedEditing(notification: NSNotification) {
        if (placeholder != nil) { //check if there is a placeholder
            placeholderLabel.hidden = true
        }
    }
    
    func textViewStoppedEditing(notification: NSNotification) {
        if (placeholder != nil) { //check if there is a placeholder set
            if (self.text == "") { //textView is empty, show placeholder
                placeholderLabel.hidden = false
            }
        }
    }
    
}
