import SwiftUI

/// PulsePair's look: colors, cards and a few reusable pieces. Views only, no app logic.
enum Brand {
    static let heart = Color(red: 0.96, green: 0.27, blue: 0.38)
    static let heartDeep = Color(red: 0.71, green: 0.09, blue: 0.25)
    static let teal = Color(red: 0.07, green: 0.66, blue: 0.64)
    static let amber = Color(red: 0.98, green: 0.62, blue: 0.13)
    static let indigo = Color(red: 0.33, green: 0.36, blue: 0.93)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let canvas = Color(uiColor: .systemGroupedBackground)

    static let heroGradient = LinearGradient(
        colors: [heart, heartDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func zoneColor(for bpm: Int) -> Color {
        switch bpm {
        case ..<60: indigo
        case 60..<100: teal
        case 100..<120: amber
        default: heart
        }
    }

    static func zoneName(for bpm: Int) -> String {
        switch bpm {
        case ..<60: "Low"
        case 60..<100: "Resting"
        case 100..<120: "Elevated"
        default: "High"
        }
    }
}

extension View {
    /// A rounded card on the grouped background.
    func brandCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Brand.card))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

struct BrandButtonStyle: ButtonStyle {
    var color: Color = Brand.heart
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color.gradient))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SectionHeader: View {
    let title: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

struct StatPill: View {
    let title: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.canvas))
    }
}

/// Marks a field as protected health information.
struct PHIBadge: View {
    var body: some View {
        Text("PHI")
            .font(.caption2.weight(.heavy))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(Brand.amber.opacity(0.18)))
            .foregroundStyle(Brand.amber)
    }
}

/// An endlessly scrolling ECG trace. Pure decoration.
struct ECGTrace: View {
    var color: Color = .white
    var lineWidth: CGFloat = 2.5
    var speed: Double = 90
    var beatWidth: CGFloat = 120

    private static let beat: [(CGFloat, CGFloat)] = [
        (0.10, 0), (0.16, 0.12), (0.22, 0), (0.30, 0),
        (0.34, -0.22), (0.39, 1.0), (0.44, -0.45), (0.49, 0),
        (0.62, 0), (0.70, 0.25), (0.78, 0), (1.0, 0),
    ]

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { ctx, size in
                let time = context.date.timeIntervalSinceReferenceDate
                let offset = CGFloat((time * speed).truncatingRemainder(dividingBy: Double(beatWidth)))
                let mid = size.height / 2
                let amplitude = size.height * 0.42
                var path = Path()
                var x = -beatWidth + offset
                path.move(to: CGPoint(x: x, y: mid))
                while x < size.width + beatWidth {
                    for (dx, dy) in Self.beat {
                        path.addLine(to: CGPoint(x: x + dx * beatWidth, y: mid - dy * amplitude))
                    }
                    x += beatWidth
                }
                let fade = Gradient(stops: [
                    .init(color: color.opacity(0), location: 0),
                    .init(color: color.opacity(0.9), location: 0.35),
                    .init(color: color, location: 1),
                ])
                ctx.stroke(
                    path,
                    with: .linearGradient(fade, startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// Expanding rings while scanning.
struct RadarView: View {
    var active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !active)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<3, id: \.self) { ring in
                    let phase = active
                        ? (time / 2.4 + Double(ring) / 3).truncatingRemainder(dividingBy: 1)
                        : 0.35 + Double(ring) * 0.2
                    Circle()
                        .stroke(Brand.heart.opacity(0.35), lineWidth: 2)
                        .scaleEffect(0.45 + phase * 1.1)
                        .opacity(active ? 1 - phase : 0.25)
                }
                Circle()
                    .fill(Brand.heroGradient)
                    .frame(width: 96, height: 96)
                    .shadow(color: Brand.heart.opacity(0.4), radius: 16, y: 8)
                    .overlay(
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(.white)
                    )
            }
            .frame(width: 210, height: 210)
        }
    }
}
