//
//  SpeechController.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/10/08.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Cocoa
import Speech

// MARK: - Protocol SpeechControllerDelegate

protocol SpeechControllerDelegate: class {
    func didReceive(withStatusMessage message: String)
    func didReceive(withTranscription transcription: String, isFilal: Bool)
    func didChange(withStatus status: SpeechController.RecordingStatus)
}

class SpeechController: NSObject {
    
    // MARK: - Properties
    
    public enum RecordingStatus: String {
        case isNotReadyRecording
        case isReadyRecording
        case isRecording
        case isStoppingRecording
    }
    
    public var recordingStatus = RecordingStatus.isNotReadyRecording {
        didSet {
            delegate?.didChange(withStatus: recordingStatus)
        }
    }
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: GeneralPreferences.shared.language))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()  // オーディオ信号の生成と処理、オーディオの入出力やAudio Nodeのつなぎこみを行うクラス
    
    weak var delegate: SpeechControllerDelegate?
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        initializeSpeechSettings()
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: generalPreferencesChangedNotificationIdentifier),
                                               object: nil,
                                               queue: nil) { (notification) in
            self.initializeSpeechSettings()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Helpers
    
    public func startRecordingButton() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordingStatus = .isStoppingRecording
        } else {
            do {
                recordingStatus = .isRecording
                try startRecording()
            } catch {
                delegate?.didReceive(withStatusMessage: "Recording Not Available")
                recordingStatus = .isNotReadyRecording
            }
        }
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
        recognitionRequest.shouldReportPartialResults = true  // 中間結果を取得する
        
        // Keep speech recognition data on device
        if #available(macOS 10.15, *) {
            if SFSpeechRecognizer.checkSupportLanguageInOffline(withIdentifier: GeneralPreferences.shared.language) &&
                GeneralPreferences.shared.sendingAudio == NSControl.StateValue.on {
                recognitionRequest.requiresOnDeviceRecognition =  false  // サーバに音声データを送信する
            } else {
                recognitionRequest.requiresOnDeviceRecognition =  true  // オフライン専用にするならtrue
            }
            print("DEBUG: 🍏\(recognitionRequest.requiresOnDeviceRecognition)")
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                print("DEBUG: 🍎\(result.bestTranscription.formattedString)")
                self.delegate?.didReceive(withTranscription: result.bestTranscription.formattedString, isFilal: false)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                if let result = result {
                    self.delegate?.didReceive(withTranscription: result.bestTranscription.formattedString, isFilal: true)
                }
                
                // Stop recognizing speech if there is a problem.
                self.recordingStatus = .isStoppingRecording
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
            self.recognitionRequest?.append(buffer)  // オーディオサンプルをPCM形式で蓄積し、音声認識システムに配信する
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        delegate?.didReceive(withStatusMessage: "(Waiting speech..)")
        self.recordingStatus = .isRecording
    }
    
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
                    if self.recordingStatus != .isRecording {
                        self.recordingStatus = .isReadyRecording
                    }
                case .denied:
                    self.delegate?.didReceive(withStatusMessage: "User denied access to speech recognition")
                    self.recordingStatus = .isNotReadyRecording
                case .restricted:
                    self.delegate?.didReceive(withStatusMessage: "Speech recognition restricted on this device")
                    self.recordingStatus = .isNotReadyRecording
                case .notDetermined:
                    self.delegate?.didReceive(withStatusMessage: "Speech recognition not yet authorized")
                    self.recordingStatus = .isNotReadyRecording
                default:
                    self.recordingStatus = .isNotReadyRecording
                }
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechController: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            if self.recordingStatus != .isRecording {
                self.recordingStatus = .isReadyRecording
            }
        } else {
            delegate?.didReceive(withStatusMessage: "recognition Not Available")
            recordingStatus = .isNotReadyRecording
        }
    }
}

