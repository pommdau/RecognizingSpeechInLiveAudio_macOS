//
//  ViewController.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/09/16.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Cocoa
import Speech

public class ViewController: NSViewController, SFSpeechRecognizerDelegate {

    // MARK: Properties
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: GeneralPreferences.shared.language))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var lastTranscription = "" {  // 以前の文字起こしテキストの保存用
        didSet { configureTextViewString() }
    }
    private var currentTranscription = "" {  // 現在文字起こし中のテキスト
        didSet { configureTextViewString() }
    }
    private var recordingStatus = RecordStatus.isNotReadyRecording {
        didSet { configureRecordButton() }
    }
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    
    private enum RecordStatus: String {
        case isNotReadyRecording
        case isReadyRecording
        case isRecording
        case isProcessing
    }
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // 設定ウィンドウからの通知を受け取る設定
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: generalPreferencesChangedNotificationIdentifier),
                                               object: nil,
                                               queue: nil) { (notification) in
            self.initializeSpeechSettings()
        }
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: advancedPreferencesChangedNotificationIdentifier),
                                               object: nil,
                                               queue: nil) { (notification) in
            self.configureTextView()
        }
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        
        configureTextView()
        initializeSpeechSettings()
    }
    
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        // Configure the audio session for the app.
        let inputNode = audioEngine.inputNode

        // Create and configure the speech recognition request.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, macOS 10.15, *) {
            recognitionRequest.requiresOnDeviceRecognition = false  // オフライン専用にするならtrue（設定に追加したいような項目）
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.currentTranscription = "\(result.bestTranscription.formattedString)"
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                
                if let result = result {
                    if self.lastTranscription.isEmpty {
                        self.lastTranscription = result.bestTranscription.formattedString
                    } else {
                        self.lastTranscription.append("\n\(result.bestTranscription.formattedString)")
                    }
                }
                self.currentTranscription = ""
                
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.recordingStatus = .isReadyRecording
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        currentTranscription = "(Waiting speech..)"
    }
    
    // MARK: - Helpers
    
    private func initializeSpeechSettings() {
        
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: GeneralPreferences.shared.language))!
        
        // Configure the SFSpeechRecognizer object already
        // stored in a local member variable.
        speechRecognizer.delegate = self
        
        // Asynchronously make the authorization request.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            // Divert to the app's main thread so that the UI
            // can be updated.
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.recordingStatus = .isReadyRecording
                case .denied:
                    self.recordingStatus = .isNotReadyRecording
                    self.currentTranscription = "User denied access to speech recognition"
                case .restricted:
                    self.recordingStatus = .isNotReadyRecording
                    self.currentTranscription = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.recordingStatus = .isNotReadyRecording
                    self.currentTranscription = "Speech recognition not yet authorized"
                default:
                    self.recordingStatus = .isNotReadyRecording
                }
            }
        }
    }
    
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
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordingStatus = .isReadyRecording
        } else {
            recordingStatus = .isNotReadyRecording
            currentTranscription = "ecognition Not Available"
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        print("DEBUG: recordButtonTapped.. \(Date().description(with: Locale.current))")
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordingStatus = .isProcessing
        } else {
            do {
                try startRecording()
                recordingStatus = .isRecording
            } catch {
                recordingStatus = .isNotReadyRecording
                currentTranscription = "Recording Not Available"
            }
        }
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        lastTranscription = ""
        currentTranscription = ""
    }
}

