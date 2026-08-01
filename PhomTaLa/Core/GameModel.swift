import Foundation
import Combine

/// A single entry in the discard pile. `discarderIndex` is nil only for the very first card,
/// which is flipped from the stock at the start of a round (nobody "discarded" it, so it can
/// never trigger a Tá Lả "cháy" penalty).
struct DiscardEntry {
    let card: Card
    let discarderIndex: Int?
}

enum TurnPhase {
    case awaitingDraw
    case awaitingMeldOrDiscard
}

@MainActor
final class GameModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var stock: [Card] = []
    @Published var discardPile: [DiscardEntry] = []
    @Published var currentTurnIndex: Int = 0
    @Published var phase: TurnPhase = .awaitingDraw
    @Published var roundOver = false
    @Published var matchOver = false
    @Published var roundLog: [String] = []
    @Published var roundNumber = 1
    @Published var matchScores: [Int] = [0, 0, 0, 0]
    @Published var roundsWon: [Int] = [0, 0, 0, 0]
    @Published var winInfo: (playerIndex: Int, kind: WinKind)? = nil
    @Published var noWinnerRound = false

    var mode: GameMode = .phom
    var difficulty: AIDifficulty = .easy
    private let matchTarget = 3 // first to 3 round wins takes the match, matches SamLoc's convention
    private var startingPlayerThisRound = 0

    /// Which card each player drew from the discard pile this round, and who discarded it —
    /// feeds the Hard AI's "avoid feeding a visible opponent interest" heuristic.
    private(set) var discardPickups: [Int: [(card: Card, from: Int?)]] = [:]
    /// Set on a successful drawFromDiscard(), consumed by the very next settleWin() to detect
    /// Tá Lả's simplified "cháy" case (won this same turn using a discard-pile pickup).
    private var drawnThisTurnFromDiscarderIndex: Int? = nil

    let names = ["home.player.you", "home.player.left", "home.player.across", "home.player.right"]

    var currentPlayer: Player { players[currentTurnIndex] }
    var topOfDiscard: Card? { discardPile.last?.card }

    // MARK: - Setup

    func startMatch(mode: GameMode, difficulty: AIDifficulty) {
        self.mode = mode
        self.difficulty = difficulty
        matchScores = [0, 0, 0, 0]
        roundsWon = [0, 0, 0, 0]
        roundNumber = 1
        matchOver = false
        startingPlayerThisRound = 0
        startRound()
    }

    func startRound() {
        roundOver = false
        noWinnerRound = false
        winInfo = nil
        roundLog = []
        discardPickups = [:]
        drawnThisTurnFromDiscarderIndex = nil

        var deck = [Card].freshDeck().shuffled()
        players = (0..<4).map { i in
            let hand = Array(deck.prefix(9))
            deck.removeFirst(9)
            return Player(id: i, name: L(names[i]), isHuman: i == 0, hand: hand.sorted(by: cardSortOrder))
        }
        let firstUp = deck.removeFirst()
        stock = deck
        discardPile = [DiscardEntry(card: firstUp, discarderIndex: nil)]

        currentTurnIndex = startingPlayerThisRound
        phase = .awaitingDraw
        log(String(format: L("log.leads"), players[currentTurnIndex].name))
        maybeTriggerAI()
    }

    private func cardSortOrder(_ a: Card, _ b: Card) -> Bool {
        a.suit == b.suit ? a.rank < b.rank : a.suit < b.suit
    }

    // MARK: - Drawing

    @discardableResult
    func drawFromStock(playerIndex: Int) -> Bool {
        guard playerIndex == currentTurnIndex, phase == .awaitingDraw, !roundOver, !matchOver else { return false }
        guard !stock.isEmpty else { endRoundNoWinner(); return false }
        let card = stock.removeLast()
        players[playerIndex].hand.append(card)
        players[playerIndex].hand.sort(by: cardSortOrder)
        drawnThisTurnFromDiscarderIndex = nil
        log(String(format: L("log.drewStock"), players[playerIndex].name))
        afterDraw(playerIndex)
        return true
    }

    @discardableResult
    func drawFromDiscard(playerIndex: Int) -> Bool {
        guard playerIndex == currentTurnIndex, phase == .awaitingDraw, !roundOver, !matchOver,
              let entry = discardPile.last else { return false }
        discardPile.removeLast()
        players[playerIndex].hand.append(entry.card)
        players[playerIndex].hand.sort(by: cardSortOrder)
        drawnThisTurnFromDiscarderIndex = entry.discarderIndex
        discardPickups[playerIndex, default: []].append((entry.card, entry.discarderIndex))
        log(String(format: L("log.drewDiscard"), players[playerIndex].name))
        afterDraw(playerIndex)
        return true
    }

    private func afterDraw(_ playerIndex: Int) {
        phase = .awaitingMeldOrDiscard

        // "Ù sạch": only possible on a player's very first turn of the round, and only if the
        // full 10-card hand partitions perfectly into melds with nothing left to discard.
        if players[playerIndex].turnsTakenThisRound == 0,
           MeldFinder.canPartitionCompletely(players[playerIndex].hand) {
            let partition = MeldFinder.bestPartition(of: players[playerIndex].hand)
            for group in partition {
                let ids = Set(group.map { $0.id })
                players[playerIndex].hand.removeAll { ids.contains($0.id) }
                players[playerIndex].melds.append(Meld(cards: group, kind: MeldFinder.meldKind(group) ?? .set))
            }
            settleWin(winner: playerIndex, kind: .clean)
            return
        }

        if !players[playerIndex].isHuman {
            scheduleAI { [weak self] in self?.runAIMeldAndDiscard(playerIndex) }
        }
    }

    // MARK: - Melding

    @discardableResult
    func layMeld(playerIndex: Int, cards: [Card]) -> Bool {
        guard playerIndex == currentTurnIndex, phase == .awaitingMeldOrDiscard, !roundOver, !matchOver else { return false }
        guard MeldFinder.isValidMeld(cards) else { return false }
        let ids = Set(cards.map { $0.id })
        guard ids.isSubset(of: Set(players[playerIndex].hand.map { $0.id })) else { return false }
        // Always leave at least one card to discard — a mid-round hand melding down to zero
        // isn't modeled (that path is reserved for the automatic "ù sạch" check above).
        guard players[playerIndex].hand.count - cards.count >= 1 else { return false }
        guard let kind = MeldFinder.meldKind(cards) else { return false }

        players[playerIndex].hand.removeAll { ids.contains($0.id) }
        players[playerIndex].melds.append(Meld(cards: cards, kind: kind))
        log(String(format: L("log.laidMeld"), players[playerIndex].name, cards.map { $0.label }.joined(separator: " ")))
        return true
    }

    // MARK: - Discarding

    @discardableResult
    func discard(playerIndex: Int, card: Card) -> Bool {
        guard playerIndex == currentTurnIndex, phase == .awaitingMeldOrDiscard, !roundOver, !matchOver else { return false }
        guard let idx = players[playerIndex].hand.firstIndex(where: { $0.id == card.id }) else { return false }

        players[playerIndex].hand.remove(at: idx)
        discardPile.append(DiscardEntry(card: card, discarderIndex: playerIndex))
        players[playerIndex].turnsTakenThisRound += 1
        log(String(format: L("log.discarded"), players[playerIndex].name, card.label))

        if players[playerIndex].hand.isEmpty {
            let allBig = !players[playerIndex].melds.isEmpty && players[playerIndex].melds.allSatisfy { $0.isBig }
            settleWin(winner: playerIndex, kind: allBig ? .big : .normal)
            return true
        }

        advanceTurn()
        return true
    }

    private func advanceTurn() {
        guard !roundOver, !matchOver else { return }
        guard !stock.isEmpty else { endRoundNoWinner(); return }
        currentTurnIndex = (currentTurnIndex + 1) % players.count
        phase = .awaitingDraw
        drawnThisTurnFromDiscarderIndex = nil
        maybeTriggerAI()
    }

    // MARK: - Scoring

    private func settleWin(winner: Int, kind: WinKind) {
        roundOver = true
        roundsWon[winner] += 1
        winInfo = (winner, kind)

        let multiplier: Int
        switch mode {
        case .phom:
            multiplier = (kind == .clean) ? 2 : 1
        case .taLa:
            switch kind {
            case .clean: multiplier = 3
            case .big: multiplier = 2
            case .normal: multiplier = 1
            }
        }

        var chayVictimIndex: Int? = nil
        if mode == .taLa, let discarder = drawnThisTurnFromDiscarderIndex, discarder != winner {
            chayVictimIndex = discarder
        }

        for i in players.indices where i != winner {
            var penalty = players[i].handValue * multiplier
            if i == chayVictimIndex { penalty *= 2 }
            matchScores[winner] += penalty
            matchScores[i] -= penalty
        }

        switch kind {
        case .clean: log(String(format: L("log.wonClean"), players[winner].name))
        case .big: log(String(format: L("log.wonBig"), players[winner].name))
        case .normal: log(String(format: L("log.won"), players[winner].name))
        }
        if let victim = chayVictimIndex {
            log(String(format: L("log.chay"), players[victim].name))
        }
        checkMatchEnd()
    }

    /// The stock ran out before anyone could ù. Score by unmelded hand value — lowest total
    /// wins the round (ties split the take, and don't count as a round win for anyone).
    private func endRoundNoWinner() {
        roundOver = true
        noWinnerRound = true
        let values = players.map { $0.handValue }
        let minValue = values.min() ?? 0
        let winners = players.indices.filter { values[$0] == minValue }

        for i in players.indices where !winners.contains(i) {
            let share = values[i] / winners.count
            for w in winners {
                matchScores[w] += share
                matchScores[i] -= share
            }
        }
        if winners.count == 1 { roundsWon[winners[0]] += 1 }
        log(L("log.drawEnded"))
        checkMatchEnd()
    }

    private func checkMatchEnd() {
        roundNumber += 1
        startingPlayerThisRound = (startingPlayerThisRound + 1) % 4
        if roundsWon.contains(where: { $0 >= matchTarget }) {
            matchOver = true
        }
    }

    private func log(_ message: String) {
        roundLog.append(message)
    }

    // MARK: - AI

    private func scheduleAI(_ action: @escaping () -> Void) {
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run { action() }
        }
    }

    private func maybeTriggerAI() {
        guard !roundOver, !matchOver, !currentPlayer.isHuman else { return }
        let index = currentTurnIndex
        scheduleAI { [weak self] in self?.runAIDraw(index) }
    }

    private func runAIDraw(_ index: Int) {
        guard index == currentTurnIndex, phase == .awaitingDraw, !roundOver, !matchOver else { return }
        let hand = players[index].hand
        let wantsDiscard = AIPlayer.shouldTakeDiscard(hand: hand, topDiscard: topOfDiscard, difficulty: difficulty)
        if wantsDiscard {
            drawFromDiscard(playerIndex: index)
        } else {
            drawFromStock(playerIndex: index)
        }
    }

    private func runAIMeldAndDiscard(_ index: Int) {
        guard index == currentTurnIndex, phase == .awaitingMeldOrDiscard, !roundOver, !matchOver else { return }

        var hand = players[index].hand
        for group in AIPlayer.greedyMelds(hand: hand) {
            guard hand.count - group.count >= 1 else { continue } // always keep a card to discard
            guard layMeld(playerIndex: index, cards: group) else { continue }
            let ids = Set(group.map { $0.id })
            hand.removeAll { ids.contains($0.id) }
        }

        hand = players[index].hand
        guard !hand.isEmpty else { return } // shouldn't happen; ù sạch already handled in afterDraw

        let dangerous: Set<CardKey> = difficulty == .hard ? dangerousCardKeys(for: index) : []
        let toDiscard = AIPlayer.chooseDiscard(hand: hand, difficulty: difficulty, dangerous: dangerous)
        discard(playerIndex: index, card: toDiscard)
    }

    /// Ranks/suits opponents have shown interest in by picking them up off the discard pile —
    /// the Hard AI treats cards near these as riskier to discard.
    private func dangerousCardKeys(for aiIndex: Int) -> Set<CardKey> {
        var keys: Set<CardKey> = []
        for (playerIndex, pickups) in discardPickups where playerIndex != aiIndex {
            for pickup in pickups { keys.insert(CardKey(pickup.card)) }
        }
        return keys
    }
}
