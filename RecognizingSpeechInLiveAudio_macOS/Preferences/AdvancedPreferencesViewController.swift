//
//  AdvancedPreferencesViewController.swift
//  FontPanelSample
//
//  Created by HIROKI IKEUCHI on 2020/01/24.
//  Copyright © 2020年 hikeuchi. All rights reserved.
//

import Cocoa

let advancedPreferencesChangedNotificationIdentifier = "AdvancedPreferencesChanged"

class AdvancedPreferencesViewController: NSViewController {
    
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
        fontNameTextField.stringValue           = String(format: "%@ %d", AdvancedPreferences.shared.font.fontName, Int(AdvancedPreferences.shared.font.pointSize))
        fontColorWell.color                     = AdvancedPreferences.shared.fontColor
        strokeColorWell.color                   = AdvancedPreferences.shared.strokeColor
        strokeWidthTextField.stringValue        = String(format: "%.1f", AdvancedPreferences.shared.strokeWidth)
        strokeWidthStepper.floatValue           = AdvancedPreferences.shared.strokeWidth
        opacitySlider.doubleValue               = Double(AdvancedPreferences.shared.opacity)
        opacityTextField.doubleValue            = Double(AdvancedPreferences.shared.opacity)
        backgroundColorWell.color               = AdvancedPreferences.shared.backgroundColor
        backgroundOpacitySlider.doubleValue     = Double(AdvancedPreferences.shared.backgroundOpacity)
        backgroundOpacityTextField.doubleValue  = Double(AdvancedPreferences.shared.backgroundOpacity)
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
    
    func postAdvancedPreferencesChangedNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: advancedPreferencesChangedNotificationIdentifier), object: nil)
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
            AdvancedPreferences.shared.fontColor = colorWell.color
        } else if (colorWell.identifier!.rawValue == "StrokeColorWell") {
            AdvancedPreferences.shared.strokeColor = colorWell.color
        } else if (colorWell.identifier!.rawValue == "BackgroundColorWell") {
            AdvancedPreferences.shared.backgroundColor = colorWell.color
        }
        postAdvancedPreferencesChangedNotification()
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
        
        AdvancedPreferences.shared.strokeWidth = strokeWidth
        strokeWidthStepper.floatValue = strokeWidth
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func strokeWidthStepperClicked(_ sender: NSStepper) {
        let strokeWidth = sender.floatValue
        AdvancedPreferences.shared.strokeWidth = strokeWidth
        strokeWidthTextField.stringValue = String(format: "%.1f", strokeWidth)
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func opacitySliderValueChanged(_ sender: Any) {
        guard let slider = sender as? NSSlider else {
            return
        }
        
        let opacity = slider.floatValue
        opacityTextField.doubleValue = Double(opacity)
        AdvancedPreferences.shared.opacity = opacity
        
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func opacityTextFieldValueChanged(_ sender: Any) {
        let opacity = opacityTextField.floatValue
        opacitySlider.doubleValue = Double(opacity)
        AdvancedPreferences.shared.opacity = opacity

        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func backgroundOpacitySliderValueChanged(_ sender: Any) {
        guard let slider = sender as? NSSlider else {
            return
        }
        
        let opacity = slider.floatValue
        backgroundOpacityTextField.doubleValue = Double(opacity)
        AdvancedPreferences.shared.backgroundOpacity = opacity
        
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func backgroundOpacityTextFieldValueChanged(_ sender: Any) {
        let opacity = backgroundOpacityTextField.floatValue
        backgroundOpacitySlider.doubleValue = Double(opacity)
        AdvancedPreferences.shared.backgroundOpacity = opacity

        postAdvancedPreferencesChangedNotification()
    }
}

// MARK: - NSFontChanging

extension AdvancedPreferencesViewController : NSFontChanging {
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let newFont = fontManager.convert(AdvancedPreferences.shared.font)
        AdvancedPreferences.shared.font = newFont
        fontNameTextField.stringValue = String(format: "%@ %d", AdvancedPreferences.shared.font.fontName, Int(AdvancedPreferences.shared.font.pointSize))
        postAdvancedPreferencesChangedNotification()
    }
}
