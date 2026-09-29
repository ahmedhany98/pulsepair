import SwiftUI

struct PairSensorView: View {
    @Environment(SensorSimulator.self) private var sensor
    @State private var showLiveReading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolEffect(.variableColor.iterative, isActive: sensor.state == .scanning)
            Text(statusText)
                .font(.headline)
                .multilineTextAlignment(.center)
            switch sensor.state {
            case .idle:
                Button("Scan for sensor") { sensor.pair() }
                    .buttonStyle(.borderedProminent)
            case .scanning, .connecting:
                ProgressView()
            case .connected:
                Button("Open live reading") { showLiveReading = true }
                    .buttonStyle(.borderedProminent)
                Button("Disconnect", role: .destructive) { sensor.disconnect() }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Pair sensor")
        .navigationDestination(isPresented: $showLiveReading) { LiveReadingView() }
        .onChange(of: sensor.state) { _, newState in
            if newState == .connected { showLiveReading = true }
        }
    }

    private var statusText: String {
        switch sensor.state {
        case .idle: "No sensor connected"
        case .scanning: "Scanning for nearby sensors…"
        case .connecting: "Connecting to \(sensor.sensorName)…"
        case .connected: "Connected to \(sensor.sensorName)"
        }
    }
}
