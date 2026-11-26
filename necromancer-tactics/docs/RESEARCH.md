# Phase 0 Research

Research date: 2026-11-25, on Linux, not on the Mac mini. Corrected 2026-11-26
after an independent audit that re-opened every cited page (see "Audit" below).

How to read this document:

- Quoted text is verbatim from the linked page, and the quotations are checked
  by script (`tools/citations/check_doc.py`). A claim without a quotation was
  read from the linked page; a claim with no link is arithmetic, or is marked.
- **Unverified** means no primary source was found. The text says what would
  settle it.
- **Inference** marks a conclusion drawn by Claude from sourced facts. It is not
  a sourced fact.
- Statements that something is absent ("no Apple page says...") cover the pages
  that were read, which are the ones linked. They are not claims about every
  page Apple publishes.
- Apple's documentation pages are rendered by JavaScript. They were read through
  the JSON that backs each page. The links are the normal page URLs.
- Later findings about the Mac, the toolchain and the free account are in
  `MAC_SETUP.md`, which supersedes section 2 here where they differ.

**Audit, 2026-11-26.** Five auditors re-opened the cited pages and reported 69
problems: 9 that could mislead, 38 inaccurate details and 22 cosmetic. All were
reviewed and the text below is corrected. The ones that changed a conclusion:
Unity does recognise iPhone Duo as a device (5.6); the two displays are a
quarter-turn apart, so one map does not simply scale between them (section 1);
Apple's statements on orientation locking conflict (3.1); Xcode Cloud on a free
account is contradicted by Apple's own pages (2.2); and Game Center needs the
paid program (2.2). The engine recommendation in section 8 stands.

## 1. Target hardware, re-verified

Sources for this section unless noted: Apple's spec page,
<https://www.apple.com/iphone-duo/specs/>, and Apple's press release,
<https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/>.

| Brief says | Apple says | Result |
|---|---|---|
| Released October 23, 2026 | "Pre-orders begin Friday, October 16, with availability beginning Friday, October 23." (press release) | Confirmed |
| Runs iOS 27 | The spec page lists iOS 27 under the heading Operating System. Press release: "iPhone Duo will be available with iOS 27.1." | Confirmed. Ships with 27.1 |
| Inner 7.6-inch OLED, 1878×2670, 430 ppi | "7.6‑inch (diagonal) all‑screen OLED folding display", "1878‑by‑2670-pixel resolution at 430 ppi" | Confirmed |
| Outer 5.4-inch OLED, 1398×2034, 460 ppi | "5.4‑inch (diagonal) all‑screen OLED display", "1398‑by‑2034-pixel resolution at 460 ppi" | Confirmed |
| Inner display roughly 4:3 | Computed from Apple's pixel counts (Apple gives no ratio figure): 2670 / 1878 = 1.42. 4:3 is 1.33, 3:2 is 1.50 | **Correction.** The inner display is about 1.42:1, between 4:3 and 3:2 |
| Wider than tall when open | Open: "Width: 6.48 inches (164.6 mm)", "Height: 4.64 inches (117.8 mm)" | Confirmed |
| 120Hz on both displays | Under Both displays: "ProMotion technology with adaptive refresh rates up to 120Hz" | Confirmed |
| A20 Pro, 6-core CPU (2 performance + 4 efficiency) | "6‑core CPU with 2 super cores and 4 efficiency cores" | Confirmed. Apple's term is "super cores" |
| 7-core GPU with Neural Accelerators, dual 16-core Neural Engine, ray tracing | "7‑core GPU with Neural Accelerators", "Dual 16‑core Neural Engine", "Hardware‑accelerated ray tracing" | Confirmed |
| RAM not listed | No RAM figure on the spec page | Confirmed. RAM is **unverified**; reading `ProcessInfo.physicalMemory` on the device would settle it |
| Apple Pencil (USB-C) on the inner display, no hover | "Supports Apple Pencil (USB-C)" is listed under Both displays. Footnote: "Hover is not supported when using Apple Pencil (USB-C) with iPhone Duo." | Hover: confirmed. **Correction:** the spec page lists Pencil support under both displays, not only the inner one. See 1.1 |
| No hinge or angle sensor listed | Under Sensors the spec page lists six items: Touch ID fingerprint sensor, barometer, high dynamic range gyro, high-g accelerometer, proximity sensor, four ambient light sensors | Confirmed for the spec page. iOS does expose the hinge angle to apps. See 3.2 |
| Dual battery, vapor-cooled | "Dual built-in rechargeable lithium‑ion batteries". Press release: "a custom-designed vapor chamber and a dual-battery architecture" | Confirmed |

Other facts that matter for the game:

- **Both displays have nearly the same shape, but a quarter-turn apart.** Press
  release: "Both displays share the same aspect ratio, so content scales
  proportionally, ensuring visual continuity." By pixel count the outer display
  is 2034 / 1398 = 1.455 and the inner is 2670 / 1878 = 1.42, so they are close
  but not identical. Their long sides point different ways. Closed, the phone is
  "Width: 3.31 inches (84.1 mm)" by "Height: 4.64 inches (117.8 mm)", so the
  outer display is taller than wide. Open, it is "Width: 6.48 inches (164.6 mm)"
  by the same height, so the inner display is wider than tall.
  Inference: one map shape fits both displays with small margins only if the map
  is turned a quarter-turn between them, or the player turns the phone. Kept the
  same way up, a map of 16 columns by 12 rows fills only about half the height
  of the outer display (1398 / 16 = 87 pixels per tile; 12 × 87 = 1044 of 2034
  pixels). The design document handles this by showing part of the map on the
  outer display (GDD 12.3).
- **Authentication is Touch ID**, not Face ID: "Fingerprint sensor built into the
  side button".
- **Split View exists on iPhone Duo.** Press release: "Split View allows users to
  open two apps side by side on iPhone for the first time." Apple's tech talk
  says every app takes part: "All apps participate in multitasking on iPhone
  Duo, where two apps can be placed in a side-by-side layout."
  <https://developer.apple.com/videos/play/tech-talks/111464/> The user can
  therefore move the game to one side of the inner display, and the game must
  resize.
- Apple markets gaming on it: "the vapor chamber sustains it for high-frame-rate
  gaming and multitasking on the large display."

### 1.1 Apple Pencil details

- Pencil support needs **iOS 27.2**, not 27.1. Apple Support: "You can use Apple
  Pencil (USB-C) with these iPad models with iPadOS 17.1.1 or later, and with
  iPhone Duo with iOS 27.2". <https://support.apple.com/en-us/108937> iOS 27.2
  has been public since 26 October 2026 (`MAC_SETUP.md` section 3).
- **Apple Pencil (USB-C) has no pressure sensitivity.** Apple's comparison table
  marks Pressure sensitivity as "Compatible with Apple Pencil Pro" and "Not
  compatible with Apple Pencil (USB-C)". It does have tilt: "Apple Pencil (USB‑C)
  provides pixel-perfect precision, low latency, and tilt sensitivity".
  <https://www.apple.com/apple-pencil/>
- Apple Pencil Pro is not listed as working with iPhone Duo on that support page.
  Only the USB-C model is.

Consequence for the design: Apple Pencil (USB-C) has tilt but no pressure, and on
iPhone Duo no hover. Inference: Apple does not say separately that tilt works on
iPhone Duo; hover is the only exception it lists for iPhone Duo, so tilt is
assumed and should be confirmed on the device. Any control that depends on
pressing harder is not possible. Drawing movement paths and precise taps only
need position, so they are unaffected.

## 2. Build pipeline and environment (brief 2.1)

This section records what Phase 0 found. `MAC_SETUP.md` has the fuller, later
research and the step-by-step plan for the Mac.

### 2.1 Xcode and macOS versions

Source: <https://developer.apple.com/xcode/system-requirements> (table "Latest
Xcode versions").

| Xcode | Requires | iOS SDK |
|---|---|---|
| 27.3 beta 2 | macOS Tahoe 26.6 or later | iOS 27.3 |
| 27.2 | macOS Tahoe 26.6 or later | iOS 27.2 |
| 27.1 | macOS Tahoe 26.6 or later | iOS 27.1 |
| 27 | macOS Tahoe 26.6 or later | iOS 27 |

- **Xcode 27.1 is the minimum for a full-screen iPhone Duo build.** Apps built
  with older SDKs still run ("Your app will work on iPhone Duo even if you
  haven't built it with the iOS 27 SDK."), but not edge to edge. Apple's tech
  talk: "When you build your app with the iOS 27.1 SDK, your app extends to the
  edge of the screen" and "To get the full-screen experience, download Xcode
  27.1. Choose the iPhone Duo simulator to run your app in Device Hub."
  <https://developer.apple.com/videos/play/tech-talks/111461/>
- All the fold APIs in section 3 are marked iOS 27.1.
- Recommendation: install **Xcode 27.2** (the current release). It includes the
  27.1 APIs and matches the iOS version that Pencil support needs.
- **The Mac must be an Apple silicon Mac on macOS Tahoe 26.6 or later.** Adam's
  Mac mini is the 2024 model with an M4 and 16 GB, and Apple lists it as
  compatible with macOS Tahoe 26 and macOS 27. Sources and detail:
  `MAC_SETUP.md` section 1.
- There is an iPhone Duo **simulator** with fold controls: "Use the control
  buttons at the bottom of the screen to open, close, rotate, or fold iPhone
  Duo." <https://developer.apple.com/videos/play/tech-talks/111461/> Simulators
  have limits: "simulators run within Device
  Hub on your Mac and don't replicate the performance or features of a physical
  device."
  <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>
  What the simulator cannot show is listed in `MAC_SETUP.md` section 6.

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
- TestFlight needs App Store Connect, which the account page's table marks only
  for program members. TestFlight allows "up to 100 members of your development
  team" as internal testers and "up to 10,000 external testers".
  <https://developer.apple.com/testflight/>
- Xcode Cloud: the program "includes 25 compute hours" a month.
  <https://developer.apple.com/xcode-cloud/> Apple's pages disagree on whether
  it can be used without the program. The Xcode updates page lists under June
  2026: "Configure Xcode Cloud for building and testing your app without joining
  the Apple Developer Program." <https://developer.apple.com/documentation/updates/xcode>
  Against that, a footnote on the Xcode Cloud page says "Xcode Cloud requires
  Apple Developer Program membership.", and the article the update note links to
  lists "Join the Apple Developer Program." among the things to do first.
  <https://developer.apple.com/documentation/xcode/getting-started-with-xcode-cloud>
  Whether a free account can use Xcode Cloud is **unverified**; trying to set it
  up in Xcode with the free account would settle it. The project does not depend
  on it: tests run in GitHub Actions.

What this means in practice:

- Inference: a **free account is enough for the vertical slice** (Phase 2, GATE
  3), provided the slice uses no program-only capability. The cost is that the
  provisioning profile expires "7 days from issuance" and the app must then be
  rebuilt and reinstalled from the Mac. The page does not say what an expired
  app does when opened; that it stops launching is an inference.
- **Game Center needs the paid program.** Apple's capability table marks Game
  Center for the paid program only, not for the free tier.
  <https://developer.apple.com/help/account/reference/supported-capabilities-ios>
  Detail in `MAC_SETUP.md` section 5.
- The paid program is needed for TestFlight, Game Center and App Store release.

### 2.3 Setup steps that need Adam present

The steps, with Apple's wording for each, are in `MAC_SETUP.md` section 3:
update macOS, install Xcode, sign in, allow outside agents, create the project,
pair the phone, turn on Developer Mode, trust the developer certificate.

They are not all one-time. Apple says of pairing: "If you upgrade the operating
system later, you'll need to pair the device again."
<https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub>
With a free account the device registration and the provisioning profile also
expire after 7 days (2.2).

## 3. Foldable-specific development (brief 2.3)

Main sources:

- "Preparing your app for iPhone Duo":
  <https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>
- Tech talk "Prepare your app for iPhone Duo" (referred to below as tech talk
  111461): <https://developer.apple.com/videos/play/tech-talks/111461/>
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
  their iPhone Duo." (tech talk 111461)
- Size classes differ by display. Outer: "regular vertical size class and compact
  horizontal size class in portrait, and compact vertical and horizontal size
  classes in landscape." Inner: "it has regular horizontal and vertical size
  classes." (tech talk 111461)
- **Orientation locking behaves differently on the inner display, and Apple's
  wording is not consistent.** Tech talk 111461
  (<https://developer.apple.com/videos/play/tech-talks/111461/>) says "The inner display doesn't
  honor your supported interface orientations." and later "iPhone Duo respects
  your supported interface orientations, but your app will scale on the inner
  display, including in Split View multitasking." The design guidance says of
  games: "You can choose to lock to either portrait or landscape orientation,
  but be sure to fill the screen as the device pose changes."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
  Inference: an app that restricts its orientations is shown scaled on the inner
  display instead of being laid out at full size. What that looks like is
  **unverified**; running an orientation-locked build in the iPhone Duo
  simulator would settle it. The safe course is to lay out for whatever size
  arrives, including the open phone turned to portrait.
- Do not use `UIScreen.main`: "On a device with two displays, avoid referencing
  the main screen in your code. It's ambiguous and will be deprecated in a future
  release." <https://developer.apple.com/videos/play/tech-talks/111461/> The API
  reference already marks `UIScreen.main`
  as deprecated: "Apple discourages the use of this symbol. Use a UIScreen
  instance found through context instead."
  <https://developer.apple.com/documentation/uikit/uiscreen/main> Use the
  scene's bounds and the trait collection.
- Safe areas are uneven: "safe areas are often asymmetric. This is especially
  true on iPhone Duo." (tech talk 111461)
- The scene-based life cycle is mandatory: "Starting in iOS 27, apps built with
  the latest SDK must use the scene-based life cycle or they fail to launch."
  <https://developer.apple.com/documentation/updates/uikit>

Inference: because fold and unfold arrive as a resize of the same running app,
game state and camera position stay in memory. Meeting the brief's "no reload,
state kept, camera kept" requirement is then a matter of the game re-laying out
on a size change. None of the pages read states in so many words that the scene
object survives the display change; that must be confirmed in the simulator and
on the device (`MAC_SETUP.md` section 7). Mid-battle saves, already required,
cover the case where it does not.

### 3.2 Fold state and posture: exposed, with a dedicated API

The brief asked whether iOS 27 exposes fold state. It does, in iOS 27.1.

- UIKit: `UIHingeInteraction` delivers a `UIHinge` with `angle` ("The current
  angle of the hinge, in radians"
  <https://developer.apple.com/documentation/uikit/uihinge/angle>) and `status`.
  The UIKit change list: "Read the hinge's current angle and status, such as
  `.closed`, `.partiallyOpen`, or `.fullyOpen`, using UIHinge."
  <https://developer.apple.com/documentation/updates/uikit> The status type also
  has an unknown case.
  <https://developer.apple.com/documentation/uikit/uihinge/status-swift.enum>
- SwiftUI: "Observe changes to the state of the hinge on iPhone Duo using the
  onHingeChange(isEnabled:_:) modifier, which delivers updates through
  DeviceHingeContext." <https://developer.apple.com/documentation/updates/swiftui>
- Apple names games as a use: "Use hinge updates when your app treats the hinge
  as input, such as driving an animation that responds to granular hinge angle
  changes, controlling a game, or showing the current angle."
  <https://developer.apple.com/documentation/uikit/uihingeinteraction>
- Apple says **not** to use the hinge angle for layout: "Don't use hinge updates
  for layout. To adapt your layout to the fold, use UIArrangementViewController
  or UIView.ReservedRegion instead." (same page)

For layout, the fold is a "reserved region" of kind `.division`. Source for the
quotations in this list:
<https://developer.apple.com/documentation/uikit/uiview/reservedregion>

- "A division is active only when the device is partially open or closed. When
  iPhone Duo is fully open, the division is inactive". Apple's overview article
  says the opposite about the closed state, so that case needs checking on the
  Mac (`MAC_SETUP.md` section 7).
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

Result for hardware feature 3 (tabletop pose): **feasible with first-party
API.** Inference: with the map as the primary view and the controls as the
secondary view, a split arrangement puts the map above the fold and the controls
below it when the phone is folded like a laptop. Apple: "it places the primary
view on top and the secondary view below it when the containing view is taller
than it is wide".
<https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>

### 3.3 Crease and cameras

- When the phone is flat, Apple gives no crease area to avoid: the division
  region "has a width of zero" when flat
  (<https://developer.apple.com/videos/play/tech-talks/111463/>) and is inactive
  when fully open.
- Cameras are `.occlusion` regions: "The inner front-facing camera can block your
  view when it's active, and the outer front-facing camera always occludes your
  view."
  <https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>
  The inner camera is under the display and "stays hidden when not in use".
  <https://www.apple.com/newsroom/2026/09/apple-unveils-iphone-duo/>
- Inference: the game does not use the camera, so the outer display's camera
  area is the one that must always be kept clear of controls. Whether the inner
  camera's region can become active while the game is on screen, because another
  app is using the camera, is **unverified**; reading the `.occlusion` regions
  at layout time covers both cases.

### 3.4 System bars on the side

On iPhone Duo the system puts navigation bars, toolbars and tab bars vertically
on the side "on the outer display when the device is closed, and for some views
in the leading or trailing position on the inner display when the device is
open."
<https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>
This affects any menu built from standard bars. Inference: a full-screen game
view with its own HUD has no standard bars to move, but system elements such as
the status bar and Dynamic Island still sit on the side, so the HUD must follow
the safe-area insets, which can be asymmetric (3.1), and the camera's occlusion
region (3.3).

### 3.5 Asset resolution and scaling

- The pixels-per-point scale factor of each display (@2x or @3x) was **not
  found** in the sources read. It can be read on the device or simulator from
  the trait collection's display scale.
  <https://developer.apple.com/documentation/uikit/uitraitcollection/displayscale>
  See 6.1.
- Pixel sizes are known (section 1). With the 16-tile side of a 16 × 12 map along
  the 2670-pixel axis of the inner display: 2670 / 16 = 166.9 and 1878 / 12 =
  156.5 pixels per tile, so a square tile of up to 156 pixels shows the whole
  map, with 174 pixels left over on the long axis. On the outer display the map
  kept the same way up gets 1398 / 16 = 87 pixels per tile; turned a
  quarter-turn it gets 2034 / 16 = 127 and 1398 / 12 = 116.5, so up to 116.
- These figures are in physical panel pixels and ignore safe areas and HUD
  space, so they are upper bounds for the on-panel tile size. They are not a
  safe bound for asset size on the inner display: App Store Connect lists
  inner-display screenshots at 2007 × 2853 pixels (6.1), and at that size the
  same map is 178 by 167 pixels per tile. Whether the inner display renders at
  that size is unverified (6.1).

## 4. Hardware feature feasibility

| # | Feature | Feasible? | Basis |
|---|---|---|---|
| 1 | Two screens, two modes, no interruption | Yes, to be confirmed on device | Fold and unfold resize the running app (3.1). Layout switches on size class |
| 2 | Apple Pencil: precise taps, drawn paths | Yes, with limits | Needs iOS 27.2. No pressure, no hover; tilt assumed (1.1). Pencil touches arrive as ordinary touch objects: "UIKit reports touches from Apple Pencil in the same way it reports touches from a person's fingers." <https://developer.apple.com/documentation/uikit/handling-input-from-apple-pencil> Their type is `UITouch.TouchType.pencil`. <https://developer.apple.com/documentation/uikit/uitouch/touchtype/pencil> Cannot be tried in the simulator |
| 3 | Tabletop / half-folded layout | Yes | Reserved regions and arrangement views (3.2) |
| 4 | 120Hz with lower rates when idle | Yes by API; 120 on the device to be confirmed | See below |
| 5 | Core Haptics | Yes on API level | Core Haptics is a current framework, iOS 13.0+. <https://developer.apple.com/documentation/corehaptics> The spec page lists Haptic Touch under Both displays but does not describe the haptic hardware; feel must be tuned on the device |
| 6 | Game controllers | Yes | Game Controller framework is current, iOS 7.0+. <https://developer.apple.com/documentation/gamecontroller> |
| 7 | Game Center / Games app | Yes, but only with the paid program | GameKit is current. <https://developer.apple.com/documentation/gamekit> Not available to a free account (2.2) |
| 8 | Neural Accelerators / Core ML | Not recommended for the slice | Inference: grid tactics AI on a 16 × 12 map is a small search problem that ordinary code handles; no source suggests a benefit. Revisit only if enemy AI proves weak |

ProMotion (feature 4) details, from
<https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays>
and
<https://developer.apple.com/documentation/bundleresources/information-property-list/cadisableminimumframedurationonphone>:

- iPhones need an Info.plist key to exceed the default rate,
  `CADisableMinimumFrameDurationOnPhone`: "If you set this key to `YES`, your app
  can request any frame rate the display supports. If you set this key to `NO`,
  frame rates higher than the system default are unavailable."
- The app requests a rate; it cannot force one: "you can't force a ProMotion
  display to show your content at any specific rate."
- "ProMotion displays are capable of dynamically switching between frame rates
  ranging from 24Hz to 120Hz on iPad Pro, and from 10Hz to 120Hz on supported
  iPhone devices."
- That article's device list does not name iPhone Duo. It says "iPhone 17 and
  later"; whether Apple counts iPhone Duo under that phrase is not stated. The
  spec page does confirm 120Hz ProMotion on both displays (section 1).

## 5. Engine and framework options (brief 2.2)

### 5.1 The fact that decides most of this

The iPhone Duo APIs (hinge, reserved regions, arrangement views) are documented
by Apple as UIKit and SwiftUI API (section 3); no other framework for them was
found. A native Swift app calls them directly.

Neither engine offers them:

- Godot 4.7.2's changelog
  (<https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/CHANGELOG.md>)
  and iOS export page do not mention iPhone Duo, the hinge or reserved regions.
  Godot's unreleased development branch names the device and reads the hinge
  state, but only to choose a screen density value.
- Unity's release notes mention iPhone Duo once, for device identification
  only: "iOS: Added: Added iPhone 18 Pro, iPhone 18 Pro Max and iPhone Duo device
  generation enums and screen cutouts." (6000.3.28f1 and 6000.6.8f1)
  <https://unity.com/releases/editor/whats-new/6000.3.28f1> None mentions the
  hinge, reserved regions or arrangement views.

Inference: in both engines the hinge, reserved regions and arrangement layouts
would each need a native plugin written and built on the Mac.

### 5.2 SpriteKit (Apple native 2D)

- **Not deprecated.** The framework page lists iOS 7.0+ with no deprecation
  marker: "Add high-performance 2D content with smooth animations to your app,
  or create a game with a high-level set of 2D game-based tools."
  <https://developer.apple.com/documentation/spritekit>
- **No sign of active development (inference from absence; Apple has not said
  so).** There is no SpriteKit page among Apple's framework update lists
  (<https://developer.apple.com/documentation/updates>), and the string
  "SpriteKit" does not appear in the iOS & iPadOS 26 to 27.3 beta 2 release
  notes, the Xcode 26 to 27.3 beta 2 release notes, or any of the 260 WWDC25 and
  WWDC26 session pages. A research agent made this search on 2026-11-25 and an
  auditor repeated it on 2026-11-26.
- **Precedent to weigh:** Apple deprecated its 3D sibling in 2025. "SceneKit is
  now deprecated across all Apple platforms. Developers can continue to use
  SceneKit in their projects, but no new features or optimizations are coming to
  this framework."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes>
  None of the pages read says anything like this about SpriteKit, and none
  announces a 2D replacement.
- Apple's own getting-started page for games presents Metal and does not
  mention SpriteKit (5.3).
- Frame rate: `SKView.preferredFramesPerSecond`, default 60. "The actual frame
  rate chosen is usually a factor of the maximum refresh rate of the screen".
  <https://developer.apple.com/documentation/spritekit/skview/preferredframespersecond>
  Lowering it on menus and during enemy turns is a one-line change. Reaching
  120 on an iPhone needs the Info.plist key in section 4. That SpriteKit
  actually reaches 120 frames per second on iPhone Duo is **unverified**; it
  needs a device test.
- Tile maps: `SKTileMapNode` exists, with a limit: "A tile map does not expose
  its tiles as nodes, and therefore you cannot assign individual tiles with a
  different zPosition or physicsBody."
  <https://developer.apple.com/documentation/spritekit/sktilemapnode>
  Inference: overlays such as range highlights and consecrated ground would be
  separate nodes on top.
- Pencil, haptics, controllers, Game Center: all first-party frameworks, called
  directly.
- Off-Mac development: none of the rendering. SpriteKit is Apple-platform only.

### 5.3 Metal directly

- Apple's getting-started page for games presents Metal as its graphics
  framework: "Metal is a framework for drawing hardware-accelerated 2D and 3D
  graphics." and "Its low-overhead model gives you direct control over what
  tasks the GPU performs". <https://developer.apple.com/games/get-started/> The
  page does not mention SpriteKit. Inference: Metal is the low-level route. No
  page read says to write a 2D sprite game in Metal rather than SpriteKit.
- Inference: sprite batching, atlases, tile maps, animation and text would all
  have to be written by hand. For a turn-based game with a few dozen sprites
  there is no performance need.
- SpriteKit and Metal can be mixed: "When you want to mix SpriteKit content with
  your own Metal content, use SKRenderer".
  <https://developer.apple.com/documentation/spritekit/choosing-a-spritekit-scene-renderer>
  `SKRenderer` is itself part of SpriteKit, so it is not a way off SpriteKit.

### 5.4 SwiftUI + SpriteKit hybrid

- `SpriteView` is "A SwiftUI view that renders a SpriteKit scene", iOS 14.0+,
  not deprecated. Its fullest initialiser takes `preferredFramesPerSecond`,
  `isPaused` and a `shouldRender` callback.
  <https://developer.apple.com/documentation/spritekit/spriteview>
- Apple documents no limits for `SpriteView`; its pages have almost no
  discussion text. Touch routing (including Pencil touch type) and 120 Hz
  through `SpriteView` are **unverified**. The fallback is wrapping `SKView`
  with `UIViewRepresentable` ("A wrapper for a UIKit view that you use to
  integrate that view into your SwiftUI view hierarchy."
  <https://developer.apple.com/documentation/swiftui/uiviewrepresentable>).
  Inference: that gives the scene ordinary UIKit touch handling.
- The benefit: menus, HUD and unit panels in SwiftUI get the iPhone Duo
  behaviour from the system. `ArrangementView` gives the map/panel split and the
  tabletop layout; `onHingeChange` gives the hinge.

### 5.5 Godot 4.x

- Current stable is 4.7.2 (18 August 2026) per
  <https://godotengine.org/download/linux/>. MIT licensed
  (<https://godotengine.org/license/>).
- iOS export: "You must export for iOS from a computer running macOS with Xcode
  installed."
  <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html>
- **Foldable risk.** Godot's iOS export template hard-codes
  `UIRequiresFullScreen` = true and `UIApplicationSupportsMultipleScenes` =
  false.
  <https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/misc/dist/apple_embedded_xcode/godot_apple_embedded/godot_apple_embedded-Info.plist>
  Apple says: "iPhone Duo will continue to honor the UIRequiresFullScreen key,
  but your app will still resize when someone opens or closes their iPhone Duo."
  <https://developer.apple.com/videos/play/tech-talks/111461/> Inference: the
  key would not block the fold resize but may opt the game out of Split View
  resizing. Godot's view resizes its window on layout
  (<https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/drivers/apple_embedded/godot_view_apple_embedded.mm>),
  so fold and unfold may work, but nothing in Godot's docs covers iPhone Duo.
  **Unverified** end to end.
- Whether Godot 4.7.2 builds against the iOS 27 SDK with Xcode 27 is
  **unverified**; its changelog (linked in 5.1) mentions only Xcode 26.
- 120 Hz: the project setting `display/window/ios/allow_high_refresh_rate`
  allows "up to 120 frames per second"
  (<https://docs.godotengine.org/en/stable/classes/class_projectsettings.html>),
  and the export template already sets the Info.plist key.
- Haptics: only `Input.vibrate_handheld(duration_ms, amplitude)`.
  <https://docs.godotengine.org/en/stable/classes/class_input.html> Inference:
  distinct patterns for raise, holy damage and burning (hardware feature 5) need
  a native plugin.
- Pencil: pressure and tilt reach drag events, read from Godot's iOS source
  (linked above). Telling Pencil from finger is **unverified**.
- Controllers: "Controllers are supported on Windows, macOS, Linux, Android,
  iOS, and Web."
  <https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html>
- Off-Mac development: the best of all options. Inference: the whole game,
  including rendering, runs on Linux; only export, plugins and device behaviour
  need the Mac. Godot has no official unit-test framework that was found;
  community ones exist (not checked).
- Language is GDScript, so the rules module would not be Swift.

### 5.6 Unity

- Licence: Unity Personal is free up to $200,000: "Unity Pro is required if you
  have over $200,000 in total annual revenue and funding." The runtime fee is
  cancelled, and the splash screen is optional in Unity 6.
  <https://unity.com/products/pricing-updates>
- iOS builds: "Unity generates an Xcode project and then Xcode builds this
  project into the final application".
  <https://docs.unity3d.com/6000.4/Documentation/Manual/ios-environment-setup.html>
- **Unity recognises iPhone Duo; fold support is unverified.** The release notes
  for 6000.3.28f1 (6.3 LTS) and 6000.6.8f1, both dated 3 November 2026, add the
  device (quoted in 5.1). 6000.6.7f1 fixes a display bug "on iOS 27".
  <https://unity.com/releases/editor/whats-new/6000.6.7f1> No Unity 6000.3 to
  6000.7 release note mentions Xcode 27, the hinge or fold layout, so building
  with Xcode 27 and any fold-aware behaviour are **unverified**. Unity's 6.3 LTS
  manual was not reachable from this session.
- 2D tooling: Tilemap and Sprite Atlas (inference: mature). Stylus touches are
  reported as `TouchType.Stylus`; that Apple Pencil on iPhone Duo arrives this
  way is **unverified**. 120 Hz is a Player setting plus
  `Application.targetFrameRate`.
  <https://docs.unity3d.com/6000.4/Documentation/ScriptReference/Application-targetFrameRate.html>
- Core Haptics, Game Controller and GameKit come through Apple's own Unity
  plug-ins, which must be built separately.
  <https://raw.githubusercontent.com/apple/unityplugins/main/README.md>
- Off-Mac development: the editor runs on Ubuntu
  (<https://docs.unity3d.com/6000.4/Documentation/Manual/system-requirements.html>)
  and tests can run from the command line, but it is a heavy install and the
  project format is hard for an AI agent to edit outside the editor (inference).

### 5.7 Newer Apple game technology

- **Games app and Game Center**: "Your games will automatically display on the
  Games app". <https://developer.apple.com/games/> Challenges and activities
  are configured in Xcode (June 2025 update): "Use a GameKit Configuration file
  in Xcode to configure Game Activities and Challenges."
  <https://developer.apple.com/documentation/updates/gamekit> Relevant later,
  and only with the paid program; not for the slice.
- **Touch Controller framework** (iOS 26): "Integrate onscreen touch controls
  into your Metal-based games."
  <https://developer.apple.com/documentation/touchcontroller> Not relevant to a
  tap-driven tactics game.
- Metal 4, Game Porting Toolkit 4 (<https://developer.apple.com/games/whats-new/>)
  and Reality Composer Pro: 3D or porting tools. Not relevant.
- No new 2D framework appears on Apple's "What's new" page for games or in its
  framework update lists (checked 2026-11-26).

### 5.8 Comparison

Cells are summaries of the subsections above; anything not sourced there is an
inference or is marked unverified.

| | SwiftUI + SpriteKit | Raw Metal | Godot 4.7 | Unity 6 |
|---|---|---|---|---|
| Fold, hinge, tabletop layout | Direct first-party API | Direct (UIKit around a Metal view) | Native plugin needed; template sets `UIRequiresFullScreen`; unverified | Native plugin needed; unverified |
| Apple Pencil | Direct through UIKit touches; through `SpriteView` unverified (5.4) | Direct | Partial; Pencil vs finger unverified | Unverified; a stylus touch type exists |
| 120 Hz and lowering it | Yes by API; 120 on device unverified | Yes by API; 120 on device unverified | Yes by project setting; 120 on device unverified | Yes by Player setting; 120 on device unverified |
| Distinct haptics | Core Haptics directly | Core Haptics directly | Plugin needed | Apple plug-in |
| Controllers | Direct | Direct | Built in | Built in or Apple plug-in |
| Rules module testable on Linux | Yes, as a pure Swift package (`swift test`); done | Same | Yes, headless, with a community test plugin (not checked) | Yes, heavy |
| Rendering developable on Linux | No | No | Yes | Yes |
| Rendering code to write | Low | High | Low | Low |
| iOS 27 / Xcode 27 support | First-party SDK (inference: supported); behaviour on device untested | First-party SDK (inference: supported) | Unverified; changelog mentions only Xcode 26 | Partly: release notes add iPhone Duo device enums and an iOS 27 fix; Xcode 27 unverified |
| Main risk | No sign of active development (inference); could be deprecated one day | Large amount of work | Fold behaviour unverified; no hinge or fold-layout API in 4.7.2 | Fold behaviour unverified; heavy tooling |
| Cost | Free | Free | Free (MIT) | Free under $200k |

Swift on Linux, for the rules module: Swift publishes Linux toolchains
(<https://www.swift.org/install/linux/>) and "Swift Testing is included in
officially-supported Swift toolchains, including those for Apple platforms,
Linux, and Windows."
<https://raw.githubusercontent.com/swiftlang/swift-testing/main/README.md>

## 6. 2D sprite pipeline (brief 2.4)

### 6.1 Display scale and resolution

- iOS uses "@2x and @3x" assets: "A 2:1 density (called @2x) has a scale factor
  of 2, and a 3:1 density (called @3x) has a scale factor of 3."
  <https://developer.apple.com/design/human-interface-guidelines/images>
- **iPhone Duo's scale factor and point dimensions are unverified.** They are
  not in the HIG layout page, the HIG iPhone Duo page, or the developer article.
  They can be read at runtime in the simulator from the trait collection's
  display scale and the scene's bounds (3.5). Inference: the simulator reports
  the same values as the phone; confirm on the device.
- **Open discrepancy on the inner display.** App Store Connect asks for inner
  display screenshots at "2007 × 2853 pixels", while the hardware spec is
  1878 × 2670. The outer display matches its hardware spec (1398 × 2034).
  <https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications>
  The pages read do not explain the difference. One possible cause is that the
  inner display renders at a larger size and scales down to the panel; that is a
  guess. What it means for us: **do not assume one rendered pixel equals one
  physical pixel on the inner display** until it is measured. This matters most
  for pixel art.

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
  changing the aspect ratio over letterboxing or pillarboxing in games; if you
  can't avoid letterboxing or pillarboxing, add artwork to the padding area to
  help the experience feel full screen."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
- Pixel art looks correct only at whole-number scale factors. Godot's docs put
  it this way: "since displays can only display "whole" pixels, this will lead
  to uneven pixel scaling which results in incorrect appearance of pixel art",
  and with integer scaling "The remaining space is filled with black bars on all
  four sides".
  <https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html>
- In SpriteKit, pixel art needs nearest-neighbour filtering set per texture,
  because linear filtering is the default: "The default value is
  SKTextureFilteringMode.linear where each pixel is drawn by using a linear
  filter of multiple texels in the texture."
  <https://developer.apple.com/documentation/spritekit/sktexture/filteringmode>

Inference: two displays at 430 and 460 ppi, a possible non-1:1 inner display
(6.1), user-resizable Split View, and Apple's preference for changing the
aspect ratio over letterboxing all work against strict pixel-perfect pixel art.
The options are:

1. **High-resolution 2D** drawn large and scaled down with linear filtering.
   Scales cleanly to any size. Costs more to produce by hand.
2. **Pixel art at whole-number scale**, with the map showing more or fewer
   tiles or decorative margin to fill the leftover space. Keeps crisp pixels;
   needs care at each display size. Apple accepts artwork in the padding when
   letterboxing cannot be avoided.
3. **Pixel art scaled freely** with slight softness or uneven pixels. Simplest,
   looks worst.

Decided at GATE 2: sprites will be made with Google's image generation. The
choice between pixel art and high-resolution 2D is still open and should follow
the display measurements on the Mac. The slice uses placeholder art either way.

### 6.3 Tools

- **Xcode sprite atlases.** "inside the new asset catalog, add a new sprite
  atlas." "sprite atlases support app thinning".
  <https://developer.apple.com/documentation/spritekit/about-texture-atlases>
  "Texture atlases improve memory usage and rendering performance by reducing
  draw calls."
  <https://developer.apple.com/documentation/spritekit/sktextureatlas>
- **Aseprite** (pixel art editor). Command-line export of sprite sheets with a
  JSON description is documented in its docs repository, with the options
  `--sheet`, `--data` and `--format`.
  <https://raw.githubusercontent.com/aseprite/docs/main/cli.md> Its price was
  not confirmed from aseprite.org (host blocked); store listings found by
  search say $19.99.
- **TexturePacker**: not confirmed from its own site (host blocked). Not needed
  if Xcode atlases are used.

### 6.4 Placeholder art

- Plan: coloured shapes with a letter or icon per unit type, generated in code
  or as simple PNGs. No licence questions, and it makes unit type and side
  readable at a glance.
- Kenney's asset packs are reported as CC0 (public domain), but this was read
  only from search results and one of Kenney's GitHub READMEs, which labels its
  sprites and 3D models "CC0 licensed"
  (<https://raw.githubusercontent.com/KenneyNL/Starter-Kit-3D-Platformer/main/README.md>),
  not from kenney.nl itself. If a pack is used, the licence file inside the
  download is the authority.

## 7. Reference games (brief 2.5)

**Sourcing limit.** The publishers' and developers' sites (Nintendo, Subset
Games, Square Enix, App Store listings, TouchArcade) were blocked from this
session. Everything in 7.1 comes from search-result excerpts of those pages,
not from the pages themselves, so the wording may not be exact and none of it
is machine-checked. Items marked "from memory" have no source at all. Allowing
those hosts, or Adam checking the games directly, would firm this up. Apple's
guidance in 7.2 was read first-hand.

### 7.1 What each game does

| Game | Finding | Source quality |
|---|---|---|
| Fire Emblem Heroes (mobile) | A unit is dragged onto its target to attack; the publisher describes easy touch and drag controls and maps that fit in the palm of the hand. | Excerpt of fire-emblem-heroes.com/en/system |
| | Map is 6 × 8 in portrait, so the whole battlefield is on screen with no scrolling. | Excerpt of a news article; no official source found |
| | Combat forecast appears while holding a dragged unit over an enemy, at the top of the screen, away from the finger. | Excerpt of the official guide |
| | Enemy attack range is a one-tap Danger Area toggle, with a setting to keep it always on. | Excerpt of the official guide |
| Fire Emblem on Switch (handheld) | Handheld mode supported. Touch control of the battle map: not found in any source. | Excerpt of Nintendo store page; touch unverified |
| Into the Breach (iOS, via Netflix) | Released on iOS and Android through Netflix in July 2022. Whether it is still available in November 2026 was not confirmed. | Excerpt of news coverage |
| | 8 × 8 board, whole board visible. Enemy actions for the next turn are always shown. | Excerpts (gamedeveloper.com, reviews) |
| | Moves can be undone freely; a full turn reset is limited to once per battle. | Excerpt of a review |
| | A gamedeveloper.com article title, as shown in a search excerpt, speaks of sacrificing cool ideas for the sake of clarity. Speaker and exact wording not confirmed. | Excerpt of an article title; attribution unverified |
| Advance Wars 1+2: Re-Boot Camp | Handheld mode supported. Reviews disagree on whether it has touch controls; no official statement found. | Conflicting excerpts; unverified |
| Final Fantasy Tactics: War of the Lions (iOS) | Exists on iOS with tap controls; controller support was added later. Reviews disagree on how good the touch controls are. | Excerpts |
| | The 2025 Ivalice Chronicles release lists Switch, PlayStation, Xbox and PC, with no mobile version. | Excerpt of Square Enix announcement |
| Legend of Keepers | Villain-side dungeon defence. Came to iOS and Android in May 2023 with an interface described as designed for mobile. | Excerpts |
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
  virtual selection button."
  <https://developer.apple.com/design/human-interface-guidelines/game-controls>
- Controllers: "If you support game controllers, try to make sure there's a
  fallback for using the platform's default interaction method."
  <https://developer.apple.com/design/human-interface-guidelines/game-controls>
- Text: default 17 pt, minimum 11 pt on iOS.
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-games>
- "avoid relying solely on color to convey an important detail"
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-games>
  This applies to range overlays, the counter triangle and consecrated tiles.
- Fold: "In a grid-style layout, prefer an even number of columns so content
  divides cleanly."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
- Continuity: "Keep functionality and the state of elements the same between
  displays."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
- Pencil: the HIG's Apple Pencil page is still iPad-only and says nothing about
  iPhone Duo. Inference: its general advice carries over: "ensure that your
  app's controls respond to Apple Pencil so people don't have to switch to using
  their finger".
  <https://developer.apple.com/design/human-interface-guidelines/apple-pencil-and-scribble>

### 7.3 Design conclusions (inference, for the GDD)

1. **A tile must be at least 44 pt** to be a comfortable finger target. How
   many tiles fit therefore depends on the point size of each display, which is
   unverified (6.1). If the displays are @3x, the outer display is about
   466 × 678 pt. With the closed phone in portrait and the map not turned,
   16 columns across 466 pt gives about 29 pt per tile: far under the guideline.
   Turned a quarter-turn, or with the closed phone held in landscape, a square
   tile is at most about 38 pt (466 / 12): still under it. The design document
   therefore shows part of the map on the outer display and scrolls (GDD 12.3,
   decided at GATE 2).
2. **Support both drag and tap-tap** for moving and attacking. Drag is fast for
   fingers; tap-tap is precise and suits the Pencil.
3. **Show the combat forecast away from the finger**, at a screen edge or in the
   side panel, never under the touch point.
4. **Free undo of the latest move, explicit confirmation of attacks and
   raises.** Mis-taps are the main touch risk.
5. **Enemy threat range as a one-tap toggle.** In this game the same idea
   extends to showing which corpses an enemy cleric or fire user can reach next
   turn, since corpse denial is the central tension.
6. **Even number of map columns across the fold**, so the fold lands between
   tiles when the phone is partly folded. 16 and 12 are both even.
7. **Flat top-down grid**, not isometric, for tap accuracy.
8. **Never rely on colour alone** for side, undead type or tile state.

## 8. Recommendation and GATE 1

GATE 1 was approved by Adam on 2026-11-25 (`DECISIONS.md`). This section is the
recommendation as presented, with the audit's corrections.

### 8.1 Engine: native Swift, with SwiftUI around a SpriteKit map

- **Rules:** a Swift package with no Apple-framework imports beyond Foundation.
  Grid, units, combat, raise, command cap, turn order, AI, save and load. Unit
  tested with `swift test` on Linux and in GitHub Actions. (Built; see
  `STATUS.md`.)
- **Map and sprites:** SpriteKit.
- **Menus, HUD, unit panels, layout across fold states:** SwiftUI, using
  `ArrangementView` and reserved regions.

Reasons:

1. iPhone Duo is the point of the project, and the fold APIs are first-party
   only. Every other engine puts a plugin between the game and the features the
   brief lists first.
2. Inference: native Swift does not wait on a third party to add iOS 27 and
   Xcode 27 support. SpriteKit's framework page lists no deprecation (5.2).
   Godot's and Unity's support is unverified (5.5, 5.6).
3. The rules module is plain Swift, so the work done on Linux moves to the Mac
   unchanged, as the brief requires.
4. Pencil, Core Haptics, Game Controller and GameKit need no bridging.
5. Inference: Swift source and the JSON Xcode project format
   (`MAC_SETUP.md` section 4) are straightforward for Claude Code to edit and
   build from the command line.

What it costs:

- No rendering work can happen until the Mac is available. On Linux the game
  can only be exercised through tests.
- Inference: SpriteKit does not appear to be under active development (5.2);
  Apple has not said so. If Apple deprecated it, the SceneKit precedent
  suggests existing code would keep building for a while, but nothing says for
  how long. Because rules are separate from rendering, only the map renderer
  would need replacing. Apple documents no path away from SpriteKit:
  `SKRenderer` is itself part of SpriteKit, so the replacement would be a
  hand-written Metal renderer (5.3) or another engine.

Runner-up: Godot, if developing the visuals on Linux mattered more than fold
support. It is not recommended, because its iPhone Duo fold behaviour is
unverified and it has no hinge or fold-layout API.

### 8.2 Build pipeline

- Mac mini on macOS Tahoe 26.6 or later, with Xcode 27.2.
- iPhone Duo on iOS 27.2 (Apple's wording for Pencil support is "with iPhone Duo
  with iOS 27.2", <https://support.apple.com/en-us/108937>; that later versions
  also work is an inference).
- A free Apple Account is enough through GATE 3, with 7-day reinstall. The paid
  program ($99 per year) is needed for TestFlight, the App Store and Game
  Center (2.2).
- GitHub Actions on Linux runs the rules tests on every push.

### 8.3 Hardware features

| Feature | Verdict |
|---|---|
| 1. Two screens, seamless | Feasible. Confirm in the simulator first |
| 2. Apple Pencil | Feasible for taps and drawn paths. No pressure, no hover. Needs iOS 27.2. Cannot be tried in the simulator |
| 3. Tabletop layout | Feasible with first-party API |
| 4. 120 Hz with idle throttling | Feasible by API. 120 on device to be confirmed |
| 5. Core Haptics | Feasible at API level. Confirm on the device |
| 6. Controllers | Feasible |
| 7. Game Center / Games app | Feasible later. Needs the paid Apple Developer Program: the Game Center capability is not available to a free account |
| 8. Core ML | Not recommended now |
| Extra: hinge as input | Available. Apple names games as a use. A possible flourish. Optional |

### 8.4 Open risks

1. **Fold transition and SpriteKit.** None of the SpriteKit pages read mentions
   iPhone Duo or folding. Inference: because a fold arrives as a resize (3.1),
   SpriteKit's documented resize handling should apply (`MAC_SETUP.md` section
   7). Unverified on iPhone Duo. First task on the Mac: the fold prototype.
2. **Inner display resolution discrepancy** (6.1) and unknown scale factors.
   Measure in the simulator before any art decisions.
3. **The 16 × 12 map on the outer display** puts tiles under the 44 pt minimum
   if shown whole (7.3). Decided at GATE 2: the outer display scrolls.
4. **SpriteKit's future** (5.2).
5. **`SpriteView` touch handling** for Pencil is not documented on the pages
   read; may need the `UIViewRepresentable` fallback.
6. **Simulator limits.** Apple: "When running apps in a simulator in Device Hub,
   some hardware-specific features might not be available."
   <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>
   Two-finger gestures and Pencil cannot be sent to the simulator in Xcode 27.2
   (`MAC_SETUP.md` section 6). Haptics, real 120 Hz and hinge feel should be
   judged on the device.
7. **Mac mini.** Adam's M4 Mac mini (2024) is on Apple's compatibility lists.
   Still to check on the Mac: the installed macOS version and free disk space
   (`MAC_SETUP.md` section 1). The drive is probably 256 GB.
8. **Reference-game findings are weakly sourced** (section 7).
9. **Open portrait layout.** The open phone can be turned to portrait and
   orientation locking is unclear (3.1). The design has no layout for that pose
   yet.

### 8.5 Questions asked at GATE 1, and the answers

1. Engine: approved, native Swift (SwiftUI + SpriteKit).
2. Apple Developer account: none. A free Apple Account will be used.
3. Repository: stays in `necromancer-tactics/` inside `adamlee117097/apps`.
4. Mac mini: M4, 16 GB, 2024 model. macOS version still to be checked.
5. Apple Pencil and iOS version: not yet answered.
6. Firmer reference-game research: not requested.
