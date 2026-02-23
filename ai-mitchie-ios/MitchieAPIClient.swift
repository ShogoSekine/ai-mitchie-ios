import Foundation

// --- 1. APIからのレスポンスを受け取るための構造体 (DTO) ---
// ※ SwiftDataのモデルとは別に定義することで、デコードエラーを防ぎます

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

// --- 2. APIクライアントクラス ---

class MitchieAPIClient {
    static let shared = MitchieAPIClient()
    
    // Info.plist および .xcconfig からURLを動的に読み取ります
    private var lambdaURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "ApiGatewayUrl") as? String else {
            // ここでエラーが出る場合は、Info.plist の設定が漏れている可能性があります
            fatalError("Info.plistにApiGatewayUrlが設定されてないぜ！プロジェクト設定を確認してくれ！")
        }
        return url
    }
    
    /// 指定された目標とレベルに基づき、7日間のプランをLambdaから取得します
    func fetch7DayPlan(goal: String, level: Int) async throws -> [DailySessionDTO] {
        // 文字列のURLをURL型に変換
        guard let url = URL(string: lambdaURL) else {
            throw URLError(.badURL)
        }
        
        // リクエストの作成
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Lambdaに渡すリクエストボディの作成
        let body: [String: Any] = [
            "goal": goal,
            "level": level,
            "days": 7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 通信の実行（タイムアウトはLambda側の設定に合わせる必要があります）
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // ステータスコードの確認
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // JSONをデコードして返却
        let decoder = JSONDecoder()
        return try decoder.decode([DailySessionDTO].self, from: data)
    }
}
