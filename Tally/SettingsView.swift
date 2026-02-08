import SwiftUI
import StoreKit

struct SettingsView: View {
    let store: CounterStore
    @Environment(\.dismiss) var dismiss
    @State private var products: [Product] = []
    @State private var isPurchasing = false
    @State private var showRestoreAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // Premium section
                Section {
                    if store.isPremium {
                        HStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("프리미엄 활성화됨")
                                    .font(.headline)
                                Text("광고 없는 깔끔한 경험을 즐기세요!")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .font(.largeTitle)
                                    .foregroundStyle(.yellow)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("광고 제거")
                                        .font(.headline)
                                    Text("한 번 구매로 영구적으로 광고를 제거하세요")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Button {
                                Task { await purchase() }
                            } label: {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text(priceText)
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .disabled(isPurchasing)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("프리미엄")
                }
                
                // Stats
                Section {
                    HStack {
                        Label("카운터 수", systemImage: "number.circle")
                        Spacer()
                        Text("\(store.counters.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("전체 카운트", systemImage: "sum")
                        Spacer()
                        Text("\(store.counters.reduce(0) { $0 + $1.value })")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("통계")
                }
                
                // General
                Section {
                    Button("구매 복원") {
                        Task { await restorePurchases() }
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/app/id6758910117?action=write-review")!) {
                        Label("리뷰 남기기", systemImage: "star.fill")
                    }
                } header: {
                    Text("일반")
                }
                
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("탈리 v1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Made with 💙")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await loadProducts()
            }
            .alert("구매 복원 완료", isPresented: $showRestoreAlert) {
                Button("확인") {}
            } message: {
                Text(store.isPremium ? "프리미엄이 복원되었습니다!" : "복원할 구매 내역이 없습니다.")
            }
        }
    }
    
    private var priceText: String {
        if let product = products.first {
            return "광고 제거 - \(product.displayPrice)"
        }
        return "광고 제거 - ₩1,100"
    }
    
    private func loadProducts() async {
        do {
            products = try await Product.products(for: ["com.lovebridge.tally.removeads"])
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    private func purchase() async {
        guard let product = products.first else {
            // Fallback: just set premium for testing
            store.isPremium = true
            return
        }
        
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(_) = verification {
                    await MainActor.run {
                        store.isPremium = true
                    }
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    private func restorePurchases() async {
        do {
            try await AppStore.sync()
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.productID == "com.lovebridge.tally.removeads" {
                        await MainActor.run {
                            store.isPremium = true
                        }
                    }
                }
            }
        } catch {
            print("Restore failed: \(error)")
        }
        showRestoreAlert = true
    }
}
