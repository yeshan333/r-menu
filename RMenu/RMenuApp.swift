import SwiftUI

@main
struct RMenuApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
        } label: {
            Label(AppConstants.appName, systemImage: "folder.badge.gearshape")
        }
    }
}
