import WidgetKit
import SwiftUI

// MARK: - Shared Data
struct WidgetCounter: Codable, Identifiable {
    var id: UUID
    var name: String
    var value: Int
    var colorIndex: Int
    var emoji: String
    // Match main app Counter fields (optional for decoding compat)
    var goal: Int?
    var createdAt: Date?
}

struct TallyEntry: TimelineEntry {
    let date: Date
    let counters: [WidgetCounter]
}

// MARK: - Provider
struct TallyProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallyEntry {
        TallyEntry(date: .now, counters: [
            WidgetCounter(id: UUID(), name: "카운터", value: 42, colorIndex: 0, emoji: "☕️")
        ])
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TallyEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TallyEntry>) -> Void) {
        let counters = loadCounters()
        let entry = TallyEntry(date: .now, counters: counters)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(300)))
        completion(timeline)
    }
    
    private func loadCounters() -> [WidgetCounter] {
        let defaults = UserDefaults(suiteName: "group.com.lovebridge.tally")
        guard let data = defaults?.data(forKey: "tally_counters"),
              let counters = try? JSONDecoder().decode([WidgetCounter].self, from: data) else {
            return [WidgetCounter(id: UUID(), name: "카운터", value: 0, colorIndex: 0, emoji: "🔢")]
        }
        return counters
    }
}

// MARK: - Widget Views
struct TallyWidgetEntryView: View {
    var entry: TallyEntry
    @Environment(\.widgetFamily) var family
    
    private let gradients: [(Color, Color)] = [
        (Color(red: 1.0, green: 0.42, blue: 0.42), Color(red: 0.93, green: 0.35, blue: 0.14)),
        (Color(red: 0.31, green: 0.8, blue: 0.77), Color(red: 0.27, green: 0.69, blue: 0.62)),
        (Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.3, blue: 0.64)),
        (Color(red: 0.94, green: 0.58, blue: 0.98), Color(red: 0.96, green: 0.34, blue: 0.42)),
        (Color(red: 0.31, green: 0.68, blue: 1.0), Color(red: 0.0, green: 0.95, blue: 1.0)),
    ]
    
    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }
    
    private var smallWidget: some View {
        let counter = entry.counters.first ?? WidgetCounter(id: UUID(), name: "카운터", value: 0, colorIndex: 0, emoji: "🔢")
        let idx = counter.colorIndex % gradients.count
        
        return VStack(spacing: 4) {
            HStack {
                Text(counter.emoji)
                    .font(.title3)
                Text(counter.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Spacer()
            }
            
            Spacer()
            
            Text("\(counter.value)")
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
            
            Spacer()
        }
        .padding()
        .containerBackground(
            LinearGradient(colors: [gradients[idx].0, gradients[idx].1], startPoint: .topLeading, endPoint: .bottomTrailing),
            for: .widget
        )
    }
    
    private var mediumWidget: some View {
        HStack(spacing: 12) {
            ForEach(entry.counters.prefix(3)) { counter in
                let idx = counter.colorIndex % gradients.count
                VStack(spacing: 6) {
                    Text(counter.emoji)
                        .font(.title2)
                    Text("\(counter.value)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                    Text(counter.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(LinearGradient(colors: [gradients[idx].0, gradients[idx].1], startPoint: .topLeading, endPoint: .bottomTrailing))
                )
            }
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget
@main
struct TallyWidget: Widget {
    let kind: String = "TallyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TallyProvider()) { entry in
            TallyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("탈리 카운터")
        .description("카운터 값을 홈 화면에서 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
