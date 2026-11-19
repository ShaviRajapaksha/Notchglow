import SwiftUI

struct PermissionRow: View {
    let title: String
    let detail: String
    let granted: Bool
    let request: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle.dashed")
                .font(.title2)
                .foregroundStyle(granted ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if granted {
                    Text("Granted").font(.caption).foregroundStyle(.green)
                } else {
                    HStack {
                        Button("Request Access", action: request)
                        Button("Open System Settings", action: openSettings)
                    }.controlSize(.small)
                }
            }
            Spacer()
        }
    }
}

struct PermissionRowsView: View {
    @ObservedObject var permissions: PermissionsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PermissionRow(
                title: "Input Monitoring",
                detail: "Lets macOS deliver key-press events to NotchGlow so it can react while you type in other apps.",
                granted: permissions.inputMonitoringGranted,
                request: permissions.requestInputMonitoring,
                openSettings: permissions.openInputMonitoringSettings)
            PermissionRow(
                title: "Accessibility",
                detail: "An alternative way to allow the same thing. You only need to grant ONE of the two.",
                granted: permissions.accessibilityGranted,
                request: permissions.requestAccessibility,
                openSettings: permissions.openAccessibilitySettings)
        }
    }
}

struct PrivacyNote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Your typing stays private", systemImage: "lock.shield.fill").font(.headline)
            Text("NotchGlow only notices that a key was pressed and when. It never reads, records, stores, logs or transmits what you type, and it makes no network connections.")
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
