import Cocoa

// 养鱼桌面 · Pond Pets（macOS）
//
// 构建方式（二选一）：
//   A. 命令行：双击或在终端执行 ./build.sh（只需 Xcode 命令行工具）
//   B. Xcode：用源码新建一个 macOS App Target，把本目录的 Swift 文件 + HTML 加入即可
//
// 运行后 Dock 里不会出现图标，只在菜单栏右侧显示一个 🐟，
// 所有开关都在那个菜单里。

let application = NSApplication.shared
let appDelegate = AppDelegate()
application.delegate = appDelegate
application.setActivationPolicy(.accessory)   // 纯菜单栏 App，不占 Dock
application.run()
