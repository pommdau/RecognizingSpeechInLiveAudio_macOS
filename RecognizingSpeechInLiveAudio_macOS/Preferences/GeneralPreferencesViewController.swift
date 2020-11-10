//
//  GeneralPreferencesViewController.swift
//  FontPanelSample
//
//  Created by HIROKI IKEUCHI on 2020/01/24.
//  Copyright © 2020年 hikeuchi. All rights reserved.
//

import Cocoa
import Speech

let generalPreferencesChangedNotificationIdentifier = "GeneralPreferencesChanged"

class GeneralPreferencesViewController: NSViewController {

    // MARK: - Properties
    
    @IBOutlet weak var overlayCheckBox: NSButton!
    @IBOutlet weak var showingTitleBarCheckBox: NSButton!
    @IBOutlet weak var languagePopup: NSPopUpButton!
    @IBOutlet weak var sendingAudioCheckBox: NSButton!
    
    private let languages = [
        ["English (United States)", "en-US"],
        ["日本語（日本）", "ja-JP"],
        ["Bahasa Melayu (Malaysia)", "ms-MY"],
        ["Deutsch (Deutschland)", "de-DE"],
        ["Deutsch (Schweiz)", "de-CH"],
        ["Deutsch (Österreich)", "de-AT"],
        ["English (Australia)", "en-AU"],
        ["English (Canada)", "en-CA"],
        ["English (India)", "en-IN"],
        ["English (Indonesia)", "en-ID"],
        ["English (Ireland)", "en-IE"],
        ["English (New Zealand)", "en-NZ"],
        ["English (Philippines)", "en-PH"],
        ["English (Saudi Arabia)", "en-SA"],
        ["English (Singapore)", "en-SG"],
        ["English (South Africa)", "en-ZA"],
        ["English (United Arab Emirates)", "en-AE"],
        ["English (United Kingdom)", "en-GB"],
        ["Hindi (Latin)", "hi-Latn"],
        ["Indonesia (Indonesia)", "id-ID"],
        ["Nederlands (België)", "nl-BE"],
        ["Nederlands (Nederland)", "nl-NL"],
        ["Tiếng Việt (Việt Nam)", "vi-VN"],
        ["Türkçe (Türkiye)", "tr-TR"],
        ["català (Espanya)", "ca-ES"],
        ["dansk (Danmark)", "da-DK"],
        ["español (Chile)", "es-CL"],
        ["español (Colombia)", "es-CO"],
        ["español (España)", "es-ES"],
        ["español (Estados Unidos)", "es-US"],
        ["español (Latinoamérica)", "es-419"],
        ["español (México)", "es-MX"],
        ["français (Belgique)", "fr-BE"],
        ["français (Canada)", "fr-CA"],
        ["français (France)", "fr-FR"],
        ["français (Suisse)", "fr-CH"],
        ["hrvatski (Hrvatska)", "hr-HR"],
        ["italiano (Italia)", "it-IT"],
        ["italiano (Svizzera)", "it-CH"],
        ["magyar (Magyarország)", "hu-HU"],
        ["norsk bokmål (Norge)", "nb-NO"],
        ["polski (Polska)", "pl-PL"],
        ["português (Brasil)", "pt-BR"],
        ["português (Portugal)", "pt-PT"],
        ["română (România)", "ro-RO"],
        ["slovenčina (Slovensko)", "sk-SK"],
        ["suomi (Suomi)", "fi-FI"],
        ["svenska (Sverige)", "sv-SE"],
        ["čeština (Česko)", "cs-CZ"],
        ["Ελληνικά (Ελλάδα)", "el-GR"],
        ["русский (Россия)", "ru-RU"],
        ["українська (Україна)", "uk-UA"],
        ["हिन्दी (भारत)", "hi-IN"],
        ["हिन्दी (भारत, TRANSLIT)", "hi-IN-translit"],
        ["ไทย (ไทย)", "th-TH"],
        ["上海话（中国大陆）", "wuu-CN"],
        ["中文（中国大陆）", "zh-CN"],
        ["中文（台灣）", "zh-TW"],
        ["中文（香港）", "zh-HK"],
        ["粤语 (中国大陆)", "yue-CN"],
        ["한국어(대한민국)", "ko-KR"],
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeLanguagePopup()
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
        
        sendingAudioCheckBox.state = GeneralPreferences.shared.sendingAudio
        sendingAudioCheckBox.isEnabled = SFSpeechRecognizer.checkSupportLanguageInOffline(withIdentifier: GeneralPreferences.shared.language)
    }
    
    private func initializeLanguagePopup() {

//         for getting support language list
//         SFSpeechRecognizer.supportedLocales().enumerated().forEach {
//            print("[\"\($0.element.localizedString(forIdentifier: $0.element.identifier)!)\", \"\($0.element.identifier)\"],")
//         }
        
//        let sortedLanguages = languages.sorted() { $0[0] < $1[0] }
//        for language in sortedLanguages {
//            print("[\"\(language[0])\", \"\(language[1])\"],")
//        }

        for language in languages {
            let menu = NSMenuItem(title: language[0], action: nil, keyEquivalent: "")
            menu.identifier = NSUserInterfaceItemIdentifier(language[1])
            languagePopup.menu?.addItem(menu)
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
    
    @IBAction func sendingAudioChanged(_ sender: Any) {
        guard let checkBox = sender as? NSButton else {
            return
        }
        
        GeneralPreferences.shared.sendingAudio = checkBox.state
        postGeneralPreferencesChangedNotification()
        configureUI()
    }
}

