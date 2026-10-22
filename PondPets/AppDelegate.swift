import Cocoa

/// 应用总控：负责按屏幕建窗口、接收菜单栏指令、转发给各个壁纸窗口。
final class AppDelegate: NSObject, NSApplicationDelegate, WallpaperControlling {

    private var statusController: StatusMenuController!
    private var wallpapers: [WallpaperWindow] = []
    private var escMonitor: Any?

    private var isInteractive = false
    private var isPaused = false
    private var speedIndex = 0
    private var weatherName = "auto"
    private var sounds: [String: Bool] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)          // 只驻留菜单栏，不占 Dock
        statusController = StatusMenuController(delegate: self)
        rebuildWindows()
        NotificationCenter.default.addObserver(self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil)
        installEscMonitor()
    }

    /// 关掉所有窗口也不退出（壁纸 App 常驻菜单栏）
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc private func screensChanged() { rebuildWindows() }

    /// 每块屏幕铺一个窗口，支持多显示器
    private func rebuildWindows() {
        for w in wallpapers { w.webViewTeardown() }
        for w in wallpapers { w.close() }
        wallpapers = NSScreen.screens.map { WallpaperWindow(screen: $0) }
        for w in wallpapers { applyState(to: w) }
    }

    private func applyState(to w: WallpaperWindow) {
        w.setPaused(isPaused)
        w.setSpeed(speedIndex)
        w.setWeather(weatherName)
        w.setPanel(isInteractive)
        for (key, value) in sounds { w.setSound(key, value) }
        if isInteractive { w.setInteractive(true) }
    }

    /// 摸鱼模式下按 Esc 回到桌面壁纸状态
    private func installEscMonitor() {
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let strongSelf = self else { return event }
            if event.keyCode == 53 && strongSelf.isInteractive {     // 53 = Esc
                strongSelf.setInteractive(false)
                strongSelf.statusController.syncInteractive(false)
                return nil
            }
            return event
        }
    }

    // MARK: - WallpaperControlling

    func setInteractive(_ on: Bool) {
        isInteractive = on
        for w in wallpapers {
            w.setInteractive(on)
            w.setPanel(on)
        }
    }

    func setPaused(_ on: Bool) {
        isPaused = on
        wallpapers.forEach { $0.setPaused(on) }
    }

    func setSpeed(_ index: Int) {
        speedIndex = index
        wallpapers.forEach { $0.setSpeed(index) }
    }

    func setWeather(_ name: String) {
        weatherName = name
        wallpapers.forEach { $0.setWeather(name) }
    }

    func setSound(_ key: String, _ on: Bool) {
        sounds[key] = on
        wallpapers.forEach { $0.setSound(key, on) }
    }

    func feed() {
        wallpapers.forEach { $0.feed() }
    }

    func tapGlass() {
        wallpapers.forEach { $0.tapGlass() }
    }

    func addFish() {
        wallpapers.forEach { $0.addFish() }
    }

    func quit() { NSApp.terminate(nil) }
}
