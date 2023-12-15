//
//  GptManager.swift
//  Friend
//
//  Created by Yuki Takanashi on 2023/11/17.
//

import Foundation

let apiKey = "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"

class GptManager {
    
    func askGPT(question: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "error"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(
            RequestBody(
                model: "gpt-3.5-turbo",
                messages: [RequestBody.Message(role: "system", content: "you are my friend Please speak as if you were having a normal conversation."),
                           RequestBody.Message(role: "user", content: question)]
            )
        )
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            return "messageの受け取りでエラー"
        }
        return content
    }



    private struct RequestBody: Encodable {
        let model: String
        let messages: [Message]
    //    let temperature: Float
        
        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct OpenAIResponse: Decodable {
        let choices: [Choice]
    }

    struct Choice: Decodable {
        let message: Message
        
        struct Message: Decodable {
            let content: String
        }
    }
    
}
