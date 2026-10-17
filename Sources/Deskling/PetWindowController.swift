import AppKit
import DesklingCore

extension NSScreen {
    var displayID: Int? {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.intValue
    }
}

final class PetWindowController {
    private static let frameInterval = 1.0 / 30

    let panel: NSPanel
    var onDropped: ((Double, Int?) -> Void)?
    var onInspect: ((NSPoint, NSView) -> Void)?
    var onClick: (() -> Void)?
    var onFrameChanged: (() -> Void)?
    /// A reminder is waiting to be seen.
    var isAlerting = false {
        didSet { settle() }
    }
    /// A focus session is running.
    var isFocusing = false {
        didSet { settle() }
    }

    private let view = PetView()
    private var walk: WalkModel
    private var skin: Skin
    private var scale: Double
    private var timer: Timer?
    private var dragging = false
    private var fall: FallModel?
    /// Seconds left in the happy pose after a click.
    private var happyRemaining = 0.0

    init(skin: Skin, scale: Double, startX: Double?, screenID: Int?) {
        self.skin = skin
        self.scale = scale
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 96, height: 96),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        let screen = NSScreen.screens.first { $0.displayID == screenID } ?? NSScreen.main ?? NSScreen.screens.first
        let x = startX ?? Double(screen?.visibleFrame.midX ?? 0)
        walk = WalkModel(x: x)

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.contentView = view
        panel.setFrameOrigin(NSPoint(x: x, y: Double(screen?.visibleFrame.minY ?? 0)))

        view.onDragBegan = { [weak self] in self?.grab() }
        view.onDragMoved = { [weak self] deltaX in self?.dragged(by: deltaX) }
        view.onDragEnded = { [weak self] in self?.drop() }
        view.onClick = { [weak self] in self?.cheer() }
        view.onInspect = { [weak self] point in
            guard let self else { return }
            self.onInspect?(point, self.view)
        }
        apply(skin: skin, scale: scale)
    }

    func start() {
        timer?.invalidate()
        let timer = Timer(timeInterval: Self.frameInterval, repeats: true) { [weak self] _ in
            self?.tick(Self.frameInterval)
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func setHidden(_ hidden: Bool) {
        if hidden {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }

    func apply(skin: Skin, scale: Double) {
        self.skin = skin
        self.scale = scale
        let height = skin.height * scale
        var aspect = 1.0
        if let image = SpriteFrames.load(url: skin.url(for: .idle))?.images.first, image.height > 0 {
            aspect = Double(image.width) / Double(image.height)
        }
        panel.setFrame(NSRect(origin: panel.frame.origin, size: NSSize(width: height * aspect, height: height)), display: true)
        refresh()
        onFrameChanged?()
    }

    /// The screen under the pet. Falls back to the main screen when its monitor was removed.
    private var currentScreen: NSScreen? {
        let center = NSPoint(x: panel.frame.midX, y: panel.frame.midY)
        return NSScreen.screens.first { $0.frame.contains(center) } ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func tick(_ dt: Double) {
        guard !dragging, panel.isVisible, let screen = currentScreen else { return }
        let visible = screen.visibleFrame
        let lower = Double(visible.minX)
        let bounds = lower...max(lower, Double(visible.maxX - panel.frame.width))
        let floor = Double(visible.minY)
        var y = floor
        happyRemaining = max(0, happyRemaining - dt)
        if var falling = fall {
            falling.step(dt: dt, floor: floor)
            fall = falling.hasLanded ? nil : falling
            y = falling.y
            walk.clamp(to: bounds)
        } else if happyRemaining == 0, !isAlerting, !isFocusing {
            walk.step(dt: dt, bounds: bounds)
        } else {
            walk.clamp(to: bounds)
        }
        let origin = NSPoint(x: walk.x, y: y)
        if origin != panel.frame.origin {
            panel.setFrameOrigin(origin)
            onFrameChanged?()
        }
        refresh()
    }

    private func grab() {
        dragging = true
        fall = nil
        walk.stop()
        refresh()
    }

    private func cheer() {
        happyRemaining = PetPresentation.happyDuration
        walk.stop()
        refresh()
        onClick?()
    }

    /// Stops a walk when the pet has something to show, and redraws.
    private func settle() {
        if isAlerting || isFocusing { walk.stop() }
        refresh()
    }

    private func dragged(by deltaX: CGFloat) {
        if deltaX != 0 { walk.face(left: deltaX < 0) }
        refresh()
        onFrameChanged?()
    }

    private func drop() {
        dragging = false
        walk.place(x: Double(panel.frame.minX))
        fall = FallModel(y: Double(panel.frame.minY))
        tick(0)
        onDropped?(walk.x, currentScreen?.displayID)
    }

    private func refresh() {
        let pose = PetPresentation.pose(isWalking: walk.isWalking, isHappy: happyRemaining > 0,
                                        isHeld: dragging, isFalling: fall != nil,
                                        isAlerting: isAlerting, isFocusing: isFocusing)
        view.show(url: skin.url(for: pose), speed: skin.playbackSpeed(for: pose), facingLeft: walk.facingLeft)
    }
}
