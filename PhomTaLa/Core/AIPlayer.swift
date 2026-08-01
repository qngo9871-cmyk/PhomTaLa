import Foundation

enum AIPlayer {
    /// Decide the draw source. Easy always draws from stock (ignores the discard pile
    /// entirely). Normal/Hard take the discard pile top only when it directly completes or
    /// extends a meld already forming in hand — never a speculative pickup.
    static func shouldTakeDiscard(hand: [Card], topDiscard: Card?, difficulty: AIDifficulty) -> Bool {
        guard difficulty != .easy, let topDiscard else { return false }
        return formsOrExtendsMeld(card: topDiscard, in: hand)
    }

    private static func formsOrExtendsMeld(card: Card, in hand: [Card]) -> Bool {
        let hypothetical = hand + [card]
        let candidates = MeldFinder.allPossibleMelds(in: hypothetical)
        return candidates.contains { group in group.contains(where: { $0.id == card.id }) }
    }

    /// Repeatedly lays down the largest available valid meld until none remain. Simple,
    /// exhaustive-enough for a ≤10-card hand, not a globally-optimal partition search.
    static func greedyMelds(hand: [Card]) -> [[Card]] {
        var remaining = hand
        var chosen: [[Card]] = []
        while true {
            let options = MeldFinder.allPossibleMelds(in: remaining).sorted { $0.count > $1.count }
            guard let best = options.first else { break }
            chosen.append(best)
            let ids = Set(best.map { $0.id })
            remaining.removeAll { ids.contains($0.id) }
        }
        return chosen
    }

    /// Picks the discard. Normal/Hard always discard the single least-useful card. Easy
    /// discards randomly among the least-useful few instead of always the optimal card.
    static func chooseDiscard(hand: [Card], difficulty: AIDifficulty, dangerous: Set<CardKey> = []) -> Card {
        let scored = hand.map { card in (card: card, score: usefulness(card: card, hand: hand, dangerous: dangerous, difficulty: difficulty)) }
        let sorted = scored.sorted { $0.score < $1.score }
        switch difficulty {
        case .easy:
            let pool = Array(sorted.prefix(3))
            return pool.randomElement()?.card ?? hand[0]
        case .normal, .hard:
            return sorted.first?.card ?? hand[0]
        }
    }

    /// Lower score = less useful to keep = safer to discard. Rewards same-rank neighbors
    /// (toward a set) and same-suit near ranks (toward a run) — the same "usefulness scoring"
    /// spirit as SamLoc's comboUsefulness, adapted for a rummy-style meld game. Hard difficulty
    /// additionally penalizes cards near ranks/suits an opponent has visibly picked up from the
    /// discard pile this round (a proxy for "likely feeds their forming meld").
    private static func usefulness(card: Card, hand: [Card], dangerous: Set<CardKey>, difficulty: AIDifficulty) -> Int {
        var score = 0

        let sameRankNeighbors = hand.filter { $0.rank == card.rank && $0.id != card.id }.count
        score += sameRankNeighbors * 10

        let sameSuitRanks = Set(hand.filter { $0.suit == card.suit && $0.id != card.id }.map { $0.rank.rawValue })
        for delta in [-2, -1, 1, 2] where sameSuitRanks.contains(card.rank.rawValue + delta) {
            score += (abs(delta) == 1 ? 6 : 3)
        }

        if difficulty == .hard {
            for key in dangerous {
                if key.rank == card.rank { score += 40 }
                else if key.suit == card.suit && abs(key.rank.rawValue - card.rank.rawValue) <= 2 { score += 15 }
            }
        }
        return score
    }
}
