# Phỏm & Tá Lả — Vietnamese Rummy

Native SwiftUI iOS app implementing Phỏm (Vietnamese draw/discard Rummy) with an optional
"Tá Lả" ruleset layered on top. Bundle `com.quyenngo.phom`. Built following the house pattern
established by the sibling app `~/Projects/SamLoc` (shipped) — same PurchaseManager/Localization
core, same XcodeGen/screenshot/icon tooling shape — but the game engine itself is architecturally
different: SamLoc is a shed-the-fastest trick-taking game (Combo-beats-Combo), this is a
draw/meld/discard Rummy game (Meld-based). No code was shared between the two engines.

**Status: 🟢 SUBMITTED, WAITING_FOR_REVIEW (2026-08-01).** App id `6796833347`, version `1.0.0`
(id `7808d607-e08a-4206-bcb5-4570b9f5c442`), build `b58dbfe8-b28b-4c5c-8b50-279e6fea814a`
attached, reviewSubmission `5c081100-c8d1-487e-aa7e-05a24b1c72ff`. Release type: automatic
(`AFTER_APPROVAL`).

## Deploy / resubmit pattern

No Xcode account/Distribution cert on this machine — pass the ASC API key explicitly to
xcodebuild (see [[feedback_asc_release_and_signing]]):
```
xcodegen generate
xcodebuild -project PhomTaLa.xcodeproj -scheme PhomTaLa -configuration Release \
  -archivePath build/PhomTaLa.xcarchive -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016 \
  archive
xcodebuild -exportArchive -archivePath build/PhomTaLa.xcarchive -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016
xcrun altool --upload-app --type ios -f build/export/PhomTaLa.ipa \
  --apiKey G85WXB4AF5 --apiIssuer 2e969722-fc4d-444c-af74-7e0233efd016
```
Metadata scripts (`asc_push_phomtala.py` / `_review.py` / `_screenshots.py`) are idempotent —
re-run after copy changes. No `asc_submit_phomtala.py` exists; submission was done via one-off
`reviewSubmissions` → `reviewSubmissionItems` → `PATCH submitted=true` calls (copy the pattern
from `asc_submit_woktonight.py` if resubmitting).

## What this is

- Standard 52-card deck, no jokers. 4 players (you + 3 AI), 9 cards dealt each. Remainder forms
  a face-down stock pile; the top card flips face-up to start the discard pile.
- Ace is **always low** — ranks run A,2,3...K. There is no Ace-high run (no Q-K-A).
- Each turn: draw one card (stock or discard-pile top, player's choice) → optionally lay down
  any number of valid melds ("phỏm") found in hand → discard exactly one card to end the turn.
- A meld ("phỏm ngang"/set: 3-4 same rank, distinct suits; "phỏm dọc"/run: 3+ consecutive ranks,
  same suit) is **locked forever** once laid down — no "laying off" extra cards onto an existing
  meld later. This is a deliberate simplification per spec, not an oversight.
- **Winning ("ù")**: instant win the moment your hand is melded down to nothing but the one card
  you then discard. **"Ù sạch"** (clean win): your very first 10-card hand, before ever
  discarding, melds perfectly with nothing left over at all — no discard needed. Detected
  automatically right after the draw via an exhaustive partition search (`MeldFinder.bestPartition`).
- **If the stock runs out** before anyone wins: round ends in a draw. Whoever has the lowest
  point-total of unmelded cards in hand wins the round instead (face/10 = 10pts, Ace = 1pt,
  numbers = face value); ties split the payout and neither counts as a round win.
- **Scoring**: the round winner collects from each opponent, individually, based on that
  opponent's own unmelded hand value at the moment of the win. First to 3 round wins takes the
  match (`matchTarget = 3`, matching SamLoc's convention).

### Phỏm mode vs. Tá Lả mode

Both modes share the identical core engine above (`GameModel`, `MeldFinder`, `AIPlayer`) — the
mode only changes the scoring multiplier table, selected on Home before a match starts:

- **Phỏm**: flat win (1x), doubled (2x) only for "ù sạch".
- **Tá Lả**: three graduated win tiers — "ù thường" (normal, 1x), **"ù to"/"ù bụng"** (every
  laid meld is 4+ cards — no minimal 3-card melds anywhere in the layout — 2x), "ù sạch" (3x).
  Also adds the **"cháy" (burned) penalty**: if a player discards a card and the very next
  player draws that *exact* card from the discard pile and wins *that same turn*, the discarder's
  individual contribution to the payout is doubled (not everyone's — just theirs).

## Judgment calls / simplifications made (all deliberate, documented here per the build spec)

- **"Cháy" simplification**: the real mechanic is "did this discard let anyone complete a
  near-finished hand." Implemented instead as: won this turn using a discard-pile pickup → the
  player who discarded that exact card (always the immediately-preceding turn's player, since
  turns are strictly sequential) pays double. This is the exact simplification the build spec
  asked for — no retroactive multi-player hand analysis.
- **Hard AI's opponent-awareness heuristic**: the spec's phrasing ("tracks which ranks/suits
  opponents have discarded to avoid completing their visible partial melds") doesn't map cleanly
  onto a no-lay-off ruleset, since a locked meld can't be extended anyway. Implemented instead
  as: Hard AI tracks which cards each opponent has *picked up* from the discard pile (a genuine
  "I want this" signal) and treats same-rank / adjacent same-suit cards as riskier to discard —
  see `GameModel.dangerousCardKeys` and `AIPlayer.usefulness`.
- **Starting player rotates** each round (round-robin) — the spec didn't specify who leads first;
  SamLoc's "whoever holds 3♠" convention doesn't apply here (no natural analog), so this app just
  rotates the seat instead, which is standard practice in real Rummy variants.
- **`layMeld` refuses to leave a hand at exactly 0 cards** outside of the automatic "ù sạch"
  path (which is caught and resolved immediately after the draw, before manual/AI melding ever
  starts). This guarantees a normal win always ends via the discard-of-the-last-card path
  described in the spec, and avoids an unreachable "nothing left to discard" state.
- **Draw-pile-exhausted payout**: the spec says the lowest unmelded-value player(s) "win" the
  round but doesn't specify the payout amount. Implemented as: each non-winner pays their own
  unmelded hand value, split evenly among tied winners — consistent with the normal win's
  "pay based on your own hand value" scoring logic elsewhere in the app.
- **`MeldFinder.bestPartition`** is a best-effort branch-and-bound search, not a guaranteed
  globally-optimal partition on pathological hands — deliberately, since hand size is capped at
  10 and the spec explicitly called for "simple exhaustive meld-finder... hand size ≤10 makes
  this cheap" rather than a fully general solver.

## AI (`Core/AIPlayer.swift`)

- **Easy**: always draws from stock (ignores the discard pile entirely); discards randomly among
  its 3 least-useful cards instead of always the single most-useless one.
- **Normal**: takes the discard-pile top only when it directly forms or extends a meld already
  possible in hand; otherwise draws from stock. Greedily lays down every valid meld it can find
  (largest-first, non-overlapping). Discards the single least-useful card.
- **Hard**: same greedy melding as Normal, plus tracks opponents' discard-pile pickups this round
  and avoids discarding cards near those ranks/suits (see judgment call above).

## Structure

- `PhomTaLa/Core/` — `Card.swift` (Suit/Rank/Card, Ace-low, point values), `Meld.swift`
  (meld validation + exhaustive partition search), `Player.swift` (Player/AIDifficulty/GameMode/
  WinKind), `GameModel.swift` (the full draw→meld→discard turn engine + both modes' scoring +
  cháy), `GameModel+Capture.swift` (deterministic states for screenshot capture, `#if DEBUG`
  only), `AIPlayer.swift`, `PurchaseManager.swift`, `Localization.swift` (both copied
  byte-for-byte from SamLoc except the product ID / capture env var name).
- `PhomTaLa/Views/` — `HomeView` (mode + difficulty pickers), `GameView` (table layout: stock/
  discard piles, opponent rows with locked melds, hand + lay-meld/discard controls, round/match
  overlays), `CardView`, `HandView` (+ `MeldRowView` for locked-meld display), `RulesView`,
  `OnboardingView`, `UpgradeView`.
- `PhomTaLa/{en,vi}.lproj/Localizable.strings` — hand-written bilingual UI strings using correct
  terminology (phỏm, ù, ù sạch, ù to, cháy, bốc bài, đánh bài, nọc for stock pile). Every
  English `%@`-for-playername string was deliberately phrased to stay grammatical when
  `%@` = "You" (invariant verbs: "drew," "discarded," "won," "got burned" — never "was burned"
  or third-person `-s` forms) — this is the exact grammar trap SamLoc's CLAUDE.md documents
  having shipped once before.
- `capture_shots.py` — `PT_CAPTURE`/`PT_LANG` DEBUG launch-arg driven screenshot capture (home/
  midgame/win/upgrade/rules scenarios), same compose-with-caption-band approach as SamLoc's.
- `make_icon.py` — generates the real 1024×1024 app icon: three fanned Aces (a completed
  same-rank meld) on a maroon gradient. See "App Store readiness pass" below.
- `project.yml` — XcodeGen spec. Run `xcodegen generate` (or `./rebuild.sh`, which also builds)
  after adding/removing source files.

## Verification performed this build

- `xcodegen generate` + `xcodebuild ... -sdk iphonesimulator build` — clean build, zero warnings
  besides the routine "no AppIntents.framework dependency" notice.
- Installed and launched on an iPhone 17 Pro Max simulator; visually inspected onboarding, home,
  live mid-game (drawn state, hand, locked meld, stock/discard piles), the "ù to" win overlay,
  rules, and upgrade screens in both English and Vietnamese via the `PT_CAPTURE`/`PT_LANG` debug
  hooks — all rendered correctly, no crashes.
- A standalone `swift` script (not part of the Xcode target) exercised `MeldFinder` directly:
  confirmed sets require distinct suits, runs require same suit + consecutive ranks, Q-K-A is
  correctly rejected as a run (no Ace-high wraparound) while A-2-3 is correctly accepted, point
  values match the spec (A=1, 2-10=face, J/Q/K=10), and `canPartitionCompletely`/`bestPartition`
  correctly detect a perfect 10-card partition vs. one dangling leftover card.
- No UI-automation (XCUITest/idb) tap-through of the live interactive flow was performed — no
  such tooling was available in this environment. The turn state machine (draw → meld → discard
  → advance/AI-trigger) was verified by code review plus the deterministic capture scenarios
  above, which exercise real `GameModel` state (not mocked).

## App Store readiness pass (2026-07-31)

- **App icon**: `make_icon.py` rewritten from the placeholder stub — bold single-emblem style
  matching SamLoc's house look, but a distinct design: three fanned Aces (♣♥♦) — a completed
  same-rank "phỏm ngang" meld — on a deep maroon/red gradient (`#2a0a10` → near-black), the
  traditional Vietnamese card-table color, deliberately distinct from SamLoc's felt-green. Each
  card layer gets a soft drop-shadow so the fan reads as three separate overlapping cards, plus a
  corner rank pip so they read as real playing cards. Generated at 1024×1024, written directly
  into `Assets.xcassets/AppIcon.appiconset/AppIcon.png`, dimensions verified via PIL.
- **Screenshots**: ran `capture_shots.py` (no code changes needed — the `PT_CAPTURE`/`PT_LANG`
  DEBUG hooks in `ContentView.swift` and `GameModel+Capture.swift` already worked correctly).
  All 10 outputs (`screenshots/final/{en,vi}/01-home.png` … `05-rules.png`) were visually
  inspected. The first run produced a contaminated `04-upgrade.png` (showed an unrelated
  "Surakarta Pro" screen) — root-caused to a one-off race with a concurrent Surakarta screenshot
  process sharing the same booted "iPhone 17 Pro Max" simulator, not a bug in this app's code or
  script; confirmed no such process was running, re-ran the capture, and all 10 images came back
  clean on the second pass: correct Vietnamese diacritics (no mojibake), correct language per
  locale, no clipping/overlap on the busier table layout (stock/discard piles, opponent meld
  rows), no placeholder text, and real card/meld rendering throughout.
- **Legal site**: `~/Projects/phomtala-legal` created from the `fanorona-legal` template
  (index/privacy/support, same CSS, contact `qngo@icloud.com`), with content adapted to this
  app's actual ruleset and Pro feature list (Hard AI, exclusive card backs, unlimited matches —
  pulled from `PurchaseManager.swift`/`UpgradeView.swift`, not guessed) and a support-page
  explanation of Phỏm mode vs. Tá Lả mode (graduated win tiers + "cháy" penalty). Pushed to a new
  public GitHub repo and GitHub Pages enabled, matching the existing `fanorona-legal` /
  `janggi-legal` / `surakarta-legal` convention. Live at
  **https://qngo9871-cmyk.github.io/phomtala-legal/**.

## TODOs for the next step (out of scope for this pass)

- `~/asc-tools` — bundle-ID registration, App Store Connect app record, IAP product
  (`com.quyenngo.phom.pro`), metadata/screenshots push (see SamLoc's `asc_push_samloc*.py` /
  `asc_register_samloc.py` scripts as the template — no PhomTaLa-specific ASC scripts exist yet).
- Consider a live device sideload + a manual interactive playtest of a full round (draw/meld/
  discard/win/cháy) before submission, since this build's verification was build+visual+logic-only.
