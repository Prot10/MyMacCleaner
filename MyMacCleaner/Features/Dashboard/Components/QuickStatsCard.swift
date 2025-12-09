import SwiftUI
import Charts

/// Card showing a quick stat with circular gauge
struct QuickStatsCard: View {
    let title: String
    let value: String
    let percentage: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            HStack(spacing: 16) {
                // Circular Gauge
                CircularGauge(value: percentage, color: color)
                    .frame(width: 50, height: 50)

                // Value
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(percentage * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(value)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

/// Circular gauge using Swift Charts
struct CircularGauge: View {
    let value: Double
    let color: Color

    var body: some View {
        Chart {
            SectorMark(
                angle: .value("Used", value),
                innerRadius: .ratio(0.7),
                angularInset: 1
            )
            .foregroundStyle(color.gradient)

            SectorMark(
                angle: .value("Free", max(0, 1 - value)),
                innerRadius: .ratio(0.7),
                angularInset: 1
            )
            .foregroundStyle(Color.gray.opacity(0.2))
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        QuickStatsCard(
            title: "Memory",
            value: "8.2 / 16 GB",
            percentage: 0.51,
            icon: "memorychip",
            color: .green
        )

        QuickStatsCard(
            title: "Storage",
            value: "234 / 500 GB",
            percentage: 0.47,
            icon: "internaldrive",
            color: .blue
        )

        QuickStatsCard(
            title: "CPU",
            value: "23%",
            percentage: 0.23,
            icon: "cpu",
            color: .orange
        )
    }
    .padding()
    .frame(width: 700)
    .background(Color(nsColor: .windowBackgroundColor))
}
