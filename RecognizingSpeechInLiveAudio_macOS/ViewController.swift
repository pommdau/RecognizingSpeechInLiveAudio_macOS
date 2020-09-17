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
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var lastTranscription = ""  // 以前の文字起こしテキストの保存用
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var recordButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    
    // MARK: View Controller Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        
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
                    self.recordButton.isEnabled = true
                    
                case .denied:
                    self.recordButton.isEnabled = false
                    self.recordButton.title = "User denied access to speech recognition"

                case .restricted:
                    self.recordButton.isEnabled = false
                    self.recordButton.title = "Speech recognition restricted on this device"

                case .notDetermined:
                    self.recordButton.isEnabled = false
                    self.recordButton.title = "Speech recognition not yet authorized"

                default:
                    self.recordButton.isEnabled = false
                }
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
                if self.lastTranscription.isEmpty {
                    self.textView.string = "\(result.bestTranscription.formattedString)"
                } else {
                    self.textView.string = "\(self.lastTranscription)\n\(result.bestTranscription.formattedString)"
                }
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
                
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordButton.isEnabled = true
                self.recordButton.title = "Start Recording"
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
        self.textView.insertText("(Macに語りかけてください!)", replacementRange: NSRange(location: -1, length: 0))
    }
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.title = "Start Recording"
        } else {
            recordButton.isEnabled = false
            recordButton.title = "ecognition Not Available"
        }
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func recordButtonTapped(_ sender: Any) {
        print("DEBUG: recordButtonTapped.. \(Date().description(with: Locale.current))")
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.title = "Stopping"
        } else {
            do {
                try startRecording()
                recordButton.title = "Stop Recording"
            } catch {
                recordButton.title = "Recording Not Available"
            }
        }
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        lastTranscription = ""
        textView.string = lastTranscription
    }
}

