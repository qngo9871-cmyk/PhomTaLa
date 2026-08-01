import SwiftUI

/// Three-page first-launch walkthrough: goal, turn structure, ù/cháy. Shown once, and
/// re-accessible from Home via "How to Play" alongside the deeper Rules reference sheet.
struct OnboardingView: View {
    var onFinished: () -> Void

    @State private var page = 0

    private let pageKeys: [(title: String, body: String)] = [
        ("onboarding.goal.title", "onboarding.goal.body"),
        ("onboarding.combos.title", "onboarding.combos.body"),
        ("onboarding.special.title", "onboarding.special.body"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.28), .black],
                            startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("🀄").font(.system(size: 48))

                Text(L(pageKeys[page].title))
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L(pageKeys[page].body))
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                HStack(spacing: 8) {
                    ForEach(pageKeys.indices, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Color.white : Color.white.opacity(0.25))
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                Button(action: advance) {
                    Text(page == pageKeys.count - 1 ? L("onboarding.begin") : L("onboarding.next"))
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.large)
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
            .padding()
        }
        .animation(.easeInOut, value: page)
    }

    private func advance() {
        if page < pageKeys.count - 1 {
            page += 1
        } else {
            onFinished()
        }
    }
}

#Preview { OnboardingView(onFinished: {}) }
