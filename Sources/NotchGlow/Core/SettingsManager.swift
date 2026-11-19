import Foundation
import SwiftUI
import Combine

/// Owns and persists all settings (UserDefaults, JSON). Saves are debounced.
final class SettingsManager: ObservableObject {
    @Published var config: AnimationConfiguration { didSet { scheduleSave() } }
    @Published var app: AppSettings { didSet { scheduleSave() } }

    private enum Keys {
        static let config = "animationConfiguration.v1"
        static let app = "appSettings.v1"
    }

    private let defaults = UserDefaults.standard
    private var saveWork: DispatchWorkItem?

    init() {
        var c = Self.load(AnimationConfiguration.self, key: Keys.config) ?? AnimationConfiguration()
        c.normalize()
        self.config = c
        self.app = Self.load(AppSettings.self, key: Keys.app) ?? AppSettings()
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func scheduleSave() {
        saveWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.flush() }
        saveWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func flush() {
        saveWork?.cancel()
        let enc = JSONEncoder()
        if let d = try? enc.encode(config) { defaults.set(d, forKey: Keys.config) }
        if let d = try? enc.encode(app) { defaults.set(d, forKey: Keys.app) }
    }

    func resetAll() {
        let onboarded = app.hasCompletedOnboarding
        config = AnimationConfiguration()
        app = AppSettings()
        app.hasCompletedOnboarding = onboarded
    }

    func resetAnimation() {
        let style = config.style
        config = AnimationConfiguration()
        config.style = style
    }

    // MARK: SwiftUI bindings
    func binding<T>(_ kp: WritableKeyPath<AnimationConfiguration, T>) -> Binding<T> {
        Binding(get: { self.config[keyPath: kp] }, set: { self.config[keyPath: kp] = $0 })
    }

    func intBinding(_ kp: WritableKeyPath<AnimationConfiguration, Int>) -> Binding<Double> {
        Binding(get: { Double(self.config[keyPath: kp]) }, set: { self.config[keyPath: kp] = Int($0.rounded()) })
    }

    func appBinding<T>(_ kp: WritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(get: { self.app[keyPath: kp] }, set: { self.app[keyPath: kp] = $0 })
    }

    func colorBinding(_ index: Int) -> Binding<Color> {
        Binding(
            get: { self.config.colors[index].color },
            set: { self.config.colors[index] = CodableColor($0) }
        )
    }
}
