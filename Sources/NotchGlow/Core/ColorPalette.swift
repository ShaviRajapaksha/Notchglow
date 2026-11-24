import Foundation

/// A ready-made three-color gradient (center to edge).
struct ColorPalette: Identifiable, Equatable {
    let id: String
    let name: String
    let colors: [CodableColor]

    init(id: String, name: String, hex: [String]) {
        self.id = id
        self.name = name
        self.colors = hex.map { CodableColor(hex: $0) }
    }

    static let all: [ColorPalette] = [
        ColorPalette(id: "aurora", name: "Aurora", hex: ["#38dbff", "#9e6bff", "#ff5cb8"]),
        ColorPalette(id: "ember",  name: "Ember",  hex: ["#ffd166", "#ff7a45", "#ff2d6f"]),
        ColorPalette(id: "lagoon", name: "Lagoon", hex: ["#7dffcf", "#2ec4ff", "#5b6bff"]),
        ColorPalette(id: "orchid", name: "Orchid", hex: ["#ff9de1", "#c77dff", "#6c5bff"]),
        ColorPalette(id: "mono",   name: "Mono",   hex: ["#ffffff", "#c9ccd6", "#8a8f9e"]),
        ColorPalette(id: "lime",   name: "Lime",   hex: ["#e8ff6a", "#7dff7a", "#1fd6a1"])
    ]
}
