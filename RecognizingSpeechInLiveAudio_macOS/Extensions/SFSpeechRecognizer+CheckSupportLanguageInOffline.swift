//
//  SFSpeechRecognizer+CheckSupportLanguageInOffline.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/10/12.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Foundation
import Speech

extension SFSpeechRecognizer {
    // オフラインに対応しているならtrueを返す
    static func checkSupportLanguageInOffline(withIdentifier identifier: String) -> Bool {
        guard let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: GeneralPreferences.shared.language)) else { return false }
        
        if speechRecognizer.supportsOnDeviceRecognition {
           return true
        } 
        
        return false
    }
}
