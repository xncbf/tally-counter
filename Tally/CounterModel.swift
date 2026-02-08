import Foundation
import StoreKit
import WidgetKit

struct Counter: Identifiable, Codable {
    var id: UUID
    var name: String
    var value: Int
    var colorIndex: Int
    var goal: Int?
    var createdAt: Date
    var emoji: String
    
    init(name: String, colorIndex: Int, emoji: String = "🔢", goal: Int? = nil) {
        self.id = UUID()
        self.name = name
        self.value = 0
        self.colorIndex = colorIndex
        self.goal = goal
        self.emoji = emoji
        self.createdAt = Date()
    }
    
    var progress: Double {
        guard let goal = goal, goal > 0 else { return 0 }
        return min(Double(value) / Double(goal), 1.0)
    }
}

@Observable
class CounterStore {
    var counters: [Counter] = [] {
        didSet { save() }
    }
    
    var isPremium: Bool = false {
        didSet {
            Self.sharedDefaults.set(isPremium, forKey: "tally_premium")
        }
    }
    
    private let key = "tally_counters"
    static let sharedDefaults = UserDefaults(suiteName: "group.com.lovebridge.tally") ?? .standard
    
    init() {
        isPremium = Self.sharedDefaults.bool(forKey: "tally_premium")
        load()
        if counters.isEmpty {
            counters = [Counter(name: "카운터", colorIndex: 0, emoji: "☕️")]
        }
    }
    
    func load() {
        guard let data = Self.sharedDefaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Counter].self, from: data) else { return }
        counters = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(counters) else { return }
        Self.sharedDefaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func increment(_ counter: Counter) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].value += 1
    }
    
    func decrement(_ counter: Counter) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].value = max(0, counters[i].value - 1)
    }
    
    func reset(_ counter: Counter) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].value = 0
    }
    
    func delete(_ counter: Counter) {
        counters.removeAll { $0.id == counter.id }
    }
    
    func add(name: String, emoji: String = "🔢", goal: Int? = nil) {
        let colorIndex = counters.count % GradientThemes.all.count
        counters.append(Counter(name: name, colorIndex: colorIndex, emoji: emoji, goal: goal))
    }
    
    func update(_ counter: Counter, name: String, emoji: String, goal: Int?) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].name = name
        counters[i].emoji = emoji
        counters[i].goal = goal
    }
}

enum GradientThemes {
    static let all: [(start: String, end: String)] = [
        ("#FF6B6B", "#EE5A24"),  // Warm Red
        ("#4ECDC4", "#44B09E"),  // Ocean Teal
        ("#667EEA", "#764BA2"),  // Purple Dream
        ("#F093FB", "#F5576C"),  // Pink Glow
        ("#4FACFE", "#00F2FE"),  // Sky Blue
        ("#43E97B", "#38F9D7"),  // Fresh Mint
        ("#FA709A", "#FEE140"),  // Sunset
        ("#A18CD1", "#FBC2EB"),  // Lavender
        ("#FCCB90", "#D57EEB"),  // Peach Purple
        ("#8EC5FC", "#E0C3FC"),  // Soft Blue
    ]
}

let emojiOptions = ["☕️", "💧", "🏃", "📚", "💊", "🎯", "💪", "🧘", "🍎", "✅", "🔢", "⭐️", "🎮", "🎵", "✏️", "🛒"]
