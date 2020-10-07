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
    
    @IBOutlet var messageTextField: NSTextField!
    
    let generalPreferences = GeneralPreferences()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Helpers
    
    func postGeneralPreferencesChangedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: generalPreferencesChangedNotificationIdentifier), object: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func overlayStatusChanged(_ sender: Any) {
        guard let checkBox = sender as? NSButton else {
            return
        }
        generalPreferences.isOverlay = checkBox.state
        
        // Dockメニュー項目の状態を変更する
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
//        appDelegate.overlayMenuItem.state = checkBox.state
        
        postGeneralPreferencesChangedNotification()
    }
    
    @IBAction func showingTitleBarStateChanged(_ sender: Any) {
        guard let checkBox = sender as? NSButton else {
            return
        }
        generalPreferences.showingTitleBar = checkBox.state
        postGeneralPreferencesChangedNotification()
    }
}

