//
//  MainWindowController.swift
//  RecognizingSpeechInLiveAudio_macOS
//
//  Created by HIROKI IKEUCHI on 2020/09/18.
//  Copyright © 2020 hikeuchi. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
        
    // MARK: - Lifecycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.delegate = self
        
        // 設定ウィンドウからの通知を受け取る設定
        NotificationCenter.default.addObserver(
            forName: Notification.Name(rawValue: generalPreferencesChangedNotificationIdentifier),
            object: nil,
            queue: nil) { notification in
                self.configureWindow()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name(rawValue: advancedPreferencesChangedNotificationIdentifier),
            object: nil,
            queue: nil) { notification in
                self.configureWindow()
        }
        
        window?.isMovableByWindowBackground = true  // 背景をドラッグして移動できるように(TODO: NSSplitViewのサブクラスを設定してから効かなくなっている)
        window?.isOpaque = false
        window?.level = .modalPanel
        
        // フルスクリーン時に表示する用の設定
        window?.styleMask.insert(.nonactivatingPanel)
        window?.collectionBehavior.insert(.canJoinAllSpaces)
        window?.collectionBehavior.insert(.fullScreenAuxiliary)
        
        configureWindow()
    }
    
    // MARK: - Helpers
    
    private func configureWindow() {
        // ウィンドウ左上のボタンを表示するかどうかの設定
        // オーバレイの場合ときは常時表示しない。またフルスクリーンのときも表示しない。
        var isHiddenWindowButton = false
        if (GeneralPreferences.shared.isOverlay == NSControl.StateValue.on) {
            isHiddenWindowButton = true
        }
        if (GeneralPreferences.shared.showingTitleBar == NSControl.StateValue.off) {
            isHiddenWindowButton = true
        }
        hideStandardWindowButton(isHidden: isHiddenWindowButton)
        
        
        if (GeneralPreferences.shared.isOverlay == NSControl.StateValue.on) {
            window?.ignoresMouseEvents = true
            window?.title = NSLocalizedString("Recognizing Speech - in overlay", comment: "")
        } else {
            window?.ignoresMouseEvents = false
            window?.title = NSLocalizedString("Recognizing Speech", comment: "")
        }
        
        // フルスクリーン状態か
        if (GeneralPreferences.shared.showingTitleBar == NSControl.StateValue.off) {
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
        
        if AdvancedPreferences.shared.backgroundOpacity > 0.0 {
            if let color = AdvancedPreferences.shared.backgroundColor.usingColorSpace(NSColorSpace.deviceRGB) {
                window?.backgroundColor = NSColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent,
                                                  alpha: CGFloat(AdvancedPreferences.shared.backgroundOpacity))
            }
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
