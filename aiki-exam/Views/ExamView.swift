import SwiftUI
import SwiftData

struct ExamView: View {

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var vocabStore: VocabularyStore
    @StateObject private var vm = ExamViewModel(settings: .shared)
    @Query private var profiles: [Profile]

    private var activeProfile: Profile? {
        profiles.first { $0.id == settings.activeProfileID } ?? profiles.first
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                statusStrip
                if let profile = activeProfile, let reason = settings.cantStartReason(profile: profile) {
                    warnBanner(reason: reason)
                }
                if vm.state != .idle { examProgressBar.padding(.horizontal, 20).padding(.top, 8) }

                Spacer()
                techniqueDisplay.padding(.horizontal, 20)
                Spacer()

                if vm.state == .running {
                    timerBar.padding(.horizontal, 20).padding(.bottom, 6)
                }
                controls
            }
            if vm.state == .finished { finishOverlay }
        }
        .navigationBarHidden(true)
        .onChange(of: settings.activeProfileID) { _, _ in rebind() }
        .onAppear { rebind() }
    }

    // MARK: – Bind / resolver

    private func rebind() {
        vm.nameResolver = { [vocabStore] key, type in vocabStore.displayName(for: key, type: type) }
        vm.bind(profile: activeProfile)
    }

    // MARK: – Sub-views

    private var statusStrip: some View {
        HStack {
            if let profile = activeProfile {
                Label(profile.name, systemImage: "person.crop.rectangle")
                    .font(.footnote).foregroundColor(.secondary)
            }
            Spacer()
            Circle().fill(vm.state.color).frame(width: 8, height: 8)
        }
        .padding(.horizontal, 20).padding(.top, 8)
    }

    private func warnBanner(reason: LocalizedStringKey) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(reason)
                .font(.body)
        }
        .padding(10)
        .background(Color.red.opacity(0.08))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var techniqueDisplay: some View {
        if let t = vm.currentTechnic {
            VStack(spacing: 12) {
                TechCard(value: vocabStore.displayName(for: t.positionKey,  type: .position))
                TechCard(value: vocabStore.displayName(for: t.attackKey,    type: .attack))
                TechCard(value: vocabStore.displayName(for: t.techniqueKey, type: .technique))
            }
        } else {
            Text(".label.exam.aiki")
                .font(.system(size: 80, design: .serif)).opacity(0.12)
        }
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
        let rem = max(0, settings.examTimeMinutes * 60 - vm.examElapsed)
        return String(format: "%d:%02d", rem / 60, rem % 60)
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

    @ViewBuilder
    private var controls: some View {
        switch vm.state {
        case .running:
            HStack(spacing: 12) {
                ExamButton(icon: "pause.fill",      label: ".button.exam.pause",  enabled: true)           { vm.pause() }
                ExamButton(icon: "forward.end.fill", label: ".button.exam.skip", enabled: vm.canSkipNow)  { vm.skip() }
            }
        case .paused:
            VStack(spacing: 8) {
                ExamButton(icon: "play.fill", label: ".button.exam.continue", enabled: true) { vm.start() }
                Button(role: .destructive) { vm.forceFinish() } label: {
                    Label(".button.exam.finish", systemImage: "stop.fill")
                        .font(.callout).frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .tint(.orange)
            }
        case .idle:
            ExamButton(icon: "play.fill", label: ".button.exam.start", enabled: vm.isFeasible) { vm.start() }
        case .finished:
            EmptyView()
        }
    }

    private var finishOverlay: some View {
        ZStack {
            Color(.secondarySystemBackground).opacity(0.96).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(".label.exam.aiki")
                    .font(.system(size: 80, design: .serif)).foregroundColor(.red)
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
    let value: String
    var body: some View {
        Text(value)
            .font(.largeTitle)
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

extension ExamState {
    var color: Color {
        switch self {
        case .idle:     return Color.secondary.opacity(0.5)
        case .running:  return .red
        case .paused:   return .orange
        case .finished: return .green
        }
    }
}
