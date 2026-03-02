import SwiftUI
import SwiftData

struct SettingsView: View {

    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]
    private let projectLink = "https://github.com/davydov-vyacheslav/i-wanna-aikido-exam"
    
    var body: some View {
        NavigationStack {
            Form {

                // Active Profile
                Section(header: Text(".title.settings.profile")) {
                    Picker(".label.settings.profile.current", selection: $settings.activeProfileID) {
                        ForEach(profiles) { p in
                            Text(p.name)
                                .tag(Optional(p.id))
                        }
                    }
                    .pickerStyle(.menu)

                    // Feasibility warning when profile is selected but incompatible
                    if let cantUseReason = settings.cantStartReason(profile: activeProfile) {
                        Label {
                            Text(cantUseReason)
                                .font(.footnote)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                        .foregroundColor(.orange)
                    }

                    Toggle(".label.settings.profile.allow_repeat", isOn: $settings.allowRepeat)
                    Toggle(".label.settings.profile.allow_sound", isOn: $settings.soundEnabled)
                    Toggle(".label.settings.profile.allow_randomize", isOn: $settings.randomize)
                    
                }

                // Exam Mode
                Section(header: Text(".title.settings.exam.mode")) {
                    Picker(".label.settings.exam_mode", selection: $settings.examMode) {
                        Text(".label.settings.exam.mode.count").tag(ExamMode.count)
                        Text(".label.settings.exam.mode.time").tag(ExamMode.time)
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

                    if settings.examMode == .count {
                        Stepper(
                            ".label.settings.exam.mode.count.stepper \(settings.examCountTarget)",
                            value: $settings.examCountTarget,
                            in: 1...200,
                            step: 1
                        )
                    } else {
                        Stepper(
                            ".label.settings.exam.mode.time.stepper \(settings.examTimeMinutes)",
                            value: $settings.examTimeMinutes,
                            in: 1...120,
                            step: 1
                        )
                    }

                    Stepper(
                        ".label.settings.exam.interval \(settings.intervalSeconds)",
                        value: $settings.intervalSeconds,
                        in: 5...120,
                        step: 5
                    )
                }

                // About Section
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

    // MARK: – Helpers

    private var activeProfile: Profile {
        profiles.first { $0.id == settings.activeProfileID } ?? profiles[0]
    }

}
