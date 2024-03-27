//
//  OpenAiService.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 6/3/2024.
//

import Foundation
import KeychainSwift

enum OpenAIError: Error, Equatable {
    case missingAPIKey
    case invalidAPIKey
    case invalidAPIUrl
    case malformedRequestBody
    case requestFailed(String)
}

extension OpenAIError {
    public var localizedDescription: String {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .invalidAPIUrl:
            return "Invalid API URL"
        case .malformedRequestBody:
            return "Malformed request body"
        case .missingAPIKey:
            return "Missing API key, please enter it in the settings"
        case let .requestFailed(error):
            return "Request failed: \(error)"
        }
    }
}

struct OpenAIKey: Equatable, Hashable {
    @Redacted var key: String
}

struct LLMPrompt {
    public let system: String
    public let instruction: String
}

actor OpenAIService {
    public static let supportedModels = [
        "gpt-4",
        "gpt-4-32k",
        "gpt-3.5-turbo",
        "gpt-3.5-turbo-0125",
        "gpt-3.5-turbo-16k",
        "gpt-4-0125-preview",
        "gpt-4-turbo-preview",
        "gpt-4-1106-preview"
    ]
    
    public static let question = LLMPrompt(
        system:
            """
            Your task is to take a list of notes and extract any cross-cutting themes or interesting patterns about the set as a whole. These notes have been selected by a user while browsing a large network of notes. These notes each have an address of the format @username/path-to-note (or /path-to-note for our own notes) and may reference one another using this naming scheme. \n\nAs part of your summary you should include any particularly relevant links that did not appear in the input set. Respond with 10 questions based on your analysis with at most 6 words in each and up to 10 addresses of recommended notes that do not appear in the input set.
            """,
        instruction:
            """
            Summarize your analysis into one incisive question, phrased to be thought provoking to a user, keep it at a maximum of 8 words.
            """
    )
    
    public static let summarize = LLMPrompt(
        system:
            """
            Your task is to take a list of notes and summarize the key ideas in 3 short dot points. These notes have been selected by a user while browsing a large network of notes. These notes each have an address of the format @username/path-to-note (or /path-to-note for our own notes) and may reference one another using this naming scheme. Ensure you mention any named entities, dates, or other important details.
            """,
        instruction:
            """
            Summarize your analysis into 3 dot points, each at most 6 words long. For example:
            
            - In a random world intelligence is useless
            - Typescript is a typed superset of JavaScript
            - A monad is like a burrito
            
            Your dot points:
            """
    )
    
    public static let poem = LLMPrompt(
        system:
            """
            Your task is to take a list of notes and summarize the key ideas in a 3 line haiku poem. These notes have been selected by a user while browsing a large network of notes. These notes each have an address of the format @username/path-to-note (or /path-to-note for our own notes) and may reference one another using this naming scheme. Ensure you mention any named entities, dates, or other important details.
            """,
        instruction:
            """
            Summarize your analysis in a haiku. For example:
            
            in a random world,
            monad is not burrito,
            life is made of toys
            
            Your haiku:
            """
    )
    
    public static let contemplate = LLMPrompt(
        system:
            """
            Your task is to take a list of notes, reflect on them and respond with a question that makes you curious. These notes have been selected by a user while browsing a large network of notes. These notes each have an address of the format @username/path-to-note (or /path-to-note for our own notes) and may reference one another using this naming scheme. Ensure you mention any named entities, dates, or other important details.
            """,
        instruction:
            """
            Respond with a single question that these notes make you want to ask. For example:
            
            When should we prefer imagination over measurement?
            
            Your question:
            """
    )
    
    public static let prompts = [
        OpenAIService.contemplate,
        OpenAIService.poem,
        OpenAIService.question,
        OpenAIService.summarize
    ]
    
    let keychain: KeychainService
    
    init(keychain: KeychainService) {
        self.keychain = keychain
    }
    
    let apiUrl = "https://api.openai.com/v1/chat/completions"
    
    private func formatNotes(entries: [EntryStub], prompt: LLMPrompt) -> String {
        return """
        Here are the notes to analyze:
        
        \(entries.map { entry in
            """
            \(entry.address)
            ```
            \(entry.excerpt.description)
            ```
            """
        }.joined(separator: "\n\n"))
        
        ---
        
        \(prompt.instruction)
        """
    }

    func sendRequest(
        entries: [EntryStub],
        prompt: LLMPrompt
    ) async -> Result<String, OpenAIError> {
        guard let url = URL(string: apiUrl) else {
            return .failure(OpenAIError.invalidAPIUrl)
        }

        var request = URLRequest(url: url)
        guard let apiKey = await keychain.getApiKey(), !apiKey.isEmpty else {
            return .failure(OpenAIError.missingAPIKey)
        }
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let requestBody: [String: Any] = [
            "model": AppDefaults.standard.preferredLlm,
            "messages": [
                ["role": "system", "content": prompt.system],
                ["role": "user", "content": formatNotes(entries: entries, prompt: prompt)]
            ],
            "max_tokens": 512,
            "temperature": 1,
        ]

        do {
            request.httpBody = try JSONSerialization.data(
                withJSONObject: requestBody,
                options: .prettyPrinted
            )
        } catch {
            return .failure(OpenAIError.malformedRequestBody)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(
                    OpenAIError.requestFailed(
                        "Could not parse response"
                    )
                )
            }
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let textResponse = jsonResponse["choices"] as? [[String: Any]],
               let firstChoice = textResponse.first,
               let reply = firstChoice["message"] as? [String: Any],
               let content = reply["content"] as? String
            {
                return .success(content)
            } else {
                return .failure(
                    OpenAIError.requestFailed(
                        "Deserialization failed"
                    )
                )
            }
        } catch {
            return .failure(OpenAIError.requestFailed(error.localizedDescription))
        }
    }
}
