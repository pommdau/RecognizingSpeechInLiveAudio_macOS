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
    
    static let shared = GeneralPreferences()
    
    private enum UserDefaultsKey: String {
        case IsOverlay
        case ShowingTitleBar
        case Language
        case WindowFrame
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKey.IsOverlay.rawValue : false,
            UserDefaultsKey.ShowingTitleBar.rawValue : true,
            UserDefaultsKey.Language.rawValue : "ja-JP"
        ])
    }
    
    // For Debug
    private func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.IsOverlay.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.ShowingTitleBar.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.WindowFrame.rawValue)
    }
    
    var isOverlay: NSControl.StateValue {
        get {
            return NSControl.StateValue(UserDefaults.standard.integer(forKey: UserDefaultsKey.IsOverlay.rawValue))
        }
        
        set(isOverlay) {
            UserDefaults.standard.set(isOverlay, forKey: UserDefaultsKey.IsOverlay.rawValue)
        }
    }
    
    var showingTitleBar: NSControl.StateValue {
        get {
            return NSControl.StateValue(UserDefaults.standard.integer(forKey: UserDefaultsKey.ShowingTitleBar.rawValue))
        }
        
        set(isFullScreen) {
            UserDefaults.standard.set(isFullScreen, forKey: UserDefaultsKey.ShowingTitleBar.rawValue)
        }
    }
    
    var language: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaultsKey.Language.rawValue) ?? "ja-JP"
        }
        
        set(language) {
            UserDefaults.standard.set(language, forKey: UserDefaultsKey.Language.rawValue)
        }
    }
    
    /// Windowの位置と大きさを保存する（SplitViewの表示の際のためのもの）
    var windowFrame: NSRect {
        get {
            guard let windowFrameString = UserDefaults.standard.string(forKey: UserDefaultsKey.WindowFrame.rawValue) else {
               return NSRect(x: 450, y: 200, width: 1000, height: 750)
            }
            let windowFrame = NSRectFromString(windowFrameString)
            return windowFrame
        }
        
        set (windowFrame) {
            UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: UserDefaultsKey.WindowFrame.rawValue)
        }
    }
}
