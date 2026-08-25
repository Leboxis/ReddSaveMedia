import Foundation

struct MediaItem: Identifiable, Hashable {
    let id: String
    let author: String
    let url: URL

    var title: String { url.lastPathComponent.isEmpty ? url.host ?? "Média Reddit" : url.lastPathComponent }
    var permalink: URL { URL(string: "https://www.reddit.com/user/\(author)/submitted/")! }
    var urls: [URL] { [url] }
}
