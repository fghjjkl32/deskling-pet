import AppKit
import DesklingCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let language = Language.current()
    private var pet: PetWindowController?
    private var menu: StatusMenuController?

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
        pet.setHidden(preferences.petHidden)
        pet.start()
        self.pet = pet

        menu = StatusMenuController(language: language, state: { [unowned self] in self.menuState() }, actions: menuActions())
    }

    private func text(_ text: Text) -> String { text.string(language) }

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
        let userSkins = SkinLoader.list(in: AppPaths.skinsDirectory()).map {
            StatusMenuController.SkinItem(path: $0.directory.path, name: $0.name)
        }
        let selected = userSkins.contains { $0.path == preferences.skinPath } ? preferences.skinPath : nil
        return StatusMenuController.State(
            skins: [StatusMenuController.SkinItem(path: nil, name: text(.defaultSkin))] + userSkins,
            selectedSkinPath: selected,
            scale: preferences.sizeScale,
            petHidden: preferences.petHidden,
            launchAtLogin: isBundled ? SMAppService.mainApp.status == .enabled : nil
        )
    }

    private func menuActions() -> StatusMenuController.Actions {
        StatusMenuController.Actions(
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
