import Foundation

struct MitchieResponse: Codable {
    let reply: String
}

class MitchieAPIClient {
    // 【重要】ここに先ほどのテストで成功したAPI GatewayのURLを貼り付けてください
    let endpoint = "https://nvjq0cxeu8.execute-api.ap-northeast-1.amazonaws.com/chat"
    
    func askMitchie(userMessage: String) async throws -> String {
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["message": userMessage]
        request.httpBody = try? JSONEncoder().encode(body)
        
        // タイムアウト設定を少し長めに（15秒程度）しておくと安心です
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        let session = URLSession(configuration: config)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // エラー時もMitchieらしく励ます
            return "ちょっと通信が混み合ってるみたいだけど、君の努力は私が一番よく分かっているからね！"
        }
        
        let result = try JSONDecoder().decode(MitchieResponse.self, from: data)
        return result.reply
    }
}
