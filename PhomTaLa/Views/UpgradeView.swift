import SwiftUI

struct UpgradeView: View {
    @StateObject private var purchases = PurchaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage(CardBackStyle.storageKey) private var selectedBackStyle: String = CardBackStyle.classic.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.3), .black],
                                startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                VStack(spacing: 22) {
                    Text("👑").font(.system(size: 50))
                    Text(L("upgrade.title")).font(.title.bold()).foregroundStyle(.white)
                    Text(L("upgrade.subtitle")).font(.subheadline).foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center).padding(.horizontal, 30)

                    VStack(alignment: .leading, spacing: 12) {
                        featureRow("brain.head.profile", L("upgrade.feature.hardAI"))
                        featureRow("sparkles", L("upgrade.feature.cardBacks"))
                        featureRow("infinity", L("upgrade.feature.unlimited"))
                    }
                    .padding(.horizontal, 30)

                    cardBackPicker

                    if purchases.isPro {
                        Text(L("upgrade.owned")).foregroundStyle(.green).font(.headline)
                    } else {
                        Button {
                            Task { await purchases.purchase() }
                        } label: {
                            if purchases.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(purchases.product?.displayPrice.isEmpty == false
                                     ? String(format: L("upgrade.buy"), purchases.product!.displayPrice)
                                     : L("upgrade.buyFallback"))
                                    .font(.title3.bold()).frame(maxWidth: 260).padding()
                            }
                        }
                        .buttonStyle(.borderedProminent).tint(.blue)
                        .disabled(purchases.isPurchasing)

                        Button(L("upgrade.restore")) { Task { await purchases.restorePurchases() } }
                            .font(.footnote).foregroundStyle(.white.opacity(0.6))

                        if let err = purchases.purchaseError {
                            Text(err).font(.caption).foregroundStyle(.red)
                        }
                    }

                    Button(L("upgrade.close")) { dismiss() }
                        .foregroundStyle(.white.opacity(0.5)).padding(.top, 6)
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    /// The actual "Exclusive card back designs" feature: three selectable back styles, live
    /// preview via `CardBackSwatch`, gated on Pro (locked/dimmed + non-interactive otherwise).
    private var cardBackPicker: some View {
        VStack(spacing: 8) {
            Text(L("upgrade.cardBackPicker")).font(.caption).foregroundStyle(.white.opacity(0.6))
            HStack(spacing: 16) {
                ForEach(CardBackStyle.allCases) { style in
                    Button {
                        selectedBackStyle = style.rawValue
                    } label: {
                        VStack(spacing: 4) {
                            CardBackSwatch(style: style, width: 42)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.yellow,
                                                lineWidth: (purchases.isPro && selectedBackStyle == style.rawValue) ? 3 : 0)
                                )
                                .opacity(purchases.isPro ? 1 : 0.4)
                            Text(L(style.nameKey)).font(.caption2).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .disabled(!purchases.isPro)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.blue).frame(width: 24)
            Text(text).foregroundStyle(.white)
        }
    }
}

#Preview { UpgradeView() }
