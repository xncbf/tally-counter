import SwiftUI

struct WatchContentView: View {
    @State private var store = WatchCounterStore()
    @State private var selectedIndex = 0
    
    var body: some View {
        NavigationStack {
            if store.counters.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    Text("카운터 추가")
                        .font(.caption)
                }
                .onTapGesture {
                    store.add(name: "카운터")
                }
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(store.counters.enumerated()), id: \.element.id) { index, counter in
                        WatchCounterCard(counter: counter, store: store)
                            .tag(index)
                    }
                    
                    // Add new counter tab
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        Text("새 카운터")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .onTapGesture {
                        store.add(name: "카운터 \(store.counters.count + 1)")
                        selectedIndex = store.counters.count - 1
                    }
                    .tag(store.counters.count)
                }
                .tabViewStyle(.verticalPage)
                .navigationTitle("탈리")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct WatchCounterCard: View {
    let counter: WatchCounter
    let store: WatchCounterStore
    
    private let colors: [Color] = [.red, .teal, .blue, .green, .yellow, .purple, .orange, .mint]
    
    private var themeColor: Color {
        colors[counter.colorIndex % colors.count]
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(counter.name)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            // Big tappable number
            Button {
                withAnimation(.spring(response: 0.2)) {
                    store.increment(counter)
                }
                WKInterfaceDevice.current().play(.click)
            } label: {
                Text("\(counter.value)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(themeColor)
                    .contentTransition(.numericText(value: Double(counter.value)))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            
            // Controls
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        store.decrement(counter)
                    }
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(themeColor.opacity(0.7))
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        store.reset(counter)
                    }
                    WKInterfaceDevice.current().play(.notification)
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        store.increment(counter)
                    }
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(themeColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}
