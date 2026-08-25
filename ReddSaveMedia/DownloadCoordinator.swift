import Foundation

@MainActor
final class DownloadCoordinator: ObservableObject {
    @Published private(set) var completed = 0
    @Published private(set) var total = 0
    @Published private(set) var status = "Prêt"
    @Published private(set) var isDownloading = false

    func download(_ items: [MediaItem]) {
        guard !items.isEmpty, !isDownloading else { return }
        let jobs = items.flatMap { item in item.urls.map { (item.id, $0) } }
        total = jobs.count
        completed = 0
        isDownloading = true
        status = "Préparation de \(jobs.count) média(s)…"
        Task {
            defer { isDownloading = false; status = "Terminé : \(completed)/\(total) média(s)" }
            for (postID, url) in jobs {
                do {
                    try await save(url, postID: postID)
                    completed += 1
                    status = "Téléchargé \(completed)/\(total)"
                } catch {
                    status = "Un média n’a pas pu être téléchargé : \(error.localizedDescription)"
                }
            }
        }
    }

    private func save(_ url: URL, postID: String) async throws {
        var request = URLRequest(url: url)
        request.setValue("ReddSaveMedia/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        let (temporaryURL, response) = try await URLSession.shared.download(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let folder = try archiveFolder()
        let ext = url.pathExtension.isEmpty ? inferredExtension(response) : url.pathExtension
        let fileName = "\(postID)-\(UUID().uuidString.prefix(8)).\(ext)"
        let destination = folder.appendingPathComponent(fileName)
        try FileManager.default.moveItem(at: temporaryURL, to: destination)
    }

    private func archiveFolder() throws -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("ReddSave Media", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func inferredExtension(_ response: URLResponse) -> String {
        switch response.mimeType {
        case "image/jpeg": return "jpg"
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "video/mp4": return "mp4"
        default: return "bin"
        }
    }
}
