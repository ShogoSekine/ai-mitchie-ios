import Foundation

// APIから返ってくるJSONの形を定義
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

class MitchieAPIClient {
    static let shared = MitchieAPIClient()
    
    // LambdaのURL（あなたのURLに書き換えてください）
    private let lambdaURL = "https://nvjq0cxeu8.execute-api.ap-northeast-1.amazonaws.com/chat"
    
    func fetch7DayPlan(goal: String, level: Int) async throws -> [DailySessionDTO] {
        guard let url = URL(string: lambdaURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Lambdaに送るパラメータ
        let body: [String: Any] = [
            "goal": goal,
            "level": level,
            "days": 7 // 7日間を指定
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 通信実行
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // JSONを構造体に変換
        return try JSONDecoder().decode([DailySessionDTO].self, from: data)
    }
}
