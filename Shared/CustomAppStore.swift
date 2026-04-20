import Foundation

struct CustomApp: Codable, Identifiable, Equatable {
    var id: String { appPath }
    let name: String
    let appPath: String
}

enum CustomAppStore {

    private static var configURL: URL {
        // 使用绝对路径（非沙盒），确保宿主 App 和扩展读写同一个文件
        let home = NSHomeDirectory().components(separatedBy: "/Library/Containers").first
            ?? ("/Users/" + NSUserName())
        let dir = URL(fileURLWithPath: home)
            .appendingPathComponent("Library/Application Support/RMenu")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("custom_apps.json")
    }

    static func load() -> [CustomApp] {
        guard let data = try? Data(contentsOf: configURL),
              let apps = try? JSONDecoder().decode([CustomApp].self, from: data) else {
            return []
        }
        return apps
    }

    static func save(_ apps: [CustomApp]) {
        guard let data = try? JSONEncoder().encode(apps) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    static func add(_ app: CustomApp) {
        var apps = load()
        guard !apps.contains(where: { $0.appPath == app.appPath }) else { return }
        apps.append(app)
        save(apps)
    }

    static func remove(at index: Int) {
        var apps = load()
        guard index >= 0, index < apps.count else { return }
        apps.remove(at: index)
        save(apps)
    }

    static func remove(_ app: CustomApp) {
        var apps = load()
        apps.removeAll { $0.appPath == app.appPath }
        save(apps)
    }
}
