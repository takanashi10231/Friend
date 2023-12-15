//
//  SpeechManager.swift
//  Friend
//
//  Created by Yuki Takanashi on 2023/10/27.
//

import Foundation
import Speech


class ListenManager: ObservableObject {
    
    static var shared = ListenManager()
    
    //オーディオクラス
    private let mAudio = AVAudioEngine()
    //音声認識要求
    private var mRecognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    //#クラスのメンバ変数にSFSpeechRecognizer,SFSpeechRecognitionTaskを定義する。
    //#SFSpeechRecognizerのlocaleには日本語に対応するため"ja_JP"を設定する。
    //音声認識クラス
    private let mRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ja_JP"))!
    //音声認識状況管理クラス
    private var mRecognitionTalk : SFSpeechRecognitionTask?
    //#クラスのメンバ変数に終了を検知するためのフラグを作成する。
    //終了フラグ （true = 終了）
    @Published public var isFinal = false
//    @Published public var isFinal = true
    //認識テキストを保存
    @Published public var text: String? {
        didSet {
            // "text"に文字列がセットされるたびにタイマーをセット
            anewSetTimer()
        }
    }
    @Published public var determinedText: String? {
        didSet {
            print("決定したtext：" + determinedText!)
        }
    }
    private var timer: Timer?
    
    
    
    init() {
        // 音声認識：権限を求めるダイアログを表示する
        SFSpeechRecognizer.requestAuthorization { status in
            switch status {
            case .notDetermined:
                print("許可されていない")
            case .denied:
                print("拒否された")
            case .restricted:
                print("端末が音声認識に対応していない")
            case .authorized:
                print("許可された")
            @unknown default:
                print("その他")
            }
        }
    }
    
    
    public func prepareRecording(sessionSampleRate: Double){
        
        //マイクなどのオーディオソースからのオーディオデータを取得
        let inputNode = mAudio.inputNode
        
        //リアルタイムまたは事前録音されたオーディオの音声認識リクエスト
        mRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let mRecognitionRequest = mRecognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        
        //中間結果取得　有効
        //ユーザーが話し続けている間にリアルタイムで認識結果を更新・取得する
        mRecognitionRequest.shouldReportPartialResults = true
        //ローカル認識　有効
        //デバイス上で音声認識を行う。音声データはAppleのサーバーに送信されず、デバイス上で直接音声認識をする
        mRecognitionRequest.requiresOnDeviceRecognition = true
        
        //既に開始している場合、一度キャンセルする。
        self.mRecognitionTalk?.cancel()
        self.mRecognitionTalk = nil
        
        //音声認識イベント処理
        //ユーザーの音声をリアルタイムで認識し、認識結果を処理するためのロジックを実装。エラーが発生した場合や認識が完了した場合には、必要な後処理を行う
        //この処理は非同期で行われ、inputNode.installTapでmRecognitionRequestに音声データが追加されるたびに、この関数が呼び出されるイメージ
        self.mRecognitionTalk = mRecognizer.recognitionTask(with: mRecognitionRequest) { result,error in
            //音声認識開始の結果を確認する
            if let result = result {
                self.isFinal = result.isFinal
                self.text = result.bestTranscription.formattedString
                // 認識結果をプリント
                print("RecognizedText: \(result.bestTranscription.formattedString)")
            }
            
            //エラー　または　終了フラグが設定されている場合は処理を修了する
            if error != nil || self.isFinal {
                //音声取得を停止する
                self.stopRecording()
                print(error!)
                print("エラーで止めたよ")
            }
        }
        
        let inputNodeFormat = AVAudioFormat(standardFormatWithSampleRate: sessionSampleRate, channels: inputNode.outputFormat(forBus: 0).channelCount)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNodeFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            // 音声を取得したら
            self.mRecognitionRequest?.append(buffer) // 認識リクエストに取得した音声を加える
        }
    }
    
    
    /// 録音開始
    public func startRecording(){
        do{
            print("録音開始")
            //終了フラグにfalseを設定する
            self.isFinal = false
            //1.音声の取得を開始
            mAudio.prepare()
            try mAudio.start()
        }
        catch let error
        {
            print(error)
        }
    }
    
    
    /// 録音停止
    public func stopRecording(){
        self.mRecognitionTalk?.cancel()
        self.mRecognitionTalk?.finish()
        self.mRecognitionRequest?.endAudio()
        self.mRecognitionRequest = nil
        self.mRecognitionTalk = nil
        //音声の取得を終了
        mAudio.stop()
        //終了フラグをtrueに設定する
        self.isFinal = true
        mAudio.inputNode.removeTap(onBus: 0)
        if let request = mRecognitionRequest {
            request.endAudio()
        }
        print("録音停止完了")
    }
    
    //以下は、文字列を決定する際のタイマー用の関数
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { [weak self] _ in
            // タイマーが発火したら実行したい処理
            self?.determineText()
        }
    }
    
    private func anewSetTimer() {
        // Aが変更されたらタイマーを再スタート
        timer?.invalidate()
        setupTimer()
    }
    
    func determineText() {
        self.determinedText = text
    }
    
    deinit {
        // インスタンスが破棄される際にタイマーを解放
        timer?.invalidate()
        timer = nil
    }
}
