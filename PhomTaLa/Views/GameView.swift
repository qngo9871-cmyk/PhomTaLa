import SwiftUI

struct GameView: View {
    @ObservedObject var game: GameModel
    @State private var selected: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    private var human: Player { game.players[0] }
    private var selectedCards: [Card] { human.hand.filter { selected.contains($0.id) } }
    private var isMyTurn: Bool { game.currentTurnIndex == 0 && !game.roundOver && !game.matchOver }
    private var canLayMeld: Bool { selectedCards.count >= 3 && MeldFinder.isValidMeld(selectedCards) }
    private var canDiscard: Bool { selectedCards.count == 1 }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.1, blue: 0.22).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                opponentRow(index: 2, label: L("home.player.across"))
                Spacer(minLength: 4)
                tableArea
                Spacer(minLength: 4)
                HStack {
                    opponentRow(index: 1, label: L("home.player.left")).frame(maxWidth: .infinity)
                    opponentRow(index: 3, label: L("home.player.right")).frame(maxWidth: .infinity)
                }
                handArea
            }

            if game.roundOver && !game.matchOver { roundOverOverlay }
            if game.matchOver { matchOverOverlay }
        }
        .navigationBarBackButtonHidden(game.roundOver == false)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: game.currentTurnIndex) { _ in selected.removeAll() }
        .onChange(of: game.roundNumber) { _ in selected.removeAll() }
    }

    // MARK: - Header / opponents

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 2) {
                Text(String(format: L("game.round"), game.roundNumber)).font(.caption).foregroundStyle(.white.opacity(0.8))
                Text(L(game.mode.titleKey)).font(.caption2.bold()).foregroundStyle(.yellow)
            }
            Spacer()
            HStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { i in
                    Text("\(game.matchScores[i])")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(i == 0 ? .yellow : .white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal).padding(.top, 8)
    }

    private func opponentRow(index: Int, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(label).font(.caption2).foregroundStyle(.white.opacity(0.7))
                if game.currentTurnIndex == index && !game.roundOver {
                    Circle().fill(.yellow).frame(width: 6, height: 6)
                }
            }
            HStack(spacing: -18) {
                ForEach(game.players[index].hand.prefix(10)) { card in
                    CardView(card: card, faceDown: true, width: 26)
                }
            }
            MeldRowView(melds: game.players[index].melds, cardWidth: 22)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Table

    private var tableArea: some View {
        VStack(spacing: 10) {
            HStack(spacing: 28) {
                stockPileView
                discardPileView
            }
            if isMyTurn && game.phase == .awaitingDraw {
                Text(L("game.drawPrompt")).font(.caption).foregroundStyle(.yellow)
            } else if isMyTurn && game.phase == .awaitingMeldOrDiscard {
                Text(canLayMeld ? L("game.meldHint") : L("game.discardHint"))
                    .font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var stockPileView: some View {
        VStack(spacing: 4) {
            ZStack {
                if !game.stock.isEmpty {
                    CardView(card: game.stock.last!, faceDown: true, width: 52)
                } else {
                    RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3))
                        .frame(width: 52, height: 52 * 1.45)
                }
            }
            .onTapGesture {
                guard isMyTurn, game.phase == .awaitingDraw else { return }
                game.drawFromStock(playerIndex: 0)
            }
            .opacity(isMyTurn && game.phase == .awaitingDraw ? 1 : 0.6)
            Text(String(format: L("game.stockCount"), game.stock.count)).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
    }

    private var discardPileView: some View {
        VStack(spacing: 4) {
            Group {
                if let top = game.topOfDiscard {
                    CardView(card: top, width: 52)
                } else {
                    RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3))
                        .frame(width: 52, height: 52 * 1.45)
                        .overlay(Text(L("game.discardEmpty")).font(.caption2).foregroundStyle(.white.opacity(0.5)))
                }
            }
            .onTapGesture {
                guard isMyTurn, game.phase == .awaitingDraw, game.topOfDiscard != nil else { return }
                game.drawFromDiscard(playerIndex: 0)
            }
            .opacity(isMyTurn && game.phase == .awaitingDraw && game.topOfDiscard != nil ? 1 : 0.6)
            Text(L("action.drawDiscard")).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Hand

    private var handArea: some View {
        VStack(spacing: 8) {
            if isMyTurn && game.phase == .awaitingDraw {
                Text(L("game.yourTurn")).font(.caption.bold()).foregroundStyle(.yellow)
            }
            if !human.melds.isEmpty {
                MeldRowView(melds: human.melds)
            }
            HandView(cards: human.hand, selected: selected) { card in toggle(card) }

            HStack(spacing: 14) {
                Button(L("action.layMeld")) {
                    if game.layMeld(playerIndex: 0, cards: selectedCards) { selected.removeAll() }
                }
                .buttonStyle(.bordered).tint(.purple)
                .disabled(!isMyTurn || game.phase != .awaitingMeldOrDiscard || !canLayMeld)

                Button(L("action.discard")) {
                    if let card = selectedCards.first, canDiscard {
                        game.discard(playerIndex: 0, card: card)
                        selected.removeAll()
                    }
                }
                .buttonStyle(.borderedProminent).tint(.blue)
                .disabled(!isMyTurn || game.phase != .awaitingMeldOrDiscard || !canDiscard)
            }
            .padding(.bottom, 10)
        }
        .padding(.top, 6)
        .background(Color.black.opacity(0.25))
    }

    private func toggle(_ card: Card) {
        guard isMyTurn, game.phase == .awaitingMeldOrDiscard else { return }
        if selected.contains(card.id) { selected.remove(card.id) } else { selected.insert(card.id) }
    }

    // MARK: - Overlays

    private var roundOverOverlay: some View {
        VStack(spacing: 16) {
            if game.noWinnerRound {
                Text(L("game.noWinner")).font(.title2.bold()).foregroundStyle(.orange)
            } else if let win = game.winInfo {
                Text(winEmoji(win.kind) + " " + L(winTitleKey(win.kind)))
                    .font(.title2.bold()).foregroundStyle(.yellow)
                Text(String(format: L("game.handValue"), game.players[win.playerIndex].handValue))
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            if let last = game.roundLog.last {
                Text(last).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85))
            }
            Button(L("game.nextRound")) { game.startRound() }
                .buttonStyle(.borderedProminent).tint(.blue)
        }
        .foregroundStyle(.white)
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(40)
    }

    private var matchOverOverlay: some View {
        VStack(spacing: 16) {
            Text(L("game.matchOver")).font(.title.bold()).foregroundStyle(.yellow)
            ForEach(0..<4, id: \.self) { i in
                Text("\(L(game.names[i])): \(game.matchScores[i])")
                    .foregroundStyle(i == 0 ? .yellow : .white)
            }
            Button(L("game.done")) { dismiss() }
                .buttonStyle(.borderedProminent).tint(.blue)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(40)
    }

    private func winTitleKey(_ kind: WinKind) -> String {
        switch kind {
        case .normal: return "win.uThuong"
        case .big: return "win.uTo"
        case .clean: return "win.uSach"
        }
    }

    private func winEmoji(_ kind: WinKind) -> String {
        switch kind {
        case .normal: return "🎉"
        case .big: return "🔥"
        case .clean: return "✨"
        }
    }
}

#Preview {
    let g = GameModel()
    g.startMatch(mode: .taLa, difficulty: .easy)
    return NavigationStack { GameView(game: g) }.preferredColorScheme(.dark)
}
