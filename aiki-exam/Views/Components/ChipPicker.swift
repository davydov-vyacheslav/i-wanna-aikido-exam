//
//  ChipPicker.swift
//  aiki-exam
//
//  Created by Slava Davydov on 01.03.2026.
//

import SwiftUI

struct ChipPicker: View {
    let items: [VocabularyItem]
    @Binding var selectedKeys: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button(".button.selectAll") { selectedKeys = Set(items.map(\.key)) }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.borderless)
                Text(".label.profile.select_buttons_separator").foregroundColor(.secondary)
                Button(".button.deselectAll") { selectedKeys = [] }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .buttonStyle(.borderless)
            }
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.id) { item in
                    let selected = selectedKeys.contains(item.key)
                    Chip(label: LocalizedStringKey(item.displayName), isSelected: selected) {
                        if selected { selectedKeys.remove(item.key) }
                        else        { selectedKeys.insert(item.key) }
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
                .background(isSelected ? Color.green.opacity(0.7) : Color.secondary.opacity(0.25))
                .foregroundColor(.primary)
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
