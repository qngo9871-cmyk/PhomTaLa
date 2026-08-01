import SwiftUI

/// A horizontally-scrollable, tappable row of a player's hand cards. Selection state is owned
/// by the caller (GameView) so it can drive both the "lay meld" and "discard" actions.
struct HandView: View {
    let cards: [Card]
    let selected: Set<UUID>
    var cardWidth: CGFloat = 46
    let onTap: (Card) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -14) {
                ForEach(cards) { card in
                    CardView(card: card, selected: selected.contains(card.id), width: cardWidth)
                        .onTapGesture { onTap(card) }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16) // room for the selected-card lift animation
        }
    }
}

/// A compact, face-up, non-interactive display of already-laid (locked) melds — shown for
/// both the human and each AI opponent once they've melded.
struct MeldRowView: View {
    let melds: [Meld]
    var cardWidth: CGFloat = 32

    var body: some View {
        if !melds.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(melds) { meld in
                        HStack(spacing: -10) {
                            ForEach(meld.cards) { CardView(card: $0, width: cardWidth) }
                        }
                        .padding(4)
                        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 8)
            }
        }
    }
}
