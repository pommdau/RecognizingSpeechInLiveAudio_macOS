//
//  GeneralPreferences.swift
//  FontPanelSample
//
//  Created by HIROKI IKEUCHI on 2020/01/24.
//  Copyright © 2020年 hikeuchi. All rights reserved.
//

import Foundation
import Cocoa

class GeneralPreferences {
    enum UserDefaultsKey: String {
        case GEP_IsOverlay
        case GEP_showingTitleBar
        case GEP_WindowFrame
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKey.GEP_IsOverlay.rawValue : false,
            UserDefaultsKey.GEP_showingTitleBar.rawValue : true
        ])
    }
    
    // For Debug
    private func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.GEP_IsOverlay.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.GEP_showingTitleBar.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.GEP_WindowFrame.rawValue)
    }
    
    var isOverlay: NSControl.StateValue {
        get {
            return NSControl.StateValue(UserDefaults.standard.integer(forKey: UserDefaultsKey.GEP_IsOverlay.rawValue))
        }
        
        set(isOverlay) {
            UserDefaults.standard.set(isOverlay, forKey: UserDefaultsKey.GEP_IsOverlay.rawValue)
        }
    }
    
    var showingTitleBar: NSControl.StateValue {
        get {
            return NSControl.StateValue(UserDefaults.standard.integer(forKey: UserDefaultsKey.GEP_showingTitleBar.rawValue))
        }
        
        set(isFullScreen) {
            UserDefaults.standard.set(isFullScreen, forKey: UserDefaultsKey.GEP_showingTitleBar.rawValue)
        }
    }
    
    /// Windowの位置と大きさを保存する（SplitViewの表示の際のためのもの）
    var windowFrame: NSRect {
        get {
            guard let windowFrameString = UserDefaults.standard.string(forKey: UserDefaultsKey.GEP_WindowFrame.rawValue) else {
               return NSRect(x: 450, y: 200, width: 1000, height: 750)
            }
            let windowFrame = NSRectFromString(windowFrameString)
            return windowFrame
        }
        
        set (windowFrame) {
            UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: UserDefaultsKey.GEP_WindowFrame.rawValue)
        }
    }
}
