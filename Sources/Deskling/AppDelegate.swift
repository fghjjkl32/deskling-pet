import AppKit
import DesklingCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let language = Language.current()
    private let bubble = BubbleController()
    private var reminders = Reminders()
    /// The reminder on show until the user clicks the bubble or the pet.
    private var alert: Reminder?
    private var pet: PetWindowController?
    private var menu: StatusMenuController?
    private var reminderTimer: Timer?

    private var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let identifier = Bundle.main.bundleIdentifier {
            let me = ProcessInfo.processInfo.processIdentifier
            let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
                .filter { $0.processIdentifier != me }
                .map { (pid: $0.processIdentifier, launch: $0.launchDate) }
            let myLaunch = NSRunningApplication(processIdentifier: me)?.launchDate
            if InstancePolicy.shouldQuit(selfPID: me, selfLaunch: myLaunch, others: others) {
                NSApp.terminate(nil)
                return
            }
        }
        guard let skin = currentSkin() else {
            showAlert(title: text(.missingResources), body: Resources.defaultSkinDirectory.path)
            NSApp.terminate(nil)
            return
        }
        try? FileManager.default.createDirectory(at: AppPaths.skinsDirectory(), withIntermediateDirectories: true)

        let pet = PetWindowController(skin: skin, scale: preferences.sizeScale, startX: preferences.petX, screenID: preferences.screenID)
        pet.onDropped = { [weak self] x, screenID in
            self?.preferences.petX = x
            self?.preferences.screenID = screenID
        }
        pet.onInspect = { [weak self] point, view in self?.menu?.popUp(at: point, in: view) }
        pet.onClick = { [weak self] in self?.dismissAlert() }
        pet.onFrameChanged = { [weak self] in self?.render() }
        pet.setHidden(preferences.petHidden)
        pet.start()
        self.pet = pet
        bubble.onDismiss = { [weak self] in self?.dismissAlert() }

        if preferences.stretchEnabled { reminders.setStretch(enabled: true, at: Date()) }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tickReminders() }
        RunLoop.main.add(timer, forMode: .common)
        reminderTimer = timer

        menu = StatusMenuController(language: language, state: { [unowned self] in self.menuState() }, actions: menuActions())
    }

    private func text(_ text: Text) -> String { text.string(language) }

    // MARK: - Reminders

    private func tickReminders() {
        if let latest = reminders.tick(at: Date()).last {
            alert = latest
            bubble.clearDismissal()
        }
        render()
    }

    private func dismissAlert() {
        guard alert != nil else { return }
        alert = nil
        render()
    }

    private func render() {
        guard let pet else { return }
        let focusing = reminders.phase == .focus
        if pet.isAlerting != (alert != nil) { pet.isAlerting = alert != nil }
        if pet.isFocusing != focusing { pet.isFocusing = focusing }
        let message = alert.map { PetPresentation.message(for: $0, language: language) }
        bubble.update(text: preferences.petHidden ? nil : message, anchor: pet.panel.frame)
    }

    // MARK: - Skins

    private func currentSkin() -> Skin? {
        if let path = preferences.skinPath, let skin = SkinLoader.load(directory: URL(fileURLWithPath: path)) {
            return skin
        }
        return SkinLoader.load(directory: Resources.defaultSkinDirectory)
    }

    private func applyCurrentSkin() {
        guard let skin = currentSkin() else { return }
        pet?.apply(skin: skin, scale: preferences.sizeScale)
    }

    // MARK: - Menu

    private func menuState() -> StatusMenuController.State {
        // The default skin is stored as no choice at all, so it survives the app moving.
        let bundled = Resources.bundledSkins.enumerated().map { index, skin in
            StatusMenuController.SkinItem(path: index == 0 ? nil : Resources.bundledSkinDirectory(skin.id).path, name: text(skin.name))
        }
        let userSkins = SkinLoader.list(in: AppPaths.skinsDirectory()).map {
            StatusMenuController.SkinItem(path: $0.directory.path, name: $0.name)
        }
        let skins = bundled + userSkins
        let selected = skins.contains { $0.path == preferences.skinPath } ? preferences.skinPath : nil
        let now = Date()
        return StatusMenuController.State(
            phase: reminders.phase.flatMap { phase in
                reminders.phaseEnds.map { (phase, Reminders.minutesLeft(until: $0, at: now)) }
            },
            timerMinutesLeft: reminders.timerEnds.map { Reminders.minutesLeft(until: $0, at: now) },
            stretchEnabled: reminders.stretchEnabled,
            skins: skins,
            selectedSkinPath: selected,
            scale: preferences.sizeScale,
            petHidden: preferences.petHidden,
            launchAtLogin: isBundled ? SMAppService.mainApp.status == .enabled : nil
        )
    }

    private func menuActions() -> StatusMenuController.Actions {
        StatusMenuController.Actions(
            toggleFocus: { [unowned self] in
                if self.reminders.phase == nil {
                    self.reminders.startFocus(at: Date())
                } else {
                    self.reminders.stopFocus()
                }
                self.render()
            },
            startTimer: { [unowned self] minutes in self.reminders.startTimer(minutes: minutes, at: Date()) },
            cancelTimer: { [unowned self] in self.reminders.cancelTimer() },
            toggleStretch: { [unowned self] in
                self.preferences.stretchEnabled.toggle()
                self.reminders.setStretch(enabled: self.preferences.stretchEnabled, at: Date())
            },
            selectSkin: { [unowned self] path in
                self.preferences.skinPath = path
                self.applyCurrentSkin()
            },
            openSkinsFolder: {
                try? FileManager.default.createDirectory(at: AppPaths.skinsDirectory(), withIntermediateDirectories: true)
                NSWorkspace.shared.open(AppPaths.skinsDirectory())
            },
            setScale: { [unowned self] scale in
                self.preferences.sizeScale = scale
                self.applyCurrentSkin()
            },
            togglePet: { [unowned self] in
                self.preferences.petHidden.toggle()
                self.pet?.setHidden(self.preferences.petHidden)
                self.render()
            },
            toggleLaunchAtLogin: { [unowned self] in self.toggleLaunchAtLogin() }
        )
    }

    private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            showAlert(title: text(.loginItemFailed), body: error.localizedDescription)
        }
    }

    private func showAlert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: text(.close))
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
