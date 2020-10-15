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
    func didReceiveError(withMessage message: String)
    func didReceive(withTranscription transcription: String, resultStatus: SpeechController.TranscriptionResultStatus)
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
    
    public enum TranscriptionResultStatus: String {
        case isRecording
        case isFinal
        case isFinalWithStopButton
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
    private var pushedStopRecordingButton = false  // 録音がストップボタンによって止められたかどうか
    
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
    
    public func isAvailableForRecording() -> Bool {
        return !audioEngine.isRunning
    }
    
    public func startRecordingButton() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordingStatus = .isStoppingRecording
            pushedStopRecordingButton = true
        } else {
            do {
                recordingStatus = .isRecording
                try startRecording()
            } catch {
                delegate?.didReceiveError(withMessage: "Recording Not Available")
                recordingStatus = .isNotReadyRecording
            }
        }
    }
    
    private func startRecording() throws {
        // Cancel the previous task if it's running.
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        /* DEBUGGING>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> */
        if let inputList = try? self.getInputDevices() {
            // no airpods // [187, 41, 52]
            // with airpods [187, 41, 52, 208] -> 私の環境だと208がairpodsっぽい
            print(inputList)
        }
        
        var inputDeviceID = 208
        guard let audioUnit = audioEngine.inputNode.audioUnit else { return }
        let errorCode = AudioUnitSetProperty(audioUnit,
                                         kAudioOutputUnitProperty_CurrentDevice,
                                         kAudioUnitScope_Global,
                                         0,
                                         &inputDeviceID,
                                         UInt32(MemoryLayout<Int>.size))
        guard errorCode != 0 else { return }
        
        
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
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                print("DEBUG: 🍎\(result.bestTranscription.formattedString)")
                self.delegate?.didReceive(withTranscription: result.bestTranscription.formattedString,
                                          resultStatus: .isRecording)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                if let result = result {
                    let transcriptionResultStatsu = self.pushedStopRecordingButton ?
                        SpeechController.TranscriptionResultStatus.isFinalWithStopButton :
                        SpeechController.TranscriptionResultStatus.isFinal
                    self.delegate?.didReceive(withTranscription: result.bestTranscription.formattedString,
                                              resultStatus: transcriptionResultStatsu)
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
        delegate?.didReceive(withTranscription: "(Waiting speech..)", resultStatus: .isRecording)
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
                    self.delegate?.didReceiveError(withMessage: "User denied access to speech recognition")
                    self.recordingStatus = .isNotReadyRecording
                case .restricted:
                    self.delegate?.didReceiveError(withMessage: "Speech recognition restricted on this device")
                    self.recordingStatus = .isNotReadyRecording
                case .notDetermined:
                    self.delegate?.didReceiveError(withMessage: "Speech recognition not yet authorized")
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
            delegate?.didReceiveError(withMessage: "recognition Not Available")
            recordingStatus = .isNotReadyRecording
        }
    }
}

extension SpeechController {
    /*
     - [入力デバイスのリストを取得するためのAudioObjectGetPropertyData](https://stackoverrun.com/ja/q/1090202)
         - 一番下のSwiftコードを参照
     */
    
    func handle(_ errorCode: OSStatus) throws {
        if errorCode != kAudioHardwareNoError {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(errorCode), userInfo: [NSLocalizedDescriptionKey : "CAError: \(errorCode)" ])
            NSApplication.shared.presentError(error)
            throw error
        }
    }
    
    func getInputDevices() throws -> [AudioDeviceID] {
        
        var inputDevices: [AudioDeviceID] = []
        
        // Construct the address of the property which holds all available devices
        var devicesPropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
        var propertySize = UInt32(0)
        
        // Get the size of the property in the kAudioObjectSystemObject so we can make space to store it
        try handle(AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &devicesPropertyAddress, 0, nil, &propertySize))
        
        // Get the number of devices by dividing the property address by the size of AudioDeviceIDs
        let numberOfDevices = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        
        // Create space to store the values
        var deviceIDs: [AudioDeviceID] = []
        for _ in 0 ..< numberOfDevices {
            deviceIDs.append(AudioDeviceID())
        }
        
        // Get the available devices
        try handle(AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &devicesPropertyAddress, 0, nil, &propertySize, &deviceIDs))
        
        // Iterate
        for id in deviceIDs {
            
            // Get the device name for fun
            var name: CFString = "" as CFString
            var propertySize = UInt32(MemoryLayout<CFString>.size)
            var deviceNamePropertyAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
            try handle(AudioObjectGetPropertyData(id, &deviceNamePropertyAddress, 0, nil, &propertySize, &name))
            
            // Check the input scope of the device for any channels. That would mean it's an input device
            
            // Get the stream configuration of the device. It's a list of audio buffers.
            var streamConfigAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration, mScope: kAudioDevicePropertyScopeInput, mElement: 0)
            
            // Get the size so we can make room again
            try handle(AudioObjectGetPropertyDataSize(id, &streamConfigAddress, 0, nil, &propertySize))
            
            // Create a buffer list with the property size we just got and let core audio fill it
            let audioBufferList = AudioBufferList.allocate(maximumBuffers: Int(propertySize))
            try handle(AudioObjectGetPropertyData(id, &streamConfigAddress, 0, nil, &propertySize, audioBufferList.unsafeMutablePointer))
            
            // Get the number of channels in all the audio buffers in the audio buffer list
            var channelCount = 0
            for i in 0 ..< Int(audioBufferList.unsafeMutablePointer.pointee.mNumberBuffers) {
                channelCount = channelCount + Int(audioBufferList[i].mNumberChannels)
            }
            
            free(audioBufferList.unsafeMutablePointer)
            
            // If there are channels, it's an input device
            if channelCount > 0 {
                Swift.print("Found input device '\(name)' with \(channelCount) channels")
                inputDevices.append(id)
            }
        }
        
        return inputDevices
    }
    
}
