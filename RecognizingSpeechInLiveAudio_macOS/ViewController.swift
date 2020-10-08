//
//  ViewController.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/09/16.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Cocoa

public class ViewController: NSViewController {

    // MARK: Properties
    
    lazy var speechController: SpeechController = {
        let speechController = SpeechController()
        speechController.delegate = self
        return speechController
    }()
    
    private var lastTranscription = "" {  // 以前の文字起こしテキストの保存用
        didSet { configureTextViewString() }
    }
    private var currentTranscription = "" {  // 現在文字起こし中のテキスト
        didSet { configureTextViewString() }
    }
    
    private var recordingStatus = SpeechController.RecordingStatus.isNotReadyRecording {
        didSet { configureRecordButton() }
    }
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定ウィンドウからの通知を受け取る設定
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: advancedPreferencesChangedNotificationIdentifier),
                                               object: nil,
                                               queue: nil) { (notification) in
            self.configureTextView()
        }
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        configureTextView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Helpers
    
    private func configureTextView() {
        let advancedPreferences = AdvancedPreferences()
        let attributes: [NSAttributedString.Key : Any] = [
            .font : NSFont(name: advancedPreferences.font.fontName, size: advancedPreferences.font.pointSize)
                ?? NSFont.boldSystemFont(ofSize: CGFloat(24)),
            .foregroundColor : advancedPreferences.fontColor,
            .strokeColor : advancedPreferences.strokeColor,
            .strokeWidth : -advancedPreferences.strokeWidth
        ]
        
        let attibutesString = NSAttributedString(string: textView.string,
                                                 attributes: attributes)
        textView.textStorage?.setAttributedString(attibutesString)
        textView.typingAttributes = attributes
        textView.layer?.opacity = advancedPreferences.opacity
    }
    
    private func configureTextViewString() {
        if self.lastTranscription.count == 0 {
            self.textView.string = currentTranscription
            self.textView.scroll(NSPoint(x: 0, y: self.textView.frame.height))
        } else if self.lastTranscription.count == 0 &&
                  self.currentTranscription.count == 0 {
            self.textView.string = "\(lastTranscription)"
            self.textView.scroll(NSPoint(x: 0, y: self.textView.frame.height))
        } else {
            self.textView.string = "\(lastTranscription)\n\(currentTranscription)"
            self.textView.scroll(NSPoint(x: 0, y: self.textView.frame.height))
        }
    }
    
    private func configureRecordButton() {
        switch recordingStatus {
        case .isNotReadyRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStartTemplate")
            recordButton.isEnabled = false
        case .isReadyRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStartTemplate")
            recordButton.isEnabled = true
        case .isRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStopTemplate")
            recordButton.isEnabled = true
        case .isProcessing:
            recordButton.image = NSImage(named: "NSTouchBarRecordStartTemplate")
            recordButton.isEnabled = false
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        speechController.startRecordingButton()
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        lastTranscription = ""
        currentTranscription = ""
    }
}

extension ViewController: SpeechControllerDelegate {
    func didReceive(withStatusMessage message: String?, status: SpeechController.RecordingStatus) {
        if let message = message {
            currentTranscription = message
        }
        recordingStatus = status
    }
    
    func didReceive(withTranscription transcription: String, isFilal: Bool) {
        if isFilal {
            lastTranscription = transcription
            recordingStatus = .isReadyRecording
        } else {
            currentTranscription = transcription
        }
    }
}
