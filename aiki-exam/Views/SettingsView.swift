import SwiftUI
import AVFAudio
import SwiftData

struct SettingsView: View {
    private let projectLink = "https://github.com/davydov-vyacheslav/i-wanna-aikido-exam"
    @EnvironmentObject private var settings: AppSettings
    @Query private var profiles: [Profile]
    @State private var availableVoices: [AVSpeechSynthesisVoice] = []

    var body: some View {
        NavigationStack {
            Form {
                Section(".title.settings.exam.mode") {
                    Picker(".label.settings.exam_mode", selection: $settings.examMode) {
                        ForEach(ExamMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch settings.examMode {
                    case .count:
                        Stepper(".label.settings.exam.mode.count.stepper \(settings.examCountTarget)",
                                value: $settings.examCountTarget, in: 1...maxAllowedCount)
                    case .time:
                        Stepper(".label.settings.exam.mode.time.stepper \(settings.examTimeMinutes)",
                                value: $settings.examTimeMinutes, in: maxAllowedMinutes...120)
                    }

                    Stepper(
                        ".label.settings.exam.interval \(settings.intervalSeconds)",
                        value: $settings.intervalSeconds,
                        in: 5...maxAllowedInterval,
                        step: 5)
                }

                Section(".title.settings.order") {
                    Toggle(".label.settings.profile.allow_randomize", isOn: $settings.randomize)
                    Toggle(".label.settings.profile.allow_repeat", isOn: $settings.allowRepeat)
                }

                Section(".title.settings.audio") {
                    Toggle(".label.settings.profile.allow_gong", isOn: $settings.soundEnabled)
                    Toggle(".label.settings.profile.allow_tts", isOn: $settings.ttsEnabled)
                    Picker(".label.settings.profile.voice", selection: $settings.voiceIdentifier) {
                        ForEach(availableVoices, id: \.identifier) { voice in
                            Text("\(voice.name) (\(voice.language))").tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Button {
                        ExamAudio.shared.voiceIdentifier = settings.voiceIdentifier
                        ExamAudio.shared.speakNow(text: "はんみはんだち肩取り面打ちいりみなげ")
                    } label: {
                        Label(".label.settings.voice.preview", systemImage: "speaker.wave.2")
                    }
                    
                    if settings.voiceIdentifier != AppSettings.defaultVoiceIdentifier {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle").foregroundColor(.blue)
                            Text("For best pronunciation, download and select **Otoya (Enhanced)** (Japanese) in iOS Settings → Accessibility → Spoken Content → Voices → Japanese")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(".label.settings.about") {
                    HStack {
                        Text(".label.settings.version")
                        Spacer()
                        Text(verbatim: SettingsService.version)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: projectLink)!) {
                            HStack {
                                Label(".label.settings.github", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                }
            }
            .navigationTitle(".title.settings")
            .onChange(of: settings.allowRepeat) { _, canRepeat in
                if !canRepeat, let p = activeProfile {
                    settings.examCountTarget = min(settings.examCountTarget, p.technics.count)
                } else {
                    
                }
            }
            .onChange(of: settings.activeProfileID) { _, _ in
                if !settings.allowRepeat, let p = activeProfile {
                    settings.examCountTarget = min(settings.examCountTarget, p.technics.count)
                }
            }
            .onChange(of: settings.examMode) { _, mode in
                if mode == .time {
                    settings.intervalSeconds = min(settings.intervalSeconds, maxAllowedInterval)
                }
            }
            .onAppear {
                Task.detached(priority: .userInitiated) {
                    let fallback = AVSpeechSynthesisVoice(language: "en-US")
                    let voices = AVSpeechSynthesisVoice.speechVoices()
                        .filter { $0.language.hasPrefix("ja") }
                        + (fallback.map { [$0] } ?? [])
                    await MainActor.run { self.availableVoices = voices }
                }
            }
        }
    }
    
    private var activeProfile: Profile? {
        profiles.first { $0.id == settings.activeProfileID } ?? profiles.first
    }
    
    private var maxAllowedCount: Int {
        guard !settings.allowRepeat, let p = activeProfile else { return 200 }
        return p.technics.count
    }

    private var maxAllowedMinutes: Int {
        Int(ceil(Double(settings.intervalSeconds) / 60.0))
    }

    private var maxAllowedInterval: Int {
        settings.examMode == .time ? min(settings.examTimeMinutes * 60, 300) : 300
    }
    
}
