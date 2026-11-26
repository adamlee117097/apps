> Raw working notes from a research agent, 2026-11-26. The claims that `MAC_SETUP.md` draws from these notes had their quotations checked by script against the source pages. The rest of these notes was not independently reviewed, and the planned second-agent review did not run. Treat anything here that is not in `MAC_SETUP.md` as a lead to verify.

# W1 working notes: can the Mac mini (2024, M4, 16 GB) run the required macOS and Xcode, and are 16 GB and its disk enough

Research date: 2026-11-25. Done from a Linux sandbox, not on the Mac. Every quote
below was checked with `check_quote.py` against the URL given (all FOUND).
"Inference" marks my own conclusion. "Unverified" marks something no primary source
settled.

The user's own statement (relayed): the Mac mini "has the 4th generation of Apple
Silicon, and it has 16 gigabytes of RAM". Storage size is unknown.

---------------------------------------------------------------------------

## Q1. Mac mini (2024): chips, memory, storage, shipped macOS

Source: https://support.apple.com/en-us/121555 ("Mac mini (2024) - Tech Specs")

- "Year introduced: 2024"
- Chip options: "Apple M4 chip 10-core CPU with 4 performance cores and 6 efficiency
  cores 10-core GPU"; "Apple M4 Pro chip 12-core CPU with 8 performance cores and 4
  efficiency cores 16-core GPU"; "Configurable to: M4 Pro with 14-core CPU and
  20-core GPU".
- Memory: "Apple M4 chip 16GB unified memory Configurable to: 24GB or 32GB";
  "Apple M4 Pro chip 24GB unified memory Configurable to: 48GB or 64GB".
- Storage: "Apple M4 chip 256GB SSD Configurable to: 512GB, 1TB, or 2TB";
  "Apple M4 Pro chip 512GB SSD Configurable to: 1TB, 2TB, 4TB, or 8TB".
- Storage footnote: "1GB = 1 billion bytes and 1TB = 1 trillion bytes; actual
  formatted capacity less."
- Operating system: the spec page names no version. "Operating System macOS macOS
  is the most advanced desktop operating system in the world."

Source: https://www.apple.com/newsroom/2024/10/apples-new-mac-mini-is-more-mighty-more-mini-and-built-for-apple-intelligence/
(Apple press release, October 29, 2024)

- "Mac mini with M4 features a 10-core CPU, 10-core GPU, and now starts with 16GB of
  unified memory."
- "macOS Sequoia completes the new Mac mini experience". The same release ties Apple
  Intelligence to "macOS Sequoia 15.1".

Source: https://support.apple.com/en-us/102852 ("Identify your Mac mini model")

- "Mac mini (2024) Model Identifier: Mac16,10, Mac16,11 ... Newest compatible
  operating system: macOS 27 Golden Gate"

Inference:
- 16 GB only exists on the M4 chip (M4 Pro starts at 24 GB). So Adam's Mac is the
  M4 (not M4 Pro) model, and its storage is one of 256 GB, 512 GB, 1 TB or 2 TB.
  256 GB is the base and the case to plan for until the Mac reports otherwise.
- It shipped in the macOS Sequoia 15 era. What it runs today is unknown; `sw_vers`
  on the Mac settles it. If it was never upgraded it is on Sequoia 15.x, which is
  too old for Xcode 27 (see Q3).

---------------------------------------------------------------------------

## Q2. macOS Tahoe 26 and macOS 27 compatibility

Tahoe: https://support.apple.com/en-us/122867 (published September 14, 2026)

- "You can install macOS Tahoe 26 on any of these Mac models." The Mac mini list is:
  "Mac mini (2024)", "Mac mini (2023)", "Mac mini (M1, 2020)".

macOS 27: https://support.apple.com/en-us/127255 (published November 05, 2026)

- Name: "macOS 27 Golden Gate".
- "macOS 27 Golden Gate is the latest major version of the Mac operating system. You
  can install it on any of these Mac models."
- "If you have a Mac with Apple silicon, you can upgrade to macOS 27".
- Mac mini list: "Mac mini (M6 or M5 Pro)", "Mac mini (2024)", "Mac mini (2023)",
  "Mac mini (M1, 2020)".

Also https://www.apple.com/os/macos/ (page title "OS - macOS 27 Golden Gate - Apple"):
"macOS 27 is compatible with these devices. ... Mac mini with Apple silicon (2020 and
later)".

Also https://support.apple.com/en-us/127455 ("How to upgrade to macOS 27 Golden
Gate"): "macOS 27 is compatible with any Mac with Apple silicon, which includes any
Mac with an M-series chip or A-series chip."

Current versions: https://support.apple.com/en-us/109033 ("Find out which macOS your
Mac is using", published November 20, 2026)

- "These are the latest versions of each Mac operating system, starting with the most
  recent." Table: "macOS 27 Golden Gate 27.2.1", "macOS Tahoe 26 26.7.3",
  "macOS Sequoia 15 15.8.3".

Release dates, from Apple security releases https://support.apple.com/en-us/100100
(rows are name / available for / date):

- "macOS Golden Gate 27.2.1 macOS Golden Gate 09 Nov 2026"
- "macOS Tahoe 26.7.3 macOS Tahoe 09 Nov 2026"
- macOS Golden Gate 27.2 and macOS Tahoe 26.7.2: 26 Oct 2026
- macOS Golden Gate 27.0.1 and macOS Tahoe 26.7.1: 28 Sep 2026
- macOS Golden Gate 27 and macOS Tahoe 26.7: 14 Sep 2026
- "macOS Tahoe 26.6.2 macOS Tahoe 17 Aug 2026"; macOS Tahoe 26.6.1: 06 Aug 2026
- "macOS Tahoe 26.6 macOS Tahoe 27 Jul 2026"

Developer releases feed https://developer.apple.com/news/releases/ :
"macOS 27.2.1 (26B131) November 9, 2026"; "macOS 27.3 beta 2 (26C5047e)
November 16, 2026" (beta).

---------------------------------------------------------------------------

## Q3. Xcode 27.2 and 27.1 requirements

Xcode 27.2 release notes:
https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes

- "Xcode 27.2 includes Swift 6.4 and SDKs for iOS 27.2, iPadOS 27.2, tvOS 27.2,
  watchOS 27.2, macOS 27.2, and visionOS 27.2."
- "Xcode 27.2 supports on-device debugging in iOS 17 and later"
- "Xcode 27.2 requires a Mac running macOS Tahoe 26.6 or later."

Xcode 27.1 release notes:
https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes

- "Xcode 27.1 includes Swift 6.4 and SDKs for iOS 27.1, iPadOS 27, tvOS 27, watchOS
  27, macOS 27, and visionOS 27."
- "Xcode 27.1 requires a Mac running macOS Tahoe 26.6 or later."

Xcode 27 release notes:
https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes

- "Xcode 27 requires a Mac running macOS Tahoe 26.6 or later."
- Intel Deprecation section: "Xcode 27 will only install and run on Apple silicon
  Macs." (162138432)

System requirements table: https://developer.apple.com/support/xcode/ (redirects to
https://developer.apple.com/xcode/system-requirements)

- "Xcode 27.3 beta 2 macOS Tahoe 26.6 or later iOS 27.3"
- "Xcode 27.2 macOS Tahoe 26.6 or later iOS 27.2"
- Xcode 27.1: macOS Tahoe 26.6 or later, iOS 27.1 SDK. Xcode 27: same, iOS 27 SDK.
- Contrast row: "Xcode 26.6 macOS Tahoe 26.2 - macOS Tahoe 26.x"
- Legend: "Supported macOS Versions: The version of macOS supported to install this
  version of Xcode."
- Device support and Simulator columns for Xcode 27.x: iOS 17 or later.
- The table has no memory or disk column. The only hardware line is "Developing for
  visionOS requires a Mac with Apple silicon."

Minimum memory or free disk space: **none stated** in the three release notes, the
system requirements table, https://developer.apple.com/xcode/ ,
https://developer.apple.com/xcode/resources/ or https://developer.apple.com/download/ .

How to get Xcode (https://developer.apple.com/xcode/resources/): "Download Xcode from
the Mac App Store". Older versions and command line tools: "To view downloads, simply
sign in to your Apple Account. Apple Developer Program membership isn't required."

---------------------------------------------------------------------------

## Q4. Disk space

No Apple page I could open states the download size or installed size of Xcode
27.x, or of the iOS 27.x platform support or simulator runtime.

Tried:
- Xcode 27, 27.1, 27.2, 27.3 beta 2 release notes: no size.
- https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components
  (the lead .../installing-additional-simulator-runtimes redirects to it): no sizes.
- https://developer.apple.com/xcode/ , /xcode/resources/ , /xcode/whats-new/ ,
  /download/ : no sizes.
- WWDC 2026 sessions 258 (What's new in Xcode 27), 259, 260 (Device Hub)
  transcripts: no sizes.
- Mac App Store listing (apps.apple.com) and itunes.apple.com lookup: blocked by the
  sandbox network policy.
- https://developer.apple.com/download/applications/ : redirects to Apple Account
  sign-in.

What Apple does say (components doc above):
- "Xcode lets you manage optional components yourself so that you can install only
  the components you use and remove the ones you don't."
- "Xcode shows the installed and enabled components along with the amount of storage
  you can recover if you remove them." (Xcode > Settings > Components)
- "To remove or disable components you no longer use and recover their storage space,
  click the information button next to the component."
- "Otherwise, Xcode downloads an Apple silicon variant to save disk space for the
  platform you specify."
- Platform support is a separate download from Xcode itself
  (https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices):
  "If you don't have platform support installed for your target, you can't build and
  run your app on a device. To install platform support, click the Get button".

Command-line install (same components doc):

```
xcodebuild -downloadPlatform <iOS|watchOS|tvOS|visionOS>  [-exportPath <destinationpath> -buildVersion <osversion> -architectureVariant <universal|arm64>]
xcodebuild -downloadPlatform iOS
xcode-select -s /Applications/Xcode.app
xcodebuild -runFirstLaunch -checkForNewerComponents
```

One Apple storage figure that does apply to this Mac if it runs macOS 27:
https://support.apple.com/en-us/121115 (Apple Intelligence, published November 05,
2026): "Up to 14 GB of storage on device for iPhone Duo, iPhone 17 Pro models and
later, iPhone Air, iPad models with M4 and later and at least 12GB of unified memory,
Mac models with M3 and later and at least 12GB of unified memory". And: "Storage used
by Apple Intelligence may temporarily exceed storage requirements during and shortly
after a software update, as new models are downloaded and older ones are removed."
An M4 with 16 GB is in that group (inference).

Leads only, NOT primary and NOT about Xcode 27: a web search surfaced Apple Developer
Forums threads from 2020 to 2022 (for example
https://developer.apple.com/forums/thread/712620) where users report that the App
Store install of older Xcode versions needed several times the download size free.
The forum pages sit behind a human-verification page and were not opened.

Inference:
- On a 256 GB Mac the disk is the main capacity risk, not the chip or memory. It
  cannot be judged without numbers from the Mac.
- What settles it, on the Mac: `df -h /` for free space; the "Size" line on the Mac
  App Store page for Xcode before downloading; after install,
  `du -sh /Applications/Xcode.app` and Xcode > Settings > Components for the iOS
  platform and simulator runtime.

---------------------------------------------------------------------------

## Q5. Memory

No Xcode 27 feature I could find states a memory requirement.

- Coding intelligence. https://developer.apple.com/documentation/xcode/setting-up-coding-intelligence
  and https://developer.apple.com/documentation/xcode/writing-code-with-intelligence-in-xcode
  and https://developer.apple.com/documentation/xcode/using-coding-intelligence-in-the-source-editor
  state no memory or chip requirement. The agents are provider services:
  https://developer.apple.com/xcode/ says "Xcode supports interacting with code using
  the model of your choice , including the frontier coding models and agents from
  Anthropic, Google, and OpenAI." A local model is optional: "To add a provider
  that's hosted locally on your Mac, select Locally Hosted and enter a port and
  optional description instead."
- Predictive code completion. Not mentioned in the Xcode 27, 27.1, 27.2 or 27.3 beta
  notes. The last statements found: Xcode 16 release notes
  (https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes)
  "Predictive Code Completion is now supported on all Apple silicon Macs."
  (130449481); Xcode 26 release notes
  (https://developer.apple.com/documentation/xcode-release-notes/xcode-26-release-notes)
  "Predictive code completion is faster and uses more context from your code, all
  running locally."
- Device Hub. https://developer.apple.com/documentation/xcode/device-hub and
  https://developer.apple.com/documentation/xcode/managing-your-simulated-and-physical-devices-in-device-hub
  and https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub :
  no memory statement.
- Simulators. No host-memory statement. Apple says only: "Be aware that simulators
  run within Device Hub on your Mac and don't replicate the performance or features
  of a physical device."
  (https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
- Related release-note items:
  - Xcode 27.1 known issue: "Initial Simulator launch can take several minutes.
    (187708500)"
  - Xcode 27: "The simulator runtimes now contain a pre-built dyld cache. This will
    make first launch of a simulator much faster. (179846743)"
  - Xcode 27.2 Device Hub adds "Simulate Memory Pressure (simulators only)". That
    tests the app under memory pressure. It is not a host requirement.
  - Xcode 27.2: "Fixed: Memory usage needle rotated beyond the meter when swap is
    used. (187611943)"
  - Xcode 27: "Fixed: Resolved an issue where Xcode could use too much memory when
    generating comments or translating strings. (179800456)"
- Claude Code itself (https://code.claude.com/docs/en/setup): "Hardware : 4 GB+ RAM,
  x64 or ARM64 processor"; operating system "macOS 13.0+".

Lead only, not opened (human-verification wall): a search result described an Apple
Developer Forums thread, https://developer.apple.com/forums/thread/859873, where one
user with an 8 GB M1 Mac reports Xcode 27.2 stalling on "Preparing iPhone Simulator".
One user's report, not an Apple requirement, and I could not read it.

Inference:
- Apple sets no memory floor for Xcode 27.x. 16 GB is the base memory of this model.
  Nothing found says 16 GB is too little. Whether it is comfortable with Xcode, one
  iPhone Duo simulator and Claude Code running together is unverified. Activity
  Monitor's memory pressure graph on the Mac during a build-and-run settles it.
- The coding agents do not use local memory for inference unless a locally hosted
  model is added. Do not add one on a 16 GB Mac.

---------------------------------------------------------------------------

## Q6. macOS Tahoe 26.6 or macOS 27?

- macOS Tahoe is still updated. Latest is 26.7.3 (09 Nov 2026), which is "26.6 or
  later". macOS Tahoe 26.6 itself is dated 27 Jul 2026. (Sources in Q2.)
- Mac mini (2024) is on both compatibility lists (Q2). So the Mac can meet Xcode
  27.2's requirement on either macOS Tahoe 26.6+ or macOS 27.x. It does not have to
  move to macOS 27 (inference from the sourced facts).
- What Apple recommends (https://support.apple.com/en-us/108382, "Update macOS on
  Mac", published September 14, 2026): "Apple recommends using the latest macOS that
  is compatible with your Mac." Also: "A macOS update can be a minor new release of
  the currently installed macOS, such as from macOS 26 to macOS 26.4, or a major new
  release of macOS, such as from macOS 26 to macOS 27." And: "Software Update shows
  only software that is compatible with your Mac model."
- Apple calls macOS 27 Golden Gate "the latest major version of the Mac operating
  system" (support 127255).
- Getting a specific version (https://support.apple.com/en-us/102662, "How to
  download and install macOS"): "You can use Terminal to download the installer for
  compatible macOS versions no earlier than the version that came with your Mac, or
  the closest version still available." "Example: softwareupdate
  --fetch-full-installer --full-installer-version 26.6.2". "You can enter
  softwareupdate --list-full-installers to get a list of macOS versions that are
  currently available for your Mac model."

Does Xcode 27.2 run on macOS 27.x?
- "Xcode 27.2 requires a Mac running macOS Tahoe 26.6 or later." No upper bound. The
  table gives Xcode 26.6 a closed range ("macOS Tahoe 26.2 - macOS Tahoe 26.x") and
  Xcode 27.x an open one ("or later").
- The 27.2 notes mention running on macOS 27.2: "Fixed: Device Hub might terminate
  unexpectedly when running on earlier macOS 27.2 betas. (190126101)"
- The Xcode 27 notes pair the two: "Workaround: Distribute with macOS 27 and Xcode 27
  or use manual signing." That workaround is for a known issue on Tahoe: "Apps with
  Hardware-Checked Pointer Arithmetic Slice feature enabled cannot be uploaded to the
  App Store on macOS Tahoe 26.6 with Xcode automatic signing enabled. (187057599)"
  (only matters for App Store upload with that feature on).
- Apple security releases: "Xcode 27.2 macOS Tahoe 26.6 and later 29 Oct 2026".
- I found no Xcode 27 / 27.1 / 27.2 feature that says it needs macOS 27 rather than
  Tahoe 26.6. (Xcode 27.3 beta 2 has one item that "requires macOS 27.3 Beta 2",
  about `xcstringstool sync` key order.)

Unverified: whether Software Update on a Mac that is still on Sequoia 15 offers macOS
Tahoe 26.7.x as well as macOS 27. Apple's pages do not say. `softwareupdate
--list-full-installers` on the Mac settles it.

---------------------------------------------------------------------------

## Q7. Latest released Xcode and its iOS SDK

https://developer.apple.com/news/releases/ :
- "Xcode 27.3 beta 2 (27C5035i) November 16, 2026" (beta)
- "Xcode 27.2 (27B52) October 29, 2026" (latest non-beta)
- "Xcode 27.1 (27A9275) October 15, 2026"
- "Xcode 27 (27A266a) September 14, 2026"
- For context: "iOS 27.2.1 (24B156) November 9, 2026" is the newest iOS release. No
  Xcode 27.2.1 is listed.

Xcode 27.2 includes the iOS 27.2 SDK (release notes quote in Q3).

Inference: an iPhone Duo on iOS 27.2.1 is inside Xcode 27.2's device-support range
(iOS 17 or later).

---------------------------------------------------------------------------

## Side findings (outside the seven questions, useful on the Mac)

- Xcode 27.2 known issues for the iPhone Duo simulator: "Screenshots and recordings
  in iPhone Duo might be black for up to a few minutes after booting the device.
  (187146039)"; "When switching between the inner and outer display of the iPhone Duo
  simulator, modifier keys such as Shift and Command might stop working. (189465196)"
  Workaround: "Click with the mouse on the currently visible screen."
- Xcode 27.1 known issue: "Running and debugging most app extensions is unavailable
  in the iPhone Duo Simulator runtime. (187708767)"
- Xcode 27.2 known issue: "Cloning a simulator device running runtime 27.2 might fail
  due to incorrect file permissions. (188407822)" Workaround:
  `find ~/Library/Developer/CoreSimulator/Devices/<SOURCE_UDID>/data -name '*.sb-????????-??????' -delete`
- Xcode 27.2: "Xcode now supports a JSON-based project format (`.xcproj`) that's more
  readable, merge-friendly, and easier for coding agents to edit."
- Xcode 27: "Agents can now boot simulators, install and launch apps, synthesize
  touch events, and capture screenshots to verify UI behavior. (175179787)"
- External agents: https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode
  gives `claude mcp add --transport stdio xcode -- xcrun mcpbridge`. The Xcode 27
  notes also describe a preview: "You can turn this experience on by using `sudo
  xcrun mcp-server enable`." (Not researched further here.)
- `simctl`: "After you install `simctl`, enter `xcrun simctl help` in Terminal to
  learn more."
  (https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line)

## Checks to run on the Mac (to close the open items)

```
sw_vers                                   # current macOS
system_profiler SPHardwareDataType        # model identifier (Apple lists Mac16,10 and Mac16,11 for Mac mini 2024), chip, memory
df -h /                                   # free disk space
softwareupdate --list-full-installers     # macOS versions Apple offers this Mac
xcodebuild -version                       # after installing Xcode
```

`sw_vers`, `system_profiler` and `xcodebuild -version` are the brief 2.1 checks named
in RESEARCH.md. `softwareupdate --list-full-installers` is from Apple's page 102662.
`df -h` is a standard Unix command, not from an Apple page.

## Could not verify

1. Download and installed size of Xcode 27.2 and of the iOS 27.2 platform support or
   simulator runtime.
2. Any Apple-stated minimum memory for Xcode 27.x, Device Hub or simulators (none
   found; absence on the pages read, not a positive statement by Apple).
3. The Mac's actual storage size, free space and current macOS version.
4. Whether Software Update offers Tahoe 26.7.x to a Mac still on Sequoia.
5. The two Apple Developer Forums leads (behind a human-verification page).
