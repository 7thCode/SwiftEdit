import Foundation
import Hub
import Observation

// MARK: - HuggingFace API Response

struct HFModel: Identifiable, Decodable {
    let id: String
    let downloads: Int?
    let likes: Int?

    var shortName: String { id.split(separator: "/").last.map(String.init) ?? id }
}

// MARK: - Download State

enum DownloadState: Equatable {
    case notDownloaded
    case downloading(Double)
    case downloaded(URL)
    case error(String)
}

// MARK: - Downloaded Model Entry

struct InstalledModel: Identifiable, Codable {
    let id: UUID
    let repoId: String
    let localPath: String

    var url: URL { URL(fileURLWithPath: localPath) }
    var name: String { repoId.split(separator: "/").last.map(String.init) ?? repoId }
}

// MARK: - Model Store

@Observable
@MainActor
final class ModelStore {
    var searchResults: [HFModel] = []
    var isSearching = false
    var searchError: String?

    var downloadStates: [String: DownloadState] = [:]
    var installedModels: [InstalledModel] = []

    private let installedKey = "installedModels"

    init() {
        loadInstalled()
    }

    // MARK: Search

    func search(query: String) async {
        isSearching = true
        searchError = nil
        do {
            var components = URLComponents(string: "https://huggingface.co/api/models")!
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "filter", value: "mlx"),
                URLQueryItem(name: "limit", value: "50"),
                URLQueryItem(name: "sort", value: "downloads"),
                URLQueryItem(name: "direction", value: "-1"),
            ]
            if !query.isEmpty {
                queryItems.append(URLQueryItem(name: "search", value: query))
            } else {
                queryItems.append(URLQueryItem(name: "author", value: "mlx-community"))
            }
            components.queryItems = queryItems
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let models = try JSONDecoder().decode([HFModel].self, from: data)
            searchResults = models
        } catch {
            searchError = error.localizedDescription
        }
        isSearching = false
    }

    // MARK: Download

    func download(model: HFModel) async {
        let repoId = model.id
        downloadStates[repoId] = .downloading(0)

        do {
            let hub = HubApi()
            let localURL = try await hub.snapshot(from: repoId, matching: ["*.json", "*.safetensors", "*.gguf"]) { progress in
                Task { @MainActor in
                    self.downloadStates[repoId] = .downloading(progress.fractionCompleted)
                }
            }
            downloadStates[repoId] = .downloaded(localURL)
            addInstalled(repoId: repoId, url: localURL)
        } catch {
            downloadStates[repoId] = .error(error.localizedDescription)
        }
    }

    func cancelDownload(repoId: String) {
        downloadStates[repoId] = .notDownloaded
    }

    // MARK: Installed management

    func removeInstalled(_ model: InstalledModel) {
        installedModels.removeAll { $0.id == model.id }
        saveInstalled()
    }

    private func addInstalled(repoId: String, url: URL) {
        let entry = InstalledModel(id: UUID(), repoId: repoId, localPath: url.path)
        if !installedModels.contains(where: { $0.repoId == repoId }) {
            installedModels.append(entry)
            saveInstalled()
        }
    }

    private func saveInstalled() {
        if let data = try? JSONEncoder().encode(installedModels) {
            UserDefaults.standard.set(data, forKey: installedKey)
        }
    }

    private func loadInstalled() {
        guard let data = UserDefaults.standard.data(forKey: installedKey),
              let models = try? JSONDecoder().decode([InstalledModel].self, from: data) else { return }
        installedModels = models
    }

    func isInstalled(repoId: String) -> Bool {
        installedModels.contains { $0.repoId == repoId }
    }
}
