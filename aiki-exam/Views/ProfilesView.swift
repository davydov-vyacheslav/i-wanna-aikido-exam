import SwiftUI
import SwiftData

// MARK: – ProfilesView

struct ProfilesView: View {
    @Environment(\.modelContext) private var ctx
    @EnvironmentObject private var settings: AppSettings
    @Query(
        filter: #Predicate<Profile> { !$0.isPreset },
        sort: \Profile.createdAt) private var profiles: [Profile]
    @Query(
        filter: #Predicate<Profile> { $0.isPreset },
        sort: \Profile.createdAt) private var presets: [Profile]

    var body: some View {
        NavigationStack {
            List {
                // Presents Profiles
                Section(header: Text(".title.profiles.presets")) {
                    ForEach(presets) { preset in
                        NavigationLink(destination: ProfileDetailView(profile: preset)) {
                            ProfileRow(profile: preset, isActive: preset.id == settings.activeProfileID)
                        }
                    }
                }

                // User Profiles
                Section(header: Text(".title.profiles.user")) {
                    ForEach(profiles) { profile in
                        NavigationLink(destination: ProfileDetailView(profile: profile)) {
                            ProfileRow(profile: profile, isActive: profile.id == settings.activeProfileID)
                        }
                    }
                    .onDelete(perform: deleteProfiles)
                }
            }
            .navigationTitle(".title.profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileWizardView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for i in offsets {
            let p = profiles[i]
            if p.id == settings.activeProfileID {
                settings.activeProfileID = profiles.first(where: { $0.id != p.id })?.id
            }
            ctx.delete(p)
        }
    }
}

// MARK: – UserProfileRow

private struct ProfileRow: View {
    let profile: Profile
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.subheadline)
                Text(".label.profile.technics_count \(profile.technics.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: – ProfileDetailView

struct ProfileDetailView: View {
    @Bindable var profile: Profile
    @Environment(\.modelContext) private var ctx
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showBulkAdd = false

    var body: some View {
        List {
            let isCurrent = (settings.activeProfileID == profile.id)
            // Stats
            Section {
                ProfileRow(profile: profile, isActive: isCurrent)
            }

            // Quick actions
            Section {
                if !isCurrent {
                    Button(action: { settings.activeProfileID = profile.id }) {
                        Label(".button.profile.set_current", systemImage: "checkmark.circle")
                    }
                }
                Button(action: cloneAndDismiss) {
                    Label(".button.profile.clone", systemImage: "doc.on.doc")
                }
            }

            // Technique list (editable)
            Section(header: Text(".title.profile.technics")) {
                if profile.isPreset {
                    ForEach(profile.technics) { tc in
                        TechnicRow(tc: tc)
                    }
                } else {
                    ForEach(profile.technics) { tc in
                        TechnicRow(tc: tc)
                    }
                    .onDelete(perform: deleteTechnics)
                }
            }

            if !profile.isPreset {
                
                Section {
                    Button(action: { showBulkAdd = true }) {
                        Label(".button.profile.add_technics", systemImage: "plus.circle")
                    }
                }

                Section {
                    Button(role: .destructive, action: deleteAndDismiss) {
                        Label(".button.profile.delete", systemImage: "trash") // TODO: alert 'are you  sure'
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle(profile.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showBulkAdd) {
            ProfileWizardView(targetProfile: profile)
        }
    }

    // MARK: – Actions

    private func deleteTechnics(at offsets: IndexSet) {
        var t = profile.technics
        t.remove(atOffsets: offsets)
        profile.technics = t
    }

    private func cloneAndDismiss() {
        let cloned = profile.clone(name: String(localized: ".label.profile.copiedFrom \(profile.name)"))
        ctx.insert(cloned)
        dismiss()
    }

    private func deleteAndDismiss() {
        if settings.activeProfileID == profile.id {
            settings.activeProfileID = nil
        }
        ctx.delete(profile)
        dismiss()
    }
}

// MARK: – TechnicRow

struct TechnicRow: View {
    let tc: TechnicItem

    var body: some View {
        HStack(spacing: 8) {
            Text(MasterPositions.init(rawValue: tc.positionKey)!.l10n)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.secondary)
                .font(.callout)
            Text(MasterAttacks.init(rawValue: tc.attackKey)!.l10n)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.callout)
            Text(MasterTechnics.init(rawValue: tc.techniqueKey)!.l10n)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(.red)
                .font(.callout)
        }
        .padding(.vertical, 2)
    }
}

struct ProfileWizardView: View {
    var targetProfile: Profile? = nil
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selPositions:  Set<MasterPositions> = []
    @State private var selAttacks:    Set<MasterAttacks> = []
    @State private var selTechniques: Set<MasterTechnics> = []

    private var isAddMode: Bool { targetProfile != nil }
    
    private var newCombos: Int {
        let existingKeys: Set<String> = isAddMode
            ? Set(targetProfile!.technics.map { "\($0.positionKey)|\($0.attackKey)|\($0.techniqueKey)" })
            : []
        var count = 0
        for p in selPositions {
            for a in selAttacks {
                for t in selTechniques where !existingKeys.contains("\(p.rawValue)|\(a.rawValue)|\(t.rawValue)") {
                    count += 1
                }
            }
        }
        return count
    }

    private var canConfirm: Bool {
        isAddMode ? newCombos > 0 : (!name.isEmpty && newCombos > 0)
    }

    var body: some View {
        let listView = List {
            if !isAddMode {
                Section {
                    TextField(".placeholder.profile.name", text: $name)
                        .font(.body)
                }
            }
            Section(".title.profile.creation.positions") {
                ChipPicker(all: Array(MasterPositions.allCases), selected: $selPositions)
            }
            Section(".title.profile.creation.attacks") {
                ChipPicker(all: Array(MasterAttacks.allCases), selected: $selAttacks)
            }
            Section(".title.profile.creation.techniques") {
                ChipPicker(all: Array(MasterTechnics.allCases), selected: $selTechniques)
            }
            Section(".title.profile.creation.summary") {
                Text(
                    isAddMode
                        ? LocalizedStringKey(".label.profile.technics.new_combinations \(newCombos)")
                        : LocalizedStringKey(".label.profile.technics.total_combinations \(newCombos)")
                )
                .foregroundColor(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button(".button.profile.creation.cancel", action: { dismiss() })
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button(isAddMode
                       ? ".button.profile.creation.add"
                       : ".button.profile.creation.create", action: confirm)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canConfirm)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.bar)
            
        }

        if isAddMode {
            NavigationStack {
                listView
                    .navigationTitle(".title.profile.add_technics")
                    .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            listView
        }
    }

    private func confirm() {
        let items = buildItems()
        if let profile = targetProfile {
            let existingKeys = Set(profile.technics.map { "\($0.positionKey)|\($0.attackKey)|\($0.techniqueKey)" })
            let toAdd = items.filter { !existingKeys.contains("\($0.positionKey)|\($0.attackKey)|\($0.techniqueKey)") }
            profile.technics.append(contentsOf: toAdd)
        } else {
            ctx.insert(Profile(name: name, technics: items, isPreset: false))
        }
        dismiss()
    }

    private func buildItems() -> [TechnicItem] {
        var items: [TechnicItem] = []
        for p in selPositions {
            for a in selAttacks {
                for t in selTechniques {
                    items.append(TechnicItem(positionKey: p.rawValue, attackKey: a.rawValue, techniqueKey: t.rawValue))
                }
            }
        }
        return items
    }

    private func create() {
        let profile = fromCartesian(
            name: name,
            positions:  Array(selPositions),
            attacks:    Array(selAttacks),
            techniques: Array(selTechniques)
        )
        ctx.insert(profile)
        dismiss()
    }
    
    /// Build a profile from Cartesian product of key-lists.
    func fromCartesian(
        name: String,
        positions: [MasterPositions],
        attacks: [MasterAttacks],
        techniques: [MasterTechnics]
    ) -> Profile {
        var items: [TechnicItem] = []
        for p in positions {
            for a in attacks {
                for t in techniques {
                    items.append(TechnicItem(positionKey: p.rawValue, attackKey: a.rawValue, techniqueKey: t.rawValue))
                }
            }
        }
        return Profile(name: name, technics: items, isPreset: false)
    }
}


// MARK: – ChipPicker

private struct ChipPicker<Option: ChipOption>: View {
    let all: [Option]
    @Binding var selected: Set<Option>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(".button.selectAll") { selected = Set(all) }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.borderless)
                Text(".label.profile.select_buttons_separator").foregroundColor(.secondary)
                Button(".button.deselectAll") { selected = [] }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.borderless)
            }
            FlowLayout(spacing: 8) {
                ForEach(all, id: \.self) { option in
                    Chip(label: option.l10n, isSelected: selected.contains(option)) {
                        if selected.contains(option) { selected.remove(option) }
                        else { selected.insert(option) }
                    }
                }
            }
        }
    }
}

private struct Chip: View {
    let label: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.green.opacity(0.7) : Color.secondary.opacity(0.5))
                .foregroundColor(isSelected ? Color.primary : Color.primary)
                .cornerRadius(20)
        }
        .animation(.spring(response: 0.2), value: isSelected)
        .buttonStyle(.borderless)
    }
}

// MARK: – FlowLayout (wrapping chip grid)

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        for (i, pos) in result.positions.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private struct Result { var size: CGSize; var positions: [CGPoint] }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> Result {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0; var y: CGFloat = 0; var rowH: CGFloat = 0
        var positions: [CGPoint] = []
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxW, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            x += s.width + spacing
            rowH = max(rowH, s.height)
        }
        return Result(size: CGSize(width: maxW, height: y + rowH), positions: positions)
    }
}


