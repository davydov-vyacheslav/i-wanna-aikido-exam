//
//  ExamQueue.swift
//  aiki-exam
//
//  Created by Slava Davydov on 06.05.2026.
//

import Foundation

struct ExamQueue {

    private let profile: Profile
    private let settings: AppSettings
    
    /// IDs excluded from pool: completed + skipped (used when allowRepeat = false).
    private var usedIDs: Set<String> = []
    
    /// Ordered queue used when allowRepeat = true && randomize = false.
    /// Completed and skipped items are appended to the end.
    private var orderedQueue: [TechnicItem] = []

    init(profile: Profile, settings: AppSettings) {
        self.profile  = profile
        self.settings = settings
        if settings.allowRepeat && !settings.randomize {
            orderedQueue = Array(profile.technics)
        }
    }

    mutating func markDone(_ item: TechnicItem) {
        if settings.allowRepeat && !settings.randomize {
            orderedQueue.append(item)
        } else {
            usedIDs.insert(item.id)
        }
    }

    mutating func markSkipped(_ item: TechnicItem) {
        if settings.allowRepeat && !settings.randomize {
            orderedQueue.append(item)
        } else {
            usedIDs.insert(item.id)
        }
    }

    /// Returns the next technique to display.
    /// Routing logic:
    ///   - allowRepeat=true, randomize=false → pop from front of orderedQueue
    ///   - allowRepeat=true, randomize=true  → random from full profile pool (excluding `exclude`)
    ///   - allowRepeat=false, randomize=true → random from unseen pool
    ///   - allowRepeat=false, randomize=false → first of unseen pool (original insertion order)
    mutating func dequeueNext(excluding exclude: TechnicItem? = nil) -> TechnicItem? {
        if settings.allowRepeat && !settings.randomize {
            guard !orderedQueue.isEmpty else { return nil }
            let item = orderedQueue.removeFirst()
            if let ex = exclude, item.id == ex.id {
                orderedQueue.append(item)
                return orderedQueue.isEmpty ? nil : orderedQueue.removeFirst()
            }
            return item
        }
        var candidates = availablePool()
        if let ex = exclude { candidates = candidates.filter { $0.id != ex.id } }
        return settings.randomize ? candidates.randomElement() : candidates.first
    }

    /// Returns the pool of candidates eligible for selection.
    /// When allowRepeat=false, excludes items already in usedIDs (done + skipped).
    func availablePool(excluding exclude: TechnicItem? = nil) -> [TechnicItem] {
        var base = profile.technics
        if !settings.allowRepeat { base = base.filter { !usedIDs.contains($0.id) } }
        if let ex = exclude      { base = base.filter { $0.id != ex.id } }
        return base
    }

    var isExhausted: Bool {
        !settings.allowRepeat && availablePool().isEmpty
    }

    func canSkip(current: TechnicItem, remainingExamSeconds: Int) -> Bool {
        if settings.allowRepeat && !settings.randomize { return !orderedQueue.isEmpty }
        let pool = availablePool(excluding: current)
        guard !pool.isEmpty else { return false }
        if settings.examMode == .time, !settings.allowRepeat {
            return settings.canSkip(remainingSeconds: remainingExamSeconds, poolSizeAfterSkip: pool.count)
        }
        return true
    }
}
