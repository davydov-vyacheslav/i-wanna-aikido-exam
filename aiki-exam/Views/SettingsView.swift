import SwiftUI

struct SettingsView: View {
    private let projectLink = "https://github.com/davydov-vyacheslav/i-wanna-aikido-exam"
    @EnvironmentObject private var settings: AppSettings

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
                                value: $settings.examCountTarget, in: 1...200)
                    case .time:
                        Stepper(".label.settings.exam.mode.time.stepper \(settings.examTimeMinutes)",
                                value: $settings.examTimeMinutes, in: 1...120)
                    }

                    Stepper(
                        ".label.settings.exam.interval \(settings.intervalSeconds)",
                        value: $settings.intervalSeconds,
                        in: 5...300,
                        step: 5)
                }

                Section(".title.settings.order") {
                    Toggle(".label.settings.profile.allow_randomize", isOn: $settings.randomize)
                    Toggle(".label.settings.profile.allow_repeat", isOn: $settings.allowRepeat)
                }

                Section(".title.settings.audio") {
                    Toggle(".label.settings.profile.allow_gong", isOn: $settings.soundEnabled)
                    Toggle(".label.settings.profile.allow_tts", isOn: $settings.ttsEnabled)
                        .disabled(!settings.soundEnabled)
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
        }
    }
}
