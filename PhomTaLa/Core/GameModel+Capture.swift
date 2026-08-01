import Foundation

#if DEBUG
extension GameModel {
    /// Deterministic states for App Store screenshot capture, keyed by PT_CAPTURE value.
    func captureSetup(_ scenario: String) {
        mode = .taLa
        difficulty = .normal
        matchScores = [24, -8, -10, -6]
        roundsWon = [1, 0, 0, 0]
        roundNumber = 2

        func hand(_ ranks: [Rank], _ suits: [Suit]) -> [Card] {
            zip(ranks, suits).map { Card(rank: $0, suit: $1) }
        }

        switch scenario {
        case "win":
            var p0 = Player(id: 0, name: L(names[0]), isHuman: true,
                             hand: [Card(rank: .nine, suit: .spades)])
            p0.melds = [
                Meld(cards: hand([.three, .four, .five], [.hearts, .hearts, .hearts]), kind: .run),
                Meld(cards: hand([.seven, .seven, .seven], [.spades, .clubs, .diamonds]), kind: .set),
            ]
            players = [
                p0,
                Player(id: 1, name: L(names[1]), isHuman: false, hand: hand([.two, .six, .jack, .king], [.clubs, .diamonds, .hearts, .spades])),
                Player(id: 2, name: L(names[2]), isHuman: false, hand: hand([.four, .eight, .queen], [.spades, .clubs, .hearts])),
                Player(id: 3, name: L(names[3]), isHuman: false, hand: hand([.five, .nine, .king, .ace], [.diamonds, .spades, .clubs, .hearts])),
            ]
            phase = .awaitingMeldOrDiscard
            currentTurnIndex = 0
            winInfo = (0, .big)
            roundOver = true
            roundLog = [String(format: L("log.wonBig"), players[0].name)]

        default: // "midgame"
            var p0 = Player(id: 0, name: L(names[0]), isHuman: true,
                             hand: hand([.four, .five, .eight, .eight, .jack, .queen, .ace, .two, .six],
                                        [.hearts, .hearts, .spades, .clubs, .diamonds, .diamonds, .spades, .hearts, .clubs]))
            p0.melds = [Meld(cards: hand([.nine, .nine, .nine], [.spades, .clubs, .hearts]), kind: .set)]
            players = [
                p0,
                Player(id: 1, name: L(names[1]), isHuman: false, hand: hand([.two, .six, .jack, .king, .three, .seven], Array(repeating: .clubs, count: 6))),
                Player(id: 2, name: L(names[2]), isHuman: false, hand: hand([.four, .eight, .queen, .five, .nine, .ten, .jack, .king], Array(repeating: .diamonds, count: 8))),
                Player(id: 3, name: L(names[3]), isHuman: false, hand: hand([.five, .nine, .king, .ace, .two, .six, .ten], Array(repeating: .spades, count: 7))),
            ]
            stock = Array(repeating: Card(rank: .three, suit: .clubs), count: 18)
            discardPile = [DiscardEntry(card: Card(rank: .ten, suit: .diamonds), discarderIndex: 3)]
            phase = .awaitingDraw
            currentTurnIndex = 0
            roundLog = [String(format: L("log.discarded"), players[3].name, "10♦")]
        }
    }
}
#endif
