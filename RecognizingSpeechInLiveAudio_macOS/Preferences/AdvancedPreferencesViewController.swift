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
    
    private let advancedPreferences = AdvancedPreferences()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIの初期設定
        fontNameTextField.stringValue = String(format: "%@ %d", advancedPreferences.font.fontName, Int(advancedPreferences.font.pointSize))
        fontColorWell.color = advancedPreferences.fontColor
        strokeColorWell.color = advancedPreferences.strokeColor
        strokeWidthTextField.stringValue = String(format: "%.1f", advancedPreferences.strokeWidth)
        strokeWidthStepper.floatValue = advancedPreferences.strokeWidth
        opacitySlider.doubleValue = Double(advancedPreferences.opacity)
        opacityTextField.doubleValue = Double(advancedPreferences.opacity)
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
            advancedPreferences.fontColor = colorWell.color
        } else if (colorWell.identifier!.rawValue == "StrokeColorWell") {
            advancedPreferences.strokeColor = colorWell.color
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
        
        advancedPreferences.strokeWidth = strokeWidth
        strokeWidthStepper.floatValue = strokeWidth
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func strokeWidthStepperClicked(_ sender: NSStepper) {
        let strokeWidth = sender.floatValue
        advancedPreferences.strokeWidth = strokeWidth
        strokeWidthTextField.stringValue = String(format: "%.1f", strokeWidth)
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func opacitySliderValueChanged(_ sender: Any) {
        guard let slider = sender as? NSSlider else {
            return
        }
        
        let opacity = slider.floatValue
        opacityTextField.doubleValue = Double(opacity)
        advancedPreferences.opacity = opacity
        
        postAdvancedPreferencesChangedNotification()
    }
    
    @IBAction func opacityTextFieldValueChanged(_ sender: Any) {
        let opacity = opacityTextField.floatValue
        opacitySlider.doubleValue = Double(opacity)
        advancedPreferences.opacity = opacity

        postAdvancedPreferencesChangedNotification()
    }
}

// MARK: - NSFontChanging

extension AdvancedPreferencesViewController : NSFontChanging {
    func changeFont(_ sender: NSFontManager?) {
        guard let fontManager = sender else {
            return
        }
        let newFont = fontManager.convert(advancedPreferences.font)
        advancedPreferences.font = newFont
        fontNameTextField.stringValue = String(format: "%@ %d", advancedPreferences.font.fontName, Int(advancedPreferences.font.pointSize))
        postAdvancedPreferencesChangedNotification()
    }
}
