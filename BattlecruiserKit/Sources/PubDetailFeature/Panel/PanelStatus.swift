import SwiftUI
import DesignSystem

/// While the detail loads: a spinner. If it fails: the reason and "Try again".
struct PanelStatus: View {
    let model: PubDetailModel

    var body: some View {
        if let error = model.lastError {
            StateView(.error(message: error.userMessage, retry: model.retry))
        } else if model.isLoading && model.detail == nil {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(Metrics.xl)
        }
    }
}
