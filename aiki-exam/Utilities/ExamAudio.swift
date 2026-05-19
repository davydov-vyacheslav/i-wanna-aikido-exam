//
//  ExamAudio.swift
//  aiki-exam
//
//  Created by Slava Davydov on 06.05.2026.
//

import AVFoundation

@MainActor
final class ExamAudio {

    static let shared = ExamAudio()
    
    private var audioPlayer:   AVAudioPlayer?
    private let synthesizer  = AVSpeechSynthesizer()
    private var pendingSpeech: DispatchWorkItem?
    private var pendingSpeechText: String?
    private var cachedVoice: AVSpeechSynthesisVoice?
    
    var voiceIdentifier: String = AppSettings.defaultVoiceIdentifier {
        didSet {
            cachedVoice = AVSpeechSynthesisVoice(identifier: voiceIdentifier)
        }
    }

    // MARK: – Gong

    init() {
        preloadGong()
        warmUpSynthesizer()
        voiceIdentifier = AppSettings.defaultVoiceIdentifier
    }

    func playGong(enabled: Bool) {
        guard enabled else { return }
        activateSession()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    var gongDuration: TimeInterval {
        audioPlayer?.duration ?? 0
    }
    
    private func warmUpSynthesizer() {
        speakNow(text: " ", volume: 0.0)
    }
    
    // MARK: – TTS

    func speakAfterGong(text: String, enabled: Bool, gongEnabled: Bool) {
        guard enabled else { return }
        cancelPending()
        synthesizer.stopSpeaking(at: .immediate)
        pendingSpeechText = text
        let delay = gongEnabled ? gongDuration : 0
        let work  = DispatchWorkItem { [weak self] in
            self?.pendingSpeechText = nil
            self?.speakNow(text: text)
        }
        pendingSpeech = work
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        } else {
            work.perform()
        }
    }

    func speakNow(text: String, volume: Float = 1.0) {
        activateSession()
        synthesizer.stopSpeaking(at: .immediate)
        let utterance  = AVSpeechUtterance(string: text)
        utterance.volume = volume
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.voice = cachedVoice ?? AVSpeechSynthesisVoice(language: "en-US") ?? AVSpeechSynthesisVoice.speechVoices().first!
        synthesizer.speak(utterance)
    }

    // MARK: – Lifecycle

    func pause() {
        cancelPending()
        audioPlayer?.pause()
        synthesizer.pauseSpeaking(at: .immediate)
    }

    func resume() {
        synthesizer.continueSpeaking()
        if let text = pendingSpeechText {
            let work = DispatchWorkItem { [weak self] in
                self?.pendingSpeechText = nil
                self?.speakNow(text: text)
            }
            pendingSpeech = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        }
    }

    func stop() {
        cancelPending()
        pendingSpeechText = nil
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: – Private

    private func cancelPending() {
        pendingSpeech?.cancel()
        pendingSpeech = nil
    }

    private func activateSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false,
             options: .notifyOthersOnDeactivation)
    }
    
    private func preloadGong() {
        guard let url = Bundle.main.url(forResource: "gong", withExtension: "caf") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.prepareToPlay()
        audioPlayer?.volume = 1.0
    }
    
    func canCurrentVoiceSpeak(_ text: String) -> Bool {
        guard let voice = cachedVoice else { return true }

        // Japanese characters
        let japaneseScalars = CharacterSet(charactersIn: "\u{3040}"..."\u{9FFF}")
            .union(CharacterSet(charactersIn: "\u{30A0}"..."\u{30FF}"))

        let textScalars = text.unicodeScalars
        let hasOnlyJapaneseAndSpaces = textScalars.allSatisfy {
            japaneseScalars.contains($0) || CharacterSet.whitespaces.contains($0)
        }

        // english voice + japanese only text -> can't read
        if voice.language.hasPrefix("en"), hasOnlyJapaneseAndSpaces, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }

        return true
    }
}
