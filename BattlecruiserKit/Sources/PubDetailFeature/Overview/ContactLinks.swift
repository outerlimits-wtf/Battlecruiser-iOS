import Foundation
import PubDBModels

/// Which contact links to offer, and where they go.
enum ContactLinks {
    struct Item {
        let title: String
        let systemImage: String
        let url: URL
    }

    static func all(_ contact: Contact) -> [Item] {
        var items: [Item] = []
        if let url = web(contact.website) { items.append(Item(title: "Website", systemImage: "safari", url: url)) }
        if let phone = contact.phone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })"), !phone.isEmpty {
            items.append(Item(title: phone, systemImage: "phone", url: url))
        }
        if let email = contact.email, let url = URL(string: "mailto:\(email)") {
            items.append(Item(title: email, systemImage: "envelope", url: url))
        }
        if let url = web(contact.facebook) { items.append(Item(title: "Facebook", systemImage: "link", url: url)) }
        if let url = web(contact.instagram) { items.append(Item(title: "Instagram", systemImage: "camera", url: url)) }
        return items
    }

    /// Only full web addresses; anything else isn't a link we can trust.
    private static func web(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string), url.scheme == "https" || url.scheme == "http" else { return nil }
        return url
    }
}
