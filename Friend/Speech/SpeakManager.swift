//
//  SpeakManager.swift
//  Friend
//
//  Created by Yuki Takanashi on 2023/11/17.
//

import Foundation
import AVFoundation

class SpeakManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    @Published var synthesizer = AVSpeechSynthesizer()
    //speak完了後に処理させるための、関数待機用
    private var completionHandler: (() -> Void)?
    
    override init() {
            super.init()
            synthesizer.delegate = self
        }
    
    func speak(_ text: String, completion: @escaping () -> Void) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
        self.completionHandler = completion
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completionHandler?()
        completionHandler = nil
    }
    
    
    
    
}
