import SwiftUI

struct HomeView: View {
    @EnvironmentObject var loc: LocalizationManager
    @StateObject private var purchases = PurchaseManager.shared
    @State private var showGame = false
    @State private var showRules = false
    @State private var showUpgrade = false
    @State private var showOnboarding = false
    @State private var selectedMode: GameMode = .phom
    @State private var selectedDifficulty: AIDifficulty = .easy
    @State private var game = GameModel()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.28), .black],
                                startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 6) {
                            Text("🀄").font(.system(size: 52))
                            Text(L("home.title")).font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white).multilineTextAlignment(.center)
                            Text(L("home.subtitle")).font(.subheadline).foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.top, 40)

                        VStack(spacing: 10) {
                            Text(L("home.mode")).font(.caption).foregroundStyle(.white.opacity(0.6))
                            Picker("", selection: $selectedMode) {
                                ForEach(GameMode.allCases) { m in
                                    Text(L(m.titleKey)).tag(m)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 320)
                            Text(L(selectedMode.subtitleKey))
                                .font(.caption2).foregroundStyle(.white.opacity(0.55))
                                .multilineTextAlignment(.center).padding(.horizontal, 30)
                        }

                        VStack(spacing: 10) {
                            Text(L("home.difficulty")).font(.caption).foregroundStyle(.white.opacity(0.6))
                            Picker("", selection: $selectedDifficulty) {
                                ForEach(AIDifficulty.allCases) { d in
                                    Text(L(d.titleKey) + (d == .hard && !purchases.isPro ? " 🔒" : "")).tag(d)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 320)
                        }

                        VStack(spacing: 14) {
                            Button {
                                if selectedDifficulty == .hard && !purchases.isPro {
                                    showUpgrade = true
                                } else {
                                    game = GameModel()
                                    game.startMatch(mode: selectedMode, difficulty: selectedDifficulty)
                                    showGame = true
                                }
                            } label: {
                                Text(L("home.play")).font(.title3.bold()).frame(maxWidth: 280).padding()
                            }
                            .buttonStyle(.borderedProminent).tint(.blue)

                            HStack(spacing: 20) {
                                Button { showOnboarding = true } label: {
                                    Text(L("home.howtoplay")).foregroundStyle(.white.opacity(0.85))
                                }
                                Button { showRules = true } label: {
                                    Text(L("home.rules")).foregroundStyle(.white.opacity(0.85))
                                }
                            }

                            if !purchases.isPro {
                                Button { showUpgrade = true } label: {
                                    Text(L("home.upgrade")).font(.footnote).foregroundStyle(.yellow)
                                }
                            }
                        }

                        Picker("", selection: $loc.language) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 220)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $showGame) {
                GameView(game: game)
            }
            .sheet(isPresented: $showRules) { RulesView() }
            .sheet(isPresented: $showUpgrade) { UpgradeView() }
            .sheet(isPresented: $showOnboarding) { OnboardingView(onFinished: { showOnboarding = false }) }
            .task { await purchases.loadProduct() }
        }
    }
}

#Preview { HomeView().environmentObject(LocalizationManager.shared) }
