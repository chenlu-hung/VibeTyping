import Foundation

/// OpenAI-compatible API client for post-transcription text correction.
actor LLMClient {
    static let shared = LLMClient()

    /// Send the raw transcription to an LLM for correction.
    /// Falls back to the original text on any error.
    func correctTranscription(_ rawText: String) async -> String {
        let settings = AppSettings.shared
        let baseURL = settings.llmEndpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard let url = URL(string: baseURL + "/v1/chat/completions") else {
            NSLog("VibeTyping: Invalid LLM endpoint URL: \(settings.llmEndpoint)")
            return rawText
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.llmApiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        let prompt = CorrectionPrompt.build(rawTranscription: rawText)

        let body: [String: Any] = [
            "model": settings.llmModel,
            "messages": [
                ["role": "system", "content": prompt.system],
                ["role": "user", "content": prompt.user]
            ],
            "temperature": 0.3,
            "max_tokens": max(rawText.count * 3, 200)
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            NSLog("VibeTyping: Failed to serialize LLM request: \(error)")
            return rawText
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                NSLog("VibeTyping: Invalid HTTP response from LLM")
                return rawText
            }

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? "unknown"
                NSLog("VibeTyping: LLM API returned status \(httpResponse.statusCode): \(body)")
                return rawText
            }

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                let corrected = content.trimmingCharacters(in: .whitespacesAndNewlines)
                return corrected.isEmpty ? rawText : corrected
            }

            NSLog("VibeTyping: Unexpected LLM response format")
            return rawText
        } catch {
            NSLog("VibeTyping: LLM request failed: \(error)")
            return rawText
        }
    }
}
