import SwiftUI
import SwiftData

struct ExamView: View {

    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = ExamViewModel(settings: .shared)
    @Query private var profiles: [Profile]

    private var activeProfile: Profile? {
        guard let id = settings.activeProfileID else { return nil }
        return profiles.first { $0.id == id }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Exam status strip
                HStack {
                    // Profile name
                    if let profile = activeProfile {
                        Label(profile.name, systemImage: "person.crop.rectangle")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    // State indicator
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: vm.state)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Feasibility warning
                if let profile = activeProfile, !settings.canStart(profile: profile) {
                    warnBanner(profile: profile)
                }

                // Progress bar (exam-level)
                if vm.state != .idle {
                    examProgressBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                Spacer()

                // Technique cards or idle placeholder
                Group {
                    if let t = vm.currentTechnic {
                        VStack(spacing: 12) {
                            TechCard(label: ".label.exam.card.position", value: MasterPositions(rawValue: t.positionKey)!.l10n)
                            TechCard(label: ".label.exam.card.attack", value: MasterAttacks(rawValue: t.attackKey)!.l10n)
                            TechCard(label: ".label.exam.card.techniq", value: MasterTechnics(rawValue: t.techniqueKey)!.l10n)
                        }

                    } else {
                        VStack(spacing: 16) {
                            Text(".label.exam.aiki")
                                .font(.system(size: 80, design: .serif))
                                .opacity(0.12)
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // Timer bar (inter-technique)
                if vm.state == .running {
                    timerBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)
                }

                // Controls
                Group {
                    if vm.state == .running {
                        HStack(spacing: 12) {
                            ExamButton(
                                icon:    "pause.fill",
                                label:   ".button.exam.pause",
                                enabled: true
                            ) { vm.pause() }

                            ExamButton(
                                icon:    "forward.end.fill",
                                label:   ".button.exam.skip",
                                enabled: vm.canSkipNow
                            ) { vm.skip() }
                        }
                    } else {
                        ExamButton(
                            icon:    "play.fill",
                            label:   ".button.exam.start",
                            enabled: vm.isFeasible && vm.state != .finished
                        ) { vm.start() }
                    }
                }
            }

            // Finish overlay
            if vm.state == .finished {
                finishOverlay
            }
        }
        .navigationBarHidden(true)
        .onChange(of: settings.activeProfileID) { _, _ in
            vm.bind(profile: activeProfile)
        }
        .onAppear {
            vm.bind(profile: activeProfile)
        }
    }

    // MARK: – Sub-views

    private var stateColor: Color { // FIXME: extension of ExamState
        switch vm.state {
        case .idle:     return Color.secondary.opacity(0.5)
        case .running:  return .red
        case .paused:   return .orange
        case .finished: return .green
        }
    }

    private func warnBanner(profile: Profile) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(".error.exam.notEnoughTechniques \(profile.technics.count) \(vm.requiredTechniquesForTimedNoRepeat)")
                .font(.body)
        }
        .padding(10)
        .background(Color.red.opacity(0.08))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var examProgressBar: some View {
        VStack(spacing: 4) {
            HStack {
                if settings.examMode == .count {
                    Text(".label.exam.statistics \(vm.doneCount) \(settings.examCountTarget)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                } else {
                    Text(timedProgressLabel)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if vm.skippedCount > 0 {
                    Image(systemName: "chevron.forward.2")
                        .font(.footnote)
                        .foregroundColor(.orange)
                    Text("\(vm.skippedCount)")
                        .font(.footnote)
                        .foregroundColor(.orange)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 4)
                    Capsule()
                        .fill(settings.examMode == .count ? Color.green : Color.blue)
                        .frame(width: geo.size.width * vm.examProgress, height: 4)
                        .animation(.easeOut(duration: 0.4), value: vm.examProgress)
                }
            }
            .frame(height: 4)
        }
    }

    private var timedProgressLabel: String {
        let elapsed = vm.examElapsed
        let total   = settings.examTimeMinutes * 60
        let rem     = max(0, total - elapsed)
        let m = rem / 60; let s = rem % 60
        return String(format: "%d:%02d", m, s)
    }

    private var timerBar: some View {
        VStack(spacing: 3) {
            HStack {
                Text(".label.exam.time.left")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Text(".label.exam.time.left.sec \(Int(ceil(vm.timerProgress * Double(settings.intervalSeconds))))")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15)).frame(height: 3)
                    Capsule()
                        .fill(Color.red)
                        .frame(width: geo.size.width * vm.timerProgress, height: 3)
                        .animation(.linear(duration: 0.1), value: vm.timerProgress)
                }
            }
            .frame(height: 3)
        }
    }

    // MARK: – Finish overlay

    private var finishOverlay: some View {
        ZStack {
            Color(.secondarySystemBackground).opacity(0.96).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(".label.exam.aiki").font(.system(size: 80, design: .serif)).foregroundColor(.red)
                Text(".label.exam.finished")
                    .font(.title2)
                Text(".label.exam.done.statistics \(vm.doneCount)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                Button(".button.exam.reset") { vm.reset() }
                    .font(.callout)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .cornerRadius(13)

            }
        }
    }
}

// MARK: – TechCard

private struct TechCard: View {
    let label: String
    let value: LocalizedStringKey

    var body: some View {
        Text(value)
            .font(.title)
            .foregroundColor(.primary)
            .lineLimit(2)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: – ExamButton

private struct ExamButton: View {
    let icon:    String
    let label:   LocalizedStringKey
    let enabled: Bool
    let action:  () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title)
                Text(label)
                    .font(.title)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .cornerRadius(13)
        }
        .disabled(!enabled)
        .tint(.red)
    }

}
