//
//  ContentView.swift
//  Friend
//
//  Created by Yuki Takanashi on 2023/10/20.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var userInput = ""
    @State private var chatResponse = "会話しよう"
    private var gptManager = GptManager()
    @ObservedObject private var listenManager = ListenManager.shared
    @StateObject var speakManager = SpeakManager()
    @State private var audioManager = AudioManager()
    // 録音中かどうかを示すフラグ
    @State private var isRecording = false
    
    init() {
        AVSpeechSynthesisVoice.speechVoices()
        self.listenManager.prepareRecording(sessionSampleRate: self.audioManager.configureAudioSession())
        self.listenManager.startRecording()        
    }
    
    var body: some View {
        VStack {
            Text(chatResponse)
                .padding()
            
             //認識されたテキストの表示
            Text(listenManager.isFinal ? "認識終了" : "認識中...")
                .font(.headline)
            
            Text(listenManager.text ?? "a")
                .font(.headline)
            
            Button(action: {
                speakManager.speak("テストだよ") {
                    print("テスト")
                }
            }) {
                // ボタンの表示内容
                Text("タップしてください")
                    .padding() // パディングを追加
                    .background(Color.blue) // 背景色を設定
                    .foregroundColor(.white) // テキストの色を白に設定
                    .cornerRadius(10) // 角を丸くする
            }
            Button(action: {
                self.listenManager.stopRecording()
            }) {
                // ボタンの表示内容
                Text("stop")
                    .padding() // パディングを追加
                    .background(Color.blue) // 背景色を設定
                    .foregroundColor(.white) // テキストの色を白に設定
                    .cornerRadius(10) // 角を丸くする
            }
            Button(action: {
                self.listenManager.prepareRecording(sessionSampleRate: self.audioManager.configureAudioSession())
                self.listenManager.startRecording()
            }) {
                // ボタンの表示内容
                Text("start")
                    .padding() // パディングを追加
                    .background(Color.blue) // 背景色を設定
                    .foregroundColor(.white) // テキストの色を白に設定
                    .cornerRadius(10) // 角を丸くする
            }
            //なんでこれがうまくいかないかは、解決しなきゃいけない問題
//            Button(action: {
//                self.listenManager.stopRecording()
//                sleep(5)
//                self.listenManager.prepareRecording(sessionSampleRate: self.audioManager.configureAudioSession())
//                self.listenManager.startRecording()
//            }) {
//                // ボタンの表示内容
//                Text("stopstart")
//                    .padding() // パディングを追加
//                    .background(Color.blue) // 背景色を設定
//                    .foregroundColor(.white) // テキストの色を白に設定
//                    .cornerRadius(10) // 角を丸くする
//            }
        }
        .padding()
        //.onReceiveを使用してspeechManager.determinedTextの変更を購読
        .onReceive(listenManager.$determinedText) { determinedText in
            if !listenManager.isFinal && determinedText != nil {
                self.listenManager.stopRecording()
                // 決定した音声を元にGPTに送信
                Task {
                    do {
                        chatResponse = try await gptManager.askGPT(question: self.listenManager.determinedText ?? "")
                    } catch {
                        print("Error: \(error)")
                    }
                    speakManager.speak(chatResponse) {
                        self.listenManager.prepareRecording(sessionSampleRate: self.audioManager.configureAudioSession())
                        self.listenManager.startRecording()
                    }
                }
            }
        }
        //本当は↓をやりたかったけど、うまくいかないからいったん諦める。なぜかstopとstartを同一関数でやるとうまくいかなくなる。startした後にエラーで引っかかりスタートしてしまう。
        //sleepして時間止めてもダメ。↑のボタンで、stopとstartを別関数でやるとうまく行く
        //.onReceiveを使用してaudioManager.sessionRateの変更を購読。録音が停止していたら、それはspeak中であり、speak完了後にprepearするので必要なし。開始していたら、再度prepearしなきゃいけない
//        .onReceive(audioManager.$sessionRate) { _ in
//            if !listenManager.isFinal {
//                sleep(5)
//                self.listenManager.stopRecording()
//                self.listenManager.prepareRecording(sessionSampleRate: self.audioManager.configureAudioSession())
//                self.listenManager.startRecording()
//                print("接続し直したよ")
//            }
//        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
