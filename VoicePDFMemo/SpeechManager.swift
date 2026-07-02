import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechManager: NSObject, ObservableObject {
    @Published var transcribedText: String = ""
    @Published var isRecording: Bool = false

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // permissions
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    // recording lifecycle
    func startRecording() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()

        guard let request = request else {
            return
        }

        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }

            if error != nil {
                self.stopRecording()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()

            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            print("Audio engine error: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.cancel()

        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
