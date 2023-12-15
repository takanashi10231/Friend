//
//  AudioManager.swift
//  Friend
//
//  Created by Yuki Takanashi on 2023/12/05.
//

import Foundation
import AVFoundation

class AudioManager {
    
    @Published public var sessionRate: Double = 0.0
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        print("機器の変更を検知したよ")
        sessionRate = +1
        print(sessionRate)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    //speakする前にこの関数を呼び出し、サンプルルートを取得する
    public func configureAudioSession() -> Double {
        let audiosession = AVAudioSession.sharedInstance()
        do {
            // .playAndRecord = 発話と録音用 mode: .measurement = オーディオ入出力の測定での利用 options: .duckOthers = オーディオ再生時に、バックグラウンドオーディオの音量を下げるオプション。
            try audiosession.setCategory(.playAndRecord, mode: .measurement ,
                                         options: [.allowBluetoothA2DP,
                                                   .duckOthers])
            // options: .notifyOthersOnDeactivation = アプリのオーディオセッションを無効化したことを、システムが他のアプリに通知
            try audiosession.setActive(true, options: .notifyOthersOnDeactivation)
            print("オーディオセッション変更したよ")
        } catch {
            print("オーディオセッションの設定に失敗: \(error)")
        }
        let currentRoute = AVAudioSession.sharedInstance().currentRoute
        for output in currentRoute.outputs {
            if output.portType == .bluetoothA2DP {
                print("Bluetoothイヤホンが接続されています")
            }
        }
        return audiosession.sampleRate
    }
    
    public func stopAudioSession() {
        let audiosession = AVAudioSession.sharedInstance()
        do {
            try audiosession.setActive(false)
            print("オーディオセッション無効にしたよ")
        } catch {
            print("オーディオセッションの無効に失敗: \(error)")
        }
    }
    
}
