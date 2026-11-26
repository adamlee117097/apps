# Mac setup and day-one checklist

Researched 2026-11-26 from a Linux cloud session. **Nothing in this file has been
run on a Mac yet.** It is the plan for the first session on Adam's Mac mini.

How to read it:

- Quoted text is verbatim from the linked page. Every quotation here was checked
  against its page by script (`tools/citations/check_doc.py`).
- **Inference** marks a conclusion drawn from sourced facts. **Unverified** means
  no primary source was found; section 8 lists what will settle each one.
- The research was done by four research agents and their quotations were
  machine-checked. Two independent reviewers then read this file against the
  cited pages on 2026-11-26 and found 25 problems, mostly steps in the wrong
  order, omissions and overstatements. This version includes their corrections.

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
- The first simulator start may be slow. Xcode 27.1 listed as a known issue:
  "Initial Simulator launch can take several minutes."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes>
  The 27.2 notes do not say whether it remains.

## 2. Checks Claude Code runs

Before anything large is installed:

```sh
sw_vers
system_profiler SPHardwareDataType
df -h /
```

Report the model, chip, memory, free disk space and macOS version to Adam.

The Xcode commands only work once Xcode is installed and selected: "You must
install and set Xcode as the active developer directory before you can invoke
these commands in Terminal."
<https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference>
So, after section 3 step 3:

```sh
xcode-select -p                # must print a path inside Xcode.app
xcodebuild -version
man xcodebuild                 # -destination syntax, -showdestinations
xcrun simctl help              # simulator commands; any pose or fold control?
xcrun devicectl help           # device commands; any pose or fold control?
xcrun xcodeproj help           # can it create a project, or only edit one?
```

If `xcode-select -p` prints the Command Line Tools folder instead, Adam runs
`sudo xcode-select --switch /Applications/Xcode.app`.

## 3. Steps that need Adam in person, in order

1. **Install Claude Code** and start it. Instructions:
   <https://code.claude.com/docs/en/setup> Cloning this repository uses `git`,
   and on a new Mac that brings up Apple's prompt to install its command-line
   tools: "On a fresh install of macOS, invoking any command in Xcode or the
   command-line tools package (such as `git`) from the command line prompts you
   to download and install the Command Line Tools for Xcode package."
   <https://developer.apple.com/documentation/xcode/installing-the-command-line-tools>
   Accept it. Claude Code then runs the first three checks in section 2.
2. **Update macOS** to Tahoe 26.6 or later, or to macOS 27, if `sw_vers` shows
   something older. Whether Software Update on an older system offers both is
   not something Apple's pages say.
3. **Install Xcode 27.2**, open it once, and install iOS platform support.
   Claude Code can do the last part from Terminal if asked.
4. **Sign in to Xcode** with a free Apple Account: "sign in with your Apple
   Developer Program or personal Apple Account in Xcode > Settings > Apple
   Accounts."
   <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>
5. **Let outside agents use Xcode.** In Xcode's Intelligence settings: "Under
   Model Context Protocol, choose either Always or “While Xcode is Open” from the
   “Allow External Agents to Use Xcode Tools” pop-up menu."
   <https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode>
6. **Create the app project in Xcode**, once. Apple documents creating a project
   only through Xcode's windows: "choose App from the New Project pop-up menu or
   choose File > New > Project and select App from anywhere in Xcode." Then save
   it into `necromancer-tactics/`, beside `NecroRules/`: "To save your code
   changes, choose File > Save Project, and in the sheet that appears, enter the
   project name in the Save As field and click Save."
   <https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app>
   Apple's command-line project tool is documented only for changing an
   existing project, so this step is probably needed; Claude Code will check
   `xcrun xcodeproj help` first and say exactly what to click.
7. **Connect Claude Code to Xcode.** With the project open in Xcode, run this in
   Terminal inside the repository folder:
   `claude mcp add --transport stdio xcode -- xcrun mcpbridge`. The folder
   matters: "Local scope is the default. A local-scoped server loads only in the
   project where you added it and stays private to you."
   <https://code.claude.com/docs/en/mcp> Then start a new Claude Code session
   there. Xcode announces the connection and Adam may have to approve it: "Xcode
   alerts you when the external agent connects to Xcode and when it's active."
   <https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode>
8. **Update the iPhone Duo first**, to iOS 27.2 or later, if Apple Pencil will be
   used. Do this before pairing, because an update undoes pairing (next step).
   iOS 27.2 has been public since 26 October 2026 and 27.2.1 since 9 November.
   <https://support.apple.com/en-us/100100>
9. **Pair the iPhone Duo.** "Connect the device with an appropriate cable to your
   Mac. If a Trust This Computer dialog appears on the device, tap Trust."
   Wireless pairing also exists for iOS 27: "In the Device Hub sheet, select the
   device that it discovers and click Next. In the next sheet, enter the PIN that
   appears on your device." Apple adds: "If you upgrade the operating system
   later, you'll need to pair the device again."
   <https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub>
   Keep the phone unlocked: "Whether you use the command line or Device Hub to
   pair physical devices, unlock the device before entering `devicectl`
   commands."
   <https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line>
10. **Turn on Developer Mode** on the phone, under Settings > Privacy & Security.
    It appears only after pairing has started, and Device Hub may ask for it
    part-way through pairing, so this step and the last can interleave. The
    phone restarts, then: "After the device restarts, another alert appears
    confirming that you want to turn on Developer Mode. In iOS and iPadOS, swipe
    up, tap Enable in the dialog, and enter your device passcode."
    <https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device>
11. **Set up signing and run once from Xcode.** Signing in (step 4) does not sign
    the app. "Then, in the Signing & Capabilities pane of the project editor,
    click Set Up Signing under Signing if it appears." Choose the Personal Team
    and a unique bundle ID, pick the phone as the run destination, and: "If a
    Register button appears under Signing, click it to add it to the
    provisioning profile." Then run.
    <https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices>
12. **Trust the developer certificate** on the phone the first time the app is
    installed. The only Apple source found for this with a personal account is
    from 2019: "Xcode installs it on your device, but in order for it to be able
    to launch, you'll need to trust your developer certificate on your device."
    <https://developer.apple.com/videos/play/wwdc2019/304/> Apple's current
    article, written about enterprise apps, gives the place as "Tap Settings >
    General > VPN & Device Management." <https://support.apple.com/en-us/118254>
    Whether the wording is the same for a personal account on iOS 27 is
    unverified. Expect to need an internet connection.

Optional, for folding the simulator without Adam (section 4): install the Claude
Code desktop app as well, or enable computer use for the terminal version.

## 4. How Claude Code works with Xcode

### The Xcode bridge

- Apple documents connecting Claude Code to Xcode: "run the following command in
  Terminal to give Claude Code access to your open project and Xcode
  capabilities". The command is in step 7 above.
  <https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode>
- The project has to be open in Xcode first: "Before prompting an external agent
  (outside of Xcode), be sure to open your project in Xcode." (same page) If
  Claude Code starts before that, the connection fails and has to be reconnected
  from its `/mcp` menu.
- Apple's Xcode 27 notes also describe an early alternative that needs no open
  project: "Xcode 27 Beta 5 adds a preview of a new MCP server experience that
  runs without requiring an open Xcode workspace."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes>
  Whether it is still a preview in 27.2 is unverified. Use the documented route
  first.
- What the Xcode bridge offers, from the Xcode 27 release notes
  (<https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes>):
  tools for "listing
  and switching between available schemes and run destinations and inspecting
  and modifying build settings, compiler flags, entitlements, and Info.plist
  keys." The notes also say, without naming the bridge: "Agents can now boot
  simulators, install and launch apps, synthesize touch events, and capture
  screenshots to verify UI behavior." **Unverified:** whether that second set
  reaches an outside agent such as Claude Code, or only agents running inside
  Xcode. `claude mcp list` and `/mcp` on the Mac will show the real list.
- Xcode 27.2 can render a SwiftUI preview to an image for the agent: "The
  RenderPreview MCP tool now returns the list of available render destinations,
  and lets the caller specify which destination to use for rendering."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>
  Previews of iPhone Duo may be wrong in 27.2: the 27.3 beta notes list as fixed
  "Previews now render correctly on iPhone Duo."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes>

### The command line

- Tests: "When you run tests with `xcodebuild` in Terminal, the command outputs
  an Xcode Test Results (`.xcresults`) bundle that contains session results,
  code coverage (if enabled), and other logs."
  <https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results>
  The rules package needs no Xcode project or simulator: `swift test` in
  `NecroRules/`, using the Swift toolchain that Xcode installs.
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
- The project file can be JSON, which suits an agent: "The JSON file format also
  makes it easier for coding intelligence agents to edit the file for you."
  Apple's pages disagree on whether that is automatic. The article says "In
  Xcode 27.2 and later, the default project configuration file is a smaller,
  hierarchical, self-describing JSON file with a `.xcproj` extension."
  <https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format>
  The 27.2 release notes say of the same format: "Enable it in the File
  inspector."
  <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>
  Check after creating the project, and switch it in the File inspector if it
  is not JSON.
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
- Two routes let Claude Code fold the simulator itself, and both need Adam to
  set something up. Source for the first:
  <https://code.claude.com/docs/en/desktop-ios-simulator>
  1. The Claude Code desktop app has a simulator pane that can fold an iPhone
     Duo simulator on request: "ask for one of the three poses, or for a
     half-open hinge angle from 1 to 179 degrees." It needs a recent version of
     the desktop app ("Claude Desktop v4.29.0 or later"), and "The simulator
     pane is available in local sessions only."
  2. The terminal version can operate the simulator window: "From the CLI,
     Claude reaches the iOS Simulator through computer use instead, which
     controls the simulator on your screen the same way you would with a mouse."
     Computer use is a preview that must be switched on: "It's off by default
     until you enable it." It also needs macOS permissions for accessibility and
     screen recording. <https://code.claude.com/docs/en/computer-use>
- If neither is set up, Adam clicks the three pose buttons and Claude Code reads
  logs and screenshots.
- Known issues in Xcode 27.2 that touch this: "Screenshots and recordings in
  iPhone Duo might be black for up to a few minutes after booting the device."
  and "When switching between the inner and outer display of the iPhone Duo
  simulator, modifier keys such as Shift and Command might stop working." Apple's
  workaround for the second is to click on the visible screen. Inference: the
  Option-drag fold slider may be affected.
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
  Wireless Accessory Configuration). Game Center and In-App Purchase are ticked
  only for the Apple Developer Program; iCloud and Push Notifications only for
  the two paid programs. The ticks are images, so this reading was made from the
  page's markup, by a researcher and again by a reviewer.
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

Sources for the table: the Xcode release notes for
27 (<https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes>),
27.2 (<https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>)
and the 27.3 beta
(<https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes>):

| Feature | In the iPhone Duo simulator |
|---|---|
| Open, closed, partly folded, any hinge angle, rotate | Yes, with Device Hub's controls (section 4) |
| Split View | Yes, by dragging the app to one side (tech talk 111461) |
| Pinch and other two-finger gestures | Depends on the input device. With only a mouse, not in Xcode 27.2: "Device Hub doesn't currently support sending a two-finger touch to a device or simulator." The 27.3 beta fixes this: "Device Hub now supports using option-drag to simulate two-finger touch gestures for iPhones and iPads." With a trackpad, a pinch does arrive, but as a transform event and not as two touches: "Common Mac mouse and trackpad gestures such as scrolling, pinching, and rotating now work with standard UIKit components on iOS devices, either physical or simulated." |
| Apple Pencil | No. A click is a finger touch: "clicking with a mouse or trackpad produces a simulated finger touch of type `UITouch.TouchType.direct` rather than `UITouch.TouchType.indirectPointer`". No simulated Pencil is documented |
| Performance and frame rate | Not measurable: "You can't use Xcode to analyze the memory footprint or measure performance when running in Simulator." <https://developer.apple.com/documentation/metal/developing-metal-apps-that-run-in-simulator> |
| Game controllers | Not connectable in Xcode 27.0: "Connecting a game controller to a simulator or device is only supported for the visionOS simulator." The later notes record no fix |
| Accessibility tools | Not on iPhone Duo in 27.2: "VoiceOver, the Accessibility Inspector, and other accessibility tools cannot convey screen content on an iPhone Duo within Device Hub." |
| Hinge update rate | Not fixed anywhere. Apple calls it system policy: "The rate and granularity of angle updates are system policy and can change based on system state, so don't depend on a particular update frequency or precision." <https://developer.apple.com/documentation/swiftui/devicehinge/angle> |
| Haptics, 120 Hz | Unverified. None of the pages read says |

Design consequence: on the folded display the design calls for a pinch to see
the whole map. On a Mac mini with only a mouse and Xcode 27.2, that pinch
cannot be made in the simulator. A trackpad can test it if the game uses a
standard gesture recogniser for it instead of counting touches (inference). The
overview also gets a button, which is right for accessibility in any case,
though accessibility itself has to be checked on the phone.

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
  of a session." The app's size is also not the screen's: "your app's size
  changes whenever the device folds or unfolds, and it doesn't always match the
  size of the screen". <https://developer.apple.com/iphone-duo/prepare/>
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
- **Inference, and the thing to prove:** one long-lived `SKScene`, created once,
  with `.resizeFill` and a camera node, keeps everything across a fold. Apple
  never says outright that the scene object survives; every statement found
  describes a resize.
- **Where the scene lives matters** (inference). Own it in a model object held
  by the app, not created inside a view's body, so that a view being rebuilt or
  hidden cannot discard it. iPhone Duo can show more than one window of an app:
  "iPhone Duo is the first iPhone to support multiple instances of your app's UI.
  If your app supports this on iPad, it will on iPhone Duo as well."
  <https://developer.apple.com/videos/play/tech-talks/111464/> A scene can be
  shown by one view at a time, so turn multiple-window support off for the game.
- Do not set `UIRequiresFullScreen`. It does not stop the resize ("iPhone Duo
  will continue to honor the UIRequiresFullScreen key, but your app will still
  resize when someone opens or closes their iPhone Duo.", tech talk 111461), and
  the key is deprecated.
- Two requirements of the iOS 27 SDK: "iOS and iPadOS apps built with the 27.0
  SDK or later are required to include a launch screen." and "Apps built with
  the latest SDK must adopt the scene-based life cycle or they fail to launch."
  <https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes>
  Inference: a SwiftUI `App` entry point meets the second; check the built
  Info.plist for the first.
- Apple's guidance for games: "Make your game playable in every device pose. You
  can choose to lock to either portrait or landscape orientation, but be sure to
  fill the screen as the device pose changes."
  <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>
  A fixed-size scene scaled to fit would letterbox, so `.resizeFill` with the
  game choosing how many tiles to show is the better fit (inference). Allow all
  four orientations and never branch on orientation.

The SwiftUI pieces, all iOS 27.1:

- `ArrangementView` lays out a primary and a secondary view by size class,
  orientation and the fold. It has two styles, and the choice matters. Source:
  <https://developer.apple.com/documentation/swiftui/arrangementview>
  - Split, the default, always gives each view its own space: "a split
    arrangement view always keeps its primary and secondary views in separate
    spaces". That is equal halves by default, even when the phone is flat. And
    "When someone is holding a closed iPhone Duo in landscape orientation, the
    split arrangement only shows the primary view."
  - Overlay layers one view over the other when flat and separates them when
    folded: "This arrangement works well when there's a clear foreground and
    background relationship between your views, such as a view for video
    playback and a view with playback controls." Folded like a laptop: "When
    someone holds a folded iPhone Duo in portrait orientation, the arrangement
    view places the secondary view in the top position and the primary view in
    the bottom position."
  - Inference: a full-screen map with controls over it is the overlay case, with
    the **controls as primary and the map as secondary**. That gives a full map
    when flat and map-above-controls when half-folded. An earlier version of
    this plan had the map as the primary of a split, which would have halved
    the map on the flat display.
  - **Unverified:** whether a `SpriteView` keeps its underlying view when an
    arrangement moves or hides it. The prototype tests this.
- The fold itself is a reserved region read from a `GeometryProxy`:
  `reservedRegions(kind:options:layoutDirectionBehavior:)`. "The method returns
  only the regions that overlap your view, including a partial overlap."
  <https://developer.apple.com/documentation/swiftui/reservedregion> Apple's
  pages disagree on whether the fold region counts as active when the phone is
  closed; three of four statements say it does not.
- The hinge: `onHingeChange(isEnabled:_:)` passes the previous and the current
  `DeviceHingeContext`. Its `hinge` is optional, and absent on a device without
  one; when present it has an `angle` and a `status`. It is for input and
  effects, not layout.
  <https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)>
- Size classes: "On the outer display, like other iPhone models, iPhone Duo has
  regular vertical size class and compact horizontal size class in portrait, and
  compact vertical and horizontal size classes in landscape." The inner display
  is regular in both. (tech talk 111461) In Split View they are not stated.
- Touches: in an `SKView`, touches reach nodes as `UITouch` objects, whose `type`
  separates Pencil from finger: "SKNode subclasses UIResponder in iOS and tvOS,
  and NSResponder in macOS, allowing nodes to respond to user interaction events
  such as touches and mouse movements."
  <https://developer.apple.com/documentation/spritekit/controlling-user-interaction-on-nodes>
  The scene must turn on `isUserInteractionEnabled`. **Unverified:** that this
  works the same through `SpriteView`; the prototype logs it.
- Frame rate: `SpriteView` takes `preferredFramesPerSecond`, default 60.
  Inference: above 60 on an iPhone probably needs the
  `CADisableMinimumFrameDurationOnPhone` key ("If you don't enable this support,
  Core Animation won't access higher frame rates (above 60Hz)."), but Apple ties
  the key to display links and animations and does not say whether a SpriteKit
  view is subject to it.
  <https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays>
  The simulator cannot answer this; the phone can.

What the prototype logs. Poses: closed portrait, closed landscape, partly open
like a book, partly open like a laptop, open, open turned to portrait, and
Split View on the inner display. Run it twice: with the `SpriteView` on its own,
and inside an `ArrangementView` as the secondary of an overlay.

1. The scene object's identity, the identity of its view, and every call to
   `didMove(to:)`, `willMove(from:)` and `didChangeSize(_:)`; SwiftUI's appear
   and disappear, the scene phase, and whether the view is paused. A paused or
   re-presented scene must not be mistaken for lost state.
2. With the view extended past the safe area: scene size, the geometry size and
   safe-area insets, `displayScale`, and the screen's bounds, scale, native
   bounds and native scale; plus the pixel size of a Device Hub screenshot.
   Together these give the point size of each display and show whether the
   inner display is drawn at a size other than the panel's (RESEARCH.md 6.1).
3. Horizontal and vertical size class.
4. From a full-screen geometry reader: the count, frame and `isActive` of the
   `.division` and `.occlusion` regions, including inactive ones.
5. `hinge` (including nil), its angle in degrees and its status while dragging
   the fold slider.
6. Whether touches reach the scene through `SpriteView`, and their `type`.
7. Whether the camera position and a counter held in the scene are unchanged
   after each transition.
8. A second build with orientation locked to landscape, to see what the inner
   display does with it (RESEARCH.md 3.1).

On the phone only: the frame rate at 120 with and without the Info.plist key,
and at 30.

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
| Is the new project file JSON | Look inside the `.xcodeproj` folder |
| Exact tools the Xcode bridge exposes, and whether they include the simulator | `claude mcp list`, `/mcp` |
| `-destination` syntax and the simulator's name | `man xcodebuild`, `xcodebuild -showdestinations` |
| Command-line pose control | `xcrun simctl help`, `xcrun devicectl help` |
| Does the scene survive a fold | Fold prototype, items 1 and 7 |
| Does the `SpriteView` survive inside an `ArrangementView` | Fold prototype, second run |
| Point size and scale of both displays | Fold prototype, item 2 |
| Size classes and size in Split View | Fold prototype, item 3 |
| Is the fold region active when closed; is the inner camera's region ever active | Fold prototype, item 4 |
| Hinge angle range | Fold prototype, item 5 |
| Do touches reach the scene through `SpriteView`; Pencil touch type | Fold prototype, item 6, then the phone |
| What an orientation-locked build looks like on the inner display | Fold prototype, item 8 |
| Does SpriteKit reach 120 frames per second | The phone |
| Signing a device build from the command line on a free account | First device build |
| Does the `Data` resource folder sign correctly (it was renamed from `Resources` on a reported signing problem) | First device build |
| Haptics, Pencil tilt, real performance, accessibility | The phone |
