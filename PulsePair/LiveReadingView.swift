import Charts
import SwiftUI

struct LiveReadingView: View {
    @Environment(SensorSimulator.self) private var sensor

    var body: some View {
        List {
            Section {
                HStack(alignment: .firstTextBaseline) {
                    Text(sensor.currentBPM.map(String.init) ?? "--")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("bpm")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                        .symbolEffect(.pulse, isActive: sensor.state == .connected)
                }
            }
            Section("Last minute") {
                Chart(sensor.lastMinute) { reading in
                    LineMark(x: .value("Time", reading.date), y: .value("BPM", reading.bpm))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 40...160)
                .frame(height: 200)
            }
            Section {
                Text(sensor.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Live reading")
    }
}
