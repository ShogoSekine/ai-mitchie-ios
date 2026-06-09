import Foundation

// MARK: - APIエラー型
enum APIError: Error, LocalizedError {
    case invalidURL
    case serverError(Int)
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "URLが無効です"
        case .serverError(let code): return "サーバーエラー(\(code))"
        case .decodingError:    return "データの解析に失敗しました"
        case .networkError(let e): return e.localizedDescription
        }
    }
}

// MARK: - APIレスポンス用構造体

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
    let howTo: String

    // howTo が返ってこない旧データとの互換性
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name         = try c.decode(String.self, forKey: .name)
        workSeconds  = try c.decode(Int.self, forKey: .workSeconds)
        restSeconds  = try c.decode(Int.self, forKey: .restSeconds)
        sets         = try c.decode(Int.self, forKey: .sets)
        howTo        = (try? c.decodeIfPresent(String.self, forKey: .howTo)) ?? ""
    }
}

// メッセージ系レスポンス用
struct MessageDTO: Codable {
    let message: String
}

// MARK: - クライアントクラス
class MitchieAPIClient {
    static let shared = MitchieAPIClient()

    private var baseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "ApiGatewayUrl") as? String else {
            fatalError("Info.plistにApiGatewayUrlが設定されてないぜ！")
        }
        return url.hasSuffix("/") ? String(url.dropLast()) : url
    }

    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ApiGatewayKey") as? String else {
            fatalError("Info.plistにApiGatewayKeyが設定されてないぜ！")
        }
        return key
    }

    // MARK: - 共通リクエスト生成
    private func makeRequest(path: String, body: [String: Any]) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.serverError(0)
            }
            guard http.statusCode == 200 else {
                throw APIError.serverError(http.statusCode)
            }
            return data
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - /plan: 7日間プラン生成
    func fetch7DayPlan(goal: String, level: Int) async throws -> [DailySessionDTO] {
        let request = try makeRequest(path: "/plan", body: ["goal": goal, "level": level, "days": 7])
        let data = try await perform(request)
        if let json = String(data: data, encoding: .utf8) {
            print("📥 /plan レスポンス: \(json.prefix(200))")
        }
        do {
            return try JSONDecoder().decode([DailySessionDTO].self, from: data)
        } catch {
            print("❌ /plan デコードエラー: \(error)")
            throw APIError.decodingError
        }
    }

    // MARK: - /praise: ワークアウト完了後の全肯定褒めメッセージ
    func fetchPraiseMessage(exercises: [String], totalSets: Int, goal: String) async throws -> String {
        let request = try makeRequest(path: "/praise", body: [
            "exercises": exercises,
            "totalSets": totalSets,
            "goal": goal
        ])
        let data = try await perform(request)
        do {
            return try JSONDecoder().decode(MessageDTO.self, from: data).message
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - /followup: サボり日フォローメッセージ
    func fetchFollowupMessage(daysOff: Int, goal: String) async throws -> String {
        let request = try makeRequest(path: "/followup", body: [
            "daysOff": daysOff,
            "goal": goal
        ])
        let data = try await perform(request)
        do {
            return try JSONDecoder().decode(MessageDTO.self, from: data).message
        } catch {
            throw APIError.decodingError
        }
    }
}
