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

Sections 5 to 8 (engine comparison, sprite pipeline, reference games,
recommendation) are in progress.
