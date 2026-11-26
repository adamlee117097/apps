> Raw working notes from a research agent, 2026-11-26. The claims that `MAC_SETUP.md` draws from these notes had their quotations checked by script against the source pages. The rest of these notes was not independently reviewed, and the planned second-agent review did not run. Treat anything here that is not in `MAC_SETUP.md` as a lead to verify.

# W1 toolchain notes: Claude Code in a terminal + Xcode 27 without the GUI

Researched 2026-11-25 from a Linux sandbox. Primary sources only (developer.apple.com, code.claude.com).
Nothing here was run on a Mac. About 135 quotes (every quote in the returned claims, and nearly all quotes in these notes) were checked with check_quote.py and came back FOUND.
A few short phrases and the command listings were copied from the fetched page text without a separate check; code lines are shown indented.
Fetched pages are cached as text under scratchpad/cache/ (see tools/fetch.py).
Labels: SOURCED = quote from the page; INFERENCE = my conclusion; UNVERIFIED = could not find a primary source.

Hardware context given by the user: Mac mini, M4 (4th-generation Apple silicon), 16 GB RAM, 2024 model, storage unknown. No paid developer account.

---------------------------------------------------------------------------------------------------

## Q1. Claude Code on macOS: requirements and install

Source: https://code.claude.com/docs/en/setup  (same content at .../setup.md)

- SOURCED requirements: "macOS 13.0+" ; "**Hardware**: 4 GB+ RAM, x64 or ARM64 processor" ; "**Network**: internet connection required." ; "**Shell**: Bash, Zsh, PowerShell, or CMD."
- SOURCED install (native, recommended), macOS:
      curl -fsSL https://claude.ai/install.sh | bash
  "The install command shows no progress while it downloads Claude Code. When the installer finishes, open a new terminal window and run `claude --version`."
- SOURCED alternative: `brew install --cask claude-code` ; "Homebrew installations do not auto-update."
- SOURCED: "Native installations automatically update in the background to keep you on the latest version."
- SOURCED verify: `claude --version` then `claude doctor` ("prints read-only installation and settings diagnostics without starting a session").
- SOURCED account: "Claude Code requires a Pro, Max, Ultra, Team, Enterprise, or Console account. The free claude.ai plan does not include Claude Code access."
  Log in: "After installing, log in by running `claude` and following the browser prompts."
- SOURCED launcher path: "On macOS and Linux, the native installer manages the launcher at `~/.local/bin/claude` as a symlink into `~/.local/share/claude/versions/`."
- SOURCED dependencies: ripgrep "usually included with Claude Code"; "**Git**: optional."
- INFERENCE: the M4 / 16 GB Mac mini exceeds Claude Code's own minimum (ARM64, 4 GB+).
  Apple's Xcode system-requirements page (https://developer.apple.com/xcode/system-requirements , reached from developer.apple.com/support/xcode/) lists a macOS version per Xcode release and no memory or storage minimum (searched the page text for memory, RAM, GB, storage, disk: nothing). So no Apple-stated RAM requirement was found for Xcode 27; 16 GB is not contradicted by any source, but how many simulators run comfortably is unknown until tried. The binding constraints are Xcode's, not Claude Code's (Xcode 27.x "requires a Mac running macOS Tahoe 26.6 or later" and "Xcode 27 will only install and run on Apple silicon Macs", both from the Xcode 27 release notes).

### Claude Code pages that mention iOS / Xcode / simulators

1. https://code.claude.com/docs/en/desktop-ios-simulator  ("Test iOS apps in the simulator") -- this is a feature of the Claude Code DESKTOP app, not the terminal CLI.
   - "The iOS Simulator pane is in public beta in Claude Code Desktop on macOS. It's available on Pro, Max, Ultra, Team, and Enterprise plans"
   - "When Claude builds, installs, launches, or checks your app in a simulator, the pane opens automatically and streams the device screen live."
   - "The simulator pane drives the simulator directly, so it doesn't need computer use and never takes over your screen or hides your other windows. From the CLI, Claude reaches the iOS Simulator through computer use instead, which controls the simulator on your screen the same way you would with a mouse."
   - Requirements: "Claude Desktop v1.24012.0 or later"; "Xcode 26.x or Xcode 27 is recommended, and the pane works with either."; "To test on an iPhone Duo, you need Xcode 27.1 or later."
   - iPhone Duo: "You can test your app on an iPhone Duo simulator in the simulator pane and fold the device into each of its poses: closed, half open, and open." Needs "Claude Desktop v4.29.0 or later".
   - "**Ask Claude to fold it**: ask for one of the three poses, or for a half-open hinge angle from 1 to 179 degrees."
   - "Claude installs the app, taps through it, and reads the screen to verify its own changes while you watch."
   - "The simulator pane is available in local sessions only."
   - "the pane uses whichever one `xcode-select` points at"
   - Limit: "Claude drives simulated devices only and can't control a physical iPhone or iPad."
   - Missing runtime: "download the iOS simulator runtime from Xcode's settings, or run `xcodebuild -downloadPlatform iOS`."
   - "Before a layout check on an iPhone Duo, Claude may ask whether to export Xcode's agent skills to your personal skills folder. These skills come with Xcode to guide coding agents ... They include a skill for getting your app's layout ready for the iPhone Duo."
   - Consent: "The first time Claude uses a simulator, the desktop app asks you to allow it." ; "Building the app, because `xcodebuild` runs your project's build scripts on your Mac." follows the permission mode.

2. https://code.claude.com/docs/en/computer-use  ("Let Claude use your computer from the CLI") -- this is how the TERMINAL CLI reaches GUI-only things.
   - "Computer use is a research preview on macOS that requires a Pro, Max, or Ultra plan. It is not available on Team or Enterprise plans. It requires an interactive session, so it is not available in non-interactive mode with the `-p` flag."
   - "Computer use is available as a built-in MCP server called `computer-use`. It's off by default until you enable it." Enable: run `/mcp`, select `computer-use`, choose Enable. "The setting persists per project".
   - macOS permissions: "**Accessibility**: lets Claude click, type, and scroll" ; "**Screen Recording**: lets Claude see what's on your screen".
   - Order of preference: "If you have an MCP server for the service, Claude uses that." / "If the task is a shell command, Claude uses Bash." / "If none of those apply, Claude uses computer use."
   - "Screen control is reserved for things nothing else can reach: native apps, simulators such as the iOS Simulator, and tools without an API."
   - "Claude controls the simulator the same way you would with a mouse. This flow applies to the CLI; in the Desktop app, the same request opens the iOS Simulator pane instead of screen control."
   - "Only one session at a time can use your computer."
   - "Claude Code downscales every screenshot before sending it to the model."

---------------------------------------------------------------------------------------------------

## Q2. Apple: "Giving external agents access to Xcode" (Xcode's MCP server)

Source A: https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode

- Protocol: Model Context Protocol. Abstract: "Let agents access your project and Xcode capabilities using the Model Context Protocol."
- What it is for: "You can give permission for external agents, that you launch outside of Xcode, to modify your Xcode project and perform actions, such as building your app."
- Command name: `xcrun mcpbridge`. "In Terminal, use the `xcrun mcpbridge` command to configure the external agent to use Xcode Tools. For example, run the following command in Terminal to give Claude Code access to your open project and Xcode capabilities:"
      claude mcp add --transport stdio xcode -- xcrun mcpbridge
  "To verify the configuration, enter `claude mcp list` or `codex mcp list` in Terminal."
- How to enable (GUI, one time): "Choose Xcode > Settings and select Intelligence in the sidebar." then "Under Model Context Protocol, choose either Always or "While Xcode is Open" from the "Allow External Agents to Use Xcode Tools" pop-up menu." Turn off with "Never".
- Limit: project must be open in Xcode. "Before prompting an external agent (outside of Xcode), be sure to open your project in Xcode." and "Open your project in Xcode and begin prompting the external agent that utilizes Xcode."
- "Xcode alerts you when the external agent connects to Xcode and when it's active."
- Hints: "Optionally, add hints about Xcode and your project to configuration files, such as the `AGENTS.md` or `CLAUDE.md` files, in the location that the external agent uses."
- THE PAGE DOES NOT LIST THE INDIVIDUAL TOOLS. It only says "Xcode Tools" / "Xcode capabilities". The tool names below come from release notes.

Source B: Xcode 27 release notes  https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes  (Coding Intelligence / Previews sections)

- Simulator control + screenshots: "Agents can now boot simulators, install and launch apps, synthesize touch events, and capture screenshots to verify UI behavior. (175179787)"
  (NOTE: says "Agents", does not say explicitly whether this is exposed to EXTERNAL MCP clients or only to agents running inside Xcode. See could-not-verify.)
- Debug/scheme/build settings tools: "The Xcode MCP server has been updated with new tools that allow agents to debug projects by manipulating the active run state, interacting with and reading the contents of the debugger console; listing and switching between available schemes and run destinations and inspecting and modifying build settings, compiler flags, entitlements, and Info.plist keys. (176935844)"
- Build and test tools reach external clients: "Xcode build and test MCP tools now send dynamic activity status instead of static text to external MCP clients. (181078347)"
- Previews: "The Preview Snapshot MCP tool can now render variants such as light/dark appearance, portrait/landscape orientation, and various type size overrides." ; "The Preview Snapshot MCP tool now returns information about the platform, device type, and operating system version of the Simulator that rendered the preview." ; "The RenderPreview MCP tool now returns the display name and line number of the preview it rendered. (182215198)" ; "Fixed: Errors encountered when using RenderPreview and ExecuteSnippet MCP tools now include full diagnostic details from the underlying failure."
- String catalogs: "Added new MCP tools to read, plan, and edit translations in String Catalog files."
- Headless variant (preview quality): "Xcode 27 Beta 5 adds a preview of a new MCP server experience that runs without requiring an open Xcode workspace. This new experience also allows you to grant code-signed agents permission to use projects within a directory tree for extended periods of time without being asked for additional permissions."
  "You can turn this experience on by using `sudo xcrun mcp-server enable`. Check its state afterward with `xcrun mcp-server status`."
  "Developers running agents in unattended environments can approve all permissions upfront with `sudo xcrun mcp-server enable --unsafe-always-allow-all-agents`. This is not a recommended configuration for at-desk use."
  "In this early preview, some aspects of the `xcrun mcp-server` command line utility may not work in all configurations, and some settings or permissions may occasionally require relaunching Xcode or rebooting your machine to apply."
  (This text is still in the final Xcode 27 release notes. It is not mentioned on the "Giving external agents access to Xcode" page, and I found no later release note that says it left preview.)
- watchOS/tvOS verification by agents is also listed (not relevant here).
- LLDB: "LLDB now ships with an MCP server (lldb-mcp)."
- Doc search: "You can now use natural language to search the developer documentation." (Developer Documentation section). Xcode updates page (https://developer.apple.com/documentation/updates/xcode): "use Xcode's built-in guidance, skills, and expertise, such as Apple Documentation Search".
- Security layer: "Coding Intelligence now includes a new security layer that monitors and controls filesystem access by coding agents and any processes they spawn."

Source C: Xcode 27.2 release notes  https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes
- "The RenderPreview MCP tool now returns the list of available render destinations, and lets the caller specify which destination to use for rendering. (186442676)"

Source D: Xcode 27.3 beta 2 release notes  https://developer.apple.com/documentation/xcode-release-notes/xcode-27_3-release-notes   (BETA, not the current release)
- "Previews now render correctly on iPhone Duo. (185995983)"   <-- listed as a resolved issue in 27.3 beta 2. INFERENCE: in Xcode 27.2 (current release) previews on iPhone Duo have a rendering bug of unstated scope.
- "Fixed: Snapshots from the RenderPreview MCP tool could have the wrong resolution when the image was downscaled."
- "Fixed an issue where the RenderPreview MCP tool could report no previews before they finished loading." / "...could render a different preview than the one requested."
- "RenderPreview MCP tool snapshot filenames and metadata now include the applied overrides."
- "This also fixes key order when using String Catalog MCP tools outside of Xcode."  (confirms some MCP tools are used outside Xcode)

Source E: Xcode 26.3 release notes (origin of the feature) https://developer.apple.com/documentation/xcode-release-notes/xcode-26_3-release-notes
- "Xcode 26.3 makes its capabilities available through the Model Context Protocol, an open standard that gives developers the flexibility to use any compatible agent or tool with Xcode."
- Known issue (26.3): "Denying Claude or Codex access to a project located in a privacy-protected directory - such as Desktop, Downloads, or Documents - will mean the project cannot be accessed by the agent ... please move your project folder to a new location outside of Desktop, Downloads, or Documents before proceeding."
  INFERENCE: keep the repo checkout outside ~/Desktop, ~/Documents, ~/Downloads on the Mac.

Source F: https://developer.apple.com/documentation/xcode/setting-up-coding-intelligence
- In-Xcode agents: "When you choose an agent in the coding assistant, it automatically has access to Xcode capabilities, such as building and testing your app."
- "To give agents that you use outside of Xcode access to your project and Xcode capabilities, see Giving external agents access to Xcode."
- ACP: "To enable an agent that doesn't appear in Intelligence settings and supports the Agent Client Protocol (ACP), click Add an Agent under Agents".
- MDM: `CodingAssistantAllowExternalIntegrations` key.

Source G: https://developer.apple.com/documentation/xcode/extending-and-customizing-agents
- Config files for IN-XCODE agents live in "`~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig`" ; "These configurations only affect agents when you launch them in Xcode."
- Permissions UI: "To manage agent permissions, click the Permissions row under Agents in Xcode that appears in Intelligence settings."
- Plug-ins: "You can install plug-ins that contain additional subagents, Model Context Protocol (MCP) servers, and skills that agents can use."
- Skills: "To discover all the skills available in Xcode, type the slash (`/`) character in the message text field".
  (Applies to the coding assistant inside Xcode. For Claude Code in a terminal, CLAUDE.md in the repo is the equivalent.)

Summary for Q2 (INFERENCE from the above): for Claude Code in a terminal the documented path is `claude mcp add --transport stdio xcode -- xcrun mcpbridge`, after a one-time GUI switch in Xcode > Settings > Intelligence, with the project open in Xcode. Release notes name build, test, RenderPreview / Preview Snapshot, ExecuteSnippet, String Catalog, debugger-console, scheme/run-destination and build-setting tools. An exact tool list with names and parameters is not on Apple's web docs; on the Mac, `claude mcp list` plus `/mcp` in a session will show it.

---------------------------------------------------------------------------------------------------

## Q4. Simulators from the command line in Xcode 27

### simctl is still documented
Source: https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference
- "Xcode includes a set of command-line tools that only ship with the app, such as `devicectl`, `simctl`, and `xcodebuild`. You must install and set Xcode as the active developer directory before you can invoke these commands in Terminal."
- "`simctl`: Control a simulated device in Device Hub. To learn more about this command, enter `xcrun simctl help` in Terminal or see Interacting with devices using the command line."
Source: https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line
- "To start simulated devices, use the `simctl` command. ... enter `xcrun simctl help` in Terminal to learn more." / "Alternatively, use Device Hub to start simulators. Select the simulated device you want to use in the sidebar and click Start in the canvas."
Source: Xcode 27 release notes, Simulator: "`simctl` and `devicectl` now support rebooting a simulator using the reboot command. (172303413)"
- Apple's web docs do NOT list simctl subcommands (boot, install, launch, io screenshot, etc.). They point to `xcrun simctl help`.

### Device Hub CLI = devicectl
Source: WWDC26 session 260 "Get the most out of Device Hub" https://developer.apple.com/videos/play/wwdc2026/260/
- "For scripts and automation, use devicectl. It's a command line tool based on the same underlying technology as Device Hub."
- "you can use devicectl to list your devices, install an app onto your device, change settings such as switching between dark and light modes, or getting more information about one of your devices. And if you want a structured output, you can use the json-output option"
Source: https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line
- "You can manage physical and simulated devices using the `devicectl` command-line tool in Terminal without running Xcode."
- "Before using `devicectl`, start the simulated devices and pair the physical devices you want to use."
- "You can launch an app on a simulated or physical device using its bundle ID or using the path to the app:"  `devicectl device process launch --device <uuid|ecid|udid|name> <bundle-identifier-or-path>`
- JSON: "don't rely on or parse the Terminal output from these commands, because the output may not be consistent in each release." Use `--json-output`.
- Device Hub.app itself: no command-line interface of its own is documented (INFERENCE from absence: the only CLIs Apple names are devicectl and simctl). A `defaults` key is documented in the Xcode 27 release notes: `defaults -container com.apple.dt.Devices write com.apple.dt.Devices hostKeybindingPolicy -int <value>`.

### iPhone Duo pose (open / closed / partially open / angle)
Source: https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub  (section "Interact with your iOS app on an iPhone Duo simulator")
- "simulate folding an iPhone Duo using the controls below the bezel in the canvas:"
- "To close the iPhone Duo, click the Closed button on the right of the Rotate Right button."
- "To partially open the iPhone Duo, click the Partially Open button in the middle of the three device pose buttons."
- "To fully open the iPhone Duo, click the Open button on the far right."
- "To fold the device to any angle, hold the Option key while dragging the slider that appears below the bezel."
- Rotation: "Click the rotate button under the device bezel or choose Controls > Rotate Left." ; "Choose an orientation from the Device > Orientation submenu."
- NO command-line way to change the pose is documented on this page, on the devicectl page, or in the 27 / 27.1 / 27.2 / 27.3b2 release notes. (searched for: pose, fold, hinge, simctl, devicectl)

Programmatic alternative (BETA): Xcode 27.3 beta release notes, UI Automation: "`XCUIAutomation` supports setting the hinge angle on iPhone Duo with a new `XCUIHinge` class. (187479559)"
- https://developer.apple.com/documentation/xcuiautomation/xcuihinge : "A reference to the hinge on iPhone Duo." ; `@MainActor class XCUIHinge`
- https://developer.apple.com/documentation/xcuiautomation/xcuihinge/angle : `var angle: CGFloat { get set }` ; "The hinge's current angle, in radians." ; "Setting this property can cause the device to switch between displays. Reading the angle alone does not tell you which layout your app uses." ; "On physical devices, programmatically opening the hinge while the device is closed is not supported and results in a test failure."
- https://developer.apple.com/documentation/xcuiautomation/xcuidevice/hinge : `nonisolated var hinge: XCUIHinge? { get }` ; "This property is `nil` on devices that do not have a hinge."
- INFERENCE: with Xcode 27.3 (beta 2 today), a UI test run by `xcodebuild test` could set `XCUIDevice.shared.hinge?.angle` and attach `XCUIScreen.main.screenshot()`; that is a fully command-line way to exercise poses. Not available in Xcode 27.2 according to the release notes.
- Rotation from a UI test is long-standing: XCUIDevice "orientation | The orientation of the device."

Claude-side alternative: Claude Code DESKTOP simulator pane folds the Duo ("ask for one of the three poses, or for a half-open hinge angle from 1 to 179 degrees") -- https://code.claude.com/docs/en/desktop-ios-simulator . From the terminal CLI the documented route is computer use (clicking Device Hub's buttons).

Whether Xcode's own MCP simulator tools ("synthesize touch events, and capture screenshots") can set the Duo pose: NOT STATED anywhere I found.

### Screenshots
- GUI: https://developer.apple.com/documentation/xcode/capturing-screenshots-and-videos-from-devices : "click the Screenshot button below the device in the canvas. Device Hub captures the screenshot at the full resolution of the simulated or physical device ... Device Hub saves the screenshot to the Desktop folder on your Mac."
- Save location keys (Xcode 27 release notes): "`com.apple.dt.devices` screenCaptureLocation", "`com.apple.iphonesimulator` ScreenShotSaveLocation", "`com.apple.screencapture` location". Xcode 27.2 adds "Screen Capture Save Location" to Device Hub App Settings.
- Agents: "Agents can now boot simulators, install and launch apps, synthesize touch events, and capture screenshots to verify UI behavior." (Xcode 27 RN)
- UI tests: `XCUIScreen.main.screenshot()` (https://developer.apple.com/documentation/xcuiautomation/xcuiscreen) ; "You can take a screenshot of every screen on the current device using ... `XCUIScreen.screens.map`" ; attach with XCTAttachment; `xcresulttool` "Read result bundles" (command-line tool reference).
- A command-line screenshot command (the classic `xcrun simctl io <device> screenshot <file>`) is NOT written out anywhere on Apple's web docs that I could open. UNVERIFIED for Xcode 27; check with `xcrun simctl help io` on the Mac.
- Known issue, Xcode 27.2: "Screenshots and recordings in iPhone Duo might be black for up to a few minutes after booting the device. (187146039)"
- Known issue, Xcode 27.2: "VoiceOver, the Accessibility Inspector, and other accessibility tools cannot convey screen content on an iPhone Duo within Device Hub. (187148389)"
- Known issue, Xcode 27.1: "Initial Simulator launch can take several minutes. (187708500)" ; "Running and debugging most app extensions is unavailable in the iPhone Duo Simulator runtime."
- Xcode 27 RN: "When running parallel testing in simulators, devices may not be visible in Device Hub but are still actively running tests."

---------------------------------------------------------------------------------------------------

## Q5. Installing and launching on a physical iPhone from the command line

Source: https://developer.apple.com/documentation/xcode/interacting-with-devices-using-the-command-line   (devicectl is still the tool in Xcode 27; no replacement)

- Pair: `devicectl manage pair` -- "To pair physical devices that you connect to your Mac with a cable, enter this command" ; "Whether you use the command line or Device Hub to pair physical devices, unlock the device before entering `devicectl` commands."
- Identify: "You pass the device to subcommands by adding the `--device` option followed by the UUID, ECID, UDID, or name for the device." ; "enter the `devicectl list devices` or `devicectl device info details` command"
- Lock state: `devicectl device info lockState --device <uuid|ecid|udid|name>`
- Install: `devicectl device install app --device <uuid|ecid|udid|name> <path>`
- Launch: `devicectl device process launch --device <uuid|ecid|udid|name> <bundle-identifier-or-path>` ; "use the `--environment-variables` option to pass environment variables to the app."
- Files: `devicectl device copy to|from ... --domain-type appDataContainer --domain-identifier <bundle ID>` ; `devicectl device info files ... --domain-type systemCrashLogs`
- Mount: "`~/Library/Developer/CoreDevice/DeviceFS`" ; `devicectl device info mountpoint --device ...`
- Invocation form: the page writes bare `devicectl`; the "Configuring command-line tools settings" page uses `xcrun devicectl device sysdiagnose --device "Work iPad" ...`.
- Xcode 27 release notes, devicectl: "--json-output now fully supports passing JSON output to stdout." ; "'devicectl list devices' now shows a unique identifier for devices."
- Signing is NOT covered by devicectl docs. The app must be built and signed first. Apple's documented signing setup is GUI: "sign in with your Apple Developer Program or personal Apple Account in Xcode > Settings > Apple Accounts." and "toggle "Automatically manage signing" on, assign your project to a team, and enter a bundle ID in the Signing & Capabilities pane" (https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices). "When you enable the "Automatically manage signing" option, Xcode registers the device and creates the development provisioning profile for you."
- Building for a device from the command line with a free Personal Team (xcodebuild -allowProvisioningUpdates etc.): flags not on Apple's web docs I could open; UNVERIFIED, read `man xcodebuild` on the Mac.
- Claude side limit: "Claude drives simulated devices only and can't control a physical iPhone or iPad." (desktop-ios-simulator page; about the Desktop pane).

---------------------------------------------------------------------------------------------------

## Q3. xcodebuild from the command line in Xcode 27

Headline: Apple's CURRENT web documentation has only fragments about xcodebuild. It does not define the `-destination` specifier, does not mention `-showdestinations`, and has no "Building from the command line" page. It points to the man page. Complete syntax must be read on the Mac: `man xcodebuild`, `xcodebuild -help`.

### What is on current Apple pages
- Tool reference https://developer.apple.com/documentation/xcode/xcode-command-line-tool-reference : "`xcodebuild`: Build Xcode projects and workspaces. To learn more about this command, enter `man xcodebuild` in Terminal."
- xcodebuild needs full Xcode: "Commands such as `xcodebuild` and `xctrace` only ship with Xcode, and aren't in the Command Line Tools for Xcode package." (https://developer.apple.com/documentation/xcode/installing-the-command-line-tools)
- Active developer directory: `xcode-select --print-path` -> `/Applications/Xcode.app/Contents/Developer` ; `sudo xcode-select --switch <path>` ; per-command `env DEVELOPER_DIR="<path>" <command>` (https://developer.apple.com/documentation/xcode/configuring-command-line-tools-settings)
- Man pages: TN3215 (2026-10-08) https://developer.apple.com/documentation/technotes/tn3215-reading-man-pages : "Developer-oriented man pages are distributed as part of Xcode. The `man` tool searches for man pages within the active developer directory."
- Tests, https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results :
      % xcodebuild test -scheme SampleApp
      % xcodebuild test -scheme SampleApp -only-testing SampleAppTests/SampleAppTests/testEmptyArrayWhenNoOverlappingNotes
      % xcodebuild test -scheme SampleApp -only-testing SampleAppTests/SampleAppTests
      % xcodebuild test -scheme SampleApp -only-testing SampleAppTests/SampleAppTests/testEmptyArrayWhenNoOverlappingNotes -run-tests-until-failure -test-iterations 20
  "The identifier for a test function has the form `test_target/test_type/test_function`." ; "The identifier for a suite has the form `test_target/test_suite`."
  "When you run tests with `xcodebuild` in Terminal, the command outputs an Xcode Test Results (`.xcresults`) bundle that contains session results, code coverage (if enabled), and other logs."
  (These examples have no -destination. The page does not say which destination is used when none is given.)
- Result bundles: "`xcresulttool`: Read result bundles. To learn more about this command, enter `man xcresulttool` in Terminal."
- Build settings: "To list the fully evaluated build settings for targets in a project, enter `xcodebuild -showBuildSettings` in Terminal." (managing-xcode-projects page)
- Generic destinations, https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle : `xcodebuild archive ... -destination "generic/platform=iOS"` ; "Replacing this value with `"generic/platform=iOS Simulator"` creates an archive for Simulator." ; "The system determines the architectures and SDK according to build settings when running the command with the `-destination` flag ... Avoid common errors by using this flag rather than `-arch` and `-sdk`." ; "To see an extensive list of all the command options, execute `xcodebuild` with the `-help` flag."
- Components, https://developer.apple.com/documentation/xcode/downloading-and-installing-additional-xcode-components :
      xcodebuild -downloadPlatform <iOS|watchOS|tvOS|visionOS>  [-exportPath <destinationpath> -buildVersion <osversion> -architectureVariant <universal|arm64>]
      xcodebuild -runFirstLaunch
      xcodebuild -runFirstLaunch -checkForNewerComponents
  "run `xcodebuild -runFirstLaunch` to install any required system components, including the `simctl` utility."
  "Otherwise, Xcode downloads an Apple silicon variant to save disk space for the platform you specify."
- Packages in CI, https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows : "Use either Xcode Cloud or the `xcodebuild` command directly on other CI systems to build Swift packages and apps that use them." ; "also pass the `-disableAutomaticPackageResolution` flag" ; "pass `-scmProvider system`" ; "For more information on using `xcodebuild`, see Technical Note 2339." (so Apple's current page still refers to the archived 2017 technote)

### Destination specifier syntax (only in OLDER Apple material)
- Xcode 15 release notes https://developer.apple.com/documentation/xcode-release-notes/xcode-15-release-notes :
      xcodebuild test -enumerate-tests -project MyProject.xcodeproj -scheme MyScheme -destination 'platform=iOS Simulator,name=iPhone 14 Pro'
- Xcode 13 release notes https://developer.apple.com/documentation/xcode-release-notes/xcode-13-release-notes :
      xcodebuild test -project MyProject.xcodeproj -scheme MyProject -destination 'platform=iOS Simulator,name=iPhone 12,OS=15.0' -test-iterations 100 -run-tests-until-failure
- Xcode 16 release notes: "Fixed an issue where xcodebuild silently selects the first compatible run destination when it fails to match the destination specifier provided by the user. (112043381)"  (so a wrong name should now fail rather than silently pick another device)
- Xcode 16.3 release notes: "Pass -prepareDeviceSupport and a -destination predicate to prepare an unlocked and attached device."
- ARCHIVED (Documentation Archive, last updated 2017-06-19) TN2339 https://developer.apple.com/library/archive/technotes/tn2339/_index.html :
  "The -destination option ... takes an argument <destination-specifier>, which describes the device, simulator, or Mac to use as a destination. It consists of a set of comma-separated key=value pairs, which are dependent upon the the device, simulator, or Mac being used."
  "For iOS Simulator and tvOS Simulator apps, destinationspecifier supports the platform, name, id, and OS keys" ; OS: "An iOS version, tvOS version, or latest" ; "The OS key is optional."
  Devices: `-destination 'platform=iOS,id=<udid>'` or `'platform=iOS,name=iPhone'`.
  Listing: `xcodebuild -list -project <your_project_name>.xcodeproj` (targets, configurations, schemes).
  Build: `xcodebuild -scheme <your_scheme_name> build` ; "build is performed by default when no action is specified".
  "The test action requires specifying a scheme and a destination."
  build-for-testing / test-without-building are described there too.
- INFERENCE (not run): the Xcode 27 commands are expected to look like
      xcodebuild -project NecroTactics.xcodeproj -scheme NecroTactics -destination 'platform=iOS Simulator,name=<iPhone Duo simulator name>' build
      xcodebuild test -project NecroTactics.xcodeproj -scheme NecroTactics -destination 'platform=iOS Simulator,name=<iPhone Duo simulator name>'
  The exact simulator name string for iPhone Duo is NOT on any page I opened. Get it on the Mac from `xcrun simctl list devices` or `xcodebuild -showdestinations -scheme <scheme>`.

### Listing destinations
- `xcodebuild -showdestinations`: NOT FOUND on any Apple web page (searched current docs, release notes 11 to 27.3b2, TN2339, the archived testing guide). UNVERIFIED for Xcode 27; check `man xcodebuild`.
- Documented alternatives: `devicectl list devices` (devices page; Xcode 27 RN "now shows a unique identifier for devices"); `xcrun simctl list --json` (Xcode 11.2 RN: "now includes more information about devices and runtimes, including the device type used by each device"); `simctl list devices --json` (Xcode 26.1 RN); the Xcode MCP server tools for "listing and switching between available schemes and run destinations" (Xcode 27 RN).

### Running the tests of a local Swift package
- `swift test` in the package directory. Xcode 27 release notes, Swift Package Manager: "When one or more test targets in a package experience a test failure, `swift test` summarizes them at the end." ; "`swift test` now supports repeating test cases until a condition is met. Pass `--maximum-repetitions` and `--repeat-until [pass|fail]`".
  (NecroRules already runs under `swift test` on Linux per docs/STATUS.md. INFERENCE: on the Mac, `swift test` builds and runs the package for macOS, not for iOS; fine for a pure rules module.)
- In Xcode: https://developer.apple.com/documentation/xcode/creating-a-standalone-swift-package-with-xcode : "Xcode creates a scheme for each product in the package manifest." ; "If your package contains multiple products, Xcode creates an additional scheme with the name [packageName]-Package to build all targets and run all unit tests." ; "Swift packages don't use `.xcodeproj` or `.xcworkspace` but rely on their folder structure and use the package manifest for additional configuration."
- `xcodebuild test -scheme <Package scheme> -destination ...` run inside a package directory (to test the package on an iOS simulator): the exact invocation is NOT written on Apple's web docs. The CI page only says xcodebuild can "build Swift packages and apps that use them". UNVERIFIED; try `xcodebuild -list` in the package directory on the Mac.

### TN3117 (asked for in the brief)
https://developer.apple.com/documentation/technotes/tn3117-resolving-build-errors-for-apple-silicon is about architecture build settings (ARCHS, EXCLUDED_ARCHS, VALID_ARCHS), not xcodebuild flags. Relevant lines: default `ARCHS` = `$(ARCHS_STANDARD)`; "Don't launch Xcode using Rosetta to resolve these errors." A new project with default settings and no pre-compiled libraries is not affected (INFERENCE).

---------------------------------------------------------------------------------------------------

## Q6. The JSON Xcode project configuration file format

Source: https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format  (page availability: Xcode 27.2)

- Name: Apple calls it the "JSON project configuration file format" / "JSON file format `.xcproj`". Xcode 27.2 release notes heading: "Project Format" - "a JSON-based project format (`.xcproj`)".
- File and location: "An Xcode project file with a `.xcodeproj` extension contains a project configuration file along with other files specific to your project. In previous Xcode releases, a project configuration file is a property list file with a `.pbxproj` extension. In Xcode 27.2 and later, the default project configuration file is a smaller, hierarchical, self-describing JSON file with a `.xcproj` extension."
  The Apple doc page gives only the extension. The file NAME `project.xcproj` comes from Apple's open-source repository README (https://raw.githubusercontent.com/apple/xcode-project-format/main/README.md , a GitHub host, not one of the four listed primary hosts): "`xcode-project-format` is a Swift library for reading, writing, and manipulating Xcode's JSON-based `project.xcproj` format." Its `xcprojformatter` tool source appends `project.xcproj` to a path ending in `.xcodeproj`.
- Both formats supported: "Xcode 27 and later supports both file formats so you can choose the format you prefer." ; Note: "The JSON file format `.xcproj` is compatible with Xcode 27 and later." ; 27.2 RN: "Projects using `.xcproj` also open in earlier versions of Xcode 27."
- Editing by people / agents: abstract: "Configure your Xcode project to use the JSON project configuration file format that's more human-readable and editable by coding intelligence agents." ; "The JSON file format also makes it easier for coding intelligence agents to edit the file for you." ; "merge conflicts are less likely because the JSON file format isolates configuration changes." ; Xcode updates page: "version-control-friendly, human-readable, and editable by coding intelligence agents" ; 27.2 RN: "more readable, merge-friendly, and easier for coding agents to edit".
  Apple does NOT give rules for hand-editing (no schema reference on developer.apple.com; it links to swiftpackageindex.com, which is blocked here). Apple's README describes the library's purpose: "so tools like generators, linters, verifiers, and validators don't each have to reverse-engineer the format from scratch."
- Converting an existing project (GUI only): "In the Project navigator, select the project, and in the File inspector, choose JSON from the Project Format pop-up menu under Project Document. If a dialog appears, click Continue to change the format." Result: "The project configuration file inside the Xcode project (`.xcodeproj`), changes from a property list file with a `.pbxproj` extension to a JSON file with a `.xcproj` extension." Undo via source control.
  No command-line conversion is documented.
- Open-source library (Apple GitHub README): Swift 6.1+, macOS 14+, "also builds on non-Darwin platforms"; `XCSchema.Project(jsonRepresentation:)`; version 0.1.0; ships CLI `xcprojformatter`. DocC articles named package-layout, schema-overview, file-format-goals exist but I could not find their raw paths.
  INFERENCE: because the library builds on Linux, a project file could in principle be validated in CI or from a cloud session. Not tested.

### Apple's own project-editing CLI: `xcrun xcodeproj`
Source: https://developer.apple.com/documentation/xcode/managing-xcode-projects-using-the-command-line
- "Use the `xcodeproj` command-line tool to modify an existing Xcode project configuration in Terminal."
- "The `xcrun xcodeproj` commands apply to a single Xcode project file with a `.xcodeproj` extension in the current folder or the enclosing project folder by default. ... add the `--project <path.xcodeproj>` option"
- Help: "enter `xcrun xcodeproj help` or `xcrun xcodeproj help <subcommand>` in Terminal."
- Settings: `xcrun xcodeproj setting get PRODUCT_BUNDLE_IDENTIFIER --target Landmarks` ; `setting list`, `setting set`, `setting set-multi`, `setting unset` ; `--target`, `--config`.
- Targets: `xcrun xcodeproj target info --target Landmarks` ; `xcrun xcodeproj target add LandmarkModels --product-type framework` ; "You can omit the `com.apple.product-type.` prefix for the `--product-type` values and pass `framework`, `tool`, or `application` instead. The command adds targets without schemes, because Xcode creates schemes automatically for you." ; `target remove`.
- Build phases: `xcrun xcodeproj target phase add --target <target> <kind>` ; `--position`, `--before`, `--after` ; `target phase remove`.
- Files/groups: `xcrun xcodeproj group add-file <path> --group <group-path>` ; `group add`, `group remove`, `group remove-file`, `group ls`.
- Packages: see Q7.
- The page does not say whether the tool works on `.pbxproj`, `.xcproj`, or both, and does not say which Xcode version introduced it. (Blog lead, NOT primary: mjtsai.com 2026-10-20 says it "arrived in beta 3 of Xcode" 27.)

### Creating a NEW iOS app project without the Xcode GUI
- Apple documents only the GUI: https://developer.apple.com/documentation/xcode/creating-an-xcode-project-for-an-app : "choose App from the New Project pop-up menu or choose File > New > Project and select App from anywhere in Xcode." ; save with "File > Save Project". WWDC26 session 258: "A brand new untitled project is created, no questions asked."
- `xcrun xcodeproj` is documented only for modifying "an existing Xcode project configuration". No `create`/`init`/`new` subcommand is documented on the web page. Whether one exists: check `xcrun xcodeproj help` on the Mac.
- PLAIN STATEMENT: I found no Apple-documented way to create a new iOS app project without the Xcode GUI.
- Leads (not primary, not verified): an Apple Developer Forums thread titled "Apple supported way to create xcodeproject without using XCode IDE or with minimal use of XCode IDE" (https://developer.apple.com/forums/thread/835705) exists but is behind a human-verification page here.
- INFERENCE, practical route: Adam creates the app project once in Xcode (about a minute: File > New > Project > App, save into the repo). In Xcode 27.2 the new project should already be JSON. After that, Claude Code can use `xcrun xcodeproj` (targets, files, settings, packages) or edit `project.xcproj` directly, and build with xcodebuild.
  Alternative INFERENCE (riskier): have Claude write `project.xcproj` JSON by hand or with the open-source library. Apple does not document a minimal valid project, so this is trial and error.

---------------------------------------------------------------------------------------------------

## Q7. Using a local Swift package from an app target

Source A (GUI): https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages
- "Open your Xcode project and create a local Swift package as part of your project by selecting File > New > Package"
- "Select your project in the Project navigator, then select your app target and navigate to its General pane."
- "Click the + button in the "Frameworks, Libraries, and Embedded Content" section, select the local package's library product, and add it as a dependency."
- "When you organize your app's codebase using local packages, your Swift package's code is part of the same repository as your app's code."
- The page describes creating a NEW package inside the project. It does not describe adding an EXISTING package folder (the NecroRules case) by drag and drop.

Source B (command line): https://developer.apple.com/documentation/xcode/managing-xcode-projects-using-the-command-line  ("Manage Swift packages")
- "Use the `pkg` subcommand to list, add, and remove Swift package dependencies in a project."
- "To add a remote package dependency, use `pkg add`. To add a local package dependency, use `pkg add-local`."
      % xcrun xcodeproj pkg add <url>
      % xcrun xcodeproj pkg add-local <path>
      % xcrun xcodeproj pkg remove <package>
- "To get the `<package>` value, enter `xcrun xcodeproj pkg list` in Terminal."
- "To add and remove package product links for a target, use the `pkg link` and `pkg unlink` subcommands."
      % xcrun xcodeproj pkg link <product> --package <package> --target <target>
      % xcrun xcodeproj pkg unlink <product> --target <target>
- INFERENCE for this project (not run): from the app project folder,
      xcrun xcodeproj pkg add-local ../NecroRules
      xcrun xcodeproj pkg list
      xcrun xcodeproj pkg link NecroRules --package <value from pkg list> --target <AppTarget>
  then `import NecroRules` in app code.

Other package pages
- https://developer.apple.com/documentation/xcode/building-swift-packages-or-apps-that-use-them-in-continuous-integration-workflows : "be sure to commit your project's `Package.resolved` file to your Git repository." (matters only once there are remote dependencies; a local package has no pinned version.)
- https://developer.apple.com/documentation/xcode/developing-a-swift-package-in-tandem-with-an-app : "a local package overrides a package dependency with the same name".
- Lead only (forum title, not readable here): "Xcode MCP: Is Swift Package depend..." https://developer.apple.com/forums/thread/844813 - a search summary says a user reported the MCP tools give agents no way to manage package dependencies. Not verified. `xcrun xcodeproj pkg` is the documented way.

---------------------------------------------------------------------------------------------------

## Q8. Rendered UI that an agent can read

1. Xcode MCP "RenderPreview" / "Preview Snapshot" tool (renders #Preview blocks and returns an image).
   - Xcode 27 RN: "The Preview Snapshot MCP tool can now render variants such as light/dark appearance, portrait/landscape orientation, and various type size overrides. It also supports specifying timelines for Widgets and toggle states for Live Activities. Taken together, this gives agents more flexibility in how they render previews in your codebase."
   - Xcode 27 RN: "The Preview Snapshot MCP tool now returns information about the platform, device type, and operating system version of the Simulator that rendered the preview."
   - Xcode 27 RN: "The RenderPreview MCP tool now supports rendering Previews using the new group feature." ; "now returns the display name and line number of the preview it rendered."
   - Xcode 27.2 RN: "The RenderPreview MCP tool now returns the list of available render destinations, and lets the caller specify which destination to use for rendering. (186442676)"
   - Xcode 27.3 beta RN: "Previews now render correctly on iPhone Duo. (185995983)" ; "Fixed: Snapshots from the RenderPreview MCP tool could have the wrong resolution when the image was downscaled." ; "RenderPreview MCP tool snapshot filenames and metadata now include the applied overrides."
   - (Apple uses both names, "Preview Snapshot MCP tool" and "RenderPreview MCP tool". I assume they are the same tool; not stated.)
   - WWDC26 259: "With access to previews in Xcode, agents don't just generate code and stop. Previews can be rendered incrementally to visually verify results".
   - Canvas side: https://developer.apple.com/documentation/xcode/interacting-with-previews-in-the-canvas : "Display Variants: Displays the different screens on the device (such as the outer and inner displays on iPhone Duo)." Xcode 27.1 RN: "The canvas overrides picker now includes a Display group for previewing content on a device's alternative display."
   - NOT STATED: whether RenderPreview can render the Duo inner vs outer display or a fold pose as an override. Whether a SpriteKit scene inside a SwiftUI preview renders usefully in a static snapshot is also not stated (a game board is animated content).
   - Xcode 27 RN deprecation: "`PreviewProvider` and its family of preview modifiers." Use `#Preview`.
   - Xcode 27 RN: "Fixed: Simulators booted for previewing are now shut down once they are no longer in use, keeping the number of running simulators within a budget based on your Mac's resources." (relevant on 16 GB)

2. Simulator screenshots taken by agents.
   - Xcode 27 RN: "Agents can now boot simulators, install and launch apps, synthesize touch events, and capture screenshots to verify UI behavior. (175179787)"
   - WWDC26 102: "And now agents can interact with your app in the simulator." ; "The agent can tap, swipe, and type. When it's done, I get a summary of the tests, and I can see all the screenshots it created along the way." (demonstrated with an agent inside Xcode)
   - Not stated whether the external `mcpbridge` connection exposes these simulator tools.

3. Claude Code's own features.
   - Desktop app simulator pane: "Claude installs the app, taps through it, and reads the screen to verify its own changes while you watch." ; "Claude's screenshots of the device are sent to Anthropic and kept under your normal conversation retention settings" (https://code.claude.com/docs/en/desktop-ios-simulator)
   - Terminal CLI: computer use (screenshots of the Mac screen with Device Hub on it). Research preview; Pro/Max/Ultra; interactive sessions only.
   - Any image file on disk (for example a screenshot written by a UI test or by a simulator command) can be opened by Claude Code's file reading tool (general Claude Code capability; not looked up for this report).

4. UI tests as a screenshot source (command-line only path).
   - `XCUIScreen.main.screenshot()` ; "You can take a screenshot of every screen on the current device using the following code: ... `XCUIScreen.screens.map`" (https://developer.apple.com/documentation/xcuiautomation/xcuiscreen) - INFERENCE: on iPhone Duo "every screen" may give both displays; not stated.
   - Attach to results with XCTAttachment; read the `.xcresult` with `xcresulttool` (man page on the Mac). Exact export subcommand not on the web docs.
   - Xcode 27.3 beta: "Xcode now supports writing UI tests with Swift Testing and `XCUIAutomation`."

---------------------------------------------------------------------------------------------------

## Other facts worth keeping

- Xcode 27.x needs macOS Tahoe 26.6+ and Apple silicon: "Xcode 27.2 requires a Mac running macOS Tahoe 26.6 or later." ; "Xcode 27 will only install and run on Apple silicon Macs." An M4 Mac mini is Apple silicon. (Whether that Mac currently runs 26.6+ must be checked with `sw_vers`.)
- Device Hub replaces the Simulator app: WWDC26 102: "Xcode 27 brings both together in the new Device Hub. It replaces Simulator and it does a whole lot more too."
- Xcode 27.3 beta: "Xcode is now available as an Apple Encrypted Archive (`.aea`). If you're installing Xcode from the command line, use `archiveutil extractXcodeAEA` to extract the Xcode archive." ; "Xcode 27.3 is the final release supporting the `.xip` format."
- Xcode 27.3 beta, Swift Testing: UI tests with Swift Testing.
- `xcdebug`: "Start a debugging session in Xcode. To learn more about this command, enter `xcdebug --help` in Terminal." ; LLDB "now ships with an MCP server (lldb-mcp)".
- Metal/GPU agent tools (possibly useful for SpriteKit rendering bugs): `gpucapture`, `gpudebug` - "well-suited for AI agents" (https://developer.apple.com/documentation/xcode/investigating-gpu-issues-with-ai-agents). Not investigated further.
- Apple itself demos Claude Code: WWDC26 357 "I am using Claude Code for everything today."

## Leads that are NOT primary sources (search snippets and blogs; do not rely on these)
- `xcrun agent skills export --output-dir <absolute path>` and `xcrun agent plugin path` to export Xcode's bundled agent skills / a Claude Code plugin (blakecrosley.com, avanderlee.com, dev.classmethod.jp, mehmetbaykar.com). Claude's own doc confirms only that "Claude may ask whether to export Xcode's agent skills to your personal skills folder". Verify on the Mac with `xcrun agent --help`.
- `xcrun mcp-server start` and a headless `XcodeService.app` (mehmetbaykar.com). Apple's release notes confirm only `sudo xcrun mcp-server enable`, `xcrun mcp-server status` and the `--unsafe-always-allow-all-agents` flag, and call it an "early preview".
- Tool names such as `RunAllTests` / `RunSomeTests` in the Xcode 26.3 MCP server (Apple Developer Forums post, community content).
- `xcodeproj` "arrived in beta 3 of Xcode" 27 (mjtsai.com quoting a developer).

## Suggested split of work on the Mac (INFERENCE, to be confirmed on the machine)
One-time steps that need a person at the GUI:
 1. Install Xcode 27.2, open it once (or `xcodebuild -runFirstLaunch`), install the iOS 27.2 platform (`xcodebuild -downloadPlatform iOS` is documented).
 2. Xcode > Settings > Apple Accounts: sign in with the free Apple Account (needed only for the physical phone).
 3. Create the app project (File > New > Project > App) and save it in the repo, outside Desktop/Documents/Downloads.
 4. Xcode > Settings > Intelligence > Model Context Protocol > allow external agents; then in Terminal `claude mcp add --transport stdio xcode -- xcrun mcpbridge`.
 5. Pair the iPhone Duo (Device Hub or `devicectl manage pair`), Developer Mode, choose the team under Signing & Capabilities.
Then from Claude Code in the terminal:
 - `xcrun xcodeproj pkg add-local` / `pkg link` for NecroRules; `swift test` for the rules; `xcodebuild ... build|test` for the app; `xcrun simctl help` / `devicectl` for simulator and phone; Xcode MCP tools (project open in Xcode) for builds, tests, previews.
 - Fold poses: no documented CLI. Options: a person clicks Device Hub's pose buttons; Claude Code computer use; Claude Code Desktop's simulator pane; or XCUIHinge UI tests once Xcode 27.3 is released.

## First commands to run on the Mac to close the gaps (none of these were run)
    sw_vers; xcodebuild -version; xcode-select -p
    man xcodebuild            (look for -destination, -showdestinations, -derivedDataPath, -resultBundlePath, -allowProvisioningUpdates)
    xcodebuild -showdestinations -scheme <scheme>
    xcrun simctl help; xcrun simctl help io; xcrun simctl list devices
    xcrun devicectl help; xcrun devicectl list devices
    xcrun xcodeproj help      (is there a create/init subcommand? does it handle .xcproj?)
    xcrun mcp-server status; xcrun agent --help
    claude mcp list           then /mcp inside a session to see the real Xcode tool list

## Could not verify (and what I tried)
- Exact list, names and parameters of the tools the Xcode MCP server exposes to an external agent: not on the "Giving external agents access to Xcode" page, the two sibling pages, or release notes (only partial names). Forum threads are behind human verification.
- Whether simulator-interaction tools (boot, tap, screenshot) are available to external MCP clients or only to agents inside Xcode.
- Any command-line or MCP way to set the iPhone Duo simulator pose in Xcode 27.2. Searched Device Hub docs, devicectl page, release notes 27 to 27.3 beta 2, WWDC26 session 260, tech talk 111461.
- simctl subcommand syntax for Xcode 27 (boot, install, launch, io screenshot): Apple's web docs give no subcommand list.
- `xcodebuild -showdestinations`, `-derivedDataPath`, `-resultBundlePath` (last one appears only in the Xcode 11 release notes), `-allowProvisioningUpdates`: not on current Apple web pages.
- Whether a free Personal Team can sign a device build purely from xcodebuild without opening Xcode.
- The simulator name string for iPhone Duo to use in `-destination`.
- Whether `xcrun xcodeproj` can create a project and whether it edits `.xcproj`.
- Schema documentation for `project.xcproj` (swiftpackageindex.com blocked; DocC article paths in the GitHub repo not found).
- Whether `xcrun mcp-server` (no open workspace needed) is still a preview in Xcode 27.2.

## Addendum
- Historical evidence that `simctl io` is the screenshot/recording subcommand: Xcode 11 release notes (https://developer.apple.com/documentation/xcode-release-notes/xcode-11-release-notes): "In this mode simulators can't be viewed and `simctl io` is unable to take screenshots or record videos." Xcode 11.2 notes: "See `xcrun simctl help io` for more information." Nothing newer on Apple's web pages gives the syntax; confirm with `xcrun simctl help io` on the Mac.
- Other simctl subcommands that appear in old Apple release notes (Xcode 11.4): `xcrun simctl ui <device> appearance dark`, `xcrun simctl privacy <device> grant photos <bundle id>`, `xcrun simctl push <device> <bundle id> <file>.apns`, `xcrun simctl keychain <device> add-root-cert <file>`, `simctl status_bar`. Xcode 14: `simctl boot` has an `--arch` argument. Xcode 26.1: `xcrun simctl runtime dyld_shared_cache update --all`. Not re-verified for Xcode 27.
