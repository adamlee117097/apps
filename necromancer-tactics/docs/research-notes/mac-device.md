> Raw working notes from a research agent, 2026-11-26. The claims that `MAC_SETUP.md` draws from these notes had their quotations checked by script against the source pages. The rest of these notes was not independently reviewed, and the planned second-agent review did not run. Treat anything here that is not in `MAC_SETUP.md` as a lead to verify.

# w1-device: free Apple Account limits, pairing the iPhone Duo, what the simulator cannot test

Research date: 2026-11-25. Done on Linux from a cloud container, not on the Mac mini (M4, 16 GB).
Every quote below was checked with `check_quote.py` against the URL given (all FOUND).
"Inference" marks my own conclusion. "Unverified" means no primary source was found.

---

## 1. Free Apple Account (Xcode "Personal Team"): capabilities

Source: <https://developer.apple.com/help/account/reference/supported-capabilities-ios>

The page DOES have a column for free accounts. The table (`aria-label="Supported capabilities (iOS)"`) has four columns:
`Capability | ADP | ADEP | Apple Developer`. Definitions on the page:

- "ADP: Apple Developer Program membership. Members of this paid program can distribute apps on the App Store."
- "ADEP: Apple Developer Enterprise Program membership. Members of this paid program can distribute apps to employees within an organization."
- "Apple Developer: Apple Account holders who have agreed to the Apple Developer Agreement to access certain resources on the Apple Developer website. No cost is associated with this agreement and developers can’t distribute apps."
- Intro line: "The capabilities available to an iOS provisioning profile depend on your program membership."

IMPORTANT caveat about evidence: the cells are check-mark icons, not text
(`<figure class="icon icon-checksolid" alt="yes">` or an empty `<td>`), so no verbatim text quote exists for a single cell.
I parsed the raw HTML (saved at `w1/device/raw/caps-ios.html`). Full table as parsed (YES = check icon, - = empty cell):

| Capability | ADP | ADEP | Apple Developer (free) |
|---|---|---|---|
| 5G Network Slicing | YES | YES | - |
| Access WiFi information | YES | YES | - |
| App Attest | YES | YES | - |
| **App groups** | YES | YES | **YES** |
| Apple Pay | YES | - | - |
| Associated domains | YES | YES | - |
| AutoFill credential provider | YES | YES | - |
| **Background modes** | YES | YES | **YES** |
| ClassKit | YES | YES | - |
| Communication Notifications | YES | YES | - |
| **Data protection** | YES | YES | **YES** |
| DriverKit Family MIDI * | YES | YES | - |
| Extended Virtual Addressing | YES | YES | - |
| Family Controls (development) * | YES | - | - |
| FileProvider Testing Mode * | YES | YES | - |
| Fonts | YES | YES | - |
| **Game Center** | YES | - | **-** |
| Group Activities | YES | YES | - |
| Head Pose | YES | YES | - |
| **HealthKit** | YES | YES | **YES** |
| HealthKit Estimate Recalibration | YES | YES | - |
| HLS Interstitial Previews | YES | - | - |
| **HomeKit** | YES | YES | **YES** |
| Hotspot | YES | YES | - |
| **iCloud: CloudKit** | YES | YES | **-** |
| **iCloud: iCloud documents** | YES | YES | **-** |
| **iCloud: iCloud key-value storage** | YES | YES | **-** |
| ID Verifier - Display Only | YES | YES | - |
| **In-App Purchase** | YES | - | **-** |
| Increased Debugging Memory Limit | YES | YES | - |
| **Inter-App Audio** | YES | YES | **YES** |
| Journaling Suggestions | YES | - | - |
| **Keychain sharing** | YES | YES | **YES** |
| Low Latency HLS | YES | - | - |
| **Maps** | YES | YES | **YES** |
| Matter Allow Setup Payload | YES | YES | - |
| MDM Managed Associated Domains | YES | YES | - |
| Media Device Discovery | YES | YES | - |
| Messages Collaboration | YES | - | - |
| Multipath | YES | YES | - |
| NFC Tag Reading | YES | YES | - |
| Network extensions | YES | YES | - |
| On Demand Install Capable | YES | - | - |
| Personal VPN | YES | YES | - |
| Push to Talk | YES | YES | - |
| **Push notifications** | YES | YES | **-** |
| Sensitive Content Analysis | YES | - | - |
| Shared with You | YES | - | - |
| Sign in with Apple | YES | - | - |
| SIM Inserted for Wireless Carriers | YES | YES | - |
| Siri | YES | YES | - |
| Spatial Audio Profile | YES | YES | - |
| Sustained Execution | YES | YES | - |
| Time Sensitive Notifications | YES | YES | - |
| Wallet | YES | YES | - |
| WeatherKit | YES | - | - |
| **Wireless Accessory Configuration** | YES | YES | **YES** |

("* Development only" per the page footnote.)

Summary for a single-player game on a free account:

- Available free (9 rows): App groups, Background modes, Data protection, HealthKit, HomeKit, Inter-App Audio, Keychain sharing, Maps, Wireless Accessory Configuration.
- NOT available free: Game Center (ADP only), all three iCloud rows (ADP + ADEP), Push notifications (ADP + ADEP), In-App Purchase (ADP only), Sign in with Apple (ADP only), Increased Debugging Memory Limit, Extended Virtual Addressing, Sustained Execution (all ADP + ADEP).
- "Game Controllers" is not a row in the table. Apple describes it as an Info.plist property, not an entitlement: "To support game controllers, add the Game Controller capability (the `GCSupportsControllerUserInteraction` property) to your project, and Xcode adds the Game Controller framework automatically." <https://developer.apple.com/documentation/gamecontroller>. Inference: it needs no provisioning, so it should work on a Personal Team. Not confirmed on the Mac.

Supporting sources:

- Xcode hides what you cannot use: "The Capabilities library displays only the capabilities available to the target platform and your program membership." <https://developer.apple.com/documentation/xcode/adding-capabilities-to-your-app>
- "Capabilities available to an app depend on the platform and your program membership." <https://developer.apple.com/help/account/capabilities/capabilities-overview>
- Game Center needs an entitlement and App Store Connect: "When you enable Game Center in your project, Xcode adds the Game Center entitlement to your App ID." <https://developer.apple.com/documentation/gamekit/initializing-and-configuring-game-center>; "Some app services — such as Game Center and In-App Purchase — require additional configuration in App Store Connect and your developer account." (adding-capabilities page). The account overview table gives App Store Connect and TestFlight to ADP only (icons, parsed from HTML; `w1/device/raw/account.html`).
- Inference: Game Center cannot be used at all on the free Personal Team (no entitlement, no App Store Connect record). The game must not hard-depend on GameKit during the free-account phase; wrap it behind a protocol and add it after joining the paid program.
- Inference: cloud saves via iCloud are not possible on the free account. Use local saves (the NecroRules save/load already exists) during the vertical slice.

## 2. Free limits (re-confirmed)

Source: <https://developer.apple.com/help/account/basics/about-your-developer-account>, section "Enable a personal team in Xcode". Exact text:

- "To install and test your apps on a personal device, you’ll need to sign in to your Apple Account in Xcode. If your account is not associated with a developer program membership, Xcode will indicate it’s a Personal Team. Your account’s App IDs, devices, certificates, and provisioning profiles are managed directly in Xcode, and you’ll be required to reprovision your apps to a device periodically."
- "You can register up to 10 App IDs, which expire after 7 days."
- "You can register up to 3 devices, which expire after 7 days."
- "You can install up to 3 apps per device. Provisioning profiles that enable apps to be installed on a device will expire 7 days from issuance. You’ll need to rebuild and reinstall your app to your device after expiration."
- Also: "To build more advanced app capabilities and distribute apps, you’ll need to be an Apple Developer Program member or Apple Developer Enterprise Program member."

Feature table on the same page (icons; parsed from HTML): "On-device testing using Xcode" is checked for "Registered for free"; "Certificates, Identifiers & Profiles", "App Store Connect", "TestFlight", "Xcode Cloud", "Code-level support" are not.

Practical consequences (inference):
- Pick one bundle identifier and keep it. Each new bundle ID uses one of the 10 App IDs for 7 days.
- The installed game stops launching 7 days after the profile was issued; re-run from Xcode to renew. Save data location should survive a rebuild-and-reinstall over the top (not verified; deleting the app would delete its data).

## 3. Pairing the iPhone Duo with the Mac (Xcode 27, Device Hub)

Sources:
- A: <https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub>
- B: <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>
- C: <https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device>
- D: <https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line>

Open Device Hub: "choose Manage Devices… from the run destination pop-up menu or choose Xcode > Open Developer Tool > Device Hub." (A)

### 3.1 Cable (A, "Pair devices using a cable")
1. "Connect the device with an appropriate cable to your Mac. If a Trust This Computer dialog appears on the device, tap Trust."
2. "In Device Hub, select the device in the sidebar and follow the instructions in the canvas. If a Pair button appears, click it. If necessary, enable Developer Mode on the device."
3. "After completing the steps, the device appears under Available in the Device Hub sidebar and a View Screen button appears in the canvas. You can disconnect the physical cable and run apps on the device through Xcode using Wi-Fi with IPv6 enabled on the same network as your Mac."

iPhone Duo has a "USB-C connector" and ships with a "USB‑C Charge Cable (1 m)" (<https://www.apple.com/iphone-duo/specs/>, read from cache). Inference: that cable into a USB-C port on the Mac mini is enough.

### 3.2 Wireless (A, "Pair physical devices wirelessly to your Mac")
- Requirement: "Upgrade your iPhone or iPad to iOS or iPadOS 27 or later to wirelessly pair it; otherwise, use a cable." iPhone Duo ships with iOS 27.1, so it qualifies.
- "First, ensure that the device is on the same Wi-Fi network as your Mac so that it can discover it."
- "Then click the Add Device button (+) in the toolbar and choose Pair Nearby Device… from the pop-up menu. Then choose the type of device from the buttons at the top of the sheet and follow the instructions that appear. For example, you may need to enable Developer Mode on the device before you can continue."
- "If a dialog appears on your Mac asking you to allow it to find devices, click Allow. In the Device Hub sheet, select the device that it discovers and click Next. In the next sheet, enter the PIN that appears on your device."
- "When the Trust This Computer dialog appears on the device, tap Trust. ... If you accidentally dismiss the trust dialog, or the device doesn’t immediately appear in Device Hub after you tap Trust, try restarting the device."
- "After completing the steps, the device appears in the Device Hub sidebar. If you upgrade the operating system later, you’ll need to pair the device again."
- New in Xcode 27: "Device Hub adds a new way to pair iPhone, iPad and Apple Watch running iOS 27/iPadOS 27/watchOS 27 and later over a network." <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes>

### 3.3 What the phone asks
- Trust prompt: "Trust This Computer" dialog, tap Trust (A).
- Passcode at trust time: Apple Support says "Enter your passcode, if you have one, to unlock your iPhone, iPad, or iPod touch." then "If you want to trust your computer, tap Trust." <https://support.apple.com/en-us/109054> (published December 04, 2025; general article, not Device Hub specific).
- PIN during wireless pairing (A, above).
- Developer Mode (C):
  - "Developer Mode only appears in Settings if you initiate pairing or if you previously paired the device to a Mac."
  - "In the Privacy & Security settings on the device, turn on the Developer Mode switch under Security. An alert appears to warn you that Developer Mode reduces the security of your device. To continue turning on Developer Mode, tap the Restart button in the alert."
  - "After the device restarts, another alert appears confirming that you want to turn on Developer Mode. In iOS and iPadOS, swipe up, tap Enable in the dialog, and enter your device passcode."
  - Turning it off: "turn off the Developer Mode switch in Settings > Privacy & Security and restart the device."
- "Trust the developer" for a Personal Team build. Older primary source (WWDC19 session 304, App Distribution): "Xcode installs it on your device, but in order for it to be able to launch, you'll need to trust your developer certificate on your device." and "You can trust the developer certificate by going into settings, general, profiles, and device management." <https://developer.apple.com/videos/play/wwdc2019/304/>. The exact Settings path on iOS 27 is UNVERIFIED for developer apps. Apple's current enterprise-app article uses "Settings > General > VPN & Device Management" and says "In iOS 18, iPadOS 18, and visionOS 2 and later, tap \"Allow & Restart\" to proceed with establishing trust" <https://support.apple.com/en-us/118254> (published June 04, 2026), and needs internet access to verify the certificate. Whether the restart also applies to Personal Team apps is unverified. Settled by: first run on the device.

### 3.4 Signing set-up (B, "Set up code signing for physical devices")
- "First, sign in with your Apple Developer Program or personal Apple Account in Xcode > Settings > Apple Accounts."
- "Then, in the Signing & Capabilities pane of the project editor, click Set Up Signing under Signing if it appears. In the sheet, choose your team from the Team pop-up menu, enter a unique bundle ID ... in the Bundle Identifier field, and click Set Up."
- "If the Set Up Signing button doesn’t appear, toggle “Automatically manage signing” on, assign your project to a team, and enter a bundle ID in the Signing & Capabilities pane instead."
- "When you enable the “Automatically manage signing” option, Xcode registers the device and creates the development provisioning profile for you. If a Register button appears under Signing, click it to add it to the provisioning profile."
- "The first time you run your app on a physical device other than a Mac, Xcode needs to register the device and create a provisioning profile that contains the device."

### 3.5 Command line (D) — useful for Claude Code in a terminal
```
% devicectl manage pair                      # "To pair physical devices that you connect to your Mac with a cable"
% devicectl list devices
% devicectl device info details --device <uuid|ecid|udid|name>
% devicectl device info lockState --device <uuid|ecid|udid|name>
% devicectl device install app --device <uuid|ecid|udid|name> <path>
% devicectl device process launch --device <uuid|ecid|udid|name> <bundle-identifier-or-path>
% devicectl device copy from --device <...> --source <filename> --destination <filename> --domain-type appDataContainer --domain-identifier <bundle ID>
```
- "Whether you use the command line or Device Hub to pair physical devices, unlock the device before entering `devicectl` commands."
- "use the `--json-output` option with subcommands that create a JSON file with the command results ... don’t rely on or parse the Terminal output from these commands"
- The trust tap, Developer Mode switch, restart and passcode are on the phone; Adam must do them. Claude Code cannot.
- `xcrun simctl help` for simulators; "`simctl` and `devicectl` now support rebooting a simulator using the reboot command." (Xcode 27 release notes).

## 4. iPhone Duo in Device Hub: pose controls

Source E: <https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub>, section "Interact with your iOS app on an iPhone Duo simulator":

- "To ensure your iOS app adapts seamlessly to both iPhone Duo displays, simulate folding an iPhone Duo using the controls below the bezel in the canvas:"
- "To close the iPhone Duo, click the Closed button on the right of the Rotate Right button."
- "To partially open the iPhone Duo, click the Partially Open button in the middle of the three device pose buttons."
- "To fully open the iPhone Duo, click the Open button on the far right."
- "To fold the device to any angle, hold the Option key while dragging the slider that appears below the bezel."

So: three pose buttons (Closed, Partially Open, Open) plus a continuous hinge-angle slider (Option-drag).
Rotation (same page, general iOS table): "Rotate the simulator to the left | Click the rotate button under the device bezel or choose Controls > Rotate Left."; right = Option-click or Controls > Rotate Right; also "Device > Orientation submenu. Face Up and Face Down do not rotate the simulator."

Tech Talk 111461 <https://developer.apple.com/videos/play/tech-talks/111461/>:
- "To get the full-screen experience, download Xcode 27.1. Choose the iPhone Duo simulator to run your app in Device Hub. Use the control buttons at the bottom of the screen to open, close, rotate, or fold iPhone Duo."
- Split View in the simulator: "Using Device Hub, preview your app on the inner display. Drag your app using the home indicator at the bottom to one side of the screen. An area to drop your app appears."

StandBy:
- Xcode 27.1 known issue: "StandBy is unavailable in the iPhone Duo Simulator runtime. (187708663)" <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes>
- Xcode 27.2 new feature list: "Support for Standby in iPhone Duo" <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>
- Xcode 27.3 beta 2 resolved: "Fixed: Standby mode might render fully blank. (192294186)" <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes>. Inference: StandBy in the 27.2 simulator may render blank.

Hinge angle from UI tests (beta only): "`XCUIAutomation` supports setting the hinge angle on iPhone Duo with a new `XCUIHinge` class. (187479559)" (Xcode 27.3 Beta release notes, "New Features in Xcode 27.3 Beta"). `XCUIHinge.angle` is "The hinge’s current angle, in radians." `var angle: CGFloat { get set }`; "Setting this property can cause the device to switch between displays." and "On physical devices, programmatically opening the hinge while the device is closed is not supported and results in a test failure." <https://developer.apple.com/documentation/xcuiautomation/xcuihinge/angle>. Not in Xcode 27.2.

Other Device Hub facts:
- Xcode 27.2 Device Hub list: "Support for touch events through Sidecar", "Support for Standby in iPhone Duo", "Slow Motion Animation (simulators only)", "Simulate Shake (simulators only)", "Simulate Fall (simulators only)", "Simulate Memory Pressure (simulators only)", "Option to Hide Device Bezels", app settings.
- Resize mode for a simulated iPhone: "To enter resize mode, run your app on the simulator and click the “Enter resize mode” button in the canvas toolbar." <https://developer.apple.com/documentation/xcode/configuring-the-environment-of-a-simulated-device>
- Xcode 27.1 Previews: "The canvas overrides picker now includes a Display group for previewing content on a device’s alternative display. (182598534)"
- Screenshots: "Device Hub captures the screenshot at the full resolution of the simulated or physical device, regardless of the display resolution of your Mac." <https://developer.apple.com/documentation/xcode/capturing-screenshots-and-videos-from-devices> (useful for reading the display scale factors, RESEARCH.md 8.4).
- Physical device mirroring: "For physical devices, you can interact with the view in Device Hub and the physical device simultaneously." <https://developer.apple.com/documentation/xcode/device-hub>

No Apple page describes a command-line (`simctl`/`devicectl`) way to set the iPhone Duo pose. Unverified whether one exists; `xcrun simctl help` on the Mac settles it.

## 5. What a simulator cannot test

### 5.1 The comparison page
- The old page "Testing in Simulator versus testing on hardware devices" is gone: `https://developer.apple.com/documentation/xcode/testing-in-simulator-versus-testing-on-hardware-devices` returns 404 (page and backing JSON), with no redirect. `.../xcode/devices-and-simulator` and `.../identifying-graphics-and-animations-issues-in-simulator` redirect (301) to `.../xcode/device-hub`. The Xcode docs index (walked from `/documentation/xcode/device-hub`) lists no replacement comparison page.
- What Apple currently says in general:
  - "Be aware that simulators run within Device Hub on your Mac and don’t replicate the performance or features of a physical device. To verify that your app runs exactly as intended, run it on one or more physical devices." (B)
  - "When running apps in a simulator in Device Hub, some hardware-specific features might not be available. Frameworks that provide access to device-specific features also provide API to tell you when those features are available. Call those APIs and handle the case where a feature isn’t available. To test the feature itself, run your code on a physical device." (B)
  - "Run your app on physical devices to test features or services that have hardware dependencies or investigating performance issues." <https://developer.apple.com/documentation/xcode/device-hub>

### 5.2 Item by item

| Item | Apple says | Status |
|---|---|---|
| Performance | "You get higher-fidelity measurements by profiling on a device instead of the simulator." <https://developer.apple.com/documentation/xcode/improving-your-app-s-performance>. Metal: "Simulator doesn’t try to exactly simulate the GPU from the iOS, tvOS, or visionOS device you’re simulating." "Simulator provides a device instance with capabilities similar to an Apple family 2 GPU"; "Design your app to run on actual hardware, and test on real devices to tune its performance." <https://developer.apple.com/documentation/metal/developing-metal-apps-that-run-in-simulator> | Sourced: simulator timings on the M4 say nothing about the A20 Pro. SpriteKit renders through Metal (inference: same caveat applies). |
| Game controllers | Xcode 27 known issue: "Connecting a game controller to a simulator or device is only supported for the visionOS simulator. (109362811)" <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes> | Sourced for Xcode 27.0. Not listed as resolved (or as still known) in the 27.1, 27.2 or 27.3 beta 2 notes, so status in 27.2 is unverified. Controller testing needs the real phone with a controller paired to the phone. |
| Game Center | "Testing your app with the Game Progress Manager requires a physical device and is available for iOS 18.4 and later, macOS 15.4 and later, tvOS 18.4 and later, and visionOS 2.4 and later." (GameKit init page). Also blocked by the free account (section 1). | Sourced: local Game Center testing tool needs a physical device. Whether GKLocalPlayer authentication works in the simulator at all: unverified. |
| Haptics (Core Haptics) | No Apple page states simulator behaviour. Apple says to check capability: "Before you create and configure a haptic engine, check the hardware capabilities to see what type of feedback the device supports. Some devices don’t support haptic feedback, including iPad, iPod touch, and Apple Vision Pro." `CHHapticEngine.capabilitiesForHardware().supportsHaptics` <https://developer.apple.com/documentation/corehaptics/preparing-your-app-to-play-haptics> | UNVERIFIED for the simulator. Lead only (Apple Developer Forums, not a primary source): a developer reports `supportsHaptics` returns false in the simulator, <https://developer.apple.com/forums/thread/132004> (seen via search snippet, not opened). Inference: a Mac mini has no Taptic Engine so haptics cannot be felt; code must guard on `supportsHaptics`. Settle by printing `supportsHaptics` in the iPhone Duo simulator. |
| Apple Pencil | Device Hub docs list only finger gestures (Tap, Double-tap, Touch and hold, Drag and drop) for iOS simulators (E). Xcode 27 notes: "clicking with a mouse or trackpad produces a simulated finger touch of type `UITouch.TouchType.direct` rather than `UITouch.TouchType.indirectPointer`." Pencil touches are a different type: "A touch from Apple Pencil." (`UITouch.TouchType.pencil`). | Inference: Device Hub cannot produce `.pencil` touches; no Apple page documents a simulated Pencil. UNVERIFIED either way. Because "UIKit reports touches from Apple Pencil in the same way it reports touches from a person’s fingers" (<https://developer.apple.com/documentation/uikit/handling-input-from-apple-pencil>), position-only Pencil input can be approximated with mouse clicks; tilt (altitude/azimuth) and real Pencil latency need the device plus an Apple Pencil (USB-C) and iOS 27.2. |
| Hinge angle (`onHingeChange`, `UIHingeInteraction`) | Simulator can set any angle: "To fold the device to any angle, hold the Option key while dragging the slider that appears below the bezel." (E). API: "Both give you access to the high-level hinge status of: closed, partially open, and fully open. Beyond the discrete status, it provides continuous updates of the hinge angle." (Tech Talk 111464). "Hinge updates arrive while the hinge is moving, at a pace the system sets." (UIHinge docs). "A null value indicates the app is running on a device without a hinge." | Sourced: the simulator has an angle control. Inference: `onHingeChange` receives angle updates in the simulator while dragging. No page says so explicitly, and update cadence in the simulator vs. the device is UNVERIFIED. Settle with the fold/unfold prototype (log angle + status). `UIHinge.Status` cases: closed, fullyOpen, partiallyOpen, unknown. |
| ProMotion 120 Hz | No Apple page states the simulator's refresh rate. ProMotion doc: "If you don’t enable this support, Core Animation won’t access higher frame rates (above 60Hz)." (key `CADisableMinimumFrameDurationOnPhone`), "The system automatically handles frame pacing for UIKit, SpriteKit, SwiftUI, and CAAnimation animations for you.", "do your own testing on an actual device to make sure your animations look good." <https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays> | UNVERIFIED for the simulator (likely tied to the Mac's display; Mac mini has no built-in display). 120 Hz behaviour, thermal throttling and Low Power Mode caps must be checked on the phone. Note the page's device list does not name iPhone Duo; the spec page does ("ProMotion technology with adaptive refresh rates up to 120Hz", RESEARCH.md section 1). Whether an SKView on iPhone needs `CADisableMinimumFrameDurationOnPhone` for >60 fps is not stated for SpriteKit specifically: unverified. |
| Multi-touch (pinch/two-finger pan on the map) | Xcode 27: "Device Hub doesn’t currently support sending a two-finger touch to a device or simulator. (169537162)". Trackpad pinch is delivered as a different event: "When pinching or rotating with a trackpad, `UIEvent.EventType.transform` is emitted." and "This hybrid behavior has been added for ease of use for Device Hub, and does not reflect functionality available on physical devices." Xcode 27.2: touches via Sidecar/"MacBook with Touch" only. Xcode 27.3 beta: "Device Hub now supports using option-drag to simulate two-finger touch gestures for iPhones and iPads. (169537162)" | Sourced. On a Mac mini with Xcode 27.2 there is no way to send two real touches to the simulator (no touch screen; Sidecar needs an iPad). Raw `touchesBegan`-based pinch code in SpriteKit must be tested on the phone, or wait for Xcode 27.3. |
| Camera/mic while mirroring | "You can’t access the camera or microphone while interacting with a physical device in Device Hub." (E) | Not relevant to the game. |
| App extensions | 27.1 known issue: "Running and debugging most app extensions is unavailable in the iPhone Duo Simulator runtime. (187708767)" | Not listed as fixed in 27.2. Not relevant unless widgets are added. |

## 6. Is iOS 27.2 public? Yes.

- Apple security releases, <https://support.apple.com/en-us/100100>: "The latest version of iOS and iPadOS is 27.2.1." Table rows (name | available for | release date):
  - "iOS 27.2.1 and iPadOS 27.2.1 | iPhone 11 and later, ... | 09 Nov 2026"
  - "iOS 27.2 and iPadOS 27.2 | iPhone 11 and later, iPad Pro 12.9-inch 4th generation and later, ... | 26 Oct 2026"
  - "iOS 27.1 | This update has no published CVE entries. | iPhone Duo | 23 Oct 2026"
  - "Xcode 27.2 | macOS Tahoe 26.6 and later | 29 Oct 2026"
- Security content page: "About the security content of iOS 27.2 and iPadOS 27.2" — "Released October 26, 2026" <https://support.apple.com/en-us/149230> (Published Date: November 20, 2026).
- "About iOS 27 Updates", <https://support.apple.com/en-us/149076> (Published Date: November 09, 2026): lists iOS 27, 27.0.1, 27.2, 27.2.1. For 27.2.1: "This update provides bug fixes and security updates for your iPhone." It has no iOS 27.1 section.
- Developer releases feed, <https://developer.apple.com/news/releases/>: "iOS 27.2.1 (24B91034)" and "iOS 27.2.1 (24B156)", both November 9, 2026; "iOS 27.3 beta 2 v2 (24C5049f)" November 19, 2026; "Xcode 27.2 (27B52)" October 29, 2026; "Xcode 27.3 beta 2 (27C5035i)" November 16, 2026. (The feed has no separate "iOS 27.2" or "iOS 27.1" item.)
- Release-notes index, <https://developer.apple.com/documentation/ios-ipados-release-notes>: lists "iOS & iPadOS 27.3 Beta 2 Release Notes", "iOS & iPadOS 27.2 Release Notes" (no beta label), "iOS & iPadOS 27 Release Notes". There is no 27.1 page (`.../ios-ipados-27_1-release-notes` is 404). The 27.2 page itself carries no date and still contains one leftover sentence saying "this beta" in a Health known issue.
- Pencil requirement, <https://support.apple.com/en-us/108937> (Published Date: November 05, 2026): "You can use Apple Pencil (USB-C) with these iPad models with iPadOS 17.1.1 or later, and with iPhone Duo with iOS 27.2:"

Conclusion (sourced): iOS 27.2 was released to the public on 26 October 2026 and 27.2.1 on 9 November 2026. The current public version is 27.2.1; 27.3 is in beta.
Inference: the second 27.2.1 build (24B91034) is probably the iPhone Duo build; Apple's pages do not say which device it is for. Inference: an iPhone Duo updated through Settings > General > Software Update will be on 27.2.1, which satisfies the Pencil requirement. Not verified on Adam's phone.
Xcode match: "Xcode 27.2 supports on-device debugging in iOS 17 and later, tvOS 17 and later, watchOS 10 and later, and visionOS. Xcode 27.2 requires a Mac running macOS Tahoe 26.6 or later." Xcode 27.2 includes the iOS 27.2 SDK. Inference: Xcode 27.2 can run and debug on a phone with iOS 27.2.1 (point releases normally need no new Xcode); not stated explicitly by Apple.

## 7. Known issues in Xcode 27.1 / 27.2 release notes (iPhone Duo, Device Hub, etc.)

Xcode 27.1 <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes> — Simulator, Known Issues (complete list):
- "Initial Simulator launch can take several minutes. (187708500)"
- "StandBy is unavailable in the iPhone Duo Simulator runtime. (187708663)"
- "Running and debugging most app extensions is unavailable in the iPhone Duo Simulator runtime. (187708767)"
- "In the iPhone Duo simulator, an app using `CameraCaptureAccessory` can use both displays at the same time without an active camera capture session. (190155353)" (fixed in 27.2)
- Mac Catalyst: iOS 27.1-only APIs show compile errors for Mac Catalyst; workaround `#if !targetEnvironment(macCatalyst)`. Not relevant (no Catalyst target).

Xcode 27.2 <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes> — Device Hub, Known Issues:
- "Screenshots and recordings in iPhone Duo might be black for up to a few minutes after booting the device. (187146039)"
- "VoiceOver, the Accessibility Inspector, and other accessibility tools cannot convey screen content on an iPhone Duo within Device Hub. (187148389)"
- "When switching between the inner and outer display of the iPhone Duo simulator, modifier keys such as Shift and Command might stop working. (189465196)" — "Workaround: Click with the mouse on the currently visible screen."
- "Device Hub is unable to customize the text size for a device running iOS 18 or earlier. (189261485)"
- CarPlay needs USB; "Secure keyboard entry" conflicts with "Capture Keyboard".
Simulator, Known Issues:
- "Cloning a simulator device running runtime 27.2 might fail due to incorrect file permissions. (188407822) (FB24939277)" — Workaround: `find ~/Library/Developer/CoreSimulator/Devices/<SOURCE_UDID>/data -name '*.sb-????????-??????' -delete`
SDK, Known Issues: other-platform SDKs wrongly report 27.1 as a deployment target (not iOS).
27.2 resolved: "Fixed: Device Hub stopped sending touch and button input to a connected device after a period of inactivity. (182695157)"; "Fixed: The Device > Simulate Memory Warning menu item did not work. (188326513)"; the CameraCaptureAccessory issue.
27.2 new: JSON project format `.xcproj` "more readable, merge-friendly, and easier for coding agents to edit. Enable it in the File inspector."

Nothing in the 27.1 or 27.2 notes mentions SpriteKit, SwiftUI `ArrangementView`, reserved regions, or the hinge (grep of both pages: no matches for spritekit, arrangement, reserved, hinge). The word "SpriteKit" does not appear in the Xcode 27, 27.1, 27.2, 27.3 beta 2 notes or the iOS 27 / 27.2 / 27.3 beta 2 notes.

Relevant items from neighbouring notes:
- Xcode 27.3 beta 2, Previews resolved: "Previews now render correctly on iPhone Duo. (185995983)". Inference: SwiftUI previews for iPhone Duo can render incorrectly in Xcode 27.2; use the simulator rather than the preview canvas to judge layout.
- Xcode 27.3 beta 2: "Fixed: Previewing on a device could erase the app’s existing data. (190012895) (FB25185762)". Inference: in 27.2, avoid on-device previews of the game once real save data exists on the phone.
- Xcode 27.0 Device Hub known issues that the later notes do not mark as fixed: game controller (109362811), "The Controls->Shake menu item does not work. (171282777)" (27.2 lists "Simulate Shake (simulators only)" as an improvement), "When running parallel testing in simulators, devices may not be visible in Device Hub but are still actively running tests. (176809181)".
- iOS 27.2 SDK behaviour change (UIKit): "On iOS 27.1 and later, the default layout margins for a `UIView` are zero. A view controller continues to provide its view with `systemMinimumLayoutMargins`..." <https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27_2-release-notes>

## 8. Could not verify
- Simulator behaviour of Core Haptics, Apple Pencil input, 120 Hz, and hinge update cadence: no Apple page found. Tried: Device Hub doc tree (device-hub, interacting-with-your-app-in-device-hub, configuring-the-environment-of-a-simulated-device, managing..., running...), Core Haptics docs, UIKit Pencil docs, ProMotion doc, WWDC26 session 260 "Get the most out of Device Hub", Tech Talks 111461/111463/111464, Xcode 27/27.1/27.2/27.3b2 release notes, two site-restricted web searches.
- Whether the game-controller limitation (109362811) still applies in Xcode 27.2.
- The exact "trust developer" Settings path and whether a restart is required for Personal Team apps on iOS 27.
- Whether `simctl`/`devicectl` can set the iPhone Duo pose from the command line (Xcode 27.2).
- Which device the iOS 27.2.1 build 24B91034 is for.
- Whether GameKit authentication works in the simulator; whether StoreKit Testing in Xcode works with a Personal Team (not researched; IAP is out of scope for the slice).

## 9. Suggested on-Mac checks (cheap, settle the unknowns)
1. In the iPhone Duo simulator: log `CHHapticEngine.capabilitiesForHardware().supportsHaptics`, `UIScreen`/trait `displayScale`, `SKView.preferredFramesPerSecond` and measured frame interval.
2. Fold prototype: log `onHingeChange` status + angle while Option-dragging the slider; note update rate.
3. `xcrun simctl help` and `xcrun devicectl help` to look for pose/hinge subcommands.
4. On the phone after pairing: same logs, plus a Pencil touch (`UITouch.TouchType`), plus confirm Settings > General > About shows 27.2 or later.
