# Pond Pets · 养鱼桌面 — a fish pond on your Mac desktop

Turn your Mac desktop into a living fish pond. A lightweight native shell
(Swift + WKWebView) puts a single-file Canvas pond on the desktop wallpaper
layer, with a school of red-bellied piranhas you can feed, startle, and grow —
your fish, their fullness, and your interactions persist between launches.

**Features**

- Full-screen pond on the real desktop wallpaper layer — never covers your icons or full-screen apps
- Menu-bar controls: feed, tap the glass, add a piranha (up to 20), pause, login auto-start
- Day cycle that follows your clock, plus weather (sun / cloud / rain / snow / fog)
- Ambient audio synthesized live with Web Audio — zero audio files, zero third-party dependencies
- Realistic fish rendering: spine-sway swimming, fins, scales, schooling formation, feeding frenzy

**Build & run (macOS 13+)**

```bash
xcode-select --install   # once, if you don't have the Xcode command line tools
./build.sh run
```

Then use the 🐟 menu in the menu bar: enter “摸鱼模式” (hands-on mode), click the
water to feed, press Esc to return to wallpaper mode.

**License** — MIT, see [LICENSE](LICENSE).

---

# 养鱼桌面 · Pond Pets — Mac 桌面养鱼壁纸

把 Mac 桌面变成一口能养鱼的池塘。鱼是宠物：有名字、会抢食、会受惊、添的鱼下次打开还认得。

## 里面有什么

```
PondPets/
├── build.sh                    构建脚本（双击或终端 ./build.sh run）
├── README.md                   本文件
└── PondPets/
    ├── main.swift              App 入口
    ├── AppDelegate.swift       总控：多屏建窗、状态转发、Esc 退出摸鱼
    ├── WallpaperWindow.swift   壁纸窗口：desktopWindow 层级 + WKWebView
    ├── StatusMenuController.swift  菜单栏 🐟 + 全部菜单
    ├── Info.plist              App 信息（LSUIElement，不占 Dock）
    └── pond-wallpaper.html     池塘：单文件 Canvas，零第三方依赖，零音频文件
```

## 在 Mac 上安装（3 步）

1. **准备工具**：Mac 上打开“终端”，先装一次 Xcode 命令行工具（只需一次）：
   ```bash
   xcode-select --install
   ```
2. **构建并运行**：在终端进入解压后的 `PondPets` 文件夹，执行：
   ```bash
   ./build.sh run
   ```
   也可以双击 `build.sh` 直接构建（构建完在 `build/PondPets.app`，双击打开）。
3. **开始养鱼**：菜单栏右侧出现 🐟 图标 → 点它 → 点 **“摸鱼模式”** → 点水面撒食喂鱼，拖动赶鱼 → 按 **Esc** 回到壁纸状态。

## 菜单一览

| 菜单 | 作用 |
|---|---|
| 摸鱼模式（⌘B） | 窗口升到普通层级，接鼠标，可点水面喂食 |
| 撒一把鱼食（⌘F） | 在池塘中央撒食 |
| 轻敲玻璃（⌘T） | 鱼群受惊散开，几秒后游回来 |
| 添一条食人鱼（⌘A） | 添一条新的食人鱼，最多 20 条 |
| 暂停动画（⌘P） | 暂停，省电 |
| 时间流速 | 跟随真实时间（按时钟自动切清晨/正午/黄昏/夜晚），或快速循环时段 |
| 天气 | 自动 / 晴 / 多云 / 雨 / 雪 / 雾（雨下雨点、雪下雪点、雾加雾层） |
| 环境音效 | 溪流 / 雨声 / 蛙鸣 / 虫鸣，全部 Web Audio 代码合成，无音频文件 |
| 开机自动启动 | 登录后自动出现 🐟 |
| 退出养鱼桌面（⌘Q） | 退出 |

## 常见问题

- **双击打开时提示“无法验证开发者” / 被 Gatekeeper 拦**：这是 ad-hoc 临时签名（本源码包未做 Apple 公证）。右键点击 `PondPets.app` → 选择“打开” → 再点“打开”，即可运行一次；之后双击就能打开。
- **桌面图标点不了？** 正常：平时池塘贴在桌面图标后面、`ignoresMouseEvents`，完全不挡操作。想喂鱼时才开“摸鱼模式”。
- **全屏 App 时池塘不见了？** 正常：壁纸窗口不进全屏空间，不抢镜。
- **换了显示器 / 插拔外接屏？** App 会自动按当前屏幕重建窗口，每块屏一个池塘。

## 原型 vs 真实壁纸

|  | 浏览器原型（space-2） | 真实壁纸（本包） |
|---|---|---|
| 本质 | 带模拟 Mac 外壳（菜单栏/Dock/桌面图标/名册/按钮/设计说明）的网页演示 | 真正的 Mac App，池塘铺在桌面壁纸层 |
| 鱼的记忆 | 刷新就重置 | 添的鱼、饱食度、互动次数存在本地（localStorage），下次打开还在 |
| 交互 | 点网页里的池塘区域 | 菜单栏 🐟 → 摸鱼模式 → 点真实桌面 |
| 音效 | 无 | 菜单开关 Web Audio 合成环境音 |

## 技术说明（给想改代码的人）

- 外壳：Swift + Cocoa + WebKit，4 个 Swift 文件；池塘是单文件 HTML（Canvas 2D），嵌进 WKWebView。
- Swift → 网页：`window.pond` 桥接：`setPaused(bool)` / `setSpeed(index)` / `setWeather(name)` / `setSound(key,on)` / `showPanel(bool)` / `setEmbedded(bool)` / `feed()` / `tapGlass()` / `addFish()`。
- 网页 → 本地：鱼数量 / 饱食度 / 互动次数经 `localStorage`（key：`pondPetsV1`）持久化；每块屏的 WebView 各自渲染，状态由 Swift 侧重推同步。
- 性能：桌面可见时渲染，暂停时跳过绘制；合盖 / 退出即停。

## 路线图 / Roadmap

- 更多鱼种与成长阶段（幼鱼 → 成鱼）
- 水质系统：喂食影响水质，需要定期“换水”
- 可选的锦鲤模式（经典配色）
- 截图分享：把你的池塘导出成一张图

## License

MIT — 见 [LICENSE](LICENSE)。
