import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, styles, appearance, dimensions, behavior, permissions, about
    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: return "General"
        case .styles: return "Animation Styles"
        case .appearance: return "Appearance"
        case .dimensions: return "Dimensions"
        case .behavior: return "Behavior"
        case .permissions: return "Permissions"
        case .about: return "About"
        }
    }
    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .styles: return "wand.and.stars"
        case .appearance: return "paintpalette"
        case .dimensions: return "ruler"
        case .behavior: return "slider.horizontal.3"
        case .permissions: return "lock.shield"
        case .about: return "info.circle"
        }
    }
}

struct SettingsRootView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var permissions: PermissionsManager
    let previewEngine: VisualizerEngine
    @State private var selection: SettingsPane

    init(settings: SettingsManager, permissions: PermissionsManager,
         previewEngine: VisualizerEngine, initialPane: SettingsPane = .general) {
        self.settings = settings
        self.permissions = permissions
        self.previewEngine = previewEngine
        _selection = State(initialValue: initialPane)
    }

    var body: some View {
        HStack(spacing: 0) {
            List(selection: $selection) {
                ForEach(SettingsPane.allCases) { pane in
                    Label(pane.title, systemImage: pane.symbol).tag(pane)
                }
            }
            .listStyle(.sidebar)
            .frame(width: 200)

            Divider()

            VStack(spacing: 0) {
                PreviewPanel(engine: previewEngine)
                Divider()
                ScrollView {
                    detail.padding(20)
                }
            }
        }
        .frame(minWidth: 860, idealWidth: 920, minHeight: 640, idealHeight: 740)
        .background(VisualEffectBackground())
    }

    @ViewBuilder private var detail: some View {
        switch selection {
        case .general: GeneralPane(settings: settings)
        case .styles: StylesPane(settings: settings)
        case .appearance: AppearancePane(settings: settings)
        case .dimensions: DimensionsPane(settings: settings)
        case .behavior: BehaviorPane(settings: settings)
        case .permissions: PermissionsPane(permissions: permissions)
        case .about: AboutPane()
        }
    }
}
