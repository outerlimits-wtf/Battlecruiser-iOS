import SwiftUI
import PubDBClient
import PubDBModels

/// TEMPORARY (milestone 2): proves the app reaches production through
/// BattlecruiserKit by listing real pubs. Delete in milestone 3, when the map
/// replaces it. It lives in the app target only because it is throwaway; real
/// screens go in feature modules (decision D24).
struct DebugPubListView: View {
    /// Central London, around Trafalgar Square.
    private let area = BoundingBox(west: -0.135, south: 51.505, east: -0.120, north: 51.512)
    private let client = PubDBClient()

    @State private var pubs: [PubSummary] = []
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
                ForEach(pubs) { pub in
                    row(for: pub)
                }
            }
            .overlay {
                if isLoading && pubs.isEmpty { ProgressView() }
            }
            .navigationTitle("PubDB (debug)")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func row(for pub: PubSummary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🚢 \(pub.name)").font(.headline)
            HStack {
                Text(pub.open.label)
                if let guinness = pub.guinness { Text("· \(guinness.formatted)") }
                if let tonight = pub.tonight { Text("· \(tonight.label)") }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await client.pubs(in: area, limit: 20)
            pubs = list.pubs
            errorMessage = list.droppedCount > 0 ? "\(list.droppedCount) pubs could not be decoded" : nil
        } catch is CancellationError {
            // The view went away or refreshed again; nothing to report.
        } catch let error as PubDBError {
            errorMessage = error.userMessage + "\n\(error)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    DebugPubListView()
}
