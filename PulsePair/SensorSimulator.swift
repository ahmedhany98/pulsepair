import Foundation
import Observation

@MainActor
@Observable
final class SensorSimulator {
    enum State {
        case idle, scanning, connecting, connected
    }

    struct Reading: Identifiable {
        let id = UUID()
        let date: Date
        let bpm: Int
    }

    let sensorName = "PulsePair HR-200"
    private(set) var state: State = .idle
    private(set) var readings: [Reading] = []
    private var stream: Task<Void, Never>?

    var currentBPM: Int? { readings.last?.bpm }

    var lastMinute: [Reading] {
        let cutoff = Date().addingTimeInterval(-60)
        return readings.filter { $0.date >= cutoff }
    }

    var summary: String {
        guard !readings.isEmpty else { return "No readings yet. Pair a sensor to record a session." }
        let values = readings.map(\.bpm)
        let average = values.reduce(0, +) / values.count
        return "\(values.count) readings from \(sensorName): average \(average) bpm, min \(values.min()!), max \(values.max()!)."
    }

    func pair() {
        guard state == .idle else { return }
        state = .scanning
        stream = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            state = .connecting
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            state = .connected
            readings = []
            var bpm = 72
            while !Task.isCancelled {
                bpm = min(150, max(55, bpm + Int.random(in: -3...3)))
                readings.append(Reading(date: Date(), bpm: bpm))
                if readings.count > 3600 {
                    readings.removeFirst(readings.count - 3600)
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func disconnect() {
        stream?.cancel()
        stream = nil
        state = .idle
    }
}
