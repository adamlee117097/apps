# Phase 0 Research

Research date: 2026-11-25. Done on Linux, not on the Mac mini.

How to read this document:

- Every technical claim carries a link that was opened on the research date.
  Quotes are verbatim from the linked page.
- **Unverified** means no primary source was found. The text says what would
  settle it.
- **Inference** marks a conclusion drawn by Claude from sourced facts. It is not
  a sourced fact.
- Apple's documentation pages are rendered by JavaScript. They were read through
  the JSON that backs each page (`https://developer.apple.com/tutorials/data/<path>.json`).
  The links below are the normal page URLs for the same content.

## 1. Target hardware, re-verified

Source for this section unless noted: Apple's spec page,
<https://www.apple.com/iphone-duo/specs/>, and Apple's press release,
<https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/>.

| Brief says | Apple says | Result |
|---|---|---|
| Released October 23, 2026 | "Pre-orders begin Friday, October 16, with availability beginning Friday, October 23." (press release) | Confirmed |
| Runs iOS 27 | Spec page: "Operating System: iOS 27". Press release: "iPhone Duo will be available with iOS 27.1." | Confirmed. Ships with 27.1 |
| Inner 7.6" OLED, 1878×2670, 430 ppi | "7.6‑inch (diagonal) all‑screen OLED folding display", "1878‑by‑2670-pixel resolution at 430 ppi" | Confirmed |
| Outer 5.4" OLED, 1398×2034, 460 ppi | "5.4‑inch (diagonal) all‑screen OLED display", "1398‑by‑2034-pixel resolution at 460 ppi" | Confirmed |
| Inner display "roughly 4:3" | 2670 / 1878 = 1.42. 4:3 is 1.33, 3:2 is 1.50 | **Correction.** The inner display is about 1.42:1, between 4:3 and 3:2 |
| Wider than tall when open | Open: "Width: 6.48 inches (164.6 mm)", "Height: 4.64 inches (117.8 mm)" | Confirmed |
| 120Hz on both displays | Under "Both displays": "ProMotion technology with adaptive refresh rates up to 120Hz" | Confirmed |
| A20 Pro, 6-core CPU (2 performance + 4 efficiency) | "6‑core CPU with 2 super cores and 4 efficiency cores" | Confirmed. Apple's term is "super cores" |
| 7-core GPU with Neural Accelerators, dual 16-core Neural Engine, ray tracing | "7‑core GPU with Neural Accelerators", "Dual 16‑core Neural Engine", "Hardware‑accelerated ray tracing" | Confirmed |
| RAM not listed | No RAM figure on the spec page | Confirmed. RAM is **unverified**; a teardown or `ProcessInfo.physicalMemory` on the device would settle it |
| Apple Pencil (USB-C) on the inner display, no hover | "Supports Apple Pencil (USB-C)" is listed under "Both displays". Footnote: "Hover is not supported when using Apple Pencil (USB-C) with iPhone Duo." | Hover: confirmed. **Correction:** the spec page lists Pencil support under both displays, not only the inner one. See 1.1 |
| No hinge or angle sensor listed | Sensors: "Touch ID fingerprint sensor, Barometer, High dynamic range gyro, High-g accelerometer, Proximity sensor, Four ambient light sensors" | Confirmed for the spec page. iOS does expose the hinge angle to apps. See 3.2 |
| Dual battery, vapor-cooled | "Dual built-in rechargeable lithium‑ion batteries". Press release: "a custom-designed vapor chamber and a dual-battery architecture" | Confirmed |

Other facts that matter for the game:

- **Both displays have nearly the same shape.** Press release: "Both displays
  share the same aspect ratio, so content scales proportionally, ensuring visual
  continuity." By pixel count the outer display is 2034 / 1398 = 1.455 and the
  inner is 1.42, so they are close but not identical. Inference: one map layout
  can be scaled between the two displays with small margins, rather than needing
  two different map shapes.
- **Authentication is Touch ID**, not Face ID: "Fingerprint sensor built into the
  side button".
- **Split View exists on iPhone Duo.** Press release: "Split View allows users to
  open two apps side by side on iPhone for the first time." The game can
  therefore be resized to part of the inner display by the user.
- Apple markets gaming on it: "the vapor chamber sustains it for high-frame-rate
  gaming and multitasking on the large display."

### 1.1 Apple Pencil details

- Pencil support needs **iOS 27.2**, not 27.1. Apple Support: "You can use Apple
  Pencil (USB-C) with these iPad models with iPadOS 17.1.1 or later, and with
  iPhone Duo with iOS 27.2".
  <https://support.apple.com/en-us/108937> (published November 5, 2026)
- **Apple Pencil (USB-C) has no pressure sensitivity.** Apple's comparison table
  marks "Pressure sensitivity" as "Compatible with Apple Pencil Pro" and "Not
  compatible with Apple Pencil (USB-C)". It does have tilt: "Apple Pencil (USB‑C)
  provides pixel-perfect precision, low latency, and tilt sensitivity".
  <https://www.apple.com/apple-pencil/>
- Apple Pencil Pro is not listed as working with iPhone Duo on that support page.
  Only the USB-C model is.

Consequence for the design: Pencil input on iPhone Duo gives position and tilt.
Any control that depends on pressing harder is not possible. Drawing movement
paths and precise taps only need position, so they are unaffected.

## 2. Build pipeline and environment (brief 2.1)

The Mac mini checks (`sw_vers`, `system_profiler`, `xcodebuild -version`) are
skipped until Adam is on the Mac, as the brief instructs.

### 2.1 Xcode and macOS versions

Source: <https://developer.apple.com/support/xcode/> ("SDKs and system
requirements" table).

| Xcode | Requires | iOS SDK |
|---|---|---|
| 27.3 beta 2 | macOS Tahoe 26.6 or later | iOS 27.3 |
| 27.2 | macOS Tahoe 26.6 or later | iOS 27.2 |
| 27.1 | macOS Tahoe 26.6 or later | iOS 27.1 |
| 27 | macOS Tahoe 26.6 or later | iOS 27 |

- **Xcode 27.1 is the minimum for a proper iPhone Duo build.** Apple's tech talk:
  "When you build your app with the iOS 27.1 SDK, your app extends to the edge of
  the screen" and "To get the full-screen experience, download Xcode 27.1. Choose
  the iPhone Duo simulator to run your app in Device Hub."
  <https://developer.apple.com/videos/play/tech-talks/111461/>
- All the fold APIs in section 3 are marked iOS 27.1.
- Recommendation: install **Xcode 27.2** (current release). It includes the 27.1
  APIs and matches the iOS version that Pencil support needs.
- **The Mac mini must run macOS Tahoe 26.6 or later.** Whether Adam's Mac mini
  can is unknown until the 2.1 checks are run on it. Which Mac mini models can
  run macOS 26.6 was not researched; it depends on the model, which the
  checks will report.
- There is an iPhone Duo **simulator** with fold controls: "Use the control
  buttons at the bottom of the screen to open, close, rotate, or fold iPhone
  Duo." (same tech talk). Simulators have limits: "simulators run within Device
  Hub on your Mac and don't replicate the performance or features of a physical
  device."
  <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>

### 2.2 Apple account: free vs paid

Source: <https://developer.apple.com/help/account/basics/about-your-developer-account>

Free account (an Apple Account signed in to Xcode, shown as "Personal Team"):

- "To install and test your apps on a personal device, you'll need to sign in to
  your Apple Account in Xcode."
- "You can register up to 10 App IDs, which expire after 7 days."
- "You can register up to 3 devices, which expire after 7 days."
- "You can install up to 3 apps per device. Provisioning profiles that enable
  apps to be installed on a device will expire 7 days from issuance. You'll need
  to rebuild and reinstall your app to your device after expiration."

Paid Apple Developer Program:

- "The Apple Developer Program is 99 USD per membership year".
  <https://developer.apple.com/programs/whats-included/>
- TestFlight needs App Store Connect, which the same account page lists only for
  program members. TestFlight allows "up to 100 members of your development
  team" as internal testers and "up to 10,000 external testers".
  <https://developer.apple.com/testflight/>
- Xcode Cloud: "Apple Developer Program membership includes 25 compute hours per
  month." <https://developer.apple.com/xcode-cloud/>. Xcode 27 also says:
  "Configure Xcode Cloud for building and testing your app without joining the
  Apple Developer Program."
  <https://developer.apple.com/documentation/updates/xcode>. The limits of that
  free use were not checked.

What this means in practice:

- A **free account is enough for the vertical slice** (Phase 2, GATE 3). The cost
  is that the app stops launching 7 days after each install and must be rebuilt
  from the Mac.
- Game Center needs a capability and an App Store Connect record. Whether a free
  Personal Team can use it is **unverified**. Apple's "Supported capabilities
  (iOS)" page would settle it; it was not opened.
- The paid program is needed for TestFlight and App Store release.

### 2.3 One-time steps that need Adam present

1. Sign in to Xcode: "sign in with your Apple Developer Program or personal Apple
   Account in Xcode > Settings > Apple Accounts."
2. Connect the iPhone Duo and pair it: "choose Manage Devices and then use Device
   Hub to pair devices with your Mac."
3. Turn on Developer Mode on the phone. It only appears after pairing starts:
   "Developer Mode only appears in Settings if you initiate pairing or if you
   previously paired the device to a Mac." Then: "In the Privacy & Security
   settings on the device, turn on the Developer Mode switch under Security...
   tap the Restart button in the alert. After the device restarts... swipe up,
   tap Enable in the dialog, and enter your device passcode."
4. In the project, pick a team and a unique bundle ID under Signing &
   Capabilities with "Automatically manage signing" on.

Sources:
<https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>,
<https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device>

Not yet checked: the "Trust This Computer" prompt wording and Wi-Fi pairing
steps in Device Hub. Source to read on the Mac:
<https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub>

## 3. Foldable-specific development (brief 2.3)

Main sources:

- "Preparing your app for iPhone Duo":
  <https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>
- Tech talk "Prepare your app for iPhone Duo":
  <https://developer.apple.com/videos/play/tech-talks/111461/>
- Tech talk "Strike a pose with adaptive layouts on iPhone Duo":
  <https://developer.apple.com/videos/play/tech-talks/111463/>
- Tech talk "Leverage multiple displays and scenes on iPhone Duo":
  <https://developer.apple.com/videos/play/tech-talks/111464/>
- UIKit and SwiftUI change lists, September 2026:
  <https://developer.apple.com/documentation/updates/uikit>,
  <https://developer.apple.com/documentation/updates/swiftui>

### 3.1 Moving between the displays

- Opening or closing the phone **resizes the running app**. It is treated like
  any other resize: "With iOS 27, people can resize your app larger than ever
  before using iPhone Mirroring on the Mac. Opening and closing iPhone Duo works
  the same way." Also: "your app will still resize when someone opens or closes
  their iPhone Duo."
- Size classes differ by display. Outer: "regular vertical size class and compact
  horizontal size class in portrait, and compact vertical and horizontal size
  classes in landscape." Inner: "it has regular horizontal and vertical size
  classes."
- Orientation cannot be locked on the inner display: "The inner display doesn't
  honor your supported interface orientations." If the app restricts
  orientations, "your app will scale on the inner display".
- Do not use `UIScreen.main`: "On a device with two displays, avoid referencing
  the main screen in your code. It's ambiguous and will be deprecated in a future
  release." Use the scene's bounds and the trait collection instead.
- Safe areas are uneven: "safe areas are often asymmetric. This is especially
  true on iPhone Duo."
- The scene-based life cycle is mandatory: "Starting in iOS 27, apps built with
  the latest SDK must use the scene-based life cycle or they fail to launch."
  (UIKit updates, June 2026)

Inference: because fold and unfold arrive as a resize of the same running app,
game state and camera position stay in memory. Meeting the brief's "no reload,
state kept, camera kept" requirement is a matter of the game re-laying out on a
size change. No Apple source states in so many words that the scene object
survives the display change; that must be confirmed in the simulator and on the
device. Mid-battle saves (already required) cover the case where it does not.

### 3.2 Fold state and posture: exposed, with a dedicated API

The brief asked whether iOS 27 exposes fold state. It does, in iOS 27.1.

- UIKit: `UIHingeInteraction` delivers a `UIHinge` with `angle` ("The current
  angle of the hinge, in radians") and `status` ("such as `.closed`,
  `.partiallyOpen`, or `.fullyOpen`").
  <https://developer.apple.com/documentation/uikit/uihingeinteraction>,
  <https://developer.apple.com/documentation/uikit/uihinge>
- SwiftUI: "Observe changes to the state of the hinge on iPhone Duo using the
  `onHingeChange(isEnabled:_:)` modifier, which delivers updates through
  `DeviceHingeContext`."
- Apple names games as a use: "Use hinge updates when your app treats the hinge
  as input, such as driving an animation that responds to granular hinge angle
  changes, controlling a game, or showing the current angle."
- Apple says **not** to use the hinge angle for layout: "Don't use hinge updates
  for layout. To adapt your layout to the fold, use `UIArrangementViewController`
  or `UIView.ReservedRegion` instead."

For layout, the fold is a "reserved region" of kind `.division`:

- "A division is active only when the device is partially open or closed. When
  iPhone Duo is fully open, the division is inactive".
- Direction: "When you partially fold iPhone Duo like a book, the fold runs
  vertically, so your content sits side by side. When you partially fold it like
  a laptop, the fold runs horizontally, so your content rests above and below
  the fold." The app finds the direction by comparing the width and height of
  the division's frame.
- Apple's rule: "keep each view entirely on one side of the division", and "If
  your layout is a grid, use an even number of columns so your content divides
  cleanly at the fold."
- Ready-made container for two related views: "A split arrangement places the
  two views side by side or one above the other, and keeps them on separate
  sides of the fold." (`UIArrangementViewController` in UIKit, `ArrangementView`
  in SwiftUI.)
  <https://developer.apple.com/documentation/uikit/uiview/reservedregion>

Result for hardware feature 3 (tabletop pose): **feasible with first-party
API.** Map on the top half and controls on the bottom half is the layout Apple's
split arrangement produces when the phone is folded like a laptop.

### 3.3 Crease and cameras

- When the phone is flat, Apple gives no crease area to avoid: the division
  region "has a width of zero" when flat (tech talk 111463) and is inactive when
  fully open.
- Cameras are `.occlusion` regions: "The inner front-facing camera can block your
  view when it's active, and the outer front-facing camera always occludes your
  view." The inner camera is under the display and "stays hidden when not in
  use" (press release). The game does not use the camera, so only the outer
  display's camera area needs to be kept clear of controls.

### 3.4 System bars on the side

On iPhone Duo the system puts navigation bars, toolbars and tab bars vertically
on the side "on the outer display when the device is closed, and for some views
in the leading or trailing position on the inner display when the device is
open." This affects any menu built from standard bars. A full-screen game view
with its own HUD is affected only through safe-area insets.

### 3.5 Asset resolution and scaling

- The points-per-pixel scale factor of each display (@2x or @3x) was **not found**
  in the sources read so far. It can be read on the device or simulator from
  `traitCollection.displayScale`. See section 5 for what the sprite research
  found.
- Pixel sizes are known (section 1). For a 12×16 map shown with the 16-tile side
  along the 2670-pixel axis: 2670 / 16 = 166 pixels per tile, and
  1878 / 12 = 156 pixels per tile, so a square tile of up to 156 pixels fits the
  whole map on the inner display with about 174 pixels left over on the long
  axis. On the outer display the same arithmetic gives 2034 / 16 = 127 and
  1398 / 12 = 116 pixels per tile. These figures ignore safe areas and HUD space,
  so they are upper bounds.

## 4. Hardware feature feasibility

| # | Feature | Feasible? | Basis |
|---|---|---|---|
| 1 | Two screens, two modes, no interruption | Yes, to be confirmed on device | Fold and unfold resize the running app (3.1). Layout switches on size class |
| 2 | Apple Pencil: precise taps, drawn paths | Yes, with limits | Needs iOS 27.2. Position and tilt only; no pressure, no hover (1.1). Pencil touches arrive as ordinary `UITouch` objects of type `.pencil`: "UIKit reports touches from Apple Pencil in the same way it reports touches from a person's fingers." <https://developer.apple.com/documentation/uikit/handling-input-from-apple-pencil> |
| 3 | Tabletop / half-folded layout | Yes | Reserved regions and arrangement views (3.2) |
| 4 | 120Hz with lower rates when idle | Yes | See below |
| 5 | Core Haptics | Yes on API level | Core Haptics is a current framework, iOS 13.0+. <https://developer.apple.com/documentation/corehaptics>. iPhone Duo's haptic hardware is not described on the spec page; feel must be tuned on the device |
| 6 | Game controllers | Yes | Game Controller framework is current, iOS 7.0+. <https://developer.apple.com/documentation/gamecontroller> |
| 7 | Game Center / Games app | Likely; see engine section | GameKit is current. <https://developer.apple.com/documentation/gamekit>. Free-account support unverified (2.2) |
| 8 | Neural Accelerators / Core ML | Not recommended for the slice | Inference: grid tactics AI on a 12×16 map is a small search problem that ordinary code handles; no source suggests a benefit. Revisit only if enemy AI proves weak |

ProMotion (feature 4) details, from
<https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays>
and
<https://developer.apple.com/documentation/bundleresources/information-property-list/cadisableminimumframedurationonphone>:

- iPhones need an Info.plist key to exceed the default rate:
  `CADisableMinimumFrameDurationOnPhone`. "If you set this key to `YES`, your app
  can request any frame rate the display supports. If you set this key to `NO`,
  frame rates higher than the system default are unavailable."
- The app requests a rate; it cannot force one: "you can't force a ProMotion
  display to show your content at any specific rate."
- "ProMotion displays are capable of dynamically switching between frame rates
  ... from 10Hz to 120Hz on supported iPhone devices."
- That article's device list does not name iPhone Duo. It says "iPhone 17 and
  later"; whether Apple counts iPhone Duo under that phrase is not stated. The
  spec page does confirm 120Hz ProMotion on both displays.

## 5. Engine and framework options (brief 2.2)

In progress.

## 6. 2D sprite pipeline (brief 2.4)

### 6.1 Display scale and resolution

- iOS uses "@2x and @3x" assets: "A 2:1 density (called @2x) has a scale factor
  of 2, and a 3:1 density (called @3x) has a scale factor of 3."
  <https://developer.apple.com/design/human-interface-guidelines/images>
- **iPhone Duo's scale factor and point dimensions are unverified.** They are
  not in the HIG layout page, the HIG iPhone Duo page, or the developer article.
  They can be read at runtime (`traitCollection.displayScale` and the scene's
  bounds) in the simulator, which settles it on day one on the Mac.
- **Open discrepancy on the inner display.** App Store Connect asks for inner
  display screenshots at "2007 × 2853 pixels", while the hardware spec is
  1878 × 2670. The outer display matches its hardware spec (1398 × 2034).
  <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications>
  Apple does not explain the difference on the pages read. One possible cause
  is that the inner display renders at a larger size and scales down to the
  panel; that is a guess. What it means for us: **do not assume one rendered
  pixel equals one physical pixel on the inner display** until it is measured.
  This matters most for pixel art.

### 6.2 Pixel art vs high-resolution 2D

- Apple's game guidance prefers art that is not tied to one resolution: "Prefer
  resolution-independent textures and graphics. If creating
  resolution-independent assets isn't possible, match the resolution of your
  game to the resolution of the device."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-games>
- Apple's iPhone Duo guidance for games: "Make your game playable in every
  device pose. You can choose to lock to either portrait or landscape
  orientation, but be sure to fill the screen as the device pose changes. When
  resizing, keep text and control sizes as consistent as possible. Prefer
  changing the aspect ratio over letterboxing or pillarboxing in games".
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
- Pixel art looks correct only at whole-number scale factors. Godot's docs put
  it this way: "since displays can only display "whole" pixels, this will lead
  to uneven pixel scaling which results in incorrect appearance of pixel art",
  and with integer scaling "The remaining space is filled with black bars on all
  four sides".
  <https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html>
- In SpriteKit, pixel art needs nearest-neighbour filtering set per texture,
  because "The default value is linear".
  <https://developer.apple.com/documentation/spritekit/sktexture/filteringmode>

Inference: two displays at 430 and 460 ppi, a possible non-1:1 inner display
(6.1), user-resizable Split View, and Apple's request not to letterbox all work
against strict pixel-perfect pixel art. The options are:

1. **High-resolution 2D** drawn large and scaled down with linear filtering.
   Scales cleanly to any size. Costs more to produce by hand.
2. **Pixel art at whole-number scale**, with the map showing more or fewer
   tiles or decorative margin to fill the leftover space. Keeps crisp pixels;
   needs care at each display size.
3. **Pixel art scaled freely** with slight softness or uneven pixels. Simplest,
   looks worst.

This is one of the GATE 2 decisions in the brief. The slice uses placeholder
art either way, so it does not block GATE 1.

### 6.3 Tools

- **Xcode sprite atlases.** "inside the new asset catalog, add a new sprite
  atlas." "sprite atlases support app thinning". "Texture atlases improve memory
  usage and rendering performance by reducing draw calls."
  <https://developer.apple.com/documentation/spritekit/about-texture-atlases>,
  <https://developer.apple.com/documentation/spritekit/sktextureatlas>
- **Aseprite** (pixel art editor). Command-line export of sprite sheets with a
  JSON description is documented: `--sheet file.png --data file.json`, with
  `--format json-hash` or `json-array`.
  <https://raw.githubusercontent.com/aseprite/docs/main/cli.md>. Its price was
  not confirmed from aseprite.org (host blocked); store listings found by
  search say $19.99.
- **TexturePacker**: not confirmed from its own site (host blocked). Not needed
  if Xcode atlases or the engine's own packer are used.

### 6.4 Placeholder art

- Plan: coloured shapes with a letter or icon per unit type, generated in code
  or as simple PNGs. No licence questions, and it makes unit type and side
  readable at a glance.
- Kenney's asset packs are reported as CC0 (public domain), but this was read
  only from search results and one of Kenney's GitHub READMEs ("Sprites and 3D
  Models (CC0 licensed)",
  <https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/README.md>),
  not from kenney.nl itself. If a pack is used, the `License.txt` inside the
  download is the authority.

## 7. Reference games (brief 2.5)

**Sourcing limit.** The publishers' and developers' sites (Nintendo, Subset
Games, Square Enix, App Store listings, TouchArcade) were blocked from this
session. Everything in 7.1 comes from search-result excerpts of those pages,
not from the pages themselves, so the quotes may not be exact. Items marked
"from memory" have no source at all. Allowing those hosts, or Adam checking the
games directly, would firm this up. Apple's guidance in 7.2 was read first-hand.

### 7.1 What each game does

| Game | Finding | Source quality |
|---|---|---|
| Fire Emblem Heroes (mobile) | Drag a unit onto its target to attack: "easy touch and drag controls, including the ability to attack by simply swiping an ally over an enemy". Maps "fit in the palm of your hand". | Excerpt of fire-emblem-heroes.com/en/system |
| | Map is 6 × 8 in portrait, so the whole battlefield is on screen with no scrolling. | Excerpt of a news article; no official source found |
| | Combat forecast appears while holding a dragged unit over an enemy, "at the top of the screen", away from the finger. | Excerpt of the official guide |
| | Enemy attack range is a one-tap "Danger Area" toggle, with a setting to keep it always on. | Excerpt of the official guide |
| Fire Emblem on Switch (handheld) | Handheld mode supported. Touch control of the battle map: not found in any source. | Excerpt of Nintendo store page; touch unverified |
| Into the Breach (iOS, via Netflix) | Released on iOS and Android through Netflix in July 2022. Whether it is still available in November 2026 was not confirmed. | Excerpt of news coverage |
| | 8 × 8 board, whole board visible. Enemy actions for the next turn are always shown. | Excerpts (gamedeveloper.com, reviews) |
| | Moves can be undone freely; a full "Reset Turn" is limited to once per battle. | Excerpt of a review |
| | Designer Justin Ma: "sacrifice cool ideas for the sake of clarity every time". | Excerpt of a gamedeveloper.com interview title |
| Advance Wars 1+2: Re-Boot Camp | Handheld mode supported. Reviews disagree on whether it has touch controls; no official statement found. | Conflicting excerpts; unverified |
| Final Fantasy Tactics: War of the Lions (iOS) | Exists on iOS with tap controls; controller support was added later. Reviews disagree on how good the touch controls are. | Excerpts |
| | The 2025 Ivalice Chronicles release lists Switch, PlayStation, Xbox and PC, with no mobile version. | Excerpt of Square Enix announcement |
| Legend of Keepers | Villain-side dungeon defence. Came to iOS and Android in May 2023 with an "interface designed for mobile". | Excerpts |
| Iratus: Lord of the Dead | Necromancer protagonist. Windows, Linux, Mac only as far as sources show. | Excerpt of developer factsheet |

From memory, unsourced: Legend of Keepers and Iratus are not grid-movement
games (lane and rank combat), so they inform theme and the villain fantasy, not
touch grid controls. Final Fantasy Tactics uses an isometric map with height.

### 7.2 Apple's guidance (read first-hand)

- Touch target size: "Make sure frequently used controls are a minimum size of
  44x44 pt, and less important controls, such as menus, are a minimum size of
  28x28 pt to accommodate people's fingers."
  <https://developer.apple.com/design/human-interface-guidelines/game-controls>
- "consider letting players tap objects to select them instead of adding a
  virtual selection button." (same page)
- "Place frequently used buttons near a player's thumb... Place secondary
  controls, like menus, at the top of the screen." (same page)
- Controllers: "If you support game controllers, try to make sure there's a
  fallback for using the platform's default interaction method." (same page)
- Text: default 17 pt, minimum 11 pt on iOS.
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-games>
- "avoid relying solely on color to convey an important detail" (same page).
  This applies to range overlays, the counter triangle and consecrated tiles.
- Fold: "In a grid-style layout, prefer an even number of columns so content
  divides cleanly."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
- Continuity: "Keep functionality and the state of elements the same between
  displays." (same page)
- Pencil: the HIG's Apple Pencil page is still iPad-only and says nothing about
  iPhone Duo. Its general advice applies: "ensure that your app's controls
  respond to Apple Pencil so people don't have to switch to using their finger".
  <https://developer.apple.com/design/human-interface-guidelines/apple-pencil-and-scribble>

### 7.3 Design conclusions (inference, for the GDD)

1. **A tile must be at least 44 pt** to be a comfortable finger target. How
   many tiles fit therefore depends on the point size of each display, which is
   unverified (6.1). If the displays are @3x, the outer display is about
   466 × 678 pt and a 12 × 16 map gives tiles of about 39 to 42 pt: slightly
   under the guideline. The brief's 12 × 16 map probably fits the inner display
   comfortably and is marginal on the outer one. Options to decide at GATE 2:
   scroll and zoom on the outer display, or a smaller map.
2. **Support both drag and tap-tap** for moving and attacking. Drag is fast for
   fingers; tap-tap is precise and suits the Pencil.
3. **Show the combat forecast away from the finger**, at a screen edge or in the
   side panel, never under the touch point.
4. **Free undo of movement, explicit confirmation of attacks and raises.**
   Mis-taps are the main touch risk.
5. **Enemy threat range as a one-tap toggle.** In this game the same idea
   extends to showing which corpses an enemy cleric or fire user can reach next
   turn, since corpse denial is the central tension.
6. **Even number of map columns across the fold**, so the fold lands between
   tiles when the phone is partly folded. 16 and 12 are both even.
7. **Flat top-down grid**, not isometric, for tap accuracy.
8. **Never rely on colour alone** for side, undead type or tile state.

## 8. Recommendation and GATE 1

In progress.
