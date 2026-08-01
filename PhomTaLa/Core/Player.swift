import Foundation

struct Player: Identifiable {
    let id: Int
    var name: String
    let isHuman: Bool
    var hand: [Card] = []
    var melds: [Meld] = []
    /// Number of full turns (draw -> optional melds -> discard) this player has completed
    /// so far this round. Used to gate "ù sạch" to a player's very first turn of the round.
    var turnsTakenThisRound: Int = 0

    var meldedCardCount: Int { melds.reduce(0) { $0 + $1.cards.count } }
    var handValue: Int { hand.reduce(0) { $0 + $1.pointValue } }
}

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy, normal, hard
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .easy: return "difficulty.easy"
        case .normal: return "difficulty.normal"
        case .hard: return "difficulty.hard"
        }
    }
}

/// Phỏm is the base ruleset; Tá Lả layers graduated win-bonus tiers and the "cháy" penalty
/// on top of the identical core draw/meld/discard loop.
enum GameMode: String, CaseIterable, Identifiable {
    case phom, taLa
    var id: String { rawValue }
    var titleKey: String {
        switch self {
        case .phom: return "mode.phom"
        case .taLa: return "mode.taLa"
        }
    }
    var subtitleKey: String {
        switch self {
        case .phom: return "mode.phom.subtitle"
        case .taLa: return "mode.taLa.subtitle"
        }
    }
}

/// The three ways a round can end in a win (draw-pile-exhausted no-winner rounds are handled
/// separately by GameModel and don't produce a WinKind).
enum WinKind {
    case normal   // "ù thường" — standard win, 1x in both modes
    case big      // "ù to" / "ù bụng" — every laid meld is 4+ cards, Tá Lả-only 2x tier
    case clean    // "ù sạch" — entire first hand melds perfectly with no discard needed
}
