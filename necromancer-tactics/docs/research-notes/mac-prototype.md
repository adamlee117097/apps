> Raw working notes from a research agent, 2026-11-26. The claims that `MAC_SETUP.md` draws from these notes had their quotations checked by script against the source pages. The rest of these notes was not independently reviewed, and the planned second-agent review did not run. Treat anything here that is not in `MAC_SETUP.md` as a lead to verify.

# Working notes: API facts for the first on-Mac task (SpriteKit scene inside SwiftUI that survives fold and unfold)

Research date: 2026-11-25/26. Done from a Linux sandbox, not on the Mac. Nothing here was compiled or run.

How to read this:

- **Sourced** = the quoted words are on the linked Apple page. Every quote below was checked with `check_quote.py` and came back FOUND, except where a line says otherwise.
- **Inference** = my conclusion from sourced facts. Not an Apple statement.
- **Unverified / not found** = no primary source found; the text says what would settle it.
- Declarations and availability come from the JSON behind each documentation page (the same data the page shows). Availability is the page's platform metadata ("iOS 27.1" and so on), not prose.
- Apple documentation code listings below were extracted by script from the page data, so indentation is Apple's. Tech Talk code was extracted from the page HTML.
- One tool quirk: `check_quote.py` cannot match a sentence that contains a link to a symbol whose name ends in `)` (for example `didChangeSize(_:)`), because of how it strips links. For those sentences the quote uses `...` in place of the symbol name. The full sentence is in the page.

Sources used most:

- SpriteKit: <https://developer.apple.com/documentation/spritekit/skscene>, <https://developer.apple.com/documentation/spritekit/skscenescalemode>, <https://developer.apple.com/documentation/spritekit/scaling-a-scene-s-content-to-fit-the-view>, <https://developer.apple.com/documentation/spritekit/spriteview>
- SwiftUI iPhone Duo APIs: <https://developer.apple.com/documentation/swiftui/arrangementview>, <https://developer.apple.com/documentation/swiftui/reservedregion>, <https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)>
- "Preparing your app for iPhone Duo": <https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>
- "Three steps to make your app shine on iPhone Duo": <https://developer.apple.com/iphone-duo/prepare/>
- Tech Talks 111461, 111463, 111464: <https://developer.apple.com/videos/play/tech-talks/111461/>, <https://developer.apple.com/videos/play/tech-talks/111463/>, <https://developer.apple.com/videos/play/tech-talks/111464/>
- WWDC26 session 278 "Modernize your UIKit app": <https://developer.apple.com/videos/play/wwdc2026/278/>
- iOS & iPadOS 27 release notes: <https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes>
- HIG "Designing for iPhone Duo": <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>

---

## 0. Short version for whoever writes the prototype

Sourced facts that decide the design:

1. Fold and unfold reach the app as a **resize** of the running app. Apple: "Opening and closing iPhone Duo works the same way" (as resizing in iPhone Mirroring), and "a fold can resize your app in the middle of a session."
2. With `scaleMode = .resizeFill`, SpriteKit resizes the scene to the view and calls `didChangeSize(_:)`. Apple: "Your game should also override the scene's `didChangeSize(_:)` method ... you should update the scene's contents to match the new size."
3. The HIG tells games on iPhone Duo to "fill the screen as the device pose changes" and to "Prefer changing the aspect ratio over letterboxing or pillarboxing".
4. For the fold itself, SwiftUI offers `ArrangementView` (two views, kept on separate sides of the fold) and `GeometryProxy.reservedRegions(kind: .division)` (the fold's rectangle in the view's own coordinates). Both are iOS 27.1.
5. The hinge angle (`onHingeChange`) is for input and effects. Apple: "Don't use hinge updates for layout."

Inference (mine): the prototype should be a `SpriteView` holding one long-lived `SKScene` with `.resizeFill` and an `SKCameraNode`, re-fitting the camera in `didChangeSize(_:)`; the scene object should be owned by `@State` or a model object so SwiftUI does not rebuild it when size classes change. Section 9 lists what the prototype must log to confirm the parts Apple does not state.

---

## 1. SpriteKit sizing (question 1)

### 1.1 `SKScene.scaleMode`

Page: <https://developer.apple.com/documentation/spritekit/skscene/scalemode>

```swift
var scaleMode: SKSceneScaleMode { get set }
```

- "It is possible for a scene's size to differ from the size of the view it is presented in. The scale mode determines how the visible portion of the scene is mapped to the view."
- "The default value is `SKSceneScaleMode.fill`."

### 1.2 `SKSceneScaleMode` cases

Page: <https://developer.apple.com/documentation/spritekit/skscenescalemode> — `enum SKSceneScaleMode`, iOS 7.0. Four cases, each with its own page:

| Case | Apple's words | Page |
|---|---|---|
| `.fill` (default) | "Each axis of the scene is scaled independently so that each axis in the scene exactly maps to the length of that axis in the view." | <https://developer.apple.com/documentation/spritekit/skscenescalemode/fill> |
| `.aspectFill` | "The scaling factor of each dimension is calculated and the larger of the two is chosen. Each axis of the scene is scaled by the same scaling factor. This guarantees that the entire area of the view is filled but may cause parts of the scene to be cropped." | <https://developer.apple.com/documentation/spritekit/skscenescalemode/aspectfill> |
| `.aspectFit` | "The scaling factor of each dimension is calculated and the smaller of the two is chosen. Each axis of the scene is scaled by the same scaling factor. This guarantees that the entire scene is visible but may require letterboxing in the view." | <https://developer.apple.com/documentation/spritekit/skscenescalemode/aspectfit> |
| `.resizeFill` | "The scene is not scaled to match the view. Instead, the scene is automatically resized so that its dimensions always match those of the view." | <https://developer.apple.com/documentation/spritekit/skscenescalemode/resizefill> |

Inference: `.fill` (the default) stretches each axis separately, so a scene left at the default would distort when the view's aspect ratio changes between the outer and inner displays. The prototype must set `scaleMode` explicitly.

### 1.3 `SKScene.size`

Page: <https://developer.apple.com/documentation/spritekit/skscene/size>

```swift
var size: CGSize { get set }
```

- Abstract: "The dimensions of the scene, in points."
- "The size of the scene specifies the size of the visible portion of the scene in points."
- "If you set the size property to a new value, the scene's `didChangeSize(_:)` method is called. This property can also change if the `scaleMode` property is set to `SKSceneScaleMode.resizeFill` and the presenting view is resized. After the scene's size changes, future updates are rendered immediately at the new size."

Designated initialiser (<https://developer.apple.com/documentation/spritekit/skscene/init(size:)>): `init(size: CGSize)`, "The size of the scene in points."

### 1.4 `SKScene.didChangeSize(_:)`

Page: <https://developer.apple.com/documentation/spritekit/skscene/didchangesize(_:)>

```swift
func didChangeSize(_ oldSize: CGSize)
```

- Abstract: "Tells you when the scene's size has changed." Parameter: "The old size of the scene, in points."
- "This method is intended to be overridden in a subclass. Typically, you use this method to adjust the positions of nodes in the scene."

### 1.5 What Apple says a scene should do when its view changes size

Page: <https://developer.apple.com/documentation/spritekit/scaling-a-scene-s-content-to-fit-the-view>

- "Set the scene's `scaleMode` property to determine how it's sized according to the view that's displaying it. For example, in iOS, `scaleMode` determines the automatic resizing of your scene when the device changes orientation."
- Apple's three strategies, verbatim:
  - "Instantiate the scene with a constant size and never change it. Pick a scaling mode that lets the view scale the scene's content. This gives the scene a predictable coordinate system and frame. You can then base your art assets and gameplay logic on this coordinate system."
  - "Adjust the size of the scene in your game. Where necessary, adjust your game logic and art assets to match the scene's size."
  - "Set the `scaleMode` property to `SKSceneScaleMode.resizeFill`. SpriteKit automatically resizes the scene so that it always matches the view's size. Where necessary, adjust your game logic and art assets to match the scene's size."
- Under "Update Your Graphics on Scene Resize": "If you expect a scene's size to change at runtime, then the initial scene size should be used to determine which art assets to use, as well as any game logic that is dependent on the scene size. Your game should also override the scene's `didChangeSize(_:)` method, which is called whenever the scene changes size. When this method is called, you should update the scene's contents to match the new size."

Apple's Listing 1 on that page (constant-size scene):

```swift
func createSceneContent() {
    scene.scaleMode = .aspectFit
    scene.backgroundColor = .black
    // Add additional scene contents here.  
   ...
}
```

### 1.6 `didMove(to:)`, `willMove(from:)`, `sceneDidLoad()`

- <https://developer.apple.com/documentation/spritekit/skscene/didmove(to:)> — `func didMove(to view: SKView)`. "Tells you when the scene is presented by a view." "You can use this method to implement any custom behavior for your scene when it is about to be presented by a view. For example, you might use this method to create the scene's contents."
- <https://developer.apple.com/documentation/spritekit/skscene/willmove(from:)> — `func willMove(from view: SKView)`. "Tells you when the scene is about to be removed from a view."
- <https://developer.apple.com/documentation/spritekit/skscene/scenedidload()> — `func sceneDidLoad()`, iOS 10.0. "It is the preferred location to peform custom setup after the scene has been initialized or decoded." (Apple's spelling.)
- <https://developer.apple.com/documentation/spritekit/skscene/view> — `weak var view: SKView? { get }`. "If the scene is not currently presented, this property holds `nil`."

Not stated by Apple: whether `didMove(to:)` can be called a second time for the same scene object when SwiftUI rebuilds the `SpriteView`'s underlying view. Inference: build the node tree once (guard with a flag, or build it in `sceneDidLoad()` / the initialiser) so a second `didMove(to:)` is harmless.

### 1.7 Camera and anchor point (what "camera kept" depends on)

- <https://developer.apple.com/documentation/spritekit/skscene/camera> — `weak var camera: SKCameraNode? { get set }`, iOS 9.0. "The default value of this property is `nil`, which means that the scene's `anchorPoint` and `size` properties determine what portion of the scene is visible. If set to point to a camera node contained in the scene, the `anchorPoint` property is ignored and the scene is rendered using the camera node's properties instead." "A camera must be added as a child of the scene for it to render that scene."

Apple's listing on that page:

```swift
let cameraNode = SKCameraNode()
    
cameraNode.position = CGPoint(x: scene.size.width / 2,
                              y: scene.size.height / 2)
    
scene.addChild(cameraNode)
scene.camera = cameraNode
```

- <https://developer.apple.com/documentation/spritekit/skscene/anchorpoint> — `var anchorPoint: CGPoint { get set }`. "The default value is `(0,0)`, which corresponds to the lower-left corner of the view's frame rectangle."
- <https://developer.apple.com/documentation/spritekit/skscene/convertpoint(fromview:)> — `func convertPoint(fromView point: CGPoint) -> CGPoint`. "The scene must be presented in a view before calling this method."

Inference: with a camera node, the camera's position (which map tile is centred) is state held on a node in the scene. If the scene object survives the fold, the camera position survives with it; only the camera's scale needs recomputing in `didChangeSize(_:)` so the same amount of map stays visible.

### 1.8 `SKView`

Page: <https://developer.apple.com/documentation/spritekit/skview> — `class SKView`; inherits from `UIView` on iOS (from the page's relationship data, not checkable with `check_quote.py`).

- "You present a scene by calling the view's `presentScene(_:)` method. When a scene is presented by the view, it alternates between running its simulation (which animates the content) and rendering the content for display."
- `isPaused` (<https://developer.apple.com/documentation/spritekit/skview/ispaused>): `var isPaused: Bool { get set }`. "If the value is `true`, the scene's content is fixed onscreen. No actions are executed and no physics simulation is performed." "When an application moves from an active to an inactive state, `isPaused` is automatically set to `true`. When an application returns to an active state, `isPaused` is automatically set to its previous value."
- `preferredFramesPerSecond` (<https://developer.apple.com/documentation/spritekit/skview/preferredframespersecond>): `var preferredFramesPerSecond: Int { get set }`, iOS 10.0. "When your application sets its preferred frame rate, the view chooses a frame rate as close to that as possible based on the capabilities of the screen the view is displayed on." "The default value is 60 frames per second."
- `ignoresSiblingOrder` (<https://developer.apple.com/documentation/spritekit/skview/ignoressiblingorder>): "The default value is `false`, which means that when multiple nodes share the same z position, those nodes are sorted and rendered in a deterministic order."
- `shouldCullNonVisibleNodes` (<https://developer.apple.com/documentation/spritekit/skview/shouldcullnonvisiblenodes>): default `true`.
- `SKViewDelegate.view(_:shouldRenderAtTime:)` (<https://developer.apple.com/documentation/spritekit/skviewdelegate/view(_:shouldrenderattime:)>): "Return `true` to initiate an update and render for the target time. Return `false` to skip the update and render for the target time."
- `preferredFrameRate` and `frameInterval` are deprecated in favour of `preferredFramesPerSecond`.

---

## 2. `SpriteView` (question 2)

Page: <https://developer.apple.com/documentation/spritekit/spriteview> — iOS 14.0.

```swift
@MainActor @preconcurrency struct SpriteView
```

Abstract: "A SwiftUI view that renders a SpriteKit scene." Conforms to `View` and `Sendable` (relationship data).

**Apple gives no prose at all for the initialisers, `Options` or `DebugOptions`: every abstract is empty.** What follows is declarations only.

Three initialisers:

```swift
// iOS 14.0 (also watchOS 7.0)
nonisolated init(scene: SKScene,
                 transition: SKTransition? = nil,
                 isPaused: Bool = false,
                 preferredFramesPerSecond: Int = 60)

// iOS 14.0 (not watchOS)
@preconcurrency nonisolated init(scene: SKScene,
                 transition: SKTransition? = nil,
                 isPaused: Bool = false,
                 preferredFramesPerSecond: Int = 60,
                 options: SpriteView.Options = [.shouldCullNonVisibleNodes],
                 shouldRender: @escaping @MainActor (TimeInterval) -> Bool = { _ in true })

// iOS 15.0
@preconcurrency nonisolated init(scene: SKScene,
                 transition: SKTransition? = nil,
                 isPaused: Bool = false,
                 preferredFramesPerSecond: Int = 60,
                 options: SpriteView.Options = [.shouldCullNonVisibleNodes],
                 debugOptions: SpriteView.DebugOptions,
                 shouldRender: @escaping @MainActor (TimeInterval) -> Bool = { _ in true })
```

(Line breaks added by me; the token text is Apple's. Pages: <https://developer.apple.com/documentation/spritekit/spriteview/init(scene:transition:ispaused:preferredframespersecond:)>, <https://developer.apple.com/documentation/spritekit/spriteview/init(scene:transition:ispaused:preferredframespersecond:options:shouldrender:)>, <https://developer.apple.com/documentation/spritekit/spriteview/init(scene:transition:ispaused:preferredframespersecond:options:debugoptions:shouldrender:)>.)

Notes on the parameters:

- `debugOptions` has **no default** in the third initialiser, so it must be passed when that initialiser is used.
- `preferredFramesPerSecond` defaults to **60**. See section 7.1 for 120 Hz.
- `SpriteView.Options` (<https://developer.apple.com/documentation/spritekit/spriteview/options>), `struct Options`, iOS 14.0. Type properties: `allowsTransparency`, `ignoresSiblingOrder`, `shouldCullNonVisibleNodes`, each `static let ...: SpriteView.Options`.
- `SpriteView.DebugOptions` (<https://developer.apple.com/documentation/spritekit/spriteview/debugoptions>), `struct DebugOptions`, iOS 14.0. Type properties: `showsDrawCount`, `showsFPS`, `showsFields`, `showsNodeCount`, `showsPhysics`, `showsQuadCount`, each `static let ...: SpriteView.DebugOptions`.

Inference: the names match the `SKView` properties of the same names (`isPaused`, `preferredFramesPerSecond`, `ignoresSiblingOrder`, `shouldCullNonVisibleNodes`, `allowsTransparency`, `showsFPS` ...) and `shouldRender` matches `SKViewDelegate.view(_:shouldRenderAtTime:)`, so the `SKView` descriptions in 1.8 are the best available description of what they do. Apple does not say this on the `SpriteView` pages.

Not stated by Apple anywhere I could find: how `SpriteView` sizes its scene (the scene's `scaleMode` is presumably honoured as in any `SKView`), whether SwiftUI keeps the same underlying `SKView` across layout changes, and how touches reach the scene. The prototype has to observe these.

---

## 3. SwiftUI iPhone Duo layout APIs (question 3)

All of the types and modifiers in 3.1 to 3.4 show **iOS 27.1** in their page metadata (the pages also list iPadOS, Mac Catalyst, macOS, tvOS, visionOS and watchOS 27.1). Apple says the same in the talks: "And in iOS 27.1, you can use system-provided arrangements in your own apps." (111463) and "Lastly, in iOS 27.1, we're introducing a new API that lets your custom UI use as much of the available screen space as possible without colliding with system-provided UI." (111461, about reserved regions). So the deployment target of the prototype must be iOS 27.1 or later, or every use needs `if #available(iOS 27.1, *)`.

### 3.1 `ArrangementView`

Page: <https://developer.apple.com/documentation/swiftui/arrangementview>

```swift
nonisolated struct ArrangementView<Primary, Secondary> where Primary : View, Secondary : View

nonisolated init(@ContentBuilder primary: () -> Primary, @ContentBuilder secondary: () -> Secondary)
nonisolated init(_ configuration: ArrangementViewStyleConfiguration)   // for custom styles
```

- Abstract: "A view that dynamically lays out a primary and secondary view based on size class, orientation, and reserved regions."
- Default style: "By default, the arrangement view uses an automatic style, which resolves to a split arrangement." (<https://developer.apple.com/documentation/swiftui/arrangementview/init(primary:secondary:)>)
- Where it may sit: "Because an arrangement view is a container that lays out other views, avoid adding an arrangement view inside another container such as a scroll view, navigation split view, grid, or other container view that lays out other views. Also avoid placing some container views inside an arrangement view, such as a navigation split view or tab view."
- "When iPhone Duo is fully open or closed, people interact with the flat display like other iPhone and iPad models."
- Note `@ContentBuilder`, not `@ViewBuilder`. SwiftUI updates page, June 2026: `ContentBuilder` "serves as the unified replacement for type-specific builders" when built with Xcode 27 or later.

**Split style** — where each view goes:

- "a split arrangement view always keeps its primary and secondary views in separate spaces"
- "In portrait orientation, the arrangement view places the primary view in the top position and the secondary view in the bottom position."
- "In landscape orientation, the arrangement view places the primary view in the leading position and the secondary view in the trailing position."
- "When someone is holding a closed iPhone Duo in landscape orientation, the split arrangement only shows the primary view."
- Overview article wording: "In a split arrangement, the arrangement view presents the primary and secondary views side by side when the containing view is wider than it is tall; or it places the primary view on top and the secondary view below it when the containing view is taller than it is wide." (<https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>)

**Overlay style** — where each view goes:

- "In a stacked overlay arrangement, the arrangement view places the primary view above the secondary view in the z-axis."
- "When someone holds a folded iPhone Duo in portrait orientation, the arrangement view places the secondary view in the top position and the primary view in the bottom position."
- "When someone holds a folded iPhone Duo in landscape orientation, the arrangement view places the secondary view in the leading position and the primary view in the trailing position."
- Overview article: "In an overlay arrangement, the arrangement view positions the primary view on top of the secondary view when there aren't any active reserved regions that are divisions. This is true when iPhone Duo is closed or fully open." and "When iPhone Duo is partially open, the overlay arrangement places the primary view in the trailing or bottom part of the display relative to the fold, and the secondary view in the leading or top part of the display relative to the fold."

Inference for this game (map + controls): the two styles put the views in **opposite** places when the phone is folded like a laptop.

| Style | Flat (open or closed) | Folded, fold horizontal (laptop; Apple's "portrait") | Folded, fold vertical (book; Apple's "landscape") |
|---|---|---|---|
| `.split` | Two separate areas, equal by default: top/bottom in portrait, leading/trailing in landscape. Exception: closed in landscape shows the primary view only | primary top, secondary bottom | primary leading, secondary trailing |
| `.overlay` | primary drawn over secondary | secondary top, primary bottom | secondary leading, primary trailing |

(The table equates Apple's "portrait"/"landscape" wording with the laptop and book folds. That mapping is mine; it follows from the `ReservedRegion` page saying a laptop-style fold "runs horizontally" and puts content "above and below the fold".)

So "map on top, controls on the bottom" is `primary = map` with `.split`, or `primary = controls, secondary = map` with `.overlay`. With `.split` the map shares the display with the controls even when the phone is flat (unless the axes are restricted, in which case only the primary view shows); with `.overlay` the map fills the display when flat and the controls float over it, which is Apple's own "video player with playback controls" example. Which one suits the game is a design decision; RESEARCH.md 3.2 only mentions split.

Apple's three listings on the `ArrangementView` page (overlay, split, limit by axis):

```swift
ArrangementView {
    PlayerControls()
} secondary: {
    VideoPlayer()
}
.arrangementViewStyle(.overlay)
```

```swift
ArrangementView {
    NowPlayingView()
} secondary: {
    LyricsView()
}
.arrangementViewStyle(.split)
```

```swift
ArrangementView {
    PrimaryContent()
} secondary: {
    SecondaryContent()
}
.arrangementViewStyle(.split.axes(.vertical))
```

### 3.2 `arrangementViewStyle(_:)`, `ArrangementViewStyle`, `axes(_:)`

- <https://developer.apple.com/documentation/swiftui/view/arrangementviewstyle(_:)>

```swift
nonisolated func arrangementViewStyle(_ style: some ArrangementViewStyle) -> some View
```

  "Sets the style for arrangement views within this view."

- <https://developer.apple.com/documentation/swiftui/arrangementviewstyle> — `@MainActor @preconcurrency protocol ArrangementViewStyle`. Static members:

```swift
@export(implementation) nonisolated static var automatic: AutomaticArrangementViewStyle { get }
@export(implementation) nonisolated static var split: SplitArrangementViewStyle { get }
@export(implementation) nonisolated static var overlay: OverlayArrangementViewStyle { get }
```

  `automatic`: "When you specify this style, the arrangement view uses `SplitArrangementViewStyle`."
  `split`: "The split arrangement adapts its layout axis based on the available size and size class."

- `axes(_:)`:

```swift
// SplitArrangementViewStyle
nonisolated func axes(_ axes: Axis.Set) -> SplitArrangementViewStyle
// OverlayArrangementViewStyle
nonisolated func axes(_ axes: Axis.Set) -> OverlayArrangementViewStyle
```

  "For axes that you don't include, the arrangement only displays the primary view." (<https://developer.apple.com/documentation/swiftui/splitarrangementviewstyle/axes(_:)>). Usage: `.arrangementViewStyle(.split.axes(.vertical))`.

- Talk 111463 on the default axis: "By default, it splits horizontally when the view is wider than it is tall" and "If the split arrangement cannot split among an axis, and it's the primary axis, the arrangement view chooses to only show a single view."

### 3.3 Split sizing and the split axis

- Default: "By default, a split arrangement view sizes the primary and secondary views equally when a display has one region." (<https://developer.apple.com/documentation/swiftui/splitarrangementviewstyle>)

```swift
nonisolated func splitArrangementLayoutRatio(_ ratio: CGFloat?) -> some View

nonisolated func splitArrangementLayoutRatio(minHorizontal: CGFloat? = nil, idealHorizontal: CGFloat? = nil, maxHorizontal: CGFloat? = nil,
                                             minVertical: CGFloat? = nil, idealVertical: CGFloat? = nil, maxVertical: CGFloat? = nil) -> some View

nonisolated func splitArrangementLayoutSize(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil,
                                            minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) -> some View

nonisolated func splitArrangementFixedLayoutSize(horizontal: Bool = true, vertical: Bool = true) -> some View
```

  (Line breaks added by me.) Pages: <https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(_:)>, <https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutratio(minhorizontal:idealhorizontal:maxhorizontal:minvertical:idealvertical:maxvertical:)>, <https://developer.apple.com/documentation/swiftui/view/splitarrangementlayoutsize(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:)>, <https://developer.apple.com/documentation/swiftui/view/splitarrangementfixedlayoutsize(horizontal:vertical:)>.

  - Ratio parameter: "A float value between zero and one that indicates the ratio the view uses for its preferred size."
  - "The arrangement sizes the view with the highest `layoutPriority` using its ratio. When a view has a ratio that would be greater than the remaining size of the arrangement view container, the arrangement uses the remaining size instead."
  - Size: "The arrangement applies width constraints to horizontal arrangement layouts, and height constraints to vertical arrangement layouts." Values are in points.
  - These modifiers go on the primary or secondary view inside the `ArrangementView`, as in Apple's example:

```swift
ArrangementView {
    PrimaryContent()
        .splitArrangementLayoutRatio(0.3)
} secondary: {
    SecondaryContent()
}
```

  Not stated: what the ratio does while the fold is active. The sentence above says the equal default applies "when a display has one region"; talk 111463 says that for a split view the system positions columns "into an even 50/50 split" around the fold. Whether a custom ratio is ignored when the device is folded must be tested.

- `splitArrangementAxis` environment value (<https://developer.apple.com/documentation/swiftui/environmentvalues/splitarrangementaxis>):

```swift
var splitArrangementAxis: Axis? { get set }
```

  "Use this value to read the axis that a split arrangement is using to place its views. ... The value is `nil` when the view is not contained within a split arrangement view." Apple's listing:

```swift
struct DetailsView: View {
    @Environment(\.splitArrangementAxis) var axis

    var body: some View {
        let layout: AnyLayout = axis == .horizontal
            ? AnyLayout(VStackLayout())
            : AnyLayout(HStackLayout())
        layout {
            Artwork()
            Metadata()
        }
    }
}
```

- Overlay extras: `overlayArrangementEdge(_ edge: HorizontalEdge?)` and `overlayArrangementEdge(_ edge: VerticalEdge?)` move the primary view to the other side when folded; `@Environment(\.overlayArrangementZIndex)` (`var overlayArrangementZIndex: Int { get set }`) tells a view whether it is currently layered (see the talk snippet in 5.1).

### 3.4 `ReservedRegion` and `GeometryProxy.reservedRegions(kind:options:layoutDirectionBehavior:)`

Pages: <https://developer.apple.com/documentation/swiftui/reservedregion>, <https://developer.apple.com/documentation/swiftui/geometryproxy/reservedregions(kind:options:layoutdirectionbehavior:)>

```swift
struct ReservedRegion        // Equatable, Hashable, Identifiable, Sendable (relationship data)

func reservedRegions(kind: ReservedRegion.Kind,
                     options: ReservedRegion.QueryOptions = [],
                     layoutDirectionBehavior: LayoutDirectionBehavior = .mirrors) -> [ReservedRegion]

// ReservedRegion members
var id: ReservedRegion.ID { get }
var kind: ReservedRegion.Kind { get }
var frame: CGRect { get }
var margins: EdgeInsets { get }
var isActive: Bool { get }

// ReservedRegion.Kind (a struct)
static var occlusion: ReservedRegion.Kind { get }
static var division: ReservedRegion.Kind { get }

// ReservedRegion.QueryOptions (@frozen struct)
static var includeInactive: ReservedRegion.QueryOptions { get }
```

Behaviour, in Apple's words:

- "The method returns only the regions that overlap your view, including a partial overlap."
- "By default, the method returns only active regions that currently affect your view."
- "The frame uses your view's own coordinates, not the screen's: `(0, 0)` is the view's top-leading corner, and the values are in points. The frame already includes the region's `margins`".
- **When the fold is active:** "A division is active only when the device is partially open or closed. When iPhone Duo is fully open, the division is inactive, so `reservedRegions(kind:options:layoutDirectionBehavior:)` returns no division regions."
- `isActive` page: "For example, the fold of iPhone Duo is active when the device is partially open, and inactive when it's fully open."
- Talk 111463: "On iPhone Duo, the fold's division region is only active when someone has folded the device. When flat, it's inactive and has a width of zero."
- **Direction of the fold:** "When you partially fold iPhone Duo like a book, the fold runs vertically at the center of the display, so your content sits side by side. When you partially fold it like a laptop, the fold runs horizontally across the center of the display, so your content stacks above and below the fold."
- "When a division is active, content that crosses it is hard to read and use, so keep each view entirely on one side of the division."
- "An inactive region still has a frame, so you can leave room for it."
- "The inner camera is active only while the camera is in use, and the outer camera is always active."
- "If your layout is a grid, use an even number of columns so your content divides cleanly at the fold."
- When to use which: "If your content is two related views that sit side by side or one above the other, use `ArrangementView` instead of reading the division yourself."

**A contradiction in Apple's own text about the closed state.** The `ReservedRegion` page (and the UIKit `UIView.ReservedRegion` page) say the division is active "when the device is partially open or closed". The overview article says there are no active division regions "when iPhone Duo is closed or fully open". The `isActive` page and the talk only mention partially open versus fully open. Inference: this probably does not matter in practice, because when the phone is closed the app is on the outer display, which has no fold, and the query "returns only the regions that overlap your view". The prototype should print the result of `reservedRegions(kind: .division, options: .includeInactive)` in all three states to settle it.

Apple's division example (it finds the fold's direction by comparing the frame's width and height):

```swift
struct SplitContent: View {
    var body: some View {
        GeometryReader { proxy in
            if let division = proxy.reservedRegions(kind: .division).first {
                let frame = division.frame
                if frame.height > frame.width {
                    // The division runs vertically, so split side by side.
                    HStack(spacing: 0) {
                        FirstPane()
                            .frame(width: frame.minX)
                        Color.clear
                            .frame(width: frame.width)
                        SecondPane()
                            .frame(width: proxy.size.width - frame.maxX)
                    }
                } else {
                    // The division runs horizontally, so stack the panes.
                    VStack(spacing: 0) {
                        FirstPane()
                            .frame(height: frame.minY)
                        Color.clear
                            .frame(height: frame.height)
                        SecondPane()
                            .frame(height: proxy.size.height - frame.maxY)
                    }
                }
            } else {
                // Lay out your content as a single region.
                FirstPane()
            }
        }
    }
}
```

Including inactive regions:

```swift
let regions = proxy.reservedRegions(
    kind: .occlusion,
    options: .includeInactive)
```

Other listings on the page (occlusion regions: count, keep a top bar clear, custom layout):

```swift
struct RegionReader: View {
    var body: some View {
        GeometryReader { proxy in
            let regions = proxy.reservedRegions(kind: .occlusion)
            Text("Occlusion regions: \(regions.count)")
        }
    }
}
```

```swift
struct TopControls: View {
    private let barHeight: CGFloat = 60

    var body: some View {
        GeometryReader { proxy in
            let regions = proxy.reservedRegions(kind: .occlusion)
            let barFrame = CGRect(
                x: 0, y: 0, width: proxy.size.width, height: barHeight)
            let topInset = regions
                .filter { $0.frame.intersects(barFrame) }
                .map(\.frame.maxY)
                .max() ?? 0

            ControlBar()
                .frame(height: barHeight)
                .padding(.top, topInset)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
```

```swift
GeometryReader { proxy in
    RegionAvoidingLayout(
        regions: proxy.reservedRegions(kind: .occlusion)
    ) {
        ForEach(items) { item in
            ItemView(item)
        }
    }
}
```

Inference for a SpriteKit map: the scene is one view, so SwiftUI cannot split it. Either (a) put the `SpriteView` in an `ArrangementView` so the whole map sits on one side of the fold, or (b) let the map span the fold and pass the division's frame into the scene so that no tile row or column straddles it (Apple's "even number of columns" rule, applied to a 16 × 12 map: both dimensions are even, so the fold can fall on a tile boundary if the map is centred on it). For (b) the frame is in SwiftUI's top-leading coordinates in points and must be converted to scene coordinates (`convertPoint(fromView:)`); SpriteKit's y axis points up.

Because `ReservedRegion` is `Equatable` and `Sendable`, and `CGRect` is too, the division can be observed without a `GeometryReader` wrapper through `onGeometryChange(for:of:action:)` (iOS 16.0), which the talk names as a valid source of the proxy: "In SwiftUI, you query reserved regions using a GeometryProxy from a GeometryReader or onGeometryChange modifier."

```swift
@export(implementation) @preconcurrency nonisolated
func onGeometryChange<T>(for type: T.Type,
                         of transform: @escaping @Sendable (GeometryProxy) -> T,
                         action: @escaping (T) -> Void) -> some View where T : Equatable, T : Sendable
```

### 3.5 `onHingeChange(isEnabled:_:)`, `DeviceHingeContext`, `DeviceHinge`

Pages: <https://developer.apple.com/documentation/swiftui/view/onhingechange(isenabled:_:)>, <https://developer.apple.com/documentation/swiftui/devicehingecontext>, <https://developer.apple.com/documentation/swiftui/devicehinge>. All iOS 27.1.

```swift
nonisolated func onHingeChange(isEnabled: Bool = true,
                               _ action: @escaping (DeviceHingeContext, DeviceHingeContext) -> Void) -> some View

struct DeviceHingeContext {          // Equatable, Sendable
    var hinge: DeviceHinge?
}

struct DeviceHinge {                 // Equatable, Hashable, Sendable
    var angle: Angle                 // SwiftUI.Angle
    var status: DeviceHinge.Status
}

// DeviceHinge.Status is a struct, not an enum
static var closed: DeviceHinge.Status { get }          // "The hinge is closed."
static var partiallyOpen: DeviceHinge.Status { get }   // "The hinge is partially open."
static var fullyOpen: DeviceHinge.Status { get }       // "The hinge is open as far as the device allows."
```

- "SwiftUI calls `action` with the initial hinge context, and again whenever the context changes. When `isEnabled` becomes `false`, if the last context `action` received had a hinge, SwiftUI calls `action` once more with no hinge."
- The closure's two arguments: "the previous hinge context and the current." (talk 111464)
- `hinge` is `nil` on a device without a hinge: "A null value indicates the app is running on a device without a hinge." (talk 111464)
- **Unit of the angle.** In SwiftUI the property is `var angle: Angle`; `Angle` is "A geometric angle whose value you access in either radians or degrees." (`.radians`, `.degrees`). In UIKit, `UIHinge.angle` is `var angle: CGFloat { get }`, "The current angle of the hinge, in radians."
- "The rate and granularity of angle updates are system policy and can change based on system state, so don't depend on a particular update frequency or precision. If you only need to know whether the hinge is closed, partially open, or fully open, prefer `status` over the angle."
- "A hinge provides its angle along with a status determined by the system based on the current angle and device orientation."
- What it is for: "Use hinge updates when your app treats the hinge as input, such as driving an animation that responds to granular hinge angle changes, controlling a game, or showing the current angle. Hinge updates arrive while the hinge is moving, at a pace the system sets."
- What it is not for: "Don't use hinge updates for layout. To adapt your layout to the fold, use `ArrangementView` or `ReservedRegion` instead. Reserved region updates arrive during a layout pass, which might be animated."
- UIKit differs slightly: `UIHinge.Status` is an `enum` with a fourth case, `unknown` ("The status of the hinge is unknown"). The SwiftUI struct lists only three values.

Inference: because `DeviceHinge.Status` is a struct with static values, a Swift `switch` over it needs a `default` case; `==` works (it is `Equatable`, and Apple's talk code uses `hinge.status == .partiallyOpen`).

Not stated: which angle corresponds to closed and which to fully open (0 and π, or something else). Print `hinge.angle.degrees` in the simulator while dragging the fold slider to find out.

Apple's listing on the `onHingeChange` page:

```swift
@State private var hinge: DeviceHinge? = nil

var body: some View {
    VStack {
        if let hinge {
            AngleDisplayView(angle: hinge.angle)
            StatusDisplayView(status: hinge.status)
        } else {
            ContentUnavailableView(
                "Hinge Unavailable",
                systemImage: "rectangle.split.2x1")
        }
    }
    .onHingeChange { _, newContext in
        hinge = newContext.hinge
    }
}
```

---

## 4. Size classes (question 4)

- <https://developer.apple.com/documentation/swiftui/environmentvalues/horizontalsizeclass> and <https://developer.apple.com/documentation/swiftui/environmentvalues/verticalsizeclass>, iOS 13.0:

```swift
@backDeployed(before: macOS 14.0, tvOS 17.0, watchOS 10.0)
var horizontalSizeClass: UserInterfaceSizeClass? { get set }

@backDeployed(before: macOS 14.0, tvOS 17.0, watchOS 10.0)
var verticalSizeClass: UserInterfaceSizeClass? { get set }

// reading them
@Environment(\.horizontalSizeClass) private var horizontalSizeClass
@Environment(\.verticalSizeClass) private var verticalSizeClass
```

  `enum UserInterfaceSizeClass` has `.compact` and `.regular`. Both values are optionals.
  "be prepared to handle size class changes while your app runs, because factors like device orientation can change at runtime."

- What each iPhone Duo display reports (talk 111461):
  - Outer: "On the outer display, like other iPhone models, iPhone Duo has regular vertical size class and compact horizontal size class in portrait, and compact vertical and horizontal size classes in landscape."
  - Inner: "On the inner display, the additional space lets you show more content like sidebars. As such, it has regular horizontal and vertical size classes."

| Display | Orientation | Horizontal | Vertical |
|---|---|---|---|
| Outer | portrait | compact | regular |
| Outer | landscape | compact | compact |
| Inner | any (as stated) | regular | regular |

- Caveats from Apple's "Three steps" page: "Don't treat "regular width" as "iPad."" and "To find out whether your app is wider than it is tall, compare the width and height of the space you have". Also: "With iPhone Duo and resizable iPhone Mirroring, an iPhone app can have any combination of size classes."

Not stated: the size classes of an app occupying half of the inner display in Split View multitasking. The statements above describe the full display.

---

## 5. Tech Talk code and key statements (question 5)

### 5.1 "Strike a pose with adaptive layouts on iPhone Duo" (111463)

<https://developer.apple.com/videos/play/tech-talks/111463/>

Key statements:

- "On iPhone Duo, the fold's division region is only active when someone has folded the device. When flat, it's inactive and has a width of zero."
- "You can use inactive regions to make high-level decisions about your app. For example, in grid-like layouts, you could prefer even numbers of columns when a division region is present regardless of its active state."
- "By default, it splits horizontally when the view is wider than it is tall" ... "If I rotate the device, the split style will split vertically since the view's now taller than it is wide."
- "If the split arrangement cannot split among an axis, and it's the primary axis, the arrangement view chooses to only show a single view."
- "Unlike the split, which prefers to position content side by side, the overlay arrangement prefers to position content above or below each other." (meaning layered) "Now if I fold the device, the overlay arrangement prefers to position the primary and secondary views side by side."
- Tabletop pose: "The top region works well for content that benefits from visibility at a distance." "The bottom region works well for interactive controls."
- Restrictions: "avoid putting navigation containers like NavigationSplitViews inside of an ArrangementView. And due to the nature of views like List and ScrollView, avoid putting ArrangementViews inside of these scrollable containers."
- An arrangement's inputs: "the horizontal and vertical size class of the view, the aspect ratio of the view's width over its height, and whether there are any active division regions."

All code shown on the page:

#### 6:46 - Query reserved regions in SwiftUI
```swift
// SwiftUI
GeometryReader { proxy in
  let regions = proxy.reservedRegions(
    kind: .division)
}
```

#### 7:03 - Query reserved regions in UIKit
```swift
// UIKit
let regions = view.reservedRegions(
  kind: .division)

// Query the frame to incorporate it into your own layout
let frames = regions.map(\.frame)
```

#### 7:22 - Include inactive regions
```swift
// SwiftUI
GeometryReader { proxy in
  let regions = proxy.reservedRegions(
    kind: .division, options: .includeInactive)

  let frames = regions.map(\.frame)
  // ...
}
```

#### 8:07 - Query occlusion regions
```swift
// SwiftUI
GeometryReader { proxy in
  let regions = proxy.reservedRegions(
    kind: .occlusion)

  let frames = regions.map(\.frame)
  // ...
}
```

#### 11:23 - Add an ArrangementView
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      PlayerView()
    } secondary: {
      UpNextView()
    }
  }
}
```

#### 11:26 - Add a UIArrangementViewController
```swift
// UIKit
let arrangementVC = UIArrangementViewController()
let navController = UINavigationController(rootViewController: arrangementVC)

let playerVC = PlayerViewController()
arrangementVC.setViewController(playerVC, for: .primary)

let upNextVC = UpNextViewController()
arrangementVC.setViewController(upNextVC, for: .secondary)
```

#### 12:00 - Specify the split arrangement style
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      PlayerView()
    } secondary: {
      UpNextView()
    }
    .arrangementViewStyle(.split)
  }
}
```

#### 12:41 - Restrict the split to one axis
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      PlayerView()
    } secondary: {
      UpNextView()
    }
    .arrangementViewStyle(
      .split.axes(.horizontal))
  }
}
```

#### 13:07 - Update the arrangement in UIKit
```swift
// UIKit
let arrangementVC = UIArrangementViewController()

// ...

arrangementVC.updateArrangement(.split.axes(.horizontal))
```

#### 13:26 - Switch to the overlay arrangement
```swift
// SwiftUI
var body: some View {
  NavigationStack {
    ArrangementView {
      UpNextView()
    } secondary: {
      PlayerView()
    }
    .arrangementViewStyle(.overlay)
  }
}
```

#### 14:07 - Respond to the overlay Z index
```swift
// SwiftUI
enum UpNextMinimization {
  case collapsed; case expanded
}

struct UpNextView: View {
  @Environment(\.overlayArrangementZIndex)
  private var zIndex: Int

  var body: some View {
    UpNextList(minimization: minimization)
  }

  var minimization: UpNextMinimization {
    zIndex > 0 ? .collapsed : .expanded
  }
}
```

#### 14:21 - Read the Z index in UIKit
```swift
// UIKit
let arrangementVC = UIArrangementViewController()

// ...

let primaryState = arrangementVC.state(for: .primary)
myModel.minimization = (primaryState?.zIndex ?? 0) > 0
  ? .collapsed : .expanded
```

### 5.2 "Leverage multiple displays and scenes on iPhone Duo" (111464)

<https://developer.apple.com/videos/play/tech-talks/111464/>

Key statements:

- "SwiftUI provides a new onHingeChange modifier, and UIKit provides UIHingeInteraction. Both give you access to the high-level hinge status of: closed, partially open, and fully open. Beyond the discrete status, it provides continuous updates of the hinge angle."
- "Hinge data is observed live, and is ideal for driving interactions or effects. For layout, use the arrangement and region APIs."
- "All apps participate in multitasking on iPhone Duo, where two apps can be placed in a side-by-side layout."
- "On the outer display of iPhone Duo, new windows cannot be created. That behavior is reserved for the inner display."
- The talk says nothing about what happens to an existing scene's object or state when the device opens or closes.

All code shown on the page:

#### 1:33 - Hold pitch bend as state
```swift
struct InstrumentView: View {
    /// Normalized bend, 0 is no bend, 1 is deepest bend
    @State private var pitchBend: Double = 0

    var body: some View {
        GuitarView(pitchBend: pitchBend)
    }
}
```

#### 1:44 - Add the onHingeChange modifier
```swift
struct InstrumentView: View {
    /// Normalized bend, 0 is no bend, 1 is deepest bend
    @State private var pitchBend: Double = 0

    var body: some View {
        GuitarView(pitchBend: pitchBend)
            .onHingeChange { _, context in

            }
    }
}
```

#### 1:57 - Check for a hinge and the partially open state
```swift
var body: some View {
    GuitarView(pitchBend: pitchBend)
        .onHingeChange { _, context in
            // A null hinge means the device doesn't have one
            if let hinge = context.hinge, hinge.status == .partiallyOpen {

            }
        }
}
```

#### 2:10 - Reset the pitch bend
```swift
var body: some View {
    GuitarView(pitchBend: pitchBend)
        .onHingeChange { _, context in
            if let hinge = context.hinge, hinge.status == .partiallyOpen {

            }
            else {
                pitchBend = 0
            }
        }
}
```

#### 2:17 - Calculate the pitch bend from the hinge angle
```swift
struct InstrumentView: View {
    /// Normalized bend, 0 is no bend, 1 is deepest bend
    @State private var pitchBend: Double = 0

    var body: some View {
        GuitarView(pitchBend: pitchBend)
            .onHingeChange { _, context in
                if let hinge = context.hinge, hinge.status == .partiallyOpen {
                    pitchBend = calculatePitchBend(angle: hinge.angle)
                }
                else {
                    pitchBend = 0
                }
            }
    }

    private func calculatePitchBend(angle: Angle) -> Double { ... }
}
```

#### 5:43 - Register a camera capture accessory
```swift
struct CameraRootView: View {
    @State private var model = TeleprompterModel()

    var body: some View {
        CameraView(model: model)
            .sceneAccessory {
                CameraCaptureAccessory {
                    TeleprompterView(model: model)
                }
            }
    }
}
```

#### 6:14 - Add a toolbar toggle
```swift
struct CameraRootView: View {
    @State private var model = TeleprompterModel()

    var body: some View {
        CameraView(model: model)
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $model.isEnabled) {
                    TeleprompterView(model: model)
                }
            }
            .toolbar {
                TeleprompterToggle(isEnabled: $model.isEnabled)
            }
    }
}
```

#### 6:25 - Observe accessory availability
```swift
struct CameraRootView: View {
    @State private var model = TeleprompterModel()

    var body: some View {
        CameraView(model: model)
            .sceneAccessory {
                CameraCaptureAccessory(isEnabled: $model.isEnabled) {
                    TeleprompterView(model: model)
                }
                .onAvailabilityChange { newValue in
                    model.isAvailable = newValue
                }
            }
            .toolbar {
                TeleprompterToggle(isEnabled: $model.isEnabled)
                    .disabled(!model.isAvailable)
            }
    }
}
```

### 5.3 "Prepare your app for iPhone Duo" (111461) — code shown

<https://developer.apple.com/videos/play/tech-talks/111461/>

#### 2:59 - Read size classes
```swift
// SwiftUI
@Environment(\.horizontalSizeClass)
private var horizontalSizeClass

@Environment(\.verticalSizeClass)
private var verticalSizeClass

// UIKit
traitCollection.horizontalSizeClass
traitCollection.verticalSizeClass
```

#### 4:16 - Access the screen from the window scene
```swift
// Avoid referencing the main screen on a two-display device.
// Access the screen dynamically from the window scene instead.
let screen = window?.windowScene?.screen
```

#### 4:30 - Match the screen corners with Concentricity
```swift
// SwiftUI
ConcentricRectangle()
    .fill(Color.green)
    .padding(8.0)
    .ignoresSafeArea()

// UIKit
// UICornerConfiguration
```

#### 5:44 - Show a sidebar on the inner display
```swift
// SwiftUI
TabView { … }
    .defaultTabBarPlacement(.sidebar)

// UIKit
tabBarController.sidebar.preferredPlacement = .sidebar
```

#### 6:52 - Align foreground content to the safe area
```swift
// UIKit
foreground.frame = view.bounds.inset(by: view.safeAreaInsets)
```

#### 7:07 - Let background content extend past the safe area
```swift
// SwiftUI
.ignoresSafeArea()

// UIKit
backgroundView.frame = view.bounds
```

#### 7:30 - Handle asymmetric safe area insets
```swift
// Avoid assuming insets on opposite sides are equal
let width = view.bounds.width - view.safeAreaInsets.left * 2

// Handle each side independently
let width = view.bounds.inset(by: view.safeAreaInsets).width
```

#### 9:25 - Replace main screen references
```swift
func updateThumbnail(from image: UIImage) {
    // Before
    let screenScale = UIScreen.main.scale

    // After
    let screenScale = traitCollection.displayScale
    // ...
}
```

---

## 6. Continuity between displays (question 6)

### 6.1 Everything Apple says, by source

**Tech Talk 111461** (<https://developer.apple.com/videos/play/tech-talks/111461/>)

- "With iOS 27, people can resize your app larger than ever before using iPhone Mirroring on the Mac. Opening and closing iPhone Duo works the same way. Your app may react to different size class boundaries, but it is still an iPhone app."
- "These principles matter more than ever for iPhone Duo, as your app will need to resize to fit every pose, opened, closed, rotated, or folded."
- "On a device with two displays, avoid referencing the main screen in your code. It's ambiguous and will be deprecated in a future release. If possible, don't use screen references at all. Instead, use more local concepts like the environment, trait collection, or the scene's bounds. If you need access to the screen, access it dynamically from the window scene."
- "iPhone Duo will continue to honor the UIRequiresFullScreen key, but your app will still resize when someone opens or closes their iPhone Duo."

**"Three steps to make your app shine on iPhone Duo"** (<https://developer.apple.com/iphone-duo/prepare/>)

- "Apps built with the iOS 27 SDK and later resize dynamically on iPhone Duo. Unfold it and your app expands to fill the inner display; fold it and your app returns to the outer display."
- "On iPhone Duo, your app's size changes whenever the device folds or unfolds, and it doesn't always match the size of the screen."
- "Re-read the size whenever it changes. Reading the size once at launch or in viewIsAppearing isn't enough, because a fold can resize your app in the middle of a session."
- "Size from the view or window. ... In SwiftUI, use GeometryReader or onGeometryChange."
- "Get scale from the trait collection. Use traitCollection.displayScale in UIKit or @Environment(\.displayScale) in SwiftUI."
- "Don't store a UIScreen. When screen information is needed, access it dynamically with view.window?.windowScene?.screen."

**"Preparing your app for iPhone Duo"** (<https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo>)

- "As iPhone Duo is opened, closed, partially folded, and rotated, content transitions between displays and adjusts for rotated positions."
- "Resizing is a key feature for your app on iPhone Duo."
- "Make layout calculations based on your scene or containing view's bounds rather than screen dimensions."
- In the camera section: "When a person opens, closes, and rotates the phone, your app may change which display it's on".

**WWDC26 session 278, "Modernize your UIKit app"** (<https://developer.apple.com/videos/play/wwdc2026/278/>) — about iPhone Mirroring and iPad, recorded before iPhone Duo was announced:

- "when your iPhone app is mirrored on a Mac, or when a person moves your app to an external display on the iPad, the screen associated with your scene changes."
- "The window scene's effective geometry provides information on how much space your app has available. If you need to monitor the effective geometry for changes, implement windowScene:didUpdateEffectiveGeometry: in your scene delegate."
- "For games, resizing can be challenging. Due to this, UIRequiresFullscreen is honored on iPhone in resizable environments starting in iOS 27. Its behavior has also been updated and no longer opts your app fully out of resizing. Instead, it enables discrete resizing that honors your supported interface orientations."
- "In discrete resizing, every time a person changes the scene size, the system transitions the scene to a new screen configuration matching that size, so your game always renders at full quality in the available space."

**UIKit reference**

- `windowScene(_:didUpdateEffectiveGeometry:)` (iOS 26.0): "Always called when a UIWindowScene moves between screens." <https://developer.apple.com/documentation/uikit/uiwindowscenedelegate/windowscene(_:didupdateeffectivegeometry:)>
- `UIScreen.main` is deprecated (iOS 26.0): "Apple discourages the use of this symbol." <https://developer.apple.com/documentation/uikit/uiscreen/main>

**iOS & iPadOS 27 release notes** (<https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes>). I searched the page for resize, UIScreen, scene, Duo, fold, hinge, SpriteKit and orientation. There is no SpriteKit section and no mention of iPhone Duo. Relevant UIKit entries (all under "Resolved Issues", describing iPhone Mirroring and iPad):

- "Fixed: In iPhone Mirroring, if your app is built with the iOS 27 SDK and sets `UIRequiresFullScreen`, its scene receives continuous resize updates when the user resizes the window. Each resize should instead be delivered as a discrete change to a new `UIScreen` with an updated bounds. (178558224)"
- "Fixed: In iPhone Mirroring, if your app is built with the iOS 27 SDK its scene will support all interface orientations regardless of the orientations declared in `UISupportedInterfaceOrientations` or returned by `UIViewController.supportedInterfaceOrientations`. Supported interface orientations should be honored until the user begins resizing the window. (178555304)"
- "Apps built with the latest SDK must adopt the scene-based life cycle or they fail to launch." (Deprecations)
- New: "you can use `UIScene.extendStateRestoration` and `UIScene.completeStateRestoration` to extend state restoration for `UIScene.ActivationState.background` to `UIScene.ActivationState.foreground` lifecycle transitions." (Not about folding.)

**iOS & iPadOS 27.1 release notes: there is no such page.** The release-notes index lists only 27.3 beta 2, 27.2 and 27 under "iOS & iPadOS 27", and `.../ios-ipados-27_1-release-notes` returns 404. The 27.2 notes contain nothing about resize, scenes, UIScreen or iPhone Duo (one UIKit item, about default layout margins being zero on iOS 27.1 and later).

**"Transitioning to the UIKit scene-based life cycle"** (<https://developer.apple.com/documentation/uikit/transitioning-to-the-uikit-scene-based-life-cycle>): states the requirement ("apps built with the latest SDK must adopt the scene-based life cycle or they fail to launch") and how to migrate. It says nothing about iPhone Duo, folding, or SwiftUI apps.

**HIG** (<https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>): "Create a consistent experience across displays. Keep functionality and the state of elements the same between displays." Design talk 111466: "People may open and close the device frequently while using your app, so it needs to be predictable and consistent inside and out."

### 6.2 What Apple does not state

Apple **never says in so many words** that the same `UIWindowScene`, the same SwiftUI scene, the same view objects or the app's in-memory state survive opening or closing the device. I found no sentence of the form "the scene is preserved" or "a new scene is created" for iPhone Duo in any of the pages above.

What the sources do support:

- Sourced: Apple consistently calls it a resize of the running app ("resize", "expands to fill the inner display", "returns to the outer display", "in the middle of a session"), and equates it with resizing in iPhone Mirroring.
- Sourced: the app "may change which display it's on", and Apple tells developers not to keep a `UIScreen` and to read the display scale from the environment. For iPhone Mirroring and external displays Apple says "the screen associated with your scene changes" — the scene stays, its screen changes.
- Inference: on iPhone Duo the same scene is resized and its `screen` (and possibly its display scale) changes; nothing is torn down, so the `SKScene` object, its node tree and the camera stay in memory. This matches RESEARCH.md 3.1 and is still an inference.
- Inference: because the display may change, anything in the scene that depends on pixel scale (texture choice, hairline widths) should be recomputed in `didChangeSize(_:)` rather than cached at launch.

Leads that are **not** primary sources and that I could not open: an Apple Developer Forums thread, "A Summary of the iPhone Duo Group Lab" (<https://developer.apple.com/forums/thread/847644>), which a search snippet summarised as saying a fold or unfold is represented as a size-class and trait-collection change, "not a scene disconnect or app teardown". The forums sit behind a browser check that the fetch tool cannot pass, so I did not read it and cannot quote it. Apple's own Group Lab videos (<https://developer.apple.com/videos/play/meet-with-apple/285/>, 286, 287) have no transcript on the page.

### 6.3 State restoration

Nothing in the iPhone Duo material mentions state restoration. Inference: since Apple describes folding as a resize, state restoration is not the mechanism for surviving a fold; it remains what it always was (the app being terminated in the background), which the game's mid-battle save already covers.

### 6.4 SwiftUI state and the scene object (supporting facts)

- `State()` macro page (<https://developer.apple.com/documentation/swiftui/state()>): "A `State()` property instantiates its default value the first time SwiftUI instantiates the view." SwiftUI updates page, June 2026: "Build your project in Xcode 27 or later so that the `@State` attribute uses the `State()` macro ... This change only initializes and stores your property once when it's a class."
- iOS 27 release notes, SwiftUI: "A `@State` declared with an expression as its initial value used to evaluate the expression each time the view struct re-instantiates. ... Xcode 27 introduces a new `@State` implementation that avoids this repeated evaluation."
- The same notes warn that with the macro, assigning a `@State` property in `init` when it also has a default value "won't compile". So write either `@State private var scene = BattleScene()` or declare it without a default and assign it in `init`, not both.

Inference: `@State private var scene = BattleScene(...)` in the view that owns the `SpriteView` (built with Xcode 27 or later) gives one scene object for the life of that view. Creating the scene inside `body`, or inside a `GeometryReader` closure, would create a new scene on every layout pass and lose the camera, which would look like "state lost on fold" even though the system kept everything alive.

---

## 7. Info.plist keys (question 7)

### 7.1 `CADisableMinimumFrameDurationOnPhone`

- Key page (<https://developer.apple.com/documentation/bundleresources/information-property-list/cadisableminimumframedurationonphone>), iOS 15.0: "A Boolean value that allows your app to access frame rates higher than the system's default." "If you set this key to `YES`, your app can request any frame rate the display supports. If you set this key to `NO`, frame rates higher than the system default are unavailable."
- ProMotion article (<https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays>): "To enable your `preferredFrameRateRange` timing hints for `CADisplayLink` callbacks and `CAAnimation` animations in your iPhone app, use the Info pane in Xcode to add the `CADisableMinimumFrameDurationOnPhone` key to your app's information property list with the Boolean value `true`". "If you don't enable this support, Core Animation won't access higher frame rates (above 60Hz)." Also: "The system automatically handles frame pacing for UIKit, SpriteKit, SwiftUI, and `CAAnimation` animations for you."
- That article's device table does not name iPhone Duo (it lists "iPhone 17 and later" and others). The spec page says iPhone Duo has ProMotion on both displays (RESEARCH.md section 1).

Inference: to render SpriteKit at 120 frames per second on iPhone Duo, add the key with value `true` **and** pass `preferredFramesPerSecond: 120` to `SpriteView` (its default is 60). Apple does not say on any page I read whether `SKView` is subject to this key; `SpriteView.DebugOptions.showsFPS` will show the result. A turn-based tactics game may not need 120 at all.

### 7.2 `UIRequiresFullScreen`

- Key page (<https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen>): iOS 9.0, **deprecated in 26.0**. "A Boolean value that indicates whether the system puts an iPad app into a compatibility mode that opts the app out of multitasking and dynamic resizing." On current iPadOS it "Scales your app's presentation when the user resizes it, rather than changing the size of your app's scene". The page does not mention iPhone or iPhone Duo.
- On iPhone Duo (talk 111461): "iPhone Duo will continue to honor the UIRequiresFullScreen key, but your app will still resize when someone opens or closes their iPhone Duo."
- On iPhone generally from iOS 27 (WWDC26 278): it "no longer opts your app fully out of resizing. Instead, it enables discrete resizing that honors your supported interface orientations", and "every time a person changes the scene size, the system transitions the scene to a new screen configuration matching that size".
- Related key `UIRequiresFullScreenIgnoredStartingWithVersion` (iOS 26.2): "A string value that specifies a system version after which the system ignores the requires full screen key."

Inference: for this game the key is not needed and should be left out of the prototype. It is deprecated, it does not prevent the resize on fold, and with it each resize arrives as a change to a new `UIScreen` instead of a plain resize, which adds a second code path to test. If orientation locking is wanted later, it can be revisited then.

### 7.3 Supported interface orientations on the inner display

- Talk 111461: "The interface orientation on the outer display behaves like any other iPhone." "Interface orientation on the inner display behaves differently. The inner display doesn't honor your supported interface orientations. As with Idiom, avoid checking interface orientation for layout decisions. Use size classes instead."
- Same talk, straight after the `UIRequiresFullScreen` sentence: "iPhone Duo respects your supported interface orientations, but your app will scale on the inner display, including in Split View multitasking."
- WWDC26 278: "In iOS 27, an app's supported interface orientation is a preference provided to the system. It will be ignored when your app is running in a resizable environment."
- HIG: "Make your game playable in every device pose. You can choose to lock to either portrait or landscape orientation, but be sure to fill the screen as the device pose changes. When resizing, keep text and control sizes as consistent as possible. Prefer changing the aspect ratio over letterboxing or pillarboxing in games; if you can't avoid letterboxing or pillarboxing, add artwork to the padding area to help the experience feel full screen."

The two sentences from 111461 read as contradictory on their own. Inference: the second one describes an app that sets `UIRequiresFullScreen` (it follows that sentence, and WWDC26 278 says that key "honors your supported interface orientations"); in that mode the app keeps its orientation and is scaled to fit the inner display. Without the key, the inner display ignores the app's orientation list and the app must lay out for whatever shape it is given. Apple does not spell this out; the simulator will show it.

Inference for the prototype: list all four orientations in `UISupportedInterfaceOrientations` and never branch on orientation; decide layout from the view's width versus height and the size classes.

### 7.4 Other keys that matter in the iOS 27 SDK

- **Launch screen is mandatory.** iOS 27 release notes: "iOS and iPadOS apps built with the 27.0 SDK or later are required to include a launch screen. Your app's `Info.plist` must contain one of the following keys: `UILaunchStoryboardName`, `UILaunchStoryboards`, `UILaunchScreen`, or `UILaunchScreens`. Apps that don't include a launch screen are rejected when the App Store begins accepting apps built with the 27.0 SDK."
- **Scene-based life cycle is mandatory** ("or they fail to launch"). `UIApplicationSceneManifest`: "The presence of this key indicates that the app supports scenes". Inference: an app whose entry point is a SwiftUI `App` with a `WindowGroup` is scene-based by construction (the `App` page: "Each scene contains the root view of a view hierarchy and has a life cycle managed by the system"); Apple's migration article does not mention SwiftUI either way.
- `UIDesignRequiresCompatibility`: "The system ignores this key when you build for iOS 27 or later".

### 7.5 Anything new for iPhone Duo?

I found **no Info.plist key that is specific to iPhone Duo**. The "User interface" key index (<https://developer.apple.com/documentation/bundleresources/user-interface>) lists none, and none of the iPhone Duo pages names one. Using the full display is decided by the SDK the app is built with:

- "When you build your app with the iOS 27.1 SDK, your app extends to the edge of the screen." (111461)
- "Apps built with the iOS 27.1 SDK or later are optimized for iPhone Duo. Apps will extend to use the full display, with toolbars and tab bars appearing vertically below the status bar." ("Three steps" page)
- "When you build with Xcode 26 and earlier, your app doesn't extend under the status bar and camera." (overview article)
- "Your app will work on iPhone Duo even if you haven't built it with the iOS 27 SDK."

Related layout facts for a full-screen game view: "Keep in mind that safe areas are often asymmetric. This is especially true on iPhone Duo." (111461). "Consider using the full display width for interfaces where bars aren't necessary." (HIG). The outer camera is an always-active `.occlusion` region.

---

## 8. Apple Pencil versus finger (question 8)

### 8.1 Inside the SpriteKit scene (UIKit responder path)

- `SKNode` is a responder: "`SKNode` subclasses `UIResponder` in iOS and tvOS, and `NSResponder` in macOS, allowing nodes to respond to user interaction events such as touches and mouse movements." (<https://developer.apple.com/documentation/spritekit/controlling-user-interaction-on-nodes>). `SKScene` inherits from `SKEffectNode`, which is an `SKNode`.
- Two strategies, Apple's words: "Enable user interaction on a single catch-all node, for example the scene, and calculate the child node or nodes that the user is interacting with by doing custom hit tests." or "Enable user interaction on every node you want the user to interact with, and subclass them to implement their responder functions."
- `isUserInteractionEnabled` on a node (<https://developer.apple.com/documentation/spritekit/sknode/isuserinteractionenabled>): `var isUserInteractionEnabled: Bool { get set }`. "The default value is `false`." "In addition to setting `isUserInteractionEnabled` to `true`, you must subclass the node and define event callbacks in order to respond to user input."
- "Nodes that have user interaction disabled will block touch and mouse events on nodes behind them where they overlap."
- The methods are `UIResponder`'s: `func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)` and its `touchesMoved`, `touchesEnded`, `touchesCancelled` siblings. "If you override this method without calling `super` (a common use pattern), you must also override the other methods for handling touch events, even if your implementations do nothing." "For touches in a view, this set contains only one touch by default."
- Touch position in scene coordinates: `func location(in node: SKNode) -> CGPoint` on `UITouch` ("Working with touch events in SpriteKit", <https://developer.apple.com/documentation/uikit/uitouch/location(in:)-44h4k>).
- **Telling the Pencil apart:** `var type: UITouch.TouchType { get }` (iOS 9.0, <https://developer.apple.com/documentation/uikit/uitouch/type>). Cases of `enum UITouch.TouchType` (<https://developer.apple.com/documentation/uikit/uitouch/touchtype>):
  - `.direct` — "A touch resulting from direct contact with the screen." "Direct touches occur when the user's finger touches the screen."
  - `.pencil` (iOS 9.1) — "A touch from Apple Pencil." "A pencil touch occurs when Apple Pencil interacts with the device's screen."
  - `.indirect`, `.indirectPointer`. A `stylus` member is listed under the page's "Deprecated" heading; use `.pencil`.

Apple's Listing 1 (a scene that catches all touches):

```swift
class TouchScene: SKScene {
    override var isUserInteractionEnabled: Bool {
        get {
            return true
        }
        set {
            // ignore
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        
        let touchedNodes = nodes(at: location)
        let frontTouchedNode = atPoint(location).name
    }
}
```

Inference: inside that `touchesBegan`, `touch.type == .pencil` distinguishes the Pencil from a finger (`.direct`). This is the standard UIKit mechanism; no page says anything iPhone Duo specific about it. Per RESEARCH.md 1.1 the Pencil needs iOS 27.2 on the device and reports no pressure. Apple does not say on the `SpriteView` pages that touches are delivered to the scene's responder methods when the scene is hosted by `SpriteView`; the prototype should confirm with a log line.

Device Hub's gesture table for simulated iOS devices (<https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub>) lists tap, double-tap, touch and hold, and drag. It does not list a way to simulate Apple Pencil input, so `.pencil` touches probably need a real device. (Not found is not the same as not possible.)

### 8.2 SwiftUI gestures

Yes, SwiftUI exposes the input kind, in two ways:

- **New in iOS 27.0: `GestureInputKinds`** (<https://developer.apple.com/documentation/swiftui/gestureinputkinds>). "An option set that specifies which input kinds a gesture should recognize." Members: `all`, `directTouch` ("A person is touching content directly." Example given: "touching a screen directly with fingers"), `indirectTouch`, `pencil` ("A person is touching content directly with an Apple Pencil, or an other supported pencil device."), `pointer`. New initialisers take it:

```swift
// DragGesture, iOS 27.0
@MainActor @preconcurrency init(minimumDistance: CGFloat = 10,
                                coordinateSpace: some CoordinateSpaceProtocol = .local,
                                inputKinds: GestureInputKinds = .all)

// SpatialTapGesture, iOS 27.0
nonisolated init(count: Int = 1,
                 coordinateSpace: some CoordinateSpaceProtocol = .local,
                 inputKinds: GestureInputKinds = .all)
```

  There is also `onTapGesture(count:coordinateSpace:inputKinds:perform:)`. SwiftUI updates page, June 2026: "Specify the sources of gesture input to recognize, such as direct or indirect touches, pencil, or pointer." This is a **filter** chosen when the gesture is created: one gesture for `.pencil`, another for `.directTouch`. `DragGesture.Value` itself has no property for the input kind (its listed members are locations, translations, time, velocity and 3D poses).

- **Since iOS 18.0: `SpatialEventGesture`** (<https://developer.apple.com/documentation/swiftui/spatialeventgesture>) reports each event's source: `var kind: SpatialEventCollection.Event.Kind` with cases including `.touch` ("An event generated from a touch directly targeting content.") and `.pencil` ("An event generated from a pencil making contact with content.", iOS 18.0).

Inference: for a game map, handling touches in the `SKScene` (8.1) is simpler than SwiftUI gestures layered on the `SpriteView`, because the scene already has the coordinate conversion and hit testing, and Apple's TN3210 notes that "Games typically use responder-based event delivery rather than gesture recognizers." SwiftUI's `inputKinds` is useful for HUD controls that should react only to a finger or only to the Pencil.

---

## 9. What the prototype must observe (because Apple does not say)

Print or log these in the iPhone Duo simulator (Device Hub: "To close the iPhone Duo, click the Closed button", "To partially open the iPhone Duo, click the Partially Open button in the middle of the three device pose buttons", "To fold the device to any angle, hold the Option key while dragging the slider that appears below the bezel."):

1. Object identity across open, partially open and closed: `ObjectIdentifier(scene)`, and whether `didMove(to:)` / `willMove(from:)` fire again. Settles 6.2.
2. `didChangeSize(_:)` old and new sizes for each transition, and how many times it fires during the animated transition.
3. `scene.view?.window?.windowScene?.screen` identity and `@Environment(\.displayScale)` on each display. Settles whether the `UIScreen` and the scale change (and the open question in RESEARCH.md 3.5).
4. `horizontalSizeClass` / `verticalSizeClass` in every pose, including Split View.
5. `proxy.reservedRegions(kind: .division, options: .includeInactive)`: frame and `isActive` when fully open, partially open in both orientations, and closed. Settles the contradiction in 3.4.
6. `hinge.status` and `hinge.angle.degrees` from `onHingeChange` at closed, half and fully open. Settles the angle range.
7. Whether a `SpriteView` placed as the primary or secondary view of an `ArrangementView` keeps the same scene and `SKView` when the arrangement switches axis or hides the secondary view.
8. Whether `touchesBegan` on the scene fires when hosted in `SpriteView`, and `touch.type` (finger only in the simulator, most likely).
9. Frame rate with and without `CADisableMinimumFrameDurationOnPhone` using `debugOptions: [.showsFPS]`.

Known simulator issue that touches this test (Xcode 27.2 release notes, <https://developer.apple.com/documentation/xcode-release-notes/xcode-27_2-release-notes>): "When switching between the inner and outer display of the iPhone Duo simulator, modifier keys such as Shift and Command might stop working."

---

## 10. Could not verify

- Whether the same `UIWindowScene` / SwiftUI scene / view objects survive open and close: Apple never states it outright (6.2). Tried: the three Tech Talks, the design talk 111466, WWDC26 278, the overview article, the "Three steps" page, the HIG page, the iOS 27 / 27.2 / 27.3 beta release notes, the scene life cycle article, `UIScreen`, `UIWindowScene`, `UIWindowSceneDelegate` reference pages. The simulator test in section 9 settles it.
- iOS & iPadOS 27.1 release notes: the page does not exist (404; not in the index).
- Apple Developer Forums (Group Lab summary thread 847644, iPhone Duo Q&A pages): blocked by a browser verification page. Group Lab videos 285 to 287 have no transcript.
- `SpriteView` behaviour beyond its declarations (sizing, view reuse, touch delivery, pausing): Apple's pages have no prose.
- Hinge angle range and zero point: not documented.
- Size classes in Split View on the inner display: not stated.
- Whether `CADisableMinimumFrameDurationOnPhone` is needed for `SKView` to exceed 60 frames per second, and whether the ProMotion article applies to iPhone Duo by name: not stated.
- Whether the split-arrangement ratio modifiers apply while the fold is active: not stated.
- Apple Pencil simulation in Device Hub: not listed on the interaction page; no statement either way.
