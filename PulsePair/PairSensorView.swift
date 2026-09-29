import LuciqSDK
import SwiftUI

struct PairSensorView: View {
    @Environment(SensorSimulator.self) private var sensor
    @State private var showLiveReading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 12) {
                    RadarView(active: sensor.state == .scanning || sensor.state == .connecting)
                    Text(statusText)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(detailText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .brandCard(padding: 20)

                sensorRow

                switch sensor.state {
                case .idle:
                    Button {
                        sensor.pair()
                    } label: {
                        Label("Scan for sensor", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(BrandButtonStyle())
                case .scanning, .connecting:
                    ProgressView()
                        .padding()
                case .connected:
                    Button {
                        showLiveReading = true
                    } label: {
                        Label("Open live reading", systemImage: "waveform.path.ecg")
                    }
                    .buttonStyle(BrandButtonStyle())
                    Button("Disconnect", role: .destructive) {
                        sensor.disconnect()
                    }
                    .buttonStyle(BrandButtonStyle(color: Brand.heart.opacity(0.14), foreground: Brand.heart))
                }
            }
            .padding()
        }
        .background(Brand.canvas.ignoresSafeArea())
        .navigationTitle("Pair sensor")
        .navigationDestination(isPresented: $showLiveReading) {
            LuciqTracedView(name: "Live reading") { LiveReadingView() }
        }
        .onChange(of: sensor.state) { _, newState in
            if newState == .connected { showLiveReading = true }
        }
    }

    private var sensorRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.text.square.fill")
                .font(.title2)
                .foregroundStyle(Brand.heart)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.heart.opacity(0.12)))
            VStack(alignment: .leading, spacing: 3) {
                Text(sensor.sensorName)
                    .font(.headline)
                Text("Bluetooth heart-rate sensor")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 5) {
                Circle()
                    .fill(sensor.state == .connected ? Color.green : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(stateLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .brandCard(padding: 14)
    }

    private var statusText: String {
        switch sensor.state {
        case .idle: "No sensor connected"
        case .scanning: "Scanning for nearby sensors…"
        case .connecting: "Connecting to \(sensor.sensorName)…"
        case .connected: "Connected to \(sensor.sensorName)"
        }
    }

    private var detailText: String {
        switch sensor.state {
        case .idle: "Wake the sensor, then scan to find it over Bluetooth."
        case .scanning: "Keep the sensor within a metre of your phone."
        case .connecting: "Exchanging keys and starting the heart-rate stream."
        case .connected: "Streaming one reading a second."
        }
    }

    private var stateLabel: String {
        switch sensor.state {
        case .idle: "Not paired"
        case .scanning: "Searching"
        case .connecting: "Pairing"
        case .connected: "Connected"
        }
    }
}
