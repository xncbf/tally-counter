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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(store.counters) { counter in
                        CounterCard(counter: counter, store: store, colorScheme: colorScheme)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                BannerAdView(adUnitID: "ca-app-pub-9848654927199314/2656554390")
                    .frame(height: 50)
            }
            .navigationTitle("탈리")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .alert("New Counter", isPresented: $showingAdd) {
                TextField("Name", text: $newName)
                Button("Add") {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    store.add(name: name.isEmpty ? "Counter" : name)
                    newName = ""
                }
                Button("Cancel", role: .cancel) { newName = "" }
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
        VStack(spacing: 20) {
            HStack {
                Text(counter.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.delete(counter)
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            Text("\(counter.value)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(counter.value)))
                .onLongPressGesture {
                    withAnimation(.spring(response: 0.3)) {
                        store.reset(counter)
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
            
            HStack(spacing: 24) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.decrement(counter)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.increment(counter)
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(themeColor.gradient)
                .shadow(color: themeColor.opacity(0.4), radius: 12, y: 6)
        )
    }
}

#Preview {
    ContentView()
}
