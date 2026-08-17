# Phỏm & Tá Lả — Vietnamese Rummy

Native SwiftUI iOS app implementing Phỏm (Vietnamese draw/discard Rummy) with an optional
"Tá Lả" ruleset layered on top. Bundle `com.quyenngo.phom`. Built following the house pattern
established by the sibling app `~/Projects/SamLoc` (shipped) — same PurchaseManager/Localization
core, same XcodeGen/screenshot/icon tooling shape — but the game engine itself is architecturally
different: SamLoc is a shed-the-fastest trick-taking game (Combo-beats-Combo), this is a
draw/meld/discard Rummy game (Meld-based). No code was shared between the two engines.

**Status: 🟡 READY FOR RESUBMISSION — scheduled batch 6, 2026-09-03 (staggered plan, with Igisoro +
Janggi), pending Apple's Guideline 5.6 account hold lifting 2026-08-18. 7-day-trial-then-full-
paywall change implemented 2026-08-18 (see below), code-only, NOT YET SUBMITTED — held for the
user's explicit go-ahead.**
The whole developer account (19 apps, including this one) was hit with a Guideline 5.6
"Developer Code of Conduct — Review Suspended" flag, almost certainly triggered by submitting
~19 similar template-style apps within an 8-day window (2026-08-01 through 2026-08-08). This is
an account-level flag, not a per-app rejection — resubmission is hard-blocked until 2026-08-18.
Prior state: submitted/WAITING_FOR_REVIEW 2026-08-01, app id `6796833347`, version `1.0.0`
(id `7808d607-e08a-4206-bcb5-4570b9f5c442`), build `b58dbfe8-b28b-4c5c-8b50-279e6fea814a`
attached, reviewSubmission `5c081100-c8d1-487e-aa7e-05a24b1c72ff`. Release type: automatic
(`AFTER_APPROVAL`). **Do not touch App Store Connect or resubmit before 2026-08-18.**

## No-permanent-free-tier rollout (2026-08-18)

Portfolio-wide fix, mirroring ChineseChess v1.0.6 and SamLoc (see
`~/Projects/SamLoc/CLAUDE.md`, commit `6bfa351`): both those sibling apps had real App Store
downloads but zero IAP purchases, because a permanently-free easy/normal AI tier was already
the complete game for casual players. Applied the identical mechanism here. **Code-only change
this pass — NOT YET SUBMITTED to the App Store, held for the user's explicit go-ahead** as part
of the staggered resubmission plan (avoiding another near-identical-submissions flag like the
Guideline 5.6 wave above); this rides along with, but does not itself trigger, the batch-6
resubmission.

**Gated before → after:**
- Before: Easy and Normal AI difficulty were free forever; only Hard AI (and card backs) were
  ever gated behind `isPro`.
- After: a 7-day trial starts on first launch (`PurchaseManager.trialActive`/
  `trialDaysRemaining`, backed by a `firstLaunchDate` UserDefaults key — existing installs with
  no stored date get the clock started now rather than being locked out immediately). During the
  trial, Easy/Normal are open and Hard stays locked (unchanged). Once the trial expires, **all
  three difficulties** lock for non-Pro users — `HomeView.isLocked(_:)` returns `true` across
  the board except for Pro accounts. Hard remains Pro-only at all times, trial or not. Home shows
  "Free trial — %d day(s) left" while active; the footnote/upgrade button and `UpgradeView`'s
  subtitle switch to "trial ended" copy afterward. Three new keys added to both
  `en.lproj`/`vi.lproj` Localizable.strings: `home.upgrade.trialended`, `home.trialdays`,
  `upgrade.subtitle.trialended`.
- Also fixed a latent DEBUG double-gate bug found while in this file:
  `PurchaseManager.updateEntitlementStatus()`'s `#if DEBUG isPro = true` was a bare override
  with no `PT_CAPTURE` exemption — a screenshot captured with `PT_CAPTURE=upgrade` would have
  shown "already purchased" instead of the real locked/buy state. Double-gated it to match the
  SamLoc/ChineseChess reference pattern (`PT_CAPTURE`/`PT_SKIP_ONBOARDING` env vars, matching
  this app's actual `ContentView.swift` naming). Note: the 2026-08-09 pass above had reviewed
  this exact code and called it clean — that review was checking for a different symptom
  (double-gating against another isPro check elsewhere), not this capture-mode leak, which is
  why it wasn't caught until this pass.

Verified via `xcodebuild -project PhomTaLa.xcodeproj -scheme PhomTaLa -destination
'generic/platform=iOS' -configuration Debug build` against the existing project file (no
`xcodegen generate` run this pass, since no source files were added/removed) — `** BUILD
SUCCEEDED **`, no errors. No interactive Simulator tap-through of the trial-expired state was
done this pass (code review + build verification only, same caveat as prior passes) — no
version bump, no archive/export/submit.

## Pre-resubmission quality pass (2026-08-09)

Full local review (code, build, logic, localization, IAP) done ahead of the 2026-08-18 window —
no ASC/App Store Connect actions taken, this pass was code-only. Bumped to **version 1.0.1,
build 2** (`project.yml` + `Info.plist`).

**Fixed:**
- **Real bug**: `GameModel.discard()` computed the "ù to"/"ù bụng" (all-big-melds) win kind
  regardless of game mode, so a Phỏm-mode win with all 4+-card melds would show the "Ù to! 🔥"
  banner and log line even though Phỏm mode's scoring never applies that bonus (only Tá Lả does,
  per `rules.tala.body`) — a mode-crossed win-kind bug, not a genuinely distinct Phỏm outcome.
  Gated `allBig` detection to `mode == .taLa` only; Phỏm now always reports `.normal` (or
  `.clean`) as its rules describe.
- **Real bug (sold-but-not-delivered feature)**: `UpgradeView` advertised "Exclusive card back
  designs" as a Pro perk, but no such feature existed anywhere in the code — `CardView` always
  rendered one hardcoded blue-diamond back regardless of purchase state. Implemented it for
  real: `CardBackStyle` (classic/maroon/gold, `PhomTaLa/Views/CardView.swift`), a
  `CardBackSwatch` preview view, a picker in `UpgradeView` (locked/dimmed for non-Pro, live
  selection for Pro, persisted via `@AppStorage("cardBackStyle")`), and `CardView` now renders
  whichever style is selected (falling back to classic for non-Pro accounts even if a stale
  selection is stored). New localized strings: `upgrade.cardBackPicker`, `cardback.classic`,
  `cardback.maroon`, `cardback.gold` (en + vi). Verified visually on a Debug-build iPhone 17 Pro
  Max simulator — all three swatches render distinctly, selection ring updates, picker disabled
  for non-Pro.

**Reviewed and confirmed already correct (no changes needed):**
- Both Phỏm and Tá Lả rulesets are genuinely distinct in scoring/win-tiers/cháy (not a stubbed
  copy) — see the "Judgment calls" section below and the bug fix above, which was the one place
  they'd bled into each other.
- `MeldFinder` set/run validation, Ace-low-only ranking, point values — re-verified by code
  reading against the rules text; matches.
- Full bilingual localization is real and complete — `en.lproj`/`vi.lproj` `Localizable.strings`
  have matching key sets, no missing translations, correct Vietnamese diacritics, natural
  (non-machine-translated) phrasing in both directions.
- In-app onboarding (`OnboardingView`, 3-page walkthrough covering goal/turn-structure/ù+cháy)
  and a full `RulesView` reference sheet (7 sections, including a Tá Lả-specific bonuses
  section) both exist and are reachable from Home ("How to Play" / "Full Rules"). Covers both
  variants, not just one.
- `PurchaseManager.updateEntitlementStatus()`'s `#if DEBUG { isPro = true }` is the only DEBUG
  special-case in the purchase path, guarded correctly, and doesn't double-gate against any
  other isPro check — no instance of this developer's recurring DEBUG/isPro double-gating bug
  pattern found in this app.
- No TODO/FIXME/placeholder/Lorem-ipsum/dummy text anywhere in the source tree (full grep sweep,
  zero hits).
- `xcodegen generate` + Debug build for iOS Simulator: clean, zero warnings (besides the routine
  "no AppIntents.framework dependency" notice), `BUILD SUCCEEDED`.

**Differentiation work done this pass:** the card-back-style picker above is genuine new
functionality (not present before), not just a bug fix — it's also small in scope per the
"prioritize correctness over redesign" guidance for this review wave.

**Still open / left for a future pass (not blocking resubmission):**
- No live device sideload or interactive XCUITest/idb tap-through of a full round was performed
  this pass either — still code-review + simulator-visual + logic-verification only, same
  caveat as the original build.
- The three new card-back gradients are palette-only (no new art/texture assets) — could be
  revisited for a more premium look in a later pass if conversion data ever justifies it.

## Polish pass (2026-08-12)

Second, deeper pass ahead of the 2026-09-03 batch-6 resubmission slot, building on the
2026-08-09 bug-focused pass above (not redone here). Bumped to **version 1.0.2, build 3**
(`project.yml`, both project-level and target-level blocks).

**Highest-stakes check: re-verified the card-back Pro feature is genuinely present, functional,
and correctly gated** — this app carries the same "sold-but-not-delivered IAP feature" defect
history as Tiến Lên and Hanafuda Koi-Koi, so the 2026-08-09 fix needed independent confirmation,
not just a re-read of the code:
- Built Debug for a dedicated `PhomTaLa-Capture` simulator, launched with `PT_CAPTURE=upgrade`
  (DEBUG defaults `isPro = true`) — screenshot confirmed "You own Phỏm & Tá Lả Pro", all three
  swatches (Classic/Maroon/Gold) rendering distinctly, Classic selected by default.
- Wrote `cardBackStyle=maroon` directly into the app's UserDefaults (via `defaults write` +
  `killall cfprefsd` to bust the simulator's preference cache), relaunched `PT_CAPTURE=upgrade` —
  selection ring correctly moved to Maroon. Relaunched `PT_CAPTURE=midgame` with that same
  persisted selection — **the maroon card back genuinely renders on the stock pile and all 3
  opponents' face-down hands in actual live `GameModel` game state**, not just the picker preview.
- Temporarily patched `PurchaseManager.updateEntitlementStatus()`'s DEBUG override to respect a
  `PT_FORCE_FREE` launch-arg override (revert confirmed via `git diff` showing no changes after),
  rebuilt, relaunched with the stale `maroon` selection still stored — confirmed a non-Pro account
  sees all three swatches dimmed/non-interactive with no selection ring and an "Unlock Pro" button
  (not "You own Pro"), **and** the live game correctly falls back to the classic blue back despite
  the stale stored preference (the `effectiveBackStyle` defense-in-depth guard works as commented).
- Conclusion: the feature is real, functional, and correctly gated in both directions — not a
  repeat of the sold-but-missing-feature defect this developer has hit three times now.

**UI bug found and fixed**: `screenshots/final/{en,vi}/04-upgrade.png` were stale — captured
before the 2026-08-09 card-back picker was built, so they showed only the 3 feature rows and no
picker UI at all (same "stale screenshot predating a later feature" class found in several
sibling apps this wave). Recaptured all 10 screenshots (both locales) on a dedicated
`PhomTaLa-Capture` simulator device to avoid the shared-simulator contamination race hitting
other concurrent agents this session; visually inspected all 10 — no contamination, correct
language per locale, and the new `04-upgrade.png` now shows the real card-back picker with a
selection ring (a nice side effect: `02-midgame.png`/`03-win.png` also picked up the maroon back
from the still-set test preference, which is genuine in-app UI, not fabricated). `capture_shots.py`
itself updated to target a dedicated per-app simulator device by name (creating it if missing)
instead of the previous generic `iPhone .*Pro Max` regex match, which risked grabbing whichever
shared simulator another concurrently-running agent had booted.

**Re-verified still solid, no changes needed**: onboarding, full bilingual in-app localization
(en/vi `Localizable.strings`), IAP DEBUG/isPro gating (single source of truth, confirmed clean —
temporarily flipped via `PT_FORCE_FREE` above, then reverted), mode-crossed win-kind fix from
2026-08-09, no build warnings.

**ASO refresh**: description and promotional text were already genuinely strong (authentic rules
detail, real differentiation language, no template boilerplate) — left unchanged per the
"only refresh keywords if copy is already strong" guidance. Refreshed keywords in both locales:
dropped terms redundant with the already-indexed name/subtitle (`phỏm`, `tá lả`, standalone
`rummy`, `bài việt nam` in vi, `bài online` in vi — the last one also risked implying online
multiplayer this offline-vs-AI app doesn't have), added non-redundant high-value terms
(`vietnamese`, `choi bai`, `4 player`, `meld` in en; `chơi bài`, `4 người chơi`, `gia đình`,
`bốc bài` in vi).

**Push-script bugs found and fixed in `~/asc-tools/asc_push_phomtala.py`** (same latent-bug
sweep applied across this session's other apps):
- `find_app_info`: returned the first appInfo matching *any* state in an unordered set, which
  could non-deterministically pick a locked state over the truly-editable `REJECTED` one when
  multiple appInfos exist. Fixed to try states in explicit priority order (matches the fix in
  `asc_push_tienlen.py`/`asc_push_surakarta.py`/etc.).
- `find_or_create_version` hardcoded `"1.0.0"` as the target version string unconditionally,
  which would have silently reset this app back to 1.0.0 on every push regardless of the actual
  local build version. Replaced with a module-level `VERSION_STRING` constant, now `"1.0.2"`.
- `set_iap_localization` had no error handling around the PATCH/POST calls — a locked
  `inAppPurchaseVersion` (409 `STATE_ERROR.IAP_VERSION_UNMODIFIABLE`, which this app's IAP hit
  live during this session's push) would have raised an unhandled `RuntimeError` and aborted the
  script before app/IAP pricing ran. Wrapped in try/except to degrade gracefully, matching the
  sibling scripts' fix.

**ASC push confirmed live**: `asc_push_phomtala.py` and `asc_push_phomtala_screenshots.py` both
run successfully — app info (name/subtitle/categories), version bumped 1.0.0 → 1.0.2
(`releaseType` stayed `AFTER_APPROVAL`), keywords/description/promo/support URL for both
locales, all 10 screenshots re-uploaded and reordered, app base price (Free) and IAP price
($2.99) both set. IAP name/description localization PATCH still 409s (pre-existing server-side
lock on this IAP's version, unrelated to this session's changes) — now handled as a graceful
skip instead of a crash; not fixable from this script, would need Apple to unlock the IAP version
or a new IAP version to be cut. No submit/review-submission action taken.

## Build staged for resubmission (2026-08-13)

Archived, exported, and uploaded a Release build ahead of the staggered resubmission — still
blocked until 2026-08-18 by the Guideline 5.6 account-level hold, this app resubmits
**2026-09-03** (batch 6). Build **1.0.2 (3)** uploaded via
`xcrun altool --upload-app` (Delivery UUID `c97e08c1-f203-423f-b2d5-6fddd459b8cb`), processed to `VALID` by Apple, and
attached to the existing `REJECTED` appStoreVersion (id `7808d607-e08a-4206-bcb5-4570b9f5c442`) via a direct
`PATCH appStoreVersions/{id}/relationships/build` API call — independently re-verified via a
follow-up `GET` on the same relationship, not just trusted from the PATCH's 204 response.

**Deliberately NOT done yet** — waiting for the user's explicit go-ahead on this app's
scheduled date, per the staggered resubmission plan:
1. Tick the Pro IAP into this version in the App Store Connect **web UI** — the API has no
   way to do this; it must be done from the version's own page (not the IAP's own page, which
   creates an orphaned draft submission — a mistake this portfolio hit once before).
2. Submit for review.

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
