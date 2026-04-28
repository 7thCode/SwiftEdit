import SwiftUI

struct ModelStoreView: View {
    @Environment(ModelStore.self) private var store
    @Environment(LLMService.self) private var llmService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("モデルストア")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Picker("", selection: $selectedTab) {
                Text("インストール済み").tag(0)
                Text("ブラウズ").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            if selectedTab == 0 {
                InstalledModelsTab()
            } else {
                BrowseTab()
            }

            Divider()

            // Model loading status bar
            ModelLoadingStatusBar()
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(minWidth: 500, minHeight: 420)
        .task {
            if store.searchResults.isEmpty {
                await store.search(query: "")
            }
        }
    }
}

// MARK: - Loading Status Bar

private struct ModelLoadingStatusBar: View {
    @Environment(LLMService.self) private var llmService

    var body: some View {
        HStack(spacing: 8) {
            switch llmService.modelState {
            case .notLoaded:
                Image(systemName: "cpu")
                    .foregroundStyle(.secondary)
                Text("モデル未選択")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .loading:
                ProgressView()
                    .controlSize(.small)
                Text("モデルを読み込み中...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .loaded(let name):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("読み込み完了: \(name)")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            case .error(let msg):
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
}

// MARK: - Installed Tab

private struct InstalledModelsTab: View {
    @Environment(ModelStore.self) private var store
    @Environment(LLMService.self) private var llmService

    var body: some View {
        if store.installedModels.isEmpty {
            ContentUnavailableView(
                "モデルなし",
                systemImage: "cpu",
                description: Text("「ブラウズ」タブからモデルをダウンロードしてください")
            )
        } else {
            List(store.installedModels) { model in
                InstalledModelRow(model: model)
            }
        }
    }
}

private struct InstalledModelRow: View {
    let model: InstalledModel
    @Environment(ModelStore.self) private var store
    @Environment(LLMService.self) private var llmService

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name).font(.headline)
                Text(model.repoId).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("ロード") {
                Task { await llmService.loadModel(from: model.url) }
            }
            .buttonStyle(.borderedProminent)
            Button(role: .destructive) {
                store.removeInstalled(model)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Browse Tab

private struct BrowseTab: View {
    @Environment(ModelStore.self) private var store
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("モデルを検索...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchTask?.cancel()
                        searchTask = Task {
                            try? await Task.sleep(for: .milliseconds(400))
                            guard !Task.isCancelled else { return }
                            await store.search(query: newValue)
                        }
                    }
                if store.isSearching {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top])
            .padding(.bottom, 8)

            if let err = store.searchError {
                Text(err).foregroundStyle(.red).padding()
            } else {
                List(store.searchResults) { model in
                    BrowseModelRow(model: model)
                }
            }
        }
    }
}

private struct BrowseModelRow: View {
    let model: HFModel
    @Environment(ModelStore.self) private var store

    var downloadState: DownloadState {
        store.downloadStates[model.id] ?? (store.isInstalled(repoId: model.id) ? .downloaded(URL(fileURLWithPath: "")) : .notDownloaded)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.shortName).font(.headline)
                Text(model.id).font(.caption).foregroundStyle(.secondary)
                if let dl = model.downloads {
                    Label("\(dl) DL", systemImage: "arrow.down.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            downloadButton
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var downloadButton: some View {
        switch downloadState {
        case .notDownloaded:
            Button("ダウンロード") {
                Task { await store.download(model: model) }
            }
            .buttonStyle(.borderedProminent)
        case .downloading(let progress):
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .frame(width: 80)
                Button("キャンセル") {
                    store.cancelDownload(repoId: model.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        case .downloaded:
            Label("インストール済み", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.callout)
        case .error:
            VStack(alignment: .trailing, spacing: 2) {
                Label("エラー", systemImage: "xmark.circle").foregroundStyle(.red).font(.callout)
                Button("再試行") {
                    Task { await store.download(model: model) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
