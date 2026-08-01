import SwiftUI

struct RulesView: View {
    @Environment(\.dismiss) private var dismiss

    private let sections: [(String, String)] = [
        ("rules.deal.title", "rules.deal.body"),
        ("rules.meld.title", "rules.meld.body"),
        ("rules.turn.title", "rules.turn.body"),
        ("rules.win.title", "rules.win.body"),
        ("rules.tala.title", "rules.tala.body"),
        ("rules.noWinner.title", "rules.noWinner.body"),
        ("rules.scoring.title", "rules.scoring.body"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sections, id: \.0) { title, body in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L(title)).font(.headline)
                            Text(L(body)).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L("rules.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("rules.done")) { dismiss() }
                }
            }
        }
    }
}

#Preview { RulesView() }
