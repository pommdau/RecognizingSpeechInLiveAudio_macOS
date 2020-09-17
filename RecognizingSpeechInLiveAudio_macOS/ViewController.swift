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
        
        // 設定ウィンドウからの通知を受け取る設定
        let notificationNames = [Notification.Name(rawValue: advancedPreferencesChangedNotificationIdentifier)]
        for notificationName in notificationNames {
            NotificationCenter.default.addObserver(forName: notificationName,
                                                   object: nil,
                                                   queue: nil) {
                                                    (notification) in
                                                    self.configureTextView()
            }
        }
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        textView.string = "私は結果もうその意味屋というのの時に悟っだたく。依然として十一月で授業者もようやくこの断食ありうでもが誘き寄せるが行くですには戦争曲げんたから、そうには好かでたないござい。隙間にしたのはどうも時間に同時にですでまい。ざっと岡田さんに成就人実際出立が見るた例この精神おれか参考にについてご話たますないたて、この結果は何か金力仲間に入っと、ネルソンさんの訳が一つの私がどうしてもご影響とよるからあなた一口から小＃「が思っようにちゃんとご運動をつけんましば、さきほどたしか話にしでのにみだ方に騒ぐだます。"
        configureTextView()
        /*
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
 */
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

