import AppKit
import UserNotifications

// Parse --key value arguments
func arg(_ key: String) -> String? {
    let args = CommandLine.arguments
    guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
    return args[i + 1]
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ n: Notification) {
        guard let title = arg("--title") else {
            fputs("Usage: lite-notifier --title <text> [--message <text>] [--icon <path>] [--activate <bundle-id>]\n", stderr)
            NSApp.terminate(nil)
            return
        }

        // Set app icon so it shows correctly in notification header
        if let path = arg("--icon"), !path.isEmpty, let icon = NSImage(contentsOfFile: path) {
            NSApp.applicationIconImage = icon
        } else if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { fputs("auth error: \(error)\n", stderr) }
            guard granted else {
                fputs("notification permission denied — grant in System Settings → Notifications\n", stderr)
                DispatchQueue.main.async { NSApp.terminate(nil) }
                return
            }
            self.deliver(center: center, title: title,
                         message:  arg("--message") ?? "",
                         iconPath: arg("--icon") ?? "",
                         activate: arg("--activate") ?? "")
        }
    }

    func deliver(center: UNUserNotificationCenter, title: String, message: String,
                 iconPath: String, activate: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = message
        #if WITH_SOUND
        content.sound = .default
        #endif
        if !activate.isEmpty { content.userInfo = ["activate": activate] }
        if !iconPath.isEmpty {
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("ln-icon-\(UUID()).\(URL(fileURLWithPath: iconPath).pathExtension)")
            if (try? FileManager.default.copyItem(atPath: iconPath, toPath: tmp.path)) != nil,
               let attachment = try? UNNotificationAttachment(identifier: "icon", url: tmp, options: nil) {
                content.attachments = [attachment]
            }
        }

        let req = UNNotificationRequest(identifier: "ln-\(UUID())", content: content, trigger: nil)
        center.add(req) { err in
            if let err { fputs("add error: \(err)\n", stderr) }
            let delay: Double = activate.isEmpty ? 0.5 : 30.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { NSApp.terminate(nil) }
        }
    }

    // Show banner even when this process is frontmost
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification,
        withCompletionHandler h: @escaping (UNNotificationPresentationOptions) -> Void) {
        h([.banner, .sound])
    }

    // Notification clicked — activate target app
    func userNotificationCenter(_ c: UNUserNotificationCenter, didReceive r: UNNotificationResponse,
        withCompletionHandler h: @escaping () -> Void) {
        if let bundle = r.notification.request.content.userInfo["activate"] as? String,
           !bundle.isEmpty,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) {
            NSWorkspace.shared.open(url)
        }
        h()
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // allows permission dialog; no dock icon
let delegate = AppDelegate()
app.delegate = delegate
app.run()
