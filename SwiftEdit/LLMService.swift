import Foundation
import Observation
import MLXLLM
import MLXLMCommon
import Tokenizers

// MARK: - Tokenizer Bridge (Tokenizers.Tokenizer → MLXLMCommon.Tokenizer)

private struct TokenizerBridge: MLXLMCommon.Tokenizer {
    private let upstream: any Tokenizers.Tokenizer

    init(_ upstream: any Tokenizers.Tokenizer) {
        self.upstream = upstream
    }

    func encode(text: String, addSpecialTokens: Bool) -> [Int] {
        upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
    }

    func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
        upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
    }

    func convertTokenToId(_ token: String) -> Int? {
        upstream.convertTokenToId(token)
    }

    func convertIdToToken(_ id: Int) -> String? {
        upstream.convertIdToToken(id)
    }

    var bosToken: String? { upstream.bosToken }
    var eosToken: String? { upstream.eosToken }
    var unknownToken: String? { upstream.unknownToken }

    func applyChatTemplate(
        messages: [[String: any Sendable]],
        tools: [[String: any Sendable]]?,
        additionalContext: [String: any Sendable]?
    ) throws -> [Int] {
        do {
            return try upstream.applyChatTemplate(
                messages: messages, tools: tools, additionalContext: additionalContext)
        } catch Tokenizers.TokenizerError.missingChatTemplate {
            throw MLXLMCommon.TokenizerError.missingChatTemplate
        }
    }
}

// MARK: - Local Tokenizer Loader

private struct LocalTokenizerLoader: MLXLMCommon.TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        let upstream = try await Tokenizers.AutoTokenizer.from(modelFolder: directory)
        return TokenizerBridge(upstream)
    }
}

// MARK: - Model State

enum ModelState: Equatable {
    case notLoaded
    case loading
    case loaded(String)
    case error(String)
}

// MARK: - LLM Service

@Observable
@MainActor
final class LLMService {
    var modelState: ModelState = .notLoaded
    var isGenerating = false

    private var modelContainer: ModelContainer?
    private var generationTask: Task<Void, Never>?

    func loadModel(from url: URL) async {
        modelState = .loading
        do {
            let container = try await LLMModelFactory.shared.loadContainer(
                from: url,
                using: LocalTokenizerLoader()
            )
            modelContainer = container
            modelState = .loaded(url.lastPathComponent)
        } catch {
            modelState = .error(error.localizedDescription)
        }
    }

    func generate(
        documentText: String,
        userPrompt: String,
        onToken: @escaping @Sendable (String) -> Void,
        onComplete: @escaping @Sendable () -> Void
    ) {
        guard let container = modelContainer, !isGenerating else { return }

        isGenerating = true
        generationTask = Task {
            defer {
                isGenerating = false
                onComplete()
            }
            do {
                let messages: [[String: any Sendable]] = [
                    ["role": "system", "content": "You are a helpful writing assistant. The user is editing the following document:\n\n\(documentText)"],
                    ["role": "user", "content": userPrompt],
                ]
                let userInput = UserInput(prompt: .messages(messages))
                let lmInput = try await container.prepare(input: userInput)
                let stream = try await container.generate(
                    input: lmInput,
                    parameters: GenerateParameters()
                )
                for await generation in stream {
                    if Task.isCancelled { break }
                    if let chunk = generation.chunk {
                        onToken(chunk)
                    }
                }
            } catch {
                onToken("\n[Error: \(error.localizedDescription)]")
            }
        }
    }

    func cancel() {
        generationTask?.cancel()
        generationTask = nil
        isGenerating = false
    }
}
