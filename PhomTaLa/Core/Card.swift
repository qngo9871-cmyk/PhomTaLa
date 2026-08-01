import Foundation

enum Suit: Int, CaseIterable, Comparable {
    case spades = 0, clubs, diamonds, hearts

    static func < (lhs: Suit, rhs: Suit) -> Bool { lhs.rawValue < rhs.rawValue }

    var symbol: String {
        switch self {
        case .spades: return "♠"
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        }
    }

    var isRed: Bool { self == .diamonds || self == .hearts }
}

/// Rank order is Ace-LOW only: A,2,3,4,5,6,7,8,9,10,J,Q,K. There is no Ace-high wraparound
/// for runs (no Q-K-A) — Ace is always the weakest rank, by design (see project spec).
enum Rank: Int, CaseIterable, Comparable {
    case ace = 0, two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .ace: return "A"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .ten: return "10"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        }
    }

    /// Scoring point value: Ace = 1, number cards = face value, face cards (J/Q/K) = 10.
    var pointValue: Int {
        switch self {
        case .ace: return 1
        case .jack, .queen, .king: return 10
        default: return rawValue + 1 // two -> 2 ... ten -> 10
        }
    }
}

struct Card: Identifiable, Hashable {
    let id = UUID()
    let rank: Rank
    let suit: Suit

    var label: String { "\(rank.label)\(suit.symbol)" }
    var pointValue: Int { rank.pointValue }
}

/// Hashable, non-UUID identity for tracking "which rank/suit region" without card instances
/// (used by the Hard AI's opponent-pickup tracking).
struct CardKey: Hashable {
    let rank: Rank
    let suit: Suit

    init(_ card: Card) {
        self.rank = card.rank
        self.suit = card.suit
    }
}

extension Array where Element == Card {
    static func freshDeck() -> [Card] {
        Suit.allCases.flatMap { suit in Rank.allCases.map { Card(rank: $0, suit: suit) } }
    }
}
