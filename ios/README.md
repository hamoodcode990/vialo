# Decant — iOS project scaffold

## What this is, and what it isn't

Everything in this folder is a **scaffold**: the source files, Info.plist keys,
privacy manifest, and app icon a Mac developer would drop into a fresh Xcode
project. It is **not** a buildable `.xcodeproj` — Xcode's project file format
is complex enough that hand-writing one with no way to open it and verify
risks handing you something that simply won't open. Creating the empty
project shell in real Xcode takes about two minutes; everything after that is
copy-paste from here.

**You will need, regardless of anything in this folder:**
- A Mac with Xcode 15+ installed (Apple's toolchain doesn't run on Windows)
- An Apple Developer Program membership — $99/year — to submit to the App
  Store (free accounts can build to your own device but not publish)
- An Apple ID enrolled in that program

Nothing here can substitute for those three things.

## ⚠️ Before you submit: the "Pro" purchase is fake

`decant.html` currently unlocks Pro with this, in the click router:

```js
if(d.buy){S.pro=1;SFX.claim();toast('Pro unlocked');saveState();shop();return;}
```

That's a local flag flip — no payment happens. Apple's App Review Guideline
3.1.1 requires **any unlock of digital content or features inside an app to
go through StoreKit In-App Purchase**; a button labeled "Unlock Pro — $6.99"
that doesn't actually charge anyone will get the app rejected (at best) the
moment a reviewer taps it. This needs real work before submission:

1. Create an In-App Purchase product in App Store Connect (non-consumable,
   e.g. `com.yourcompany.decant.pro`) — requires a live Developer account and
   a few other one-time setup items (banking/tax info) App Store Connect will
   walk you through.
2. Replace the click handler with a `StoreKit 2` purchase call (`Product.products(for:)`,
   `product.purchase()`), verify the transaction, and set `S.pro=1` (plus
   `saveState()`) only after a verified purchase — and check for existing
   purchases on launch so "Restore purchase" (already in the UI copy) works.
3. This has to be native Swift code calling into the webview via
   `WKScriptMessageHandler`/`evaluateJavaScript`, since a WKWebView can't call
   StoreKit directly. I didn't build this bridge — it needs a live Developer
   account and product configuration in App Store Connect to test against,
   neither of which I have access to here.

I'm flagging this clearly rather than leaving it for App Review to find.

## Step-by-step

1. **Create the project.** Xcode → File → New → Project → iOS → App.
   - Product Name: `Decant`
   - Interface: SwiftUI, Language: Swift
   - Uncheck "Use Core Data" and "Include Tests" (not needed)
   - Save it anywhere; you'll replace its contents next.

2. **Delete the generated `ContentView.swift` and `<ProjectName>App.swift`**
   Xcode created, and drag in these files instead (check "Copy items if
   needed" and make sure the app target's checkbox is ticked):
   - `Decant/DecantApp.swift`
   - `Decant/ContentView.swift`
   - `Decant/decant.html` — **the actual game**, copied verbatim from the
     repo root. Make sure it's added as a bundle *resource* (Xcode does this
     automatically for `.html` files), not compiled source.
   - `Decant/PrivacyInfo.xcprivacy`

3. **Replace the asset catalog.** Delete Xcode's default `Assets.xcassets`
   and drag in `Decant/Assets.xcassets` from this folder — it already has the
   app icon (`AppIcon.appiconset`, single 1024×1024 source, Xcode 14+'s
   simplified format that auto-generates every other size) and a
   `LaunchBackground` color matching the game's ivory background.

4. **Add the Info.plist keys.** Select the project → your target → the
   **Info** tab. Add each key from `Decant/Info.plist` in this folder (open
   it as text to see the raw key names — `CFBundleDisplayName`,
   `UILaunchScreen` → `UIColorName` = `LaunchBackground`, the status bar and
   orientation keys, `ITSAppUsesNonExemptEncryption` = `NO`). Adding them
   through the Info tab works regardless of whether your project uses an
   auto-generated or file-based Info.plist, which is safer than me telling
   you to swap in a raw file I can't verify against your project's build
   settings.

5. **Set your bundle identifier.** Target → Signing & Capabilities → change
   `Bundle Identifier` to something you own, e.g. `com.yourname.decant`.
   Select your Team (requires the paid account to run on a real device or
   submit; the free tier works for the simulator).

6. **Build and run** — Simulator first (any iPhone). You should see the
   ivory menu, the four mode tiles, everything exactly as it looks in
   Chrome. Test sound (tap something — WebAudio needs a user gesture to
   unlock, same as the web version), test a full duel, test Solo.

7. **Test on a real device** before archiving — the simulator doesn't
   exercise Safe Area insets, haptics-adjacent touch behavior, or audio
   output the same way hardware does.

8. **Archive and upload** — Product → Archive, then use the Organizer window
   to upload to App Store Connect. This is also where you'd attach the
   TestFlight beta before a public release.

## What App Store Connect will ask for that no file can provide

- **Screenshots** for each device size you support (at minimum 6.7" and
  5.5" iPhone). Since the whole UI is one responsive web page, the cleanest
  way to get these is running the app in Simulator at each required device
  size and using Simulator's own screenshot command (⌘S).
- **Privacy policy URL** — required even though this app collects and sends
  nothing; App Store Connect won't let you submit without one. A one-page
  static statement ("Decant stores your stats and progress locally on your
  device. Nothing is collected, transmitted, or shared.") hosted anywhere
  you control is enough.
- **App description, keywords, support URL, age rating questionnaire** —
  all filled in through the App Store Connect web UI, not a file.
- **Export compliance** — the `ITSAppUsesNonExemptEncryption = NO` key
  already in the provided Info.plist answers this automatically (the app
  uses no custom encryption), so you shouldn't be prompted again at
  submission.

## Why the web app already behaves like a native one

`decant.html` was built with iOS in mind from the start — `env(safe-area-inset-*)`
throughout the CSS, `user-scalable=no` and pinch/double-tap-zoom blocking,
rubber-band scroll blocking outside scrollable panes, and a WebAudio unlock
on first touch. `ContentView.swift` deliberately stays out of its way
(`contentInsetAdjustmentBehavior = .never`, scroll/bounce disabled on the
wrapper) rather than re-implementing any of that natively — the page already
does it.
