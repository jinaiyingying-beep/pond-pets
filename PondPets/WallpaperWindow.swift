import Cocoa
import CoreGraphics
import WebKit

/// 一块屏幕上铺满的“壁纸窗口”。
///
/// 默认层级是 `desktopWindow`，也就是贴在桌面图标**后面**、桌面图片之上；
/// 因为 Finder 的桌面会拦截点击，所以默认 `ignoresMouseEvents = true`，完全不打扰你操作。
/// 菜单里打开「摸鱼模式」时，临时把窗口抬到普通层级并接收鼠标，就能点水面投喂、拖动赶鱼；
/// 按 Esc 或再从菜单关掉，就降回图标后面。
final class WallpaperWindow: NSWindow, WKNavigationDelegate {

    private var webView: WKWebView!
    private(set) var interactive = false
    private var pageReady = false

    // 与网页同步的状态；页面加载完成后统一推一次
    private var stPaused = false
    private var stPanel = false
    private var stSpeed = 0
    private var stWeather = "auto"
    private var stSounds: [String: Bool] = [:]

    /// 桌面图层（图标在它上面）
    private static let desktopLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))

    init(screen: NSScreen) {
        super.init(contentRect: screen.frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)

        isOpaque = true
        backgroundColor = .black
        hasShadow = false
        isMovable = false
        isReleasedWhenClosed = false
        level = Self.desktopLevel
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        ignoresMouseEvents = true
        setFrame(screen.frame, display: false)

        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []   // 允许菜单直接开关环境音效
        config.suppressesIncrementalRendering = false

        let wv = WKWebView(frame: contentView?.bounds ?? screen.frame, configuration: config)
        wv.autoresizingMask = [.width, .height]
        wv.underPageBackgroundColor = .black                   // 避免加载瞬间闪白
        wv.navigationDelegate = self
        contentView?.addSubview(wv)
        webView = wv

        loadPage()
        // 桌面层级下 orderFrontRegardless 仍会排在图标之后，但比 orderBack 更稳妥地保证窗口真的显示出来
        orderFrontRegardless()
    }

    override var canBecomeKey: Bool { interactive }
    override var canBecomeMain: Bool { interactive }

    private func loadPage() {
        guard let url = Bundle.main.url(forResource: "pond-wallpaper", withExtension: "html") else {
            NSLog("⚠️ 找不到 pond-wallpaper.html 资源，请确认它已加入 Resources")
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    // MARK: - 状态推送（Swift → 网页）

    func setPaused(_ on: Bool) { stPaused = on; push("pond.setPaused(\(on))") }
    func setPanel(_ on: Bool) { stPanel = on; push("pond.showPanel(\(on))") }
    func setSpeed(_ index: Int) { stSpeed = index; push("pond.setSpeed(\(index))") }
    func setWeather(_ name: String) { stWeather = name; push("pond.setWeather('\(name)')") }
    func setSound(_ key: String, _ on: Bool) { stSounds[key] = on; push("pond.setSound('\(key)', \(on))") }

    // MARK: - 互动（菜单 → 网页）

    func feed() { push("pond.feed()") }
    func tapGlass() { push("pond.tapGlass()") }
    func addFish() { push("pond.addFish()") }

    /// 页面刚加载完 / 换屏幕时，把全部状态重新推一遍
    private func pushAllState() {
        guard pageReady else { return }
        eval("if(window.pond){pond.setEmbedded(true);"
             + "pond.setPaused(\(stPaused));"
             + "pond.showPanel(\(stPanel));"
             + "pond.setSpeed(\(stSpeed));"
             + "pond.setWeather('\(stWeather)');}")
        for (key, on) in stSounds {
            eval("if(window.pond){pond.setSound('\(key)', \(on));}")
        }
    }

    private func push(_ js: String) { eval("if(window.pond){\(js);}") }
    private func eval(_ js: String) { webView.evaluateJavaScript(js, completionHandler: nil) }

    // MARK: - 摸鱼模式

    func setInteractive(_ on: Bool) {
        guard on != interactive else { return }
        interactive = on
        if on {
            level = .normal
            collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            ignoresMouseEvents = false
            NSApp.activate(ignoringOtherApps: true)
            makeKeyAndOrderFront(nil)
        } else {
            ignoresMouseEvents = true
            level = Self.desktopLevel
            collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
            orderBack(nil)
        }
    }

    // MARK: - 销毁（换屏幕时先卸载，免得 WebKit 进程悬着）

    func webViewTeardown() {
        pageReady = false
        webView?.navigationDelegate = nil
        webView?.stopLoading()
        webView?.removeFromSuperview()
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageReady = true
        pushAllState()
    }
}
