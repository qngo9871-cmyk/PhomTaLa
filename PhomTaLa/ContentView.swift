import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        #if DEBUG
        if let lang = ProcessInfo.processInfo.environment["PT_LANG"], let l = AppLanguage(rawValue: lang) {
            LocalizationManager.shared.setLanguage(l)
        }
        if let capture = ProcessInfo.processInfo.environment["PT_CAPTURE"], capture != "home" {
            if capture == "onboarding" {
                return AnyView(OnboardingView(onFinished: {}).preferredColorScheme(.dark))
            }
            if capture == "upgrade" {
                return AnyView(UpgradeView().preferredColorScheme(.dark))
            }
            if capture == "rules" {
                return AnyView(RulesView().preferredColorScheme(.dark))
            }
            let game = GameModel()
            game.captureSetup(capture)
            return AnyView(NavigationStack { GameView(game: game) }.preferredColorScheme(.dark))
        }
        if ProcessInfo.processInfo.environment["PT_SKIP_ONBOARDING"] != nil {
            return AnyView(HomeView())
        }
        #endif
        if !hasSeenOnboarding {
            return AnyView(OnboardingView(onFinished: { hasSeenOnboarding = true }))
        }
        return AnyView(HomeView())
    }
}

#Preview { ContentView() }
