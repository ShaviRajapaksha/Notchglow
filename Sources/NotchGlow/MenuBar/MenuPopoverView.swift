import SwiftUI

struct MenuPopoverView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var permissions: PermissionsManager
    let openSettings: (SettingsPane?) -> Void
    let openOnboarding: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path").font(.title3).foregroundStyle(.tint)
                Text("NotchGlow").font(.headline)
                Spacer()
                Toggle("", isOn: settings.appBinding(\.isEnabled))
                    .toggleStyle(.switch).labelsHidden()
            }

            if settings.app.reactToTyping && !permissions.isSufficient {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Permission needed to react to typing in other apps.")
                            .font(.callout).fixedSize(horizontal: false, vertical: true)
                        Button("Grant Access…", action: openOnboarding).controlSize(.small)
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.orange.opacity(0.12)))
            }

            Toggle("Pause all detection", isOn: settings.appBinding(\.detectionPaused))
                .disabled(!settings.app.isEnabled)
            Toggle("React to typing", isOn: settings.appBinding(\.reactToTyping))
                .disabled(!settings.app.isEnabled)
            Toggle("React to music & system sound", isOn: settings.appBinding(\.reactToSystemAudio))
                .disabled(!settings.app.isEnabled)

            Divider()

            Text("ANIMATION STYLE").font(.caption2).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(AnimationStyle.allCases) { style in
                    let selected = settings.config.style == style
                    Button {
                        settings.config.style = style
                    } label: {
                        Label(style.title, systemImage: style.symbol)
                            .font(.callout)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6).padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(selected ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            Text("LAYER").font(.caption2).foregroundStyle(.secondary)
            Picker("Layer", selection: settings.appBinding(\.layer)) {
                ForEach(OverlayLayer.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider()

            HStack {
                Button("Customize…") { openSettings(nil) }
                Spacer()
                Button("Quit", action: quit)
            }
        }
        .padding(14)
        .frame(width: 310)
    }
}
