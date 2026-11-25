import SwiftUI

/// Map or list. Goes when the web's sheet layout arrives (parity B5).
enum PubsMode: String, CaseIterable, Identifiable {
    case map = "Map"
    case list = "List"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .map: "map"
        case .list: "list.bullet"
        }
    }
}

struct ModePicker: View {
    @Binding var mode: PubsMode

    var body: some View {
        Picker("Show pubs as", selection: $mode) {
            ForEach(PubsMode.allCases) { mode in
                Label(mode.rawValue, systemImage: mode.systemImage).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
