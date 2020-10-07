//
//  GeneralPreferencesViewController.swift
//  FontPanelSample
//
//  Created by HIROKI IKEUCHI on 2020/01/24.
//  Copyright © 2020年 hikeuchi. All rights reserved.
//

import Cocoa

let generalPreferencesChangedNotificationIdentifier = "GeneralPreferencesChanged"

class GeneralPreferencesViewController: NSViewController {

    // MARK: - Properties
    
    @IBOutlet weak var overlayCheckBox: NSButton!
    @IBOutlet weak var showingTitleBarCheckBox: NSButton!
    @IBOutlet weak var languagePopup: NSPopUpButton!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Helpers
    
    public func postGeneralPreferencesChangedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: generalPreferencesChangedNotificationIdentifier), object: nil)
    }
    
    private func configureUI() {
        overlayCheckBox.state = GeneralPreferences.shared.isOverlay
        showingTitleBarCheckBox.state = GeneralPreferences.shared.showingTitleBar
        
        for popupIndex in 0..<languagePopup.numberOfItems {
            let item = languagePopup.item(at: popupIndex)
            if let identifier = item?.identifier,
               identifier.rawValue == GeneralPreferences.shared.language {
                languagePopup.selectItem(at: popupIndex)
                break
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func overlayStatusChanged(_ sender: Any) {
        guard let checkBox = sender as? NSButton else {
            return
        }

        GeneralPreferences.shared.isOverlay = checkBox.state
        postGeneralPreferencesChangedNotification()
        configureUI()
    }
    
    @IBAction func showingTitleBarStateChanged(_ sender: Any) {
        guard let checkBox = sender as? NSButton else {
            return
        }
        
        GeneralPreferences.shared.showingTitleBar = checkBox.state
        postGeneralPreferencesChangedNotification()
        configureUI()
    }
    
    @IBAction func languageChanged(_ sender: NSPopUpButton) {
        guard let language = sender.selectedItem?.identifier?.rawValue else { return }
        GeneralPreferences.shared.language = language
        postGeneralPreferencesChangedNotification()
        configureUI()
    }
}

