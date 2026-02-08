import Foundation

struct Counter: Identifiable, Codable {
    var id: UUID
    var name: String
    var value: Int
    var colorIndex: Int
    var createdAt: Date
    
    init(name: String, colorIndex: Int) {
        self.id = UUID()
        self.name = name
        self.value = 0
        self.colorIndex = colorIndex
        self.createdAt = Date()
    }
}

@Observable
class CounterStore {
    var counters: [Counter] = [] {
        didSet { save() }
    }
    
    private let key = "tally_counters"
    
    init() {
        load()
        if counters.isEmpty {
            counters = [Counter(name: "Counter", colorIndex: 0)]
        }
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Counter].self, from: data) else { return }
        counters = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(counters) else { return }
        UserDefaults.standard.set(data, forKey: key)
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
    
    func add(name: String) {
        let colorIndex = counters.count % ThemeColors.all.count
        counters.append(Counter(name: name, colorIndex: colorIndex))
    }
}

enum ThemeColors {
    static let all: [(light: String, dark: String)] = [
        ("#FF6B6B", "#C0392B"), // Red
        ("#4ECDC4", "#16A085"), // Teal
        ("#45B7D1", "#2980B9"), // Blue
        ("#96CEB4", "#27AE60"), // Green
        ("#FFEAA7", "#F39C12"), // Yellow
        ("#DDA0DD", "#8E44AD"), // Purple
        ("#F8B500", "#E67E22"), // Orange
        ("#A8E6CF", "#1ABC9C"), // Mint
    ]
}
