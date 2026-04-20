import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    /// 当前菜单使用的应用列表（每次 menu(for:) 时刷新）
    private var menuApps: [ExternalApp] = []

    /// 缓存：内置应用中已安装的列表（init 时检测一次，避免每次右键重复检测）
    private var cachedBuiltinApps: [ExternalApp] = []

    /// 图标缓存，避免每次右键重复读取
    private var iconCache: [String: NSImage] = [:]

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/")
        ]
        cachedBuiltinApps = detectInstalledBuiltinApps()
    }

    override func beginObservingDirectory(at url: URL) {}

    override func endObservingDirectory(at url: URL) {}

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: AppConstants.appName)
        menuApps = buildAppList()

        for (index, app) in menuApps.enumerated() {
            let item = NSMenuItem(
                title: "通过 \(app.name) 打开",
                action: #selector(handleOpenApp(_:)),
                keyEquivalent: ""
            )
            item.tag = index
            item.image = cachedIcon(for: app.appPath)
            menu.addItem(item)
        }

        if !menuApps.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        let copyPathItem = NSMenuItem(
            title: "复制路径",
            action: #selector(handleCopyPath(_:)),
            keyEquivalent: ""
        )
        copyPathItem.image = NSImage(systemSymbolName: "doc.on.doc",
                                     accessibilityDescription: nil)
        menu.addItem(copyPathItem)

        return menu
    }

    // MARK: - Actions

    @objc func handleOpenApp(_ sender: NSMenuItem) {
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return }
        let index = sender.tag
        guard index >= 0, index < menuApps.count else { return }
        OpenAppAction.execute(app: menuApps[index], urls: urls)
    }

    @objc func handleCopyPath(_ sender: NSMenuItem) {
        let urls = resolveTargetURLs()
        guard !urls.isEmpty else { return }
        CopyPathAction.execute(urls: urls)
    }

    // MARK: - App Detection

    /// 启动时检测一次内置应用（只用快速的 fileExists，不启动 Process）
    private func detectInstalledBuiltinApps() -> [ExternalApp] {
        ExternalApp.allApps.filter { app in
            FileManager.default.fileExists(atPath: app.appPath)
        }
    }

    /// 构建菜单应用列表（使用缓存的内置应用 + 实时读取自定义应用）
    private func buildAppList() -> [ExternalApp] {
        var apps = cachedBuiltinApps

        let customApps = CustomAppStore.load()
        for custom in customApps {
            let alreadyExists = apps.contains { $0.appPath == custom.appPath }
            guard !alreadyExists else { continue }
            guard FileManager.default.fileExists(atPath: custom.appPath) else { continue }
            apps.append(ExternalApp(
                name: custom.name,
                bundleID: "",
                appPath: custom.appPath,
                cliNames: []
            ))
        }

        return apps
    }

    // MARK: - Helpers

    private func resolveTargetURLs() -> [URL] {
        if let selected = FIFinderSyncController.default().selectedItemURLs(),
           !selected.isEmpty {
            return selected
        }
        if let targeted = FIFinderSyncController.default().targetedURL() {
            return [targeted]
        }
        return []
    }

    /// 带缓存的图标获取
    private func cachedIcon(for path: String) -> NSImage? {
        if let cached = iconCache[path] { return cached }
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: path)
        icon.size = NSSize(width: 16, height: 16)
        iconCache[path] = icon
        return icon
    }
}
