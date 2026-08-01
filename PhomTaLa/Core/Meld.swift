import Foundation

/// "phỏm ngang" (a same-rank set, 3-4 different suits) or "phỏm dọc" (a same-suit run of
/// 3+ consecutive ranks, Ace-low only).
enum MeldKind {
    case set
    case run
}

struct Meld: Identifiable {
    let id = UUID()
    var cards: [Card]
    var kind: MeldKind

    /// A meld with 4+ cards. Tá Lả's "ù to"/"ù bụng" bonus requires every laid meld to be
    /// big — i.e. no minimal 3-card melds anywhere in the winning layout.
    var isBig: Bool { cards.count >= 4 }
}

/// Pure functions for validating and discovering melds. No "laying off" onto existing melds
/// is implemented anywhere in this app (see project CLAUDE.md) — a laid meld is fixed forever
/// once placed, so this type only ever needs to reason about cards still in a player's hand.
enum MeldFinder {
    static func isValidSet(_ cards: [Card]) -> Bool {
        guard cards.count == 3 || cards.count == 4 else { return false }
        guard Set(cards.map { $0.rank }).count == 1 else { return false }
        return Set(cards.map { $0.suit }).count == cards.count
    }

    static func isValidRun(_ cards: [Card]) -> Bool {
        guard cards.count >= 3 else { return false }
        guard Set(cards.map { $0.suit }).count == 1 else { return false }
        let ranks = cards.map { $0.rank.rawValue }.sorted()
        guard Set(ranks).count == ranks.count else { return false }
        for i in 1..<ranks.count where ranks[i] != ranks[i - 1] + 1 { return false }
        return true
    }

    static func isValidMeld(_ cards: [Card]) -> Bool {
        isValidSet(cards) || isValidRun(cards)
    }

    static func meldKind(_ cards: [Card]) -> MeldKind? {
        if isValidSet(cards) { return .set }
        if isValidRun(cards) { return .run }
        return nil
    }

    /// Every valid meld (3- and 4-card sets, every length-3+ run) that can be formed from
    /// subsets of `cards`. Hand size is capped at 10, so this stays cheap.
    static func allPossibleMelds(in cards: [Card]) -> [[Card]] {
        var results: [[Card]] = []

        let byRank = Dictionary(grouping: cards, by: { $0.rank })
        for (_, group) in byRank where group.count >= 3 {
            for combo in combinations(group, 3) where isValidSet(combo) { results.append(combo) }
            if group.count == 4 { results.append(group) }
        }

        let bySuit = Dictionary(grouping: cards, by: { $0.suit })
        for (_, group) in bySuit {
            let sorted = group.sorted { $0.rank.rawValue < $1.rank.rawValue }
            for start in 0..<sorted.count {
                var run: [Card] = [sorted[start]]
                for next in (start + 1)..<sorted.count {
                    guard sorted[next].rank.rawValue == run.last!.rank.rawValue + 1 else { break }
                    run.append(sorted[next])
                    if run.count >= 3 { results.append(run) }
                }
            }
        }
        return results
    }

    private static func combinations<T>(_ arr: [T], _ k: Int) -> [[T]] {
        guard k > 0 else { return [[]] }
        guard arr.count >= k else { return [] }
        if arr.count == k { return [arr] }
        var rest = arr
        let first = rest.removeFirst()
        return combinations(rest, k - 1).map { [first] + $0 } + combinations(rest, k)
    }

    /// Best-effort search for the largest set of non-overlapping valid melds inside `cards`.
    /// Used for "ù sạch" detection (does everything partition with nothing left over?) and by
    /// the AI's greedy melding pass. Not guaranteed globally optimal on pathological hands, but
    /// hand size ≤10 keeps the branch-and-bound search small for every realistic Phỏm hand.
    static func bestPartition(of cards: [Card]) -> [[Card]] {
        let candidates = allPossibleMelds(in: cards).sorted { $0.count > $1.count }
        var best: [[Card]] = []
        func score(_ groups: [[Card]]) -> Int { groups.reduce(0) { $0 + $1.count } }

        func search(remainingIDs: Set<UUID>, chosen: [[Card]], startIdx: Int) {
            if score(chosen) > score(best) { best = chosen }
            guard startIdx < candidates.count else { return }
            for i in startIdx..<candidates.count {
                let candidate = candidates[i]
                let ids = Set(candidate.map { $0.id })
                guard ids.isSubset(of: remainingIDs) else { continue }
                search(remainingIDs: remainingIDs.subtracting(ids), chosen: chosen + [candidate], startIdx: i + 1)
            }
        }
        search(remainingIDs: Set(cards.map { $0.id }), chosen: [], startIdx: 0)
        return best
    }

    /// True if every card in `cards` belongs to some meld in the best partition — i.e. nothing
    /// would be left over to discard. This is the "ù sạch" (clean win) test.
    static func canPartitionCompletely(_ cards: [Card]) -> Bool {
        guard !cards.isEmpty else { return false }
        return bestPartition(of: cards).reduce(0) { $0 + $1.count } == cards.count
    }
}
