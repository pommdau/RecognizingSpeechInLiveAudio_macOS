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
    
    private var recordingStatus = SpeechController.RecordingStatus.isReadyRecording {
        didSet {
            print("DEBUG: 🐱\(recordingStatus.rawValue)")
            configureRecordButtons()
        }
    }
    
    var restartingTimer: Timer!
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var processingIndicaror: NSProgressIndicator!
    @IBOutlet weak var clearButton: NSButton!
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定ウィンドウからの通知を受け取る設定
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: appearancePreferencesChangedNotificationIdentifier),
                                               object: nil,
                                               queue: nil) { (notification) in
            self.configureTextView()
        }
    }
    
    public override func viewWillAppear() {
        super.viewWillAppear()
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.delegate = self

        view.window?.animator().setFrame(GeneralPreferences().windowFrame, display: false)
        configureTextView()
        configureRecordButtons()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Selectors
    
    @objc func restartRecoding() {
        if self.speechController.isAvailableForRecording() {
            restartingTimer.invalidate()
            self.recordButtonTapped(self)  // 自動で録音が打ち切られている場合、自動で録音を再開する
        }
    }
    
    // MARK: - Helpers
    
    private func configureTextView() {
        let appearancePreferences = AppearancePreferences()
        let attributes: [NSAttributedString.Key : Any] = [
            .font : NSFont(name: appearancePreferences.font.fontName, size: appearancePreferences.font.pointSize)
                ?? NSFont.boldSystemFont(ofSize: CGFloat(24)),
            .foregroundColor : appearancePreferences.fontColor,
            .strokeColor : appearancePreferences.strokeColor,
            .strokeWidth : -appearancePreferences.strokeWidth
        ]
        
        let attibutesString = NSAttributedString(string: textView.string,
                                                 attributes: attributes)
        textView.textStorage?.setAttributedString(attibutesString)
        textView.typingAttributes = attributes
        textView.layer?.opacity = appearancePreferences.opacity
    }
    
    private func configureTextViewString() {
        if lastTranscription.count > 0 && currentTranscription.count > 0 {
            textView.string = "\(lastTranscription)\n\(currentTranscription)"
        } else {
            textView.string = "\(lastTranscription)\(currentTranscription)"
        }
        self.textView.scroll(NSPoint(x: 0, y: self.textView.frame.height))
    }
    
    private func configureRecordButtons() {
        processingIndicaror.set(tintColor: .white)
        recordButton.image?.isTemplate = true
        
        switch recordingStatus {
        case .isNotReadyRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStartTemplate")
            recordButton.isEnabled = false
            recordButton.isHidden = false
            recordButton.contentTintColor = .disabledControlTextColor
            processingIndicaror.isHidden = true
            processingIndicaror.stopAnimation(self)
        case .isReadyRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStartTemplate")
            recordButton.isEnabled = true
            recordButton.isHidden = false
            recordButton.contentTintColor = .systemRed
            processingIndicaror.isHidden = true
            processingIndicaror.stopAnimation(self)
        case .isRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStopTemplate")
            recordButton.isEnabled = true
            recordButton.isHidden = false
            recordButton.contentTintColor = .black
            processingIndicaror.isHidden = true
            processingIndicaror.stopAnimation(self)
        case .isStoppingRecording:
            recordButton.image = NSImage(named: "NSTouchBarRecordStartTemplate")
            recordButton.isEnabled = false
            recordButton.isHidden = true
            recordButton.contentTintColor = .disabledControlTextColor
            processingIndicaror.isHidden = false
            processingIndicaror.startAnimation(self)
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

// MARK: - SpeechControllerDelegate

extension ViewController: SpeechControllerDelegate {
    func didChange(withStatus status: SpeechController.RecordingStatus) {
        recordingStatus = status
    }
    
    func didReceiveError(withMessage message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.runModal()
        NSApp.terminate(self)
    }
    
    func didReceive(withTranscription transcription: String, resultStatus: SpeechController.TranscriptionResultStatus) {
        switch resultStatus {
        case .isRecording:
            currentTranscription = transcription
        case .isFinal, .isFinalWithStopButton:
            currentTranscription = ""
            if lastTranscription.count == 0 {
                lastTranscription = "\(transcription)"
            } else {
                lastTranscription = "\(lastTranscription)\n\(transcription)"
            }
        }

        if resultStatus == .isFinal {
            // 自動で録音が止まった場合は自動で再開する
            restartingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(restartRecoding), userInfo: nil, repeats: true)
        }
    }
    
}

// MARK: - NSWindowDelegate

extension ViewController: NSWindowDelegate {
    // メインウィンドウが閉じた場合にアプリケーションを終了する
    public func windowWillClose(_ notification: Notification) {
        NSApp.terminate(self)
    }
    
    public func windowDidResize(_ notification: Notification) {
        if let newPanel = notification.object as? NSPanel {
            GeneralPreferences().windowFrame = newPanel.frame
        }
    }
    
    public func windowDidMove(_ notification: Notification) {
        if let newPanel = notification.object as? NSPanel {
            GeneralPreferences().windowFrame = newPanel.frame
        }
    }
}
