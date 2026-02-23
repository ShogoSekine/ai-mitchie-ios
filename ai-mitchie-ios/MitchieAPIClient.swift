import Foundation

// --- APIレスポンス用構造体 ---

// 7日間プラン用
struct DailySessionDTO: Codable {
    let dayNumber: Int
    let mitchieQuote: String
    let exercises: [ExerciseDTO]
}

struct ExerciseDTO: Codable {
    let name: String
    let workSeconds: Int
    let restSeconds: Int
    let sets: Int
}

// チャット用（Mitchieからの返答テキストだけを受け取る場合）
struct MitchieChatResponse: Codable {
    let response: String
}

// --- クライアントクラス ---

class MitchieAPIClient {
    static let shared = MitchieAPIClient()
    
    private var lambdaURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "ApiGatewayUrl") as? String else {
            fatalError("Info.plistにApiGatewayUrlが設定されてないぜ！")
        }
        return url
    }
    
    // 1. 【チャット用】Mitchieと会話するメソッド
    func askMitchie(userMessage: String) async throws -> String {
        guard let url = URL(string: lambdaURL) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // mode: "chat" を送ることで、Lambda側で処理を分岐させる想定です
        let body: [String: Any] = [
            "mode": "chat",
            "message": userMessage
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // レスポンスをデコード（Lambda側の返却形式に合わせて調整してください）
        let chatResult = try JSONDecoder().decode(MitchieChatResponse.self, from: data)
        return chatResult.response
    }
    
    // 2. 【ダッシュボード用】7日間のプランを生成するメソッド
    func fetch7DayPlan(goal: String, level: Int) async throws -> [DailySessionDTO] {
        guard let url = URL(string: lambdaURL) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "mode": "generate_plan",
            "goal": goal,
            "level": level,
            "days": 7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([DailySessionDTO].self, from: data)
    }
}
