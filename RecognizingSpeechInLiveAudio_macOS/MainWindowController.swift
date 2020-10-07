//
//  MainWindowController.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/09/18.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    private let generalPreferences = GeneralPreferences()
    
    //       @IBOutlet var splitViewWindow: IKEHSplitViewPanel!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        //           splitViewWindow.delegate = self
        self.window?.delegate = self
        
        // 設定ウィンドウからの通知を受け取る設定
        NotificationCenter.default.addObserver(
            forName: Notification.Name(rawValue: generalPreferencesChangedNotificationIdentifier),
            object: nil,
            queue: nil) { notification in
                self.handleGeneralPreferencesChanged()
        }
        window?.isMovableByWindowBackground = true  // 背景をドラッグして移動できるように(TODO: NSSplitViewのサブクラスを設定してから効かなくなっている)
        window?.isOpaque = false
        window?.level = .modalPanel
        
        // フルスクリーン時に表示する用の設定
        window?.styleMask.insert(.nonactivatingPanel)
        window?.collectionBehavior.insert(.canJoinAllSpaces)
        window?.collectionBehavior.insert(.fullScreenAuxiliary)
        
        handleGeneralPreferencesChanged()
    }
    
    // MARK: - Helpers
    
    private func handleGeneralPreferencesChanged() {
        // ウィンドウ左上のボタンを表示するかどうかの設定
        // オーバレイの場合ときは常時表示しない。またフルスクリーンのときも表示しない。
        var isHiddenWindowButton = false
        if (generalPreferences.isOverlay == NSControl.StateValue.on) {
            isHiddenWindowButton = true
        }
        if (generalPreferences.showingTitleBar == NSControl.StateValue.off) {
            isHiddenWindowButton = true
        }
        hideStandardWindowButton(isHidden: isHiddenWindowButton)
        
        
        if (generalPreferences.isOverlay == NSControl.StateValue.on) {
            window?.ignoresMouseEvents = true
            window?.title = NSLocalizedString("Recognizing Speech - in overlay", comment: "")
        } else {
            window?.ignoresMouseEvents = false
            window?.title = NSLocalizedString("Recognizing Speech", comment: "")
        }
        
        // フルスクリーン状態か
        if (generalPreferences.showingTitleBar == NSControl.StateValue.off) {
            window?.backgroundColor = NSColor(white: 1, alpha: 0.00)
            window?.hasShadow = false
            window?.styleMask.insert(.borderless)
            window?.titlebarAppearsTransparent = true
            window?.titleVisibility = .hidden
        } else {
            window?.backgroundColor = NSColor(white: 1, alpha: 0.01)
            window?.hasShadow = true
            window?.styleMask.remove(.borderless)
            window?.styleMask.insert(.titled)
            window?.titlebarAppearsTransparent = false
            window?.titleVisibility = .visible
        }
    }
    
    private func hideStandardWindowButton(isHidden: Bool) {
        window?.standardWindowButton(.miniaturizeButton)!.isHidden = isHidden
        window?.standardWindowButton(.zoomButton)!.isHidden = isHidden
        window?.standardWindowButton(.closeButton)!.isHidden = isHidden
    }
    
}

// MARK: - NSWindowDelegate

extension MainWindowController: NSWindowDelegate {
    // メインウィンドウが閉じた場合にアプリケーションを終了する
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(self)
    }
}
