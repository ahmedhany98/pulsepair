import Foundation
import os

struct HeartRateCalibration {
    let channelOffsets: [Int]

    func offset(forChannel channel: Int) -> Int {
        channelOffsets[channel]
    }
}

enum SensorReadingError: LocalizedError {
    case outOfRange(bpm: Int)

    var errorDescription: String? {
        switch self {
        case .outOfRange(let bpm): "Sensor reported an impossible heart rate of \(bpm) bpm."
        }
    }
}

@MainActor
enum ChaosActions {
    static let logger = Logger(subsystem: "com.pulsepair.companion", category: "chaos")
    private static var hoard: [UnsafeMutableRawPointer] = []

    static func crash() {
        let calibration = HeartRateCalibration(channelOffsets: [])
        let offset = calibration.offset(forChannel: Int.random(in: 1...4))
        logger.error("Unreachable offset \(offset)")
    }

    static func handledError() -> String {
        do {
            try validate(bpm: 412)
            return "Reading accepted"
        } catch {
            logger.error("Handled error: \(error.localizedDescription, privacy: .public)")
            LuciqSetup.reportNonFatal(error)
            return "Caught and reported as non-fatal: \(error.localizedDescription)"
        }
    }

    static func validate(bpm: Int) throws {
        guard (30...220).contains(bpm) else { throw SensorReadingError.outOfRange(bpm: bpm) }
    }

    static func call(_ path: String) async -> String {
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let status = try await API.status(path)
            let elapsed = start.duration(to: clock.now)
            return "GET \(path) → HTTP \(status) in \(elapsed.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow)))"
        } catch {
            return "GET \(path) failed: \(error.localizedDescription)"
        }
    }

    static func freeze() {
        Thread.sleep(forTimeInterval: 5)
    }

    static func memoryHog(report: @escaping (String) -> Void) {
        Task {
            let chunk = 50 * 1024 * 1024
            var allocatedMB = 0
            while true {
                #if targetEnvironment(simulator)
                if allocatedMB >= 3072 {
                    report("Stopped at 3 GB: the simulator doesn't enforce iOS memory limits. Use a real device to see the OS kill the app.")
                    return
                }
                #endif
                let block = UnsafeMutableRawPointer.allocate(byteCount: chunk, alignment: 16)
                block.initializeMemory(as: UInt8.self, repeating: 0xAB, count: chunk)
                hoard.append(block)
                allocatedMB += 50
                if allocatedMB % 500 == 0 { report("Allocated \(allocatedMB) MB") }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
}
