import SwiftUI
import DesignSystem
import PubDBModels

/// Website, phone, email, Facebook, Instagram: small pills, as on the web.
struct ContactPills: View {
    let contact: Contact

    var body: some View {
        let links = ContactLinks.all(contact)
        if !links.isEmpty {
            ChipFlow {
                ForEach(links, id: \.title) { link in
                    Link(destination: link.url) {
                        Label(link.title, systemImage: link.systemImage)
                    }
                    .buttonStyle(ChipStyle())
                }
            }
        }
    }
}
