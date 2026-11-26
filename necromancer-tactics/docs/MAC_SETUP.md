# Mac setup and day-one checklist

Researched 2026-11-26 from a Linux cloud session. **Nothing in this file has been
run on a Mac yet.** It is the plan for the first session on Adam's Mac mini.

How to read it:

- Quoted text is verbatim from the linked page. Every quotation here was checked
  against its page by script (`tools/citations/check_doc.py`).
- **Inference** marks a conclusion drawn from sourced facts. **Unverified** means
  no primary source was found; section 8 lists what will settle each one.
- The research was done by four research agents. Their quotations were
  machine-checked; the planned second-agent review of their reasoning did not
  run, because the account's usage limit was reached. Claude read every claim
  used here against its quotation.

## 1. The machine

- Adam's Mac is a Mac mini with an M4 chip and 16 GB of memory (Adam's
  statement, 2026-11-25), bought in July 2025.
- That is the Mac mini (2024). Apple's specifications for it: "Apple M4 chip
  16GB unified memory Configurable to: 24GB or 32GB" and "Apple M4 chip 256GB
  SSD Configurable to: 512GB, 1TB, or 2TB". The M4 Pro model starts at 24 GB, so
  a 16 GB machine is the M4. <https://support.apple.com/en-us/121555>
- Inference: it has the 256 GB drive. Adam paid Apple's starting price, and
  Apple's launch announcement says "Mac mini with M4 starts at $599 (U.S.)".
  <https://www.apple.com/newsroom/2024/10/apples-new-mac-mini-is-more-mighty-more-mini-and-built-for-apple-intelligence/>
  A sale or a custom order could mean a larger drive. `df -h /` settles it.

### macOS

- Xcode 27.2 needs macOS Tahoe 26.6 or later: "Xcode 27.2 requires a Mac running
  macOS Tahoe 26.6 or later."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>
- The Mac can run it. Apple's list for macOS Tahoe 26 includes "Mac mini
  (2024)". <https://support.apple.com/en-us/122867> So does the list for the
  newer system: "macOS 27 Golden Gate is the latest major version of the Mac
  operating system. You can install it on any of these Mac models."
  <https://support.apple.com/en-us/127255>
- Current versions on 2026-11-20: "macOS 27 Golden Gate 27.2.1" and "macOS Tahoe
  26 26.7.3". <https://support.apple.com/en-us/109033>
- Inference: either an up-to-date macOS Tahoe or macOS 27 will do. The Mac does
  not have to move to macOS 27 for this project.
- The Mac mini (2024) launched with macOS Sequoia: "macOS Sequoia completes the
  new Mac mini experience".
  <https://www.apple.com/newsroom/2024/10/apples-new-mac-mini-is-more-mighty-more-mini-and-built-for-apple-intelligence/>
  That is too old for Xcode 27. What it runs today is unknown until `sw_vers` is run.

### Xcode

- The latest released Xcode is 27.2, dated October 29, 2026. Xcode 27.3 is in
  beta. <https://developer.apple.com/news/releases/>
- "Xcode 27.2 includes Swift 6.4 and SDKs for iOS 27.2, iPadOS 27.2, tvOS 27.2,
  watchOS 27.2, macOS 27.2, and visionOS 27.2."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>
- Xcode 27 needs Apple silicon, which an M4 is: "Xcode 27 will only install and
  run on Apple silicon Macs."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes>
- iOS support is a separate download: "If you don't have platform support
  installed for your target, you can't build and run your app on a device."
  <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>

### Memory and disk

- Apple states no minimum memory and no minimum free disk space for Xcode 27 on
  any page read (release notes for 27, 27.1 and 27.2, the requirements table,
  the components, coding intelligence and Device Hub documentation). That is an
  absence on those pages, not a statement by Apple.
- **Unverified:** the download and installed size of Xcode 27.2 and of the iOS
  27.2 simulator runtime. No Apple page read gives them.
- Inference: with a 256 GB drive, free disk space is the main risk, more than
  the chip or the memory. Xcode shows what each component uses: "Xcode shows the
  installed and enabled components along with the amount of storage you can
  recover if you remove them."
  <https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components>
- **Unverified:** whether 16 GB is comfortable with Xcode, one iPhone Duo
  simulator and Claude Code running together. Activity Monitor on the Mac will
  show it.
- Claude Code itself needs little: "Hardware: 4 GB+ RAM, x64 or ARM64 processor".
  <https://code.claude.com/docs/en/setup>
- Expect a slow first simulator start. Xcode 27.1 lists as a known issue:
  "Initial Simulator launch can take several minutes."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes>

## 2. Checks Claude Code runs first

These are the checks from section 2.1 of the project brief, plus the commands
whose help text settles open questions in section 8.

```sh
sw_vers
system_profiler SPHardwareDataType
df -h /
xcodebuild -version
man xcodebuild                 # -destination syntax, -showdestinations
xcrun simctl help              # simulator commands; any pose or fold control?
xcrun devicectl help           # device commands; any pose or fold control?
xcrun xcodeproj help           # can it create a project, or only edit one?
```

Report the model, chip, memory, free disk space, macOS version and Xcode
version to Adam before installing anything large.

## 3. Steps that need Adam in person

1. **Update macOS** to Tahoe 26.6 or later, or to macOS 27, if `sw_vers` shows
   something older.
2. **Install Xcode 27.2** and, inside it, iOS platform support.
3. **Sign in to Xcode** with a free Apple Account: "sign in with your Apple
   Developer Program or personal Apple Account in Xcode > Settings > Apple
   Accounts."
   <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>
4. **Let outside agents use Xcode.** In Xcode's Intelligence settings: "Under
   Model Context Protocol, choose either Always or “While Xcode is Open” from the
   “Allow External Agents to Use Xcode Tools” pop-up menu."
   <https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode>
5. **Install Claude Code** on the Mac, clone this repository, and start a
   session in it. Install instructions: <https://code.claude.com/docs/en/setup>
6. **Create the app project in Xcode**, once. Apple documents creating a project
   only through Xcode's windows: "choose App from the New Project pop-up menu or
   choose File > New > Project and select App from anywhere in Xcode."
   <https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app>
   Claude Code will first check whether `xcrun xcodeproj` can do it instead, and
   will say exactly what to click if not. The project goes in
   `necromancer-tactics/`, beside `NecroRules/`.
7. **Pair the iPhone Duo.** "Connect the device with an appropriate cable to your
   Mac. If a Trust This Computer dialog appears on the device, tap Trust."
   Wireless pairing also exists for iOS 27: "In the Device Hub sheet, select the
   device that it discovers and click Next. In the next sheet, enter the PIN that
   appears on your device." Keep the phone unlocked while this happens. Apple
   adds: "If you upgrade the operating system later, you'll need to pair the
   device again."
   <https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub>
8. **Turn on Developer Mode** on the phone, under Settings > Privacy & Security.
   It appears only after pairing has started. The phone restarts, then: "After
   the device restarts, another alert appears confirming that you want to turn on
   Developer Mode. In iOS and iPadOS, swipe up, tap Enable in the dialog, and
   enter your device passcode."
   <https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device>
9. **Trust the developer certificate** on the phone the first time the app is
   installed. The only Apple source found for this step is from 2019: "Xcode
   installs it on your device, but in order for it to be able to launch, you'll
   need to trust your developer certificate on your device."
   <https://developer.apple.com/videos/play/wwdc2019/304/> The exact Settings
   path on iOS 27 is unverified.
10. **Update the iPhone Duo to iOS 27.2 or later** if Apple Pencil will be used.
    iOS 27.2 has been public since 26 October 2026 and 27.2.1 since 9 November.
    <https://support.apple.com/en-us/100100>

## 4. How Claude Code works with Xcode

### The Xcode bridge

- Apple documents connecting Claude Code to Xcode: "run the following command in
  Terminal to give Claude Code access to your open project and Xcode
  capabilities". The command is
  `claude mcp add --transport stdio xcode -- xcrun mcpbridge`.
  <https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode>
- The project has to be open in Xcode while the agent works (step 4 above).
- What it offers, from the Xcode 27 release notes: "Agents can now boot
  simulators, install and launch apps, synthesize touch events, and capture
  screenshots to verify UI behavior." and tools for "listing and switching
  between available schemes and run destinations and inspecting and modifying
  build settings, compiler flags, entitlements, and Info.plist keys."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes>
- Xcode 27.2 can render a SwiftUI preview to an image for the agent: "The
  RenderPreview MCP tool now returns the list of available render destinations,
  and lets the caller specify which destination to use for rendering."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>
  Previews of iPhone Duo may be wrong in 27.2: the 27.3 beta notes list as fixed
  "Previews now render correctly on iPhone Duo."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes>
- **Unverified:** the exact list of tools the bridge gives an outside agent, and
  whether the simulator tools (boot, tap, screenshot) reach an outside agent or
  only agents running inside Xcode. `claude mcp list` and `/mcp` on the Mac will
  show the list.

### The command line

- Tests: "When you run tests with `xcodebuild` in Terminal, the command outputs
  an Xcode Test Results (`.xcresults`) bundle that contains session results,
  code coverage (if enabled), and other logs."
  <https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results>
  The rules package needs no Xcode at all: `swift test` in `NecroRules/`.
- The `-destination` syntax is not defined on Apple's current web pages. Its
  reference says: "To learn more about this command, enter `man xcodebuild` in
  Terminal." <https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference>
- Simulators and devices: "You can manage physical and simulated devices using
  the `devicectl` command-line tool in Terminal without running Xcode." Apple's
  example for installing on a phone is
  "devicectl device install app --device <uuid|ecid|udid|name> <path>".
  <https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line>
- Project files: "Use the `xcodeproj` command-line tool to modify an existing
  Xcode project configuration in Terminal." It can attach the rules package:
  the page shows `xcrun xcodeproj pkg add-local <path>` and "xcrun xcodeproj pkg
  link <product> --package <package> --target <target>".
  <https://developer.apple.com/documentation/xcode/managing-xcode-projects-using-the-command-line>
- The project file itself is now JSON: "In Xcode 27.2 and later, the default
  project configuration file is a smaller, hierarchical, self-describing JSON
  file with a `.xcproj` extension." Apple adds: "The JSON file format also makes
  it easier for coding intelligence agents to edit the file for you."
  <https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format>
- **Unverified:** whether a free Personal Team can sign a device build purely
  from `xcodebuild` without Xcode's window open. Apple documents signing only
  through Xcode: "When you enable the “Automatically manage signing” option,
  Xcode registers the device and creates the development provisioning profile
  for you."
  <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>

### Seeing the simulator and folding it

- Apple documents changing the iPhone Duo simulator's pose only with on-screen
  controls in Device Hub: buttons for closed, partially open and open, and "To
  fold the device to any angle, hold the Option key while dragging the slider
  that appears below the bezel."
  <https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub>
- **Unverified:** any command-line way to set the pose in Xcode 27.2. The 27.3
  beta adds one for UI tests: "`XCUIAutomation` supports setting the hinge angle
  on iPhone Duo with a new `XCUIHinge` class."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes>
- From a terminal, Claude Code can operate the simulator window the way a person
  would: "From the CLI, Claude reaches the iOS Simulator through computer use
  instead, which controls the simulator on your screen the same way you would
  with a mouse." The Claude Code desktop app has a simulator pane (public beta)
  that can fold an iPhone Duo simulator on request: "ask for one of the three
  poses, or for a half-open hinge angle from 1 to 179 degrees."
  <https://code.claude.com/docs/en/desktop-ios-simulator>
- Inference: for the fold prototype, the desktop app's simulator pane or
  computer use is the way to change the pose and read the screen. If neither
  works, Adam clicks the three pose buttons and Claude Code reads logs and
  screenshots.
- Known issue in Xcode 27.2: "Screenshots and recordings in iPhone Duo might be
  black for up to a few minutes after booting the device."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>

## 5. What a free Apple Account allows

Adam has no developer account. A free Apple Account is enough to put the game on
his own phone.

- Limits: "You can register up to 10 App IDs, which expire after 7 days." "You
  can register up to 3 devices, which expire after 7 days." "You can install up
  to 3 apps per device. Provisioning profiles that enable apps to be installed on
  a device will expire 7 days from issuance. You'll need to rebuild and
  reinstall your app to your device after expiration."
  <https://developer.apple.com/help/account/basics/about-your-developer-account>
- **Game Center is not available on a free account.** Apple's capability table
  has a column for the free tier, which it describes as "Apple Developer: Apple
  Account holders who have agreed to the Apple Developer Agreement". In that
  column only nine capabilities are ticked (App groups, Background modes, Data
  protection, HealthKit, HomeKit, Inter-App Audio, Keychain sharing, Maps,
  Wireless Accessory Configuration). Game Center, iCloud, Push Notifications and
  In-App Purchase are ticked only for the paid program. The ticks are images, so
  this row-by-row reading was made from the page's markup, not from a quotable
  sentence.
  <https://developer.apple.com/help/account/reference/supported-capabilities-ios>
- Consequence: the game keeps saves on the device, and Game Center waits for the
  paid program ($99 per year), which the App Store release needs anyway.
- Inference: game controllers need no paid capability. Apple describes
  controller support as a property list entry: "To support game controllers, add
  the Game Controller capability (the GCSupportsControllerUserInteraction
  property) to your project". <https://developer.apple.com/documentation/gamecontroller>
  Core Haptics and Apple Pencil input are ordinary frameworks and are not rows
  in the capability table.

## 6. What the simulator cannot show

Apple's general statement: "Be aware that simulators run within Device Hub on
your Mac and don't replicate the performance or features of a physical device."
<https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>

| Feature | In the iPhone Duo simulator | Source |
|---|---|---|
| Open, closed, partly folded, any hinge angle, rotate | Yes, with Device Hub's controls | Section 4 |
| Split View | Yes: "Drag your app using the home indicator at the bottom to one side of the screen." | <https://developer.apple.com/videos/play/tech-talks/111461/> |
| Two-finger gestures such as pinch | Not in Xcode 27.2: "Device Hub doesn't currently support sending a two-finger touch to a device or simulator." | <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes> |
| Apple Pencil | No. A click arrives as a finger touch; no simulated Pencil is documented (inference from the same release notes) | Same |
| Performance and frame rate | Not representative: "Simulator doesn't try to exactly simulate the GPU from the iOS, tvOS, or visionOS device you're simulating." | <https://developer.apple.com/documentation/metal/developing-metal-apps-that-run-in-simulator> |
| Game controllers | Not connectable in Xcode 27.0: "Connecting a game controller to a simulator or device is only supported for the visionOS simulator." Whether 27.2 changed this is unverified | <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes> |
| Haptics, 120 Hz, hinge update rate | Unverified. No Apple page says | Section 8 |

Design consequence: on the folded display the design calls for a pinch to see
the whole map. That gesture cannot be tested in the simulator on this Mac with
Xcode 27.2, so the overview also needs a button. This is good for accessibility
in any case.

## 7. First task on the Mac: the fold prototype

Goal: one screen that shows a SpriteKit scene inside SwiftUI, with a marker at a
known map position, and proves that opening, closing and half-folding the
simulated iPhone Duo keeps the scene, its state and its camera. This retires the
largest open risk in RESEARCH.md section 8.4 before any game UI is built.

What Apple says, and what follows from it:

- A fold is a resize of the running app: "With iOS 27, people can resize your app
  larger than ever before using iPhone Mirroring on the Mac. Opening and closing
  iPhone Duo works the same way."
  <https://developer.apple.com/videos/play/tech-talks/111461/>
- Size must be re-read when it changes: "Reading the size once at launch or in
  viewIsAppearing isn't enough, because a fold can resize your app in the middle
  of a session." <https://developer.apple.com/iphone-duo/prepare/>
- SpriteKit has a mode for exactly this. `SKSceneScaleMode.resizeFill`: "The
  scene is not scaled to match the view. Instead, the scene is automatically
  resized so that its dimensions always match those of the view."
  <https://developer.apple.com/documentation/spritekit/skscenescalemode/resizefill>
  The scene is then told: "Your game should also override the scene's ...
  method, which is called whenever the scene changes size. When this method is
  called, you should update the scene's contents to match the new size." (the
  method is `didChangeSize(_:)`)
  <https://developer.apple.com/documentation/spritekit/scaling-a-scene-s-content-to-fit-the-view>
- The camera is a node in the scene: "If set to point to a camera node contained
  in the scene, the anchorPoint property is ignored and the scene is rendered
  using the camera node's properties instead."
  <https://developer.apple.com/documentation/spritekit/skscene/camera>
- **Inference, and the thing to prove:** one long-lived `SKScene`, created once
  and held in SwiftUI state, with `.resizeFill` and a camera node, keeps
  everything across a fold. Apple never says outright that the scene object
  survives; every statement found describes a resize.
- Do not set `UIRequiresFullScreen`. It does not stop the resize ("iPhone Duo
  will continue to honor the UIRequiresFullScreen key, but your app will still
  resize when someone opens or closes their iPhone Duo.", tech talk 111461
  above), and the key is deprecated.
- Apple's guidance for games: "Make your game playable in every device pose. You
  can choose to lock to either portrait or landscape orientation, but be sure to
  fill the screen as the device pose changes."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
  A fixed-size scene scaled to fit would letterbox, so `.resizeFill` with the
  game choosing how many tiles to show is the better fit (inference).

The SwiftUI pieces, all iOS 27.1:

- `ArrangementView` holds a primary and a secondary view and places them around
  the fold. The split style: "In portrait orientation, the arrangement view
  places the primary view in the top position and the secondary view in the
  bottom position." Styles are chosen with `arrangementViewStyle(_:)` and can be
  limited to an axis: "For axes that you don't include, the arrangement only
  displays the primary view."
  <https://developer.apple.com/documentation/swiftui/arrangementview>,
  <https://developer.apple.com/documentation/swiftui/splitarrangementviewstyle/axes(_:)>
- The fold itself is a reserved region read from a `GeometryProxy`:
  `reservedRegions(kind:options:layoutDirectionBehavior:)`. "A division is active
  only when the device is partially open or closed. When iPhone Duo is fully
  open, the division is inactive".
  <https://developer.apple.com/documentation/swiftui/reservedregion>
- The hinge: `onHingeChange(isEnabled:_:)` delivers a `DeviceHingeContext` whose
  `hinge` has an `angle` and a `status`.
  <https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)>
- Size classes: "On the outer display, like other iPhone models, iPhone Duo has
  regular vertical size class and compact horizontal size class in portrait, and
  compact vertical and horizontal size classes in landscape." The inner display
  is regular in both. (tech talk 111461 above)
- Touches inside the scene arrive as `UITouch` objects, whose `type` separates
  Pencil from finger: "SKNode subclasses UIResponder in iOS and tvOS, and
  NSResponder in macOS, allowing nodes to respond to user interaction events
  such as touches and mouse movements."
  <https://developer.apple.com/documentation/spritekit/controlling-user-interaction-on-nodes>
- Frame rate: `SpriteView` takes `preferredFramesPerSecond`, default 60. Above 60
  on an iPhone needs the `CADisableMinimumFrameDurationOnPhone` key: "If you
  don't enable this support, Core Animation won't access higher frame rates
  (above 60Hz)."
  <https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays>

What the prototype logs, in each of closed, partly open (book and laptop), open,
and open-rotated-to-portrait:

1. The scene object's identity and every call to `didMove(to:)` and
   `didChangeSize(_:)`. This answers whether state survives.
2. The scene size in points and `displayScale`. This gives the real point
   dimensions of both displays, which RESEARCH.md 6.1 could not find.
3. Horizontal and vertical size class.
4. `reservedRegions(kind: .division, options: .includeInactive)`: frame and
   `isActive`. Apple's pages disagree about the closed state.
5. `hinge.angle` in degrees and `hinge.status` while dragging the fold slider.
6. The frames-per-second counter with `preferredFramesPerSecond` at 120 and 30.
7. Whether the camera position and a counter held in the scene are unchanged
   after each transition.

The raw research notes, including every Apple code sample found for
`ArrangementView`, reserved regions and the hinge, are in
`docs/research-notes/mac-prototype.md`.

## 8. Questions only the Mac or the phone can settle

| Question | How it gets settled |
|---|---|
| macOS version, drive size, free space | Section 2 commands |
| Size of Xcode 27.2 and the iOS 27.2 runtime | Xcode > Settings > Components |
| Is 16 GB comfortable | Activity Monitor during a simulator run |
| Can a project be created without Xcode's window | `xcrun xcodeproj help` |
| Exact tools the Xcode bridge exposes | `claude mcp list`, `/mcp` |
| `-destination` syntax and the simulator's name | `man xcodebuild`, `xcodebuild -showdestinations` |
| Command-line pose control | `xcrun simctl help`, `xcrun devicectl help` |
| Does the scene survive a fold | Fold prototype, item 1 |
| Point size and scale of both displays | Fold prototype, item 2 |
| Is the fold region active when closed | Fold prototype, item 4 |
| Hinge angle range | Fold prototype, item 5 |
| Does SpriteKit reach 120 frames per second | Fold prototype, item 6, then the phone |
| Signing a device build from the command line on a free account | First device build |
| Does the `Data` resource folder sign correctly (it was renamed from `Resources` on a reported signing problem) | First device build |
| Haptics, Pencil tilt, real performance | The phone |
