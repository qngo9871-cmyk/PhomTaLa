import SwiftUI

/// The Pro upgrade advertises "Exclusive card back designs" (see upgrade.feature.cardBacks) —
/// this is the actual feature behind that claim: three selectable back designs, persisted via
/// UserDefaults and gated to Pro owners. Kept intentionally small (three palette-only styles,
/// no new art assets) per the "small amount of genuine differentiation, don't over-build" scope
/// for this review pass.
enum CardBackStyle: String, CaseIterable, Identifiable {
    case classic, maroon, gold
    var id: String { rawValue }

    static let storageKey = "cardBackStyle"

    var nameKey: String {
        switch self {
        case .classic: return "cardback.classic"
        case .maroon: return "cardback.maroon"
        case .gold: return "cardback.gold"
        }
    }

    var icon: String {
        switch self {
        case .classic: return "diamond.fill"
        case .maroon: return "seal.fill"
        case .gold: return "sparkles"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .classic:
            return LinearGradient(colors: [Color(red: 0.05, green: 0.15, blue: 0.55), Color(red: 0.02, green: 0.06, blue: 0.3)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        case .maroon:
            // Echoes the app icon's maroon/near-black lacquer gradient, so the Pro back reads
            // as belonging to the same house look rather than a random extra color.
            return LinearGradient(colors: [Color(red: 0.55, green: 0.06, blue: 0.14), Color(red: 0.12, green: 0.01, blue: 0.04)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(red: 0.58, green: 0.44, blue: 0.08), Color(red: 0.14, green: 0.1, blue: 0.02)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// Pure, ungated rendering of a card-back design. Used by `CardView` (which decides *which*
/// style to actually show, gated on Pro ownership) and by the Upgrade screen's style picker
/// (which needs to preview all three designs regardless of ownership).
struct CardBackSwatch: View {
    let style: CardBackStyle
    var width: CGFloat = 46

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(style.gradient)
            .frame(width: width, height: width * 1.45)
            .overlay(
                Image(systemName: style.icon)
                    .foregroundStyle(.white.opacity(0.35))
                    .font(.system(size: width * 0.4))
            )
    }
}

struct CardView: View {
    let card: Card
    var selected: Bool = false
    var faceDown: Bool = false
    var width: CGFloat = 46

    @ObservedObject private var purchases = PurchaseManager.shared
    @AppStorage(CardBackStyle.storageKey) private var storedBackStyle: String = CardBackStyle.classic.rawValue

    /// Non-Pro accounts always see the classic back, even if a style was picked before a lapsed
    /// restore — the picker itself is also disabled for non-Pro, this is just defense in depth.
    private var effectiveBackStyle: CardBackStyle {
        guard purchases.isPro, let style = CardBackStyle(rawValue: storedBackStyle) else { return .classic }
        return style
    }

    var body: some View {
        Group {
            if faceDown {
                CardBackSwatch(style: effectiveBackStyle, width: width)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: width, height: width * 1.45)
                    .overlay {
                        VStack(spacing: 2) {
                            Text(card.rank.label)
                                .font(.system(size: width * 0.32, weight: .bold, design: .rounded))
                            Text(card.suit.symbol)
                                .font(.system(size: width * 0.32))
                        }
                        .foregroundStyle(card.suit.isRed ? .red : .black)
                    }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? Color.yellow : Color.black.opacity(0.25), lineWidth: selected ? 3 : 1)
        )
        .offset(y: selected ? -14 : 0)
        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
        .animation(.spring(response: 0.25), value: selected)
    }
}

#Preview {
    HStack {
        CardView(card: Card(rank: .ace, suit: .spades))
        CardView(card: Card(rank: .king, suit: .hearts), selected: true)
        CardView(card: Card(rank: .ten, suit: .diamonds), faceDown: true)
    }
    .padding().background(Color.green)
}
