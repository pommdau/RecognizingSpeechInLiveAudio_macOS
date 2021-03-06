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
        case SendingAudio
        case WindowFrame
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKey.IsOverlay.rawValue : false,
            UserDefaultsKey.ShowingTitleBar.rawValue : false,
            UserDefaultsKey.Language.rawValue : "en-US",
            UserDefaultsKey.SendingAudio.rawValue : false,
        ])
    }
    
    // For Debug
    func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.IsOverlay.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.ShowingTitleBar.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.Language.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.SendingAudio.rawValue)
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
            return UserDefaults.standard.string(forKey: UserDefaultsKey.Language.rawValue) ?? "en-US"
        }
        
        set(language) {
            UserDefaults.standard.set(language, forKey: UserDefaultsKey.Language.rawValue)
        }
    }
    
    var sendingAudio: NSControl.StateValue {
        get {
            return NSControl.StateValue(UserDefaults.standard.integer(forKey: UserDefaultsKey.SendingAudio.rawValue))
        }
        
        set(sendingAudio) {
            UserDefaults.standard.set(sendingAudio, forKey: UserDefaultsKey.SendingAudio.rawValue)
        }
    }
    
    /// Windowの位置と大きさを保存する（SplitViewの表示の際のためのもの）
    var windowFrame: NSRect {
        get {
            guard let windowFrameString = UserDefaults.standard.string(forKey: UserDefaultsKey.WindowFrame.rawValue) else {
                return NSRect(x: 200, y: 74, width: 1200, height: 300)
            }
            let windowFrame = NSRectFromString(windowFrameString)
            return windowFrame
        }
        
        set (windowFrame) {
            UserDefaults.standard.set(NSStringFromRect(windowFrame), forKey: UserDefaultsKey.WindowFrame.rawValue)
        }
    }
}
