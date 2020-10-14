//
//  AppearancePreferencesViewController.swift
//  FontPanelSample
//
//  Created by HIROKI IKEUCHI on 2020/01/24.
//  Copyright © 2020年 hikeuchi. All rights reserved.
//

import Cocoa

let appearancePreferencesChangedNotificationIdentifier = "AppearancePreferencesChanged"

class AppearancePreferencesViewController: NSViewController {
    
    // MARK: - Properties
        
    @IBOutlet weak var fontNameTextField: NSTextField!
    @IBOutlet var fontColorWell: NSColorWell!
    @IBOutlet var strokeColorWell: NSColorWell!
    @IBOutlet var strokeWidthTextField: NSTextField!
    @IBOutlet var strokeWidthStepper: NSStepper!
    @IBOutlet var opacitySlider: NSSlider!
    @IBOutlet var opacityTextField: NSTextField!
    @IBOutlet var backgroundColorWell: NSColorWell!
    @IBOutlet var backgroundOpacitySlider: NSSlider!
    @IBOutlet var backgroundOpacityTextField: NSTextField!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIの初期設定
        fontNameTextField.stringValue           = String(format: "%@ %d", AppearancePreferences.shared.font.fontName, Int(AppearancePreferences.shared.font.pointSize))
        fontColorWell.color                     = AppearancePreferences.shared.fontColor
        strokeColorWell.color                   = AppearancePreferences.shared.strokeColor
        strokeWidthTextField.stringValue        = String(format: "%.1f", AppearancePreferences.shared.strokeWidth)
        strokeWidthStepper.floatValue           = AppearancePreferences.shared.strokeWidth
        opacitySlider.doubleValue               = Double(AppearancePreferences.shared.opacity)
        opacityTextField.doubleValue            = Double(AppearancePreferences.shared.opacity)
        backgroundColorWell.color               = AppearancePreferences.shared.backgroundColor
        backgroundOpacitySlider.doubleValue     = Double(AppearancePreferences.shared.backgroundOpacity)
        backgroundOpacityTextField.doubleValue  = Double(AppearancePreferences.shared.backgroundOpacity)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    override func viewDidDisappear() {
        let panel = NSFontManager.shared.fontPanel(true)
        panel?.close()  // フォントパネルだけが残ってしまわないようにする
    }
    
    // MARK: - Helpers
    
    func postAppearancePreferencesChangedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: appearancePreferencesChangedNotificationIdentifier), object: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func showFontPanel(_ sender: Any) {
        let fontManager = NSFontManager.shared
        fontManager.target = self
        let panel = fontManager.fontPanel(true)
        panel?.orderFront(self)
        panel?.isEnabled = true // trueをセットすると使用可能になります（今回は無くても良い？）
    }
    
    @IBAction func changeFontColor(_ sender: Any) {
        guard let colorWell = sender as? NSColorWell else {
            return
        }
        if (colorWell.identifier!.rawValue == "FontColorWell") {
            AppearancePreferences.shared.fontColor = colorWell.color
        } else if (colorWell.identifier!.rawValue == "StrokeColorWell") {
            AppearancePreferences.shared.strokeColor = colorWell.color
        } else if (colorWell.identifier!.rawValue == "BackgroundColorWell") {
            AppearancePreferences.shared.backgroundColor = colorWell.color
        }
        postAppearancePreferencesChangedNotification()
    }
    
    @IBAction func strokeWidthChanged(_ sender: NSTextField) {
        var strokeWidth = sender.floatValue // 変換できない場合は0.0が帰ってくる
        
        if strokeWidth < 0.0 || strokeWidth > 100.0 {
            strokeWidth = 0.0
        }
        
        if strokeWidth == 0.0 {
            sender.stringValue = "0.0"
        } else {
            sender.stringValue = String(format: "%.1f", strokeWidth)
        }
        
        AppearancePreferences.shared.strokeWidth = strokeWidth
        strokeWidthStepper.floatValue = strokeWidth
        postAppearancePreferencesChangedNotification()
    }
    
    @IBAction func strokeWidthStepperClicked(_ sender: NSStepper) {
        let strokeWidth = sender.floatValue
        AppearancePreferences.shared.strokeWidth = strokeWidth
        strokeWidthTextField.stringValue = String(format: "%.1f", strokeWidth)
        postAppearancePreferencesChangedNotification()
    }
    
    @IBAction func opacitySliderValueChanged(_ sender: Any) {
        guard let slider = sender as? NSSlider else {
            return
        }
        
        let opacity = slider.floatValue
        opacityTextField.doubleValue = Double(opacity)
        AppearancePreferences.shared.opacity = opacity
        
        postAppearancePreferencesChangedNotification()
    }
    
    @IBAction func opacityTextFieldValueChanged(_ sender: Any) {
        let opacity = opacityTextField.floatValue
        opacitySlider.doubleValue = Double(opacity)
        AppearancePreferences.shared.opacity = opacity

        postAppearancePreferencesChangedNotification()
    }
    
    @IBAction func backgroundOpacitySliderValueChanged(_ sender: Any) {
        guard let slider = sender as? NSSlider else {
            return
        }
        
        let opacity = slider.floatValue
        backgroundOpacityTextField.doubleValue = Double(opacity)
        AppearancePreferences.shared.backgroundOpacity = opacity
        
        postAppearancePreferencesChangedNotification()
    }
    
    @IBAction func backgroundOpacityTextFieldValueChanged(_ sender: Any) {
        let opacity = backgroundOpacityTextField.floatValue
        backgroundOpacitySlider.doubleValue = Double(opacity)
        AppearancePreferences.shared.backgroundOpacity = opacity

        postAppearancePreferencesChangedNotification()
    }
}

// MARK: - NSFontChanging

extension AppearancePreferencesViewController : NSFontChanging {
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let newFont = fontManager.convert(AppearancePreferences.shared.font)
        AppearancePreferences.shared.font = newFont
        fontNameTextField.stringValue = String(format: "%@ %d", AppearancePreferences.shared.font.fontName, Int(AppearancePreferences.shared.font.pointSize))
        postAppearancePreferencesChangedNotification()
    }
}
