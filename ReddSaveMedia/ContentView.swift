import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var downloads: DownloadCoordinator
    @State private var username = ""
    @State private var items: [MediaItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Aucune connexion, aucun cookie et aucune API Reddit ne sont utilisés.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    TextField("Nom d’utilisateur Reddit", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        scan()
                    } label: {
                        if isLoading { ProgressView() } else { Label("Analyser les médias publics", systemImage: "magnifyingglass") }
                    }
                    .disabled(isLoading || username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: {
                    Text("Profil public")
                } footer: {
                    Text("Les contenus privés, supprimés, sauvegardés ou réservés à un compte ne sont pas accessibles.")
                }

                if !items.isEmpty {
                    Section {
                        Button {
                            downloads.download(items)
                        } label: {
                            Label("Télécharger les \(items.count) médias", systemImage: "arrow.down.circle.fill")
                        }
                        .disabled(downloads.isDownloading)
                        if downloads.isDownloading || downloads.completed > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                ProgressView(value: Double(downloads.completed), total: Double(max(downloads.total, 1)))
                                Text(downloads.status).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("\(items.count) média(s) public(s)")
                    }

                    Section("Médias trouvés") {
                        ForEach(items) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title).font(.headline).lineLimit(2)
                                Text(item.url.host ?? "Reddit")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                HStack {
                                    Link("Voir le profil", destination: item.permalink)
                                    Spacer()
                                    Button("Télécharger") { downloads.download([item]) }
                                        .buttonStyle(.bordered)
                                        .disabled(downloads.isDownloading)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                } else if !isLoading {
                    ContentUnavailableView("Aucun média chargé", systemImage: "photo.stack", description: Text("Saisissez un profil public, puis lancez l’analyse."))
                }
            }
            .navigationTitle("ReddSave Media")
            .alert("Attention", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Erreur inconnue")
            }
        }
    }

    private func scan() {
        isLoading = true
        items = []
        Task {
            defer { isLoading = false }
            do {
                items = try await PublicProfileCrawler.crawl(username: username)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
