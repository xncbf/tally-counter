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
    @State private var showingSettings = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                (colorScheme == .dark ? Color.black : Color(.systemGroupedBackground))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Summary card
                            if store.counters.count > 1 {
                                SummaryCard(store: store, colorScheme: colorScheme)
                            }
                            
                            ForEach(store.counters) { counter in
                                CounterCard(counter: counter, store: store, colorScheme: colorScheme)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.8).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                    
                    // Ad banner
                    if !store.isPremium {
                        BannerAdView(adUnitID: AdConfig.bannerAdUnitID)
                            .frame(height: 50)
                            .background(.ultraThinMaterial)
                    }
                }
            }
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddCounterSheet(store: store)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(store: store)
            }
        }
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let store: CounterStore
    let colorScheme: ColorScheme
    
    var totalCount: Int {
        store.counters.reduce(0) { $0 + $1.value }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("전체 합계")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("\(totalCount)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .contentTransition(.numericText(value: Double(totalCount)))
            }
            
            Spacer()
            
            HStack(spacing: -8) {
                ForEach(store.counters.prefix(4)) { counter in
                    Text(counter.emoji)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                if store.counters.count > 4 {
                    Text("+\(store.counters.count - 4)")
                        .font(.caption2.bold())
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        }
    }
}

// MARK: - Counter Card
struct CounterCard: View {
    let counter: Counter
    let store: CounterStore
    let colorScheme: ColorScheme
    @State private var isTapping = false
    @State private var showEdit = false
    
    private var gradient: LinearGradient {
        let idx = counter.colorIndex % GradientThemes.all.count
        let theme = GradientThemes.all[idx]
        return LinearGradient(
            colors: [Color(hex: theme.start), Color(hex: theme.end)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with emoji + name
            HStack {
                HStack(spacing: 8) {
                    Text(counter.emoji)
                        .font(.title3)
                    Text(counter.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                Menu {
                    Button { showEdit = true } label: {
                        Label("편집", systemImage: "pencil")
                    }
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            store.reset(counter)
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    } label: {
                        Label("초기화", systemImage: "arrow.counterclockwise")
                    }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            store.delete(counter)
                        }
                    } label: {
                        Label("삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(.white.opacity(0.12), in: Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 4)
            
            // Goal progress bar
            if let goal = counter.goal, goal > 0 {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .frame(height: 6)
                            Capsule()
                                .fill(.white.opacity(0.8))
                                .frame(width: geo.size.width * counter.progress, height: 6)
                                .animation(.spring(response: 0.4), value: counter.progress)
                        }
                    }
                    .frame(height: 6)
                    
                    HStack {
                        Text("\(Int(counter.progress * 100))%")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Text("목표 \(goal)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
            }
            
            // Counter value — tappable
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isTapping = true
                    store.increment(counter)
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                
                // Check goal reached
                if let goal = counter.goal, counter.value + 1 >= goal {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2)) { isTapping = false }
                }
            } label: {
                Text("\(counter.value)")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(counter.value)))
                    .scaleEffect(isTapping ? 1.1 : 1.0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: counter.value)
            
            // Bottom controls
            HStack(spacing: 20) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.decrement(counter)
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.15))
                        )
                }
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.increment(counter)
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.2))
                        )
                }
            }
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(gradient)
                .shadow(color: Color(hex: GradientThemes.all[counter.colorIndex % GradientThemes.all.count].start).opacity(0.35), radius: 16, y: 8)
        )
        .sheet(isPresented: $showEdit) {
            EditCounterSheet(counter: counter, store: store)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Add Counter Sheet
struct AddCounterSheet: View {
    let store: CounterStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedEmoji = "🔢"
    @State private var goalText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("카운터 이름", text: $name)
                }
                
                Section("이모지") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedEmoji == emoji ? Color.accentColor : .clear, lineWidth: 2)
                                )
                                .onTapGesture { selectedEmoji = emoji }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("목표 (선택)") {
                    TextField("예: 100", text: $goalText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("새 카운터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("추가") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        let goal = Int(goalText)
                        store.add(name: n.isEmpty ? "카운터" : n, emoji: selectedEmoji, goal: goal)
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Edit Counter Sheet
struct EditCounterSheet: View {
    let counter: Counter
    let store: CounterStore
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var selectedEmoji: String
    @State private var goalText: String
    
    init(counter: Counter, store: CounterStore) {
        self.counter = counter
        self.store = store
        _name = State(initialValue: counter.name)
        _selectedEmoji = State(initialValue: counter.emoji)
        _goalText = State(initialValue: counter.goal.map { "\($0)" } ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("카운터 이름", text: $name)
                }
                
                Section("이모지") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedEmoji == emoji ? Color.accentColor : .clear, lineWidth: 2)
                                )
                                .onTapGesture { selectedEmoji = emoji }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("목표 (선택)") {
                    TextField("예: 100", text: $goalText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        store.update(counter, name: n.isEmpty ? "카운터" : n, emoji: selectedEmoji, goal: Int(goalText))
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - Ad Config
enum AdConfig {
    static var bannerAdUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2934735716" // Test ID
        #else
        return "ca-app-pub-9848654927199314/2656554390" // Real ID
        #endif
    }
}

#Preview {
    ContentView()
}
