import SwiftUI
import AppKit

/// Rounded container. Deliberately a flat fill, not a blur material: live blurs on every card made switching
/// panes stutter while the preview was animating.
struct Card<Content: View>: View {
    let title: String?
    let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title { Text(title).font(.headline) }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    var decimals: Int = 0
    var unit: String = ""
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.\(decimals)f", value) + unit)
                    .foregroundStyle(.secondary).monospacedDigit()
            }
            if let step {
                Slider(value: $value, in: range, step: step)
            } else {
                Slider(value: $value, in: range)
            }
            if let note {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

/// Generates demo typing for the live preview.
final class PreviewDemo: ObservableObject {
    @Published var autoDemo = true {
        didSet { autoDemo ? scheduleNext(0.3) : cancel() }
    }
    private let engine: VisualizerEngine
    private var work: DispatchWorkItem?
    private var remaining = 0
    private var fast = true

    init(engine: VisualizerEngine) { self.engine = engine }

    func start() { if autoDemo { scheduleNext(0.4) } }
    func stop() { cancel() }

    private func cancel() { work?.cancel(); work = nil }

    private func scheduleNext(_ delay: TimeInterval) {
        work?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.step() }
        work = w
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: w)
    }

    private func step() {
        guard autoDemo else { return }
        if remaining <= 0 {
            remaining = Int.random(in: 14...40)
            fast = Bool.random()
        }
        engine.registerKeystroke()
        remaining -= 1
        if remaining <= 0 {
            scheduleNext(Double.random(in: 2.4...3.8))
        } else {
            scheduleNext(fast ? Double.random(in: 0.04...0.09) : Double.random(in: 0.14...0.30))
        }
    }

    func burst() {
        for i in 0..<14 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) { [weak self] in
                self?.engine.registerKeystroke()
            }
        }
    }
}

/// Live preview shown above every settings pane. Reacts to every setting change in real time.
struct PreviewPanel: View {
    let engine: VisualizerEngine
    @StateObject private var demo: PreviewDemo

    init(engine: VisualizerEngine) {
        self.engine = engine
        _demo = StateObject(wrappedValue: PreviewDemo(engine: engine))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Color(white: 0.06), Color(white: 0.12)],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 26).padding(.horizontal, 14)      // mock menu bar
                VisualizerPreview(engine: engine)
            }
            HStack(spacing: 10) {
                Toggle("Auto-demo", isOn: $demo.autoDemo)
                    .toggleStyle(.switch).controlSize(.small)
                Button("Type burst") { demo.burst() }.controlSize(.small)
            }
            .padding(10)
            .environment(\.colorScheme, .dark)
        }
        .frame(height: 160)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .onAppear { demo.start() }
        .onDisappear { demo.stop() }
    }
}
