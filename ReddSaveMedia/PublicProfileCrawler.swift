import Foundation

/// Reads only public HTML pages. It deliberately does not use Reddit JSON/API routes,
/// OAuth, a WebView session, cookies, or account credentials.
enum PublicProfileCrawler {
    enum CrawlError: LocalizedError {
        case invalidUsername
        case invalidPage
        case noMedia

        var errorDescription: String? {
            switch self {
            case .invalidUsername: return "Indiquez un nom d’utilisateur valide."
            case .invalidPage: return "La page publique Reddit n’a pas pu être lue."
            case .noMedia: return "Aucun média public n’a été trouvé sur les pages accessibles de ce profil."
            }
        }
    }

    /// The page limit prevents an accidental unbounded crawl of a public profile.
    static func crawl(username rawUsername: String, maximumPages: Int = 20) async throws -> [MediaItem] {
        let username = try normalizedUsername(rawUsername)
        var visited = Set<URL>()
        var pending = [URL(string: "https://www.reddit.com/user/\(username)/submitted/")!]
        var media = Set<URL>()

        while let pageURL = pending.first, visited.count < maximumPages {
            pending.removeFirst()
            guard visited.insert(pageURL).inserted else { continue }
            let html = try await publicHTML(at: pageURL)
            media.formUnion(extractMediaURLs(from: html))
            let nextPages = extractPaginationURLs(from: html, username: username)
            pending.append(contentsOf: nextPages.filter { !visited.contains($0) && !pending.contains($0) })
        }

        let items = media.map { MediaItem(id: $0.absoluteString, author: username, url: $0) }
            .sorted { $0.url.absoluteString.localizedCaseInsensitiveCompare($1.url.absoluteString) == .orderedAscending }
        guard !items.isEmpty else { throw CrawlError.noMedia }
        return items
    }

    private static func normalizedUsername(_ value: String) throws -> String {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "u/", with: "")
            .replacingOccurrences(of: "/", with: "")
        guard !cleaned.isEmpty,
              cleaned.range(of: "^[A-Za-z0-9_-]{3,20}$", options: .regularExpression) != nil else {
            throw CrawlError.invalidUsername
        }
        return cleaned
    }

    private static func publicHTML(at url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("ReddSaveMedia/1.0 (public profile archiver)", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
              let html = String(data: data, encoding: .utf8) else { throw CrawlError.invalidPage }
        return html
    }

    private static func extractMediaURLs(from html: String) -> Set<URL> {
        let normalized = html
            .replacingOccurrences(of: "\\u002F", with: "/")
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "&amp;", with: "&")
        let matches = normalized.matches(for: #"https://(?:i|preview)\.redd\.it/[^\s\"'<>\\]+|https://v\.redd\.it/[^\s\"'<>\\]+/DASH_[0-9]+\.mp4[^\s\"'<>\\]*"#)
        let urls = matches.compactMap(URL.init(string:))
        let originals = urls.filter { $0.host == "i.redd.it" }
        let videos = bestVideoURLs(urls.filter { $0.host == "v.redd.it" })
        // Original i.redd.it assets take precedence over resized preview URLs.
        return Set(originals + videos)
    }

    private static func bestVideoURLs(_ urls: [URL]) -> [URL] {
        let grouped = Dictionary(grouping: urls, by: { $0.deletingLastPathComponent().absoluteString })
        return grouped.values.compactMap { candidates in
            candidates.max { videoHeight($0) < videoHeight($1) }
        }
    }

    private static func videoHeight(_ url: URL) -> Int {
        url.lastPathComponent.firstMatch(for: #"DASH_([0-9]+)\.mp4"#).flatMap(Int.init) ?? 0
    }

    private static func extractPaginationURLs(from html: String, username: String) -> [URL] {
        let pattern = #"href=[\"']([^\"']*/user/"# + NSRegularExpression.escapedPattern(for: username) + #"/submitted/\?[^\"']+)[\"']"#
        return html.matches(for: pattern, captureGroup: 1).compactMap { link in
            URL(string: link, relativeTo: URL(string: "https://www.reddit.com"))?.absoluteURL
        }
    }
}

private extension String {
    func matches(for pattern: String, captureGroup: Int = 0) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard match.numberOfRanges > captureGroup, let range = Range(match.range(at: captureGroup), in: self) else { return nil }
            return String(self[range])
        }
    }

    func firstMatch(for pattern: String) -> String? {
        matches(for: pattern, captureGroup: 1).first
    }
}
