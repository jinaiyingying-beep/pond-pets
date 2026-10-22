import Cocoa
import ServiceManagement

/// 与壁纸窗口通信的接口，由 AppDelegate 实现
protocol WallpaperControlling: AnyObject {
    func setInteractive(_ on: Bool)
    func setPaused(_ on: Bool)
    func setSpeed(_ index: Int)
    func setWeather(_ name: String)
    func setSound(_ key: String, _ on: Bool)
    func feed()
    func tapGlass()
    func addFish()
    func quit()
}

/// 菜单栏图标 + 下拉菜单，是这个 App 唯一的控制入口。
final class StatusMenuController: NSObject {

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private weak var delegate: WallpaperControlling?

    private var interactiveOn = false
    private var pausedOn = false

    private var speedItems: [NSMenuItem] = []
    private var weatherItems: [NSMenuItem] = []
    private var soundState: [String: Bool] = [
        "s_stream": false, "s_rain": false, "s_frog": false, "s_cricket": false,
    ]

    private let speedTitles = ["跟随真实时间", "快速循环 · 慢", "快速循环 · 中", "快速循环 · 快", "快速循环 · 很快"]
    private let weatherOptions: [(title: String, key: String)] = [
        ("自动", "auto"), ("晴", "clear"), ("多云", "cloudy"),
        ("雨", "rain"), ("雪", "snow"), ("雾", "fog"),
    ]
    private let soundOptions: [(title: String, key: String)] = [
        ("溪流", "s_stream"), ("雨声", "s_rain"), ("蛙鸣", "s_frog"), ("虫鸣", "s_cricket"),
    ]

    init(delegate: WallpaperControlling) {
        self.delegate = delegate
        super.init()
        configureButton()
        buildMenu()
    }

    // MARK: - 菜单栏按钮

    private func configureButton() {
        guard let button = statusItem.button else { return }
        if let image = NSImage(systemSymbolName: "fish", accessibilityDescription: "养鱼桌面") {
            button.image = image
        } else {
            button.title = "🐟"
        }
        button.toolTip = "养鱼桌面 · Pond Pets"
    }

    private func buildMenu() {
        let menu = NSMenu()

        let interactive = NSMenuItem(title: "摸鱼模式（可点鱼喂食）",
                                     action: #selector(toggleInteractive(_:)), keyEquivalent: "b")
        interactive.target = self
        menu.addItem(interactive)

        let feed = NSMenuItem(title: "撒一把鱼食", action: #selector(feedFish(_:)), keyEquivalent: "f")
        feed.target = self
        menu.addItem(feed)

        let tap = NSMenuItem(title: "轻敲玻璃", action: #selector(tapGlass(_:)), keyEquivalent: "t")
        tap.target = self
        menu.addItem(tap)

        let add = NSMenuItem(title: "添一条食人鱼", action: #selector(addFish(_:)), keyEquivalent: "a")
        add.target = self
        menu.addItem(add)

        let paused = NSMenuItem(title: "暂停动画", action: #selector(togglePaused(_:)), keyEquivalent: "p")
        paused.target = self
        menu.addItem(paused)

        menu.addItem(.separator())

        // 时间流速
        let speedRoot = NSMenuItem(title: "时间流速", action: nil, keyEquivalent: "")
        let speedMenu = NSMenu()
        for (index, title) in speedTitles.enumerated() {
            let item = NSMenuItem(title: title, action: #selector(selectSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            item.state = (index == 0) ? .on : .off
            speedMenu.addItem(item)
            speedItems.append(item)
        }
        speedRoot.submenu = speedMenu
        menu.addItem(speedRoot)

        // 天气
        let weatherRoot = NSMenuItem(title: "天气", action: nil, keyEquivalent: "")
        let weatherMenu = NSMenu()
        for (index, option) in weatherOptions.enumerated() {
            let item = NSMenuItem(title: option.title, action: #selector(selectWeather(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.key
            item.state = (index == 0) ? .on : .off
            weatherMenu.addItem(item)
            weatherItems.append(item)
        }
        weatherRoot.submenu = weatherMenu
        menu.addItem(weatherRoot)

        // 环境音效
        let soundRoot = NSMenuItem(title: "环境音效", action: nil, keyEquivalent: "")
        let soundMenu = NSMenu()
        for option in soundOptions {
            let item = NSMenuItem(title: option.title, action: #selector(toggleSoundItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option.key
            item.state = .off
            soundMenu.addItem(item)
        }
        soundRoot.submenu = soundMenu
        menu.addItem(soundRoot)

        menu.addItem(.separator())

        let launch = NSMenuItem(title: "开机自动启动", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launch.target = self
        launch.state = launchAtLoginEnabled() ? .on : .off
        menu.addItem(launch)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "退出养鱼桌面", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    /// 供 Esc 退出摸鱼模式时同步勾选状态
    func syncInteractive(_ on: Bool) {
        interactiveOn = on
        statusItem.menu?.item(at: 0)?.state = on ? .on : .off
    }

    // MARK: - 菜单动作

    @objc private func toggleInteractive(_ sender: NSMenuItem) {
        interactiveOn.toggle()
        sender.state = interactiveOn ? .on : .off
        delegate?.setInteractive(interactiveOn)
    }

    @objc private func feedFish(_ sender: NSMenuItem) {
        delegate?.feed()
    }

    @objc private func tapGlass(_ sender: NSMenuItem) {
        delegate?.tapGlass()
    }

    @objc private func addFish(_ sender: NSMenuItem) {
        delegate?.addFish()
    }

    @objc private func togglePaused(_ sender: NSMenuItem) {
        pausedOn.toggle()
        sender.state = pausedOn ? .on : .off
        delegate?.setPaused(pausedOn)
    }

    @objc private func selectSpeed(_ sender: NSMenuItem) {
        for item in speedItems { item.state = (item === sender) ? .on : .off }
        delegate?.setSpeed(sender.tag)
    }

    @objc private func selectWeather(_ sender: NSMenuItem) {
        for item in weatherItems { item.state = (item === sender) ? .on : .off }
        delegate?.setWeather((sender.representedObject as? String) ?? "auto")
    }

    @objc private func toggleSoundItem(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        let newValue = !(soundState[key] ?? false)
        soundState[key] = newValue
        sender.state = newValue ? .on : .off
        delegate?.setSound(key, newValue)
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if launchAtLoginEnabled() {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("⚠️ 开机自启设置失败：\(error.localizedDescription)")
        }
        sender.state = launchAtLoginEnabled() ? .on : .off
    }

    private func launchAtLoginEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }

    @objc private func quitApp() { delegate?.quit() }
}
