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

actor OpenAIService {
    let keychain: KeychainService
    
    init(keychain: KeychainService) {
        self.keychain = keychain
    }
    
    let apiUrl = "https://api.openai.com/v1/chat/completions"
    
    private func formatNotes(entries: [EntryStub]) -> String {
        return """
        Please analyze these notes:
        
        \(entries.map { entry in
            """
            \(entry.address)
            ```
            \(entry.excerpt.description)
            ```
            """
        }.joined(separator: "\n\n"))
        
        ---
        
        Summarize your analysis into one incisive question, phrased to be thought provoking to a user, keep it at a maximum of 8 words.
        """
    }

    func sendTextToOpenAI(
        entries: [EntryStub]
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
            "model": "gpt-4-1106-preview",
            "messages": [
                ["role": "system", "content": "Your task is to take a list of notes and extract any cross-cutting themes or interesting patterns about the set as a whole. These notes have been selected by a user while browsing a large network of notes. These notes each have an address of the format @username/path-to-note (or /path-to-note for our own notes) and may reference one another using this naming scheme. \n\nAs part of your summary you should include any particularly relevant links that did not appear in the input set. Respond with 10 questions based on your analysis with at most 6 words in each and up to 10 addresses of recommended notes that do not appear in the input set."],
                ["role": "user", "content": formatNotes(entries: entries)]
            ],
            "max_tokens": 1280,
            "temperature": 1,
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
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
