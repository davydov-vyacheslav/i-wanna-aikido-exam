//
//  ExamTimer.swift
//  aiki-exam
//
//  Created by Slava Davydov on 06.05.2026.
//

import Foundation

@MainActor
final class ExamTimers {

    var onAdvance:  (() -> Void)?
    var onProgress: ((Double) -> Void)?
    var onExamTick: (() -> Void)?

    private var progressTimer:  Timer?
    private var examClockTimer: Timer?
    private var progressStep:   Int = 0
    private var totalSteps:     Int = 0

    private let tickInterval: TimeInterval = 1
    
    // MARK: – Public

    func startAll(intervalSeconds: Int, includeExamClock: Bool) {
        totalSteps = Int(Double(intervalSeconds) / tickInterval)
        progressStep = totalSteps
        startProgressTimer()
        if includeExamClock { startExamClock() }
    }

    func stop() {
        stopProgressTimer()
        examClockTimer?.invalidate(); examClockTimer = nil
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func restartInterval(intervalSeconds: Int) {
        progressTimer?.invalidate()
        totalSteps   = Int(Double(intervalSeconds) / tickInterval)
        progressStep = totalSteps
        onProgress?(1.0)
        startProgressTimer()
    }

    func resumeTimers(intervalSeconds: Int, includeExamClock: Bool) {
        startProgressTimer()
        if includeExamClock { startExamClock() }
    }

    func resetProgress() {
        progressTimer?.invalidate()
        progressStep = totalSteps
        onProgress?(1.0)
        startProgressTimer()
    }

    // MARK: – Private

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.progressStep -= 1
                if self.progressStep <= 0 {
                    self.stopProgressTimer()
                    self.onProgress?(0)
                    self.onAdvance?()
                } else {
                    self.onProgress?(Double(self.progressStep) / Double(self.totalSteps))
                }
            }
        }
    }

    private func startExamClock() {
        examClockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.onExamTick?() }
        }
    }
}
