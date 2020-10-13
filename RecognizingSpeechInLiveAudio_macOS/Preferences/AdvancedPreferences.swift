//
//  AdvancedPreferences.swift
//  FontPanelSample
//
//  Created by HIROKI IKEUCHI on 2020/01/24.
//  Copyright © 2020年 hikeuchi. All rights reserved.
//

import Foundation
import Cocoa

class AdvancedPreferences {
    
    static let shared =  AdvancedPreferences()
    
    private enum UserDefaultsKey: String {
        case fontName
        case fontSize
        case fontColor
        case strokeColor
        case strokeWidth
        case opacity
        case backgroundColor
        case backgroundOpacity
    }
    
    init() {
        // NSColorに関してはGetterの処理に任せている
        UserDefaults.standard.register(defaults: [UserDefaultsKey.fontName.rawValue : "HiraginoSans-W7",
                                                  UserDefaultsKey.fontSize.rawValue : 44.0,
                                                  UserDefaultsKey.strokeWidth.rawValue : 0.0,
                                                  UserDefaultsKey.opacity.rawValue : 1.0,
                                                  UserDefaultsKey.backgroundOpacity.rawValue : 0.7])
    }
    
    // For Debug
    func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.fontName.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.fontSize.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.fontColor.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.strokeColor.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.strokeWidth.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.opacity.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.backgroundColor.rawValue)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.backgroundOpacity.rawValue)
    }
    
    var font: NSFont {
        get {
            guard let name = UserDefaults.standard.object(forKey: UserDefaultsKey.fontName.rawValue) as? String else {
                return NSFont.systemFont(ofSize: NSFont.systemFontSize)
            }
            
            let size = CGFloat(UserDefaults.standard.float(forKey: UserDefaultsKey.fontSize.rawValue)) // 登録されていないときは…？
            guard let font = NSFont(name: name, size: size) else {
                return NSFont.systemFont(ofSize: NSFont.systemFontSize)
            }
            return font
        }
        
        set(font) {
            UserDefaults.standard.set(font.fontName, forKey: UserDefaultsKey.fontName.rawValue)
            UserDefaults.standard.set(Float(font.pointSize), forKey: UserDefaultsKey.fontSize.rawValue)
        }
    }
    
    var fontColor: NSColor {
        get {
            guard let colorData = UserDefaults.standard.data(forKey: UserDefaultsKey.fontColor.rawValue) else {
                return NSColor.white
            }
            guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
                return NSColor.white
            }
            return color
        }
        
        set (color) {
            guard let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) else {
                return
            }
            UserDefaults.standard.set(colorData, forKey: UserDefaultsKey.fontColor.rawValue)
        }
    }
    
    var strokeColor: NSColor {
        get {
            guard let colorData = UserDefaults.standard.data(forKey: UserDefaultsKey.strokeColor.rawValue) else {
                return NSColor.black
            }
            guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
                return NSColor.black
            }
            return color
        }
        
        set (color) {
            guard let colorData = try? NSKeyedArchiver.archivedData(withRootObject: backgroundColor, requiringSecureCoding: false) else {
                return
            }
            UserDefaults.standard.set(colorData, forKey: UserDefaultsKey.strokeColor.rawValue)
        }
    }
    
    var strokeWidth: Float {
        get {
            let strokeWidth = UserDefaults.standard.float(forKey: UserDefaultsKey.strokeWidth.rawValue)
            return strokeWidth
        }
        
        set (strokeWidth) {
            UserDefaults.standard.set(strokeWidth, forKey: UserDefaultsKey.strokeWidth.rawValue)
        }
    }
    
    var opacity: Float {
        get {
            let opacity = UserDefaults.standard.float(forKey: UserDefaultsKey.opacity.rawValue)
            return opacity
        }
        
        set (opacity) {
            UserDefaults.standard.set(opacity, forKey: UserDefaultsKey.opacity.rawValue)
        }
    }
    
    var backgroundColor: NSColor {
        get {
            guard let colorData = UserDefaults.standard.data(forKey: UserDefaultsKey.backgroundColor.rawValue) else {
                return NSColor.black
            }

            guard let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) else {
                return NSColor.black
            }
            return color
        }
        
        set (backgroundColor) {
            guard let colorData = try? NSKeyedArchiver.archivedData(withRootObject: backgroundColor, requiringSecureCoding: false) else {
                return
            }
            UserDefaults.standard.set(colorData, forKey: UserDefaultsKey.backgroundColor.rawValue)
        }
    }
    
    var backgroundOpacity: Float {
        get {
            let backgroundOpacity = UserDefaults.standard.float(forKey: UserDefaultsKey.backgroundOpacity.rawValue)
            return backgroundOpacity
        }
        
        set (backgroundOpacity) {
            UserDefaults.standard.set(backgroundOpacity, forKey: UserDefaultsKey.backgroundOpacity.rawValue)
        }
    }
}
