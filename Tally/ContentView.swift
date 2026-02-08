import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double((rgbValue & 0x0000FF)) / 255.0
        )
    }
}

struct ContentView: View {
    @State private var store = CounterStore()
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var editingCounter: Counter?
    @Environment(\.colorScheme) var colorScheme
    
    var totalCount: Int {
        store.counters.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Total summary header
                if store.counters.count > 1 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("전체 합계")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(totalCount)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .contentTransition(.numericText(value: Double(totalCount)))
                        }
                        Spacer()
                        Text("\(store.counters.count)개 카운터")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(store.counters) { counter in
                            CounterCard(counter: counter, store: store, colorScheme: colorScheme)
                                .contextMenu {
                                    Button {
                                        withAnimation { store.reset(counter) }
                                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                    } label: {
                                        Label("초기화", systemImage: "arrow.counterclockwise")
                                    }
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.3)) {
                                            store.delete(counter)
                                        }
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                
                // Ad banner at bottom
                BannerAdView(adUnitID: "ca-app-pub-9848654927199314/2656554390")
                    .frame(height: 50)
                    .background(Color(.systemBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("탈리")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .alert("새 카운터", isPresented: $showingAdd) {
                TextField("이름", text: $newName)
                Button("추가") {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    store.add(name: name.isEmpty ? "카운터" : name)
                    newName = ""
                }
                Button("취소", role: .cancel) { newName = "" }
            }
        }
    }
}

struct CounterCard: View {
    let counter: Counter
    let store: CounterStore
    let colorScheme: ColorScheme
    
    private var themeColor: Color {
        let idx = counter.colorIndex % ThemeColors.all.count
        let pair = ThemeColors.all[idx]
        return Color(hex: colorScheme == .dark ? pair.dark : pair.light)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(counter.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                // Reset button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.reset(counter)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(6)
                        .background(.white.opacity(0.15), in: Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            // Counter value - big tappable area
            Button {
                withAnimation(.spring(response: 0.3)) {
                    store.increment(counter)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Text("\(counter.value)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(counter.value)))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.plain)
            
            // Bottom controls
            HStack(spacing: 0) {
                // Minus button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.decrement(counter)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.12))
                }
                
                Divider()
                    .frame(height: 24)
                    .background(.white.opacity(0.2))
                
                // Plus button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.increment(counter)
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.12))
                }
            }
            .clipShape(
                .rect(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeColor.gradient)
                .shadow(color: themeColor.opacity(0.3), radius: 12, y: 6)
        )
    }
}

#Preview {
    ContentView()
}
