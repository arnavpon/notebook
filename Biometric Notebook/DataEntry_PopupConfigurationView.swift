//  DataEntry_PopupConfigurationView.swift
//  Biometric Notebook
//  Created by Arnav Pondicherry  on 8/27/16.
//  Copyright © 2016 Confluent Ideals. All rights reserved.

// Exercise & FoodIntake Module > view that handles the presentation of the configuration view which handles preliminary variable configuration prior to core data entry functionality.

import UIKit

enum DataEntry_PopupConfigurationViewTypes {
    case CollectionView //select from options presented in collectionView
    case SearchBar //search in a textField for an item from a predefined list
    case SimpleNumberEntry //textField w/ Int input
}

protocol DataEntry_PopupConfigurationViewProtocol {
    var cellType: DataEntryCellTypes { get } //indicates which type of cell is conforming to protocol
    func valueWasReturnedByUser(value: AnyObject) //receives user's input from ConfigView
    func backButtonWasClicked() //handles reverse navigation
}

class DataEntry_PopupConfigurationView: UIView {
    
    var linkedTableViewCell: DataEntry_PopupConfigurationViewProtocol? //linked cell
    override var frame: CGRect {
        didSet {
            self.setNeedsLayout() //redraw view w/ new frame
        }
    }
    var type: DataEntry_PopupConfigurationViewTypes? { //controls which views are displayed
        didSet {
            revealActiveViews() //hide/reveal appropriate views
            self.setNeedsLayout() //redraw view according to self.type
        }
    }
    var shouldDisplayBackButton: Bool = false { //indicates whether backBtn is visible
        didSet {
            self.setNeedsLayout() //redraw view when set
        }
    }
    
    //Default Properties:
    private let instructionsLabel = UILabel(frame: CGRectZero) //lbl @ the top of the view
    private let backButton = UIButton(frame: CGRectZero) //enables reverse navigation
    private let mainView = UIView(frame: CGRectZero) //contains all other views
    private let inputTextField = UITextField(frame: CGRectZero) //for search bar & simple number entry
    
    //SearchBar Properties:
    private var searchBar = UISearchBar(frame: CGRectZero) //search bar - acts as TV header
    private var searchResultsTableView = UITableView(frame: CGRectZero)
    private var tableViewDataSource: [String]? //contains FULL list of searchable values
    private var filteredResults = [String]() //populated when user types in search bar
    private var shouldShowSearchResults: Bool = false { //controls TV display of filteredResults
        didSet {
            if (shouldShowSearchResults) && !(filteredResults.isEmpty) { //reveal TV **
                searchResultsTableView.hidden = false
                return //terminate fx
            }
            searchResultsTableView.hidden = true //default is to hide TV
        }
    }
    
    //CollectionView Properties:
    private let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
    private var collectionViewDataSource: [String]? { //array holding optionBtn titles
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView.reloadData() //update UI
            }
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(instructionsLabel) //instructionsLabel is added -> self
        self.addSubview(backButton) //backBtn is added -> self
        self.addSubview(mainView) //all other views are added -> mainView
        
        //Configure instructionsLabel:
        instructionsLabel.backgroundColor = UIColor(red: 0, green: 55/255, blue: 235/255, alpha: 1)
        instructionsLabel.textColor = UIColor.whiteColor()
        instructionsLabel.textAlignment = .Center
        instructionsLabel.numberOfLines = 2
        instructionsLabel.adjustsFontSizeToFitWidth = true
        
        //Configure backButton:
        backButton.addTarget(self, action: #selector(self.backButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        backButton.setImage(UIImage(named: "left_arrow"), forState: .Normal)
        
        //Configure mainView:
        mainView.backgroundColor = UIColor.whiteColor() //set background to cover TV cell behind
        mainView.layer.borderColor = UIColor.blackColor().CGColor //set border
        mainView.layer.borderWidth = 1
        
        //Configure inputTF:
        mainView.addSubview(inputTextField)
        inputTextField.delegate = self
        inputTextField.enablesReturnKeyAutomatically = true
        inputTextField.textAlignment = .Center
        inputTextField.borderStyle = .RoundedRect
        inputTextField.hidden = true //starts out hidden
        
        //Configure collectionView:
        mainView.addSubview(collectionView)
        let layoutObject = UICollectionViewFlowLayout() //configure layout obj for collView
        layoutObject.scrollDirection = UICollectionViewScrollDirection.Horizontal
        collectionView.collectionViewLayout = layoutObject //*update collectionView layoutObj*
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.registerClass(ExM_CustomCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(ExM_CustomCollectionViewCell)) //register custom class
        collectionView.hidden = true //starts out hidden
        
        //Configure searchResultsTV:
        mainView.addSubview(searchResultsTableView)
        searchResultsTableView.delegate = self
        searchResultsTableView.dataSource = self
        searchResultsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "search_result")
        searchResultsTableView.tableHeaderView = searchBar //set searchBar as TV header
        searchResultsTableView.hidden = true //starts out hidden
        
        //Configure searchBar:
        mainView.addSubview(searchBar)
        searchBar.delegate = self
        searchBar.enablesReturnKeyAutomatically = true //allow user to hit 'Return' to search
        searchBar.showsCancelButton = false
        searchBar.barStyle = .Black
        searchBar.hidden = true //starts out hidden
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configurePopupViewWithDataSource(viewType: DataEntry_PopupConfigurationViewTypes, dataSource: [String]?, instructions: String) { //sets the viewType & dataSources
        self.instructionsLabel.text = instructions //set topLbl
        switch viewType {
        case .CollectionView: //set list of options from which to choose for collectionView
            if let collectionViewSource = dataSource {
                self.collectionViewDataSource = collectionViewSource //set dataSource
            }
        case .SearchBar: //set list of searchable options
            if let tableViewSource = dataSource {
                self.tableViewDataSource = tableViewSource //set TV dataSource
            }
        case .SimpleNumberEntry: //no sources to set
            break
        }
        self.type = viewType //set type AFTER parsing 'settings' dictionary
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        
        //(1) Draw default views:
        let labelHeight: CGFloat = 40
        var originX: CGFloat = 0 //starting X point for label
        if (shouldDisplayBackButton) { //draw frame for backButton
            let buttonWidth: CGFloat = 40
            originX = buttonWidth
            backButton.frame = CGRectMake(0, 0, buttonWidth, labelHeight) //btn is left of label
        } else { //no backButton - set frame to 0
            backButton.frame = CGRectZero
        }
        instructionsLabel.frame = CGRectMake(originX, 0, (self.frame.width - originX), labelHeight)
        mainView.frame = CGRectMake(0, labelHeight, self.frame.width, (self.frame.height - labelHeight))
        
        //(2) Draw dynamic views:
        if let viewType = self.type { //only redraw the views for the CURRENTLY SET type
            switch viewType {
            case .CollectionView:
                self.configureCollectionViewVisuals()
            case .SearchBar:
                self.configureSearchBarVisuals()
            case .SimpleNumberEntry:
                self.configureTextFieldVisuals()
            }
        }
    }
    
    private func configureTextFieldVisuals() { //configures textField
        let textFieldWidth: CGFloat = 0.70 * (mainView.frame.width) //takes up % of total width
        let textFieldHeight: CGFloat = 35
        inputTextField.frame = centerFrameInRect(CGSize(width: textFieldWidth, height: textFieldHeight), superviewFrame: mainView.frame) //center TF in mainView
        inputTextField.becomeFirstResponder() //**
    }
    
    private func configureSearchBarVisuals() { //updates visuals for searchBar functionality
        searchResultsTableView.frame = CGRectMake(0, 0, mainView.frame.width, mainView.frame.height)
        searchBar.sizeToFit() //?? formats size properly WRT tableView
        if (linkedTableViewCell?.cellType == DataEntryCellTypes.FIM_FoodIntake) {
            self.searchBar.placeholder = "Search for a food"
        } else if (linkedTableViewCell?.cellType == DataEntryCellTypes.ExM_Workout) {
            self.searchBar.placeholder = "Search for an exercise"
        }
        searchBar.becomeFirstResponder() //**
    }
    
    private func configureCollectionViewVisuals() { //updates collectionView frame
        collectionView.frame = CGRectMake(0, 0, mainView.frame.width, mainView.frame.height) //covers the entire area of 'mainView'
    }
    
    private func revealActiveViews() { //displays or hides views based on self.type
        var visibleViews: [UIView] = []
        if let viewType = self.type {
            switch viewType {
            case .CollectionView: //reveal collectionView
                visibleViews = [self.collectionView]
            case .SearchBar: //reveal searchBar & TV
                visibleViews = [self.searchResultsTableView, self.searchBar]
            case .SimpleNumberEntry: //reveal textField
                visibleViews = [self.inputTextField]
            }
        }
        for subview in self.mainView.subviews {
            subview.hidden = !(visibleViews.contains(subview)) //reveal views contained in array
        }
    }
    
    // MARK: - Button Actions
    
    @IBAction func backButtonClick(sender: UIButton) {
        if let linkedCell = self.linkedTableViewCell {
            linkedCell.backButtonWasClicked() //send btn click -> parent TV cell
        }
    }
    
    // MARK: - Data Reporting
    
    private func returnResponseToParentCell(response: AnyObject) { //sends response object -> TV cell
        if let linkedCell = self.linkedTableViewCell {
            linkedCell.valueWasReturnedByUser(response) //use protocol method
        }
    }
    
}

extension DataEntry_PopupConfigurationView: UITextFieldDelegate {
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (self.type == .SimpleNumberEntry) && (string.characters.count > 0) {
            guard let _ = Int(string) else { //make sure replacement string is a number
                return false //block entry
            }
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let viewType = self.type {
            switch viewType {
            case .SimpleNumberEntry:
                if let text = textField.text, number = Int(text) {
                    if (number > 0) { //make sure value is valid (> 0)
                        self.returnResponseToParentCell(number) //return entered value -> parent
                        return true
                    }
                }
            default: //do nothing
                break
            }
        }
        return false //default is FALSE
    }
    
}

extension DataEntry_PopupConfigurationView: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    // MARK: - Table View
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (shouldShowSearchResults) { //only return rows if TV is displaying searchResults
            return filteredResults.count
        }
        return 0 //default is not to display rows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("search_result")!
        if (shouldShowSearchResults) { //use filteredResults to populate dataArray
            cell.textLabel?.text = filteredResults[indexPath.row]
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        searchBar.text = "" //clear searchBar text
        returnResponseToParentCell(filteredResults[indexPath.row]) //return selected cell's title
        return false
    }
    
    // MARK: - Search Bar
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let trimmedText = searchText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if (trimmedText.isEmpty) { //called when the field is cleared
            if (shouldShowSearchResults) { //instruct TV to NOT show any searchResults
                shouldShowSearchResults = false //set indicator to clear TV
            }
        } else { //called when text is ENTERED - show searchResults
            shouldShowSearchResults = true //instruct TV to display searchResults
            updateTableViewForSearchResults(trimmedText) //modify TV cells based on search term
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) { //called when 'Return' is pressed
        print("Search bar search button clicked...")
        if let searchBarText = searchBar.text {
            let searchBarTrimmedText = searchBarText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if !(searchBarTrimmedText.isEmpty) { //make sure some string has been input
                if (filteredResults.count == 1) { //1 item in filteredArray - select that option
                    searchBar.text = "" //clear text
                    shouldShowSearchResults = false //set data from filtered -> complete array
                    returnResponseToParentCell(filteredResults.first!) //send back lone value in array
                } else if (filteredResults.count > 1) { //more than 1 option
                    if (filteredResults.contains(searchBarTrimmedText.capitalizedString)) { //if EXACT match is present, select that option
                        searchBar.text = "" //clear text
                        shouldShowSearchResults = false //set data from filtered -> complete array
                        returnResponseToParentCell(searchBarTrimmedText.capitalizedString)
                    } else { //return searchBar -> 1st responder
                        searchBar.becomeFirstResponder()
                    }
                }
            }
        }
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) { //called after tapping out of searchBar
        print("Search bar text did end editing!")
        if (shouldShowSearchResults) { //reset TV data & button visuals
            shouldShowSearchResults = false //set indicator
            searchResultsTableView.reloadData() //hide TV cells
        }
    }
    
    private func updateTableViewForSearchResults(searchString: String) { //modifies TV based on input txt
        if let dataSource = tableViewDataSource {
            filteredResults = dataSource.filter({ (let itemInSource) -> Bool in
                let item = itemInSource as NSString //cast each item in array -> NSString
                let result = (item.rangeOfString(searchString, options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) //== TRUE if searchString is found, FALSE if searchString is NOT found in the given 'item'
                return (result) //this code filters the dataSource elements according to what we ask from it in the closure body (in this case the 'searchString), & stores the MATCHING elements -> filteredResults. The method checks if the searched term (searchString) exists in the item, and if so it returns an NSRange. If the string we’re searching for does NOT exist in the current element, then it returns 'NSNotFound'. The closure expects a Bool value to be returned, so return the comparison result between the rangeOfString return value & the NSNotFound value.
            })
            searchResultsTableView.reloadData() //update TV w/ modified array
        }
    }
    
}

extension DataEntry_PopupConfigurationView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout { //defines collectionView conformance
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let source = collectionViewDataSource {
            return source.count //pass # of options to display
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(ExM_CustomCollectionViewCell), forIndexPath: indexPath) as! ExM_CustomCollectionViewCell
        if let source = collectionViewDataSource {
            cell.cellIndex = indexPath.row //set indicator for cell #
            cell.linkedConfigurationView = self //create linkage to self
            cell.optionButton.setTitle(source[indexPath.row], forState: .Normal)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 120, height: 60) //rectangular view
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let insetValue: CGFloat = 15 //inset the cells from the L & R edges of the container
        return UIEdgeInsets(top: 0, left: insetValue, bottom: 0, right: insetValue)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 30 //spacing between items in view
    }
    
    func optionButtonWasSelectedAtIndex(index: Int) { //handles optionBtn selection
        if let source = collectionViewDataSource {
            print("[ExM_cell] Selected Option = [\(source[index])]")
            returnResponseToParentCell(index) //return selected button
        }
    }
    
}

class ExM_CustomCollectionViewCell: UICollectionViewCell { //cell contains 1 button that takes up the entire area of the cell - on click, triggers behavior in TV cell class
    
    var optionButton = UIButton(frame: CGRectZero)
    var cellIndex: Int? //set by collectionView when dataSource is set
    var linkedConfigurationView: DataEntry_PopupConfigurationView? //linked view
    
    override var frame: CGRect {
        didSet {
            setNeedsLayout() //redraw button if frame changes
        }
    }
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //Configure optionButton:
        self.contentView.addSubview(optionButton)
        optionButton.addTarget(self, action: #selector(self.optionButtonClick(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        optionButton.titleLabel?.textAlignment = .Center
        optionButton.titleLabel?.numberOfLines = 2
        optionButton.backgroundColor = UIColor.blackColor() //**
        optionButton.setTitleColor(UIColor.whiteColor(), forState: .Normal) //**
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Visual Layout
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        optionButton.frame = CGRectMake(0, 0, self.frame.width, self.frame.height) //btn fills cell
    }
    
    // MARK: - Button Actions
    
    @IBAction func optionButtonClick(sender: AnyObject) {
        if let index = cellIndex, linkedView = linkedConfigurationView { //indicate which btn was selected
            print("[optionButtonClick()] Button @ index \(index) was pressed!")
            linkedView.optionButtonWasSelectedAtIndex(index) //pass selection -> collectionView
        }
    }
    
}