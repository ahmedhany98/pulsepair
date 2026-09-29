import Charts
import SwiftUI

struct LiveReadingView: View {
    @Environment(SensorSimulator.self) private var sensor

    private let alertThreshold = 120

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                bpmCard
                if let bpm = sensor.currentBPM, bpm >= alertThreshold {
                    alertBanner(bpm)
                }
                chartCard
                statsCard
                Text(sensor.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
        .background(Brand.canvas.ignoresSafeArea())
        .navigationTitle("Live reading")
    }

    private var bpmCard: some View {
        let bpm = sensor.currentBPM
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(sensor.state == .connected ? Color.green : Color.white.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text(sensor.sensorName)
                }
                .font(.subheadline.weight(.medium))
                .opacity(0.9)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(bpm.map(String.init) ?? "--")
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("bpm")
                        .font(.title3.weight(.semibold))
                        .opacity(0.85)
                }
                if let bpm {
                    Text(Brand.zoneName(for: bpm))
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.22)))
                }
            }
            Spacer()
            Image(systemName: "heart.fill")
                .font(.system(size: 66))
                .symbolEffect(.pulse, isActive: sensor.state == .connected)
                .symbolEffect(.bounce, value: sensor.readings.count)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Brand.heroGradient))
        .shadow(color: Brand.heart.opacity(0.35), radius: 18, y: 10)
        .animation(.snappy, value: bpm)
    }

    private func alertBanner(_ bpm: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.heart.fill")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("High heart rate")
                    .font(.headline)
                Text("\(bpm) bpm is above the \(alertThreshold) bpm alert threshold.")
                    .font(.caption)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Brand.amber.gradient))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last minute")
                    .font(.headline)
                Spacer()
                Text("1 reading / sec")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Chart {
                RuleMark(y: .value("Alert", alertThreshold))
                    .foregroundStyle(Brand.amber.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Alert \(alertThreshold)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.amber)
                    }
                ForEach(sensor.lastMinute) { reading in
                    AreaMark(
                        x: .value("Time", reading.date),
                        yStart: .value("Floor", 40),
                        yEnd: .value("BPM", reading.bpm)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Brand.heart.opacity(0.32), Brand.heart.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(x: .value("Time", reading.date), y: .value("BPM", reading.bpm))
                        .foregroundStyle(Brand.heart)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 40...160)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [60, 100, 140])
            }
            .frame(height: 190)
        }
        .brandCard()
    }

    private var statsCard: some View {
        let values = sensor.readings.map(\.bpm)
        let average = values.isEmpty ? nil : values.reduce(0, +) / values.count
        return HStack(spacing: 10) {
            StatPill(title: "Min", value: values.min().map(String.init) ?? "–", tint: Brand.indigo)
            StatPill(title: "Average", value: average.map(String.init) ?? "–", tint: Brand.teal)
            StatPill(title: "Max", value: values.max().map(String.init) ?? "–", tint: Brand.heart)
        }
        .brandCard(padding: 12)
    }
}
