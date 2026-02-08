import Foundation
import WatchKit

struct WatchCounter: Identifiable, Codable {
    var id: UUID
    var name: String
    var value: Int
    var colorIndex: Int
    
    init(name: String, colorIndex: Int) {
        self.id = UUID()
        self.name = name
        self.value = 0
        self.colorIndex = colorIndex
    }
}

@Observable
class WatchCounterStore {
    var counters: [WatchCounter] = [] {
        didSet { save() }
    }
    
    private let key = "tally_watch_counters"
    
    init() {
        load()
        if counters.isEmpty {
            counters = [WatchCounter(name: "카운터", colorIndex: 0)]
        }
    }
    
    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WatchCounter].self, from: data) else { return }
        counters = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(counters) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func increment(_ counter: WatchCounter) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].value += 1
    }
    
    func decrement(_ counter: WatchCounter) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].value = max(0, counters[i].value - 1)
    }
    
    func reset(_ counter: WatchCounter) {
        guard let i = counters.firstIndex(where: { $0.id == counter.id }) else { return }
        counters[i].value = 0
    }
    
    func delete(_ counter: WatchCounter) {
        counters.removeAll { $0.id == counter.id }
    }
    
    func add(name: String) {
        let colorIndex = counters.count % 8
        counters.append(WatchCounter(name: name, colorIndex: colorIndex))
    }
}
