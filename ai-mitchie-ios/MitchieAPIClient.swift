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

// --- クライアントクラス ---

class MitchieAPIClient {
    static let shared = MitchieAPIClient()
    
    private var lambdaURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "ApiGatewayUrl") as? String else {
            fatalError("Info.plistにApiGatewayUrlが設定されてないぜ！")
        }
        print("Loaded API Gateway URL from Info.plist: \(url)")
        return url
    }
    
    // 【ダッシュボード用】7日間のプランを生成するメソッド
    func fetch7DayPlan(goal: String, level: Int) async throws -> [DailySessionDTO] {
        print("fetch7DayPlan called with goal: \(goal), level: \(level)")
        guard let url = URL(string: lambdaURL) else { throw URLError(.badURL) }
        print("API Gateway URL: \(lambdaURL)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["goal": goal, "level": level, "days": 7]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // --- 🔍 デバッグ1: 生のレスポンスを表示 ---
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📥 Lambdaから届いた生のJSON: \n\(jsonString)")
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ ステータスコードが200じゃないぜ: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            throw URLError(.badServerResponse)
        }
        
        // --- 🔍 デバッグ2: デコードエラーを詳細に捕まえる ---
        do {
            return try JSONDecoder().decode([DailySessionDTO].self, from: data)
        } catch let decodingError as DecodingError {
            // ここで「どの項目が違うのか」を詳しく出力します
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ キーが見つからないぜ: \(key.stringValue) (パス: \(context.codingPath))")
            case .typeMismatch(let type, let context):
                print("❌ 型が違うぜ: \(type) (パス: \(context.codingPath))")
            case .valueNotFound(let type, let context):
                print("❌ 値が空っぽだぜ: \(type) (パス: \(context.codingPath))")
            case .dataCorrupted(let context):
                print("❌ データが壊れてる（JSONじゃない）ぜ: \(context.debugDescription)")
            @unknown default:
                print("❌ 未知のデコードエラーだぜ")
            }
            throw decodingError
        } catch {
            print("❌ その他のエラー: \(error)")
            throw error
        }
    }
}
