import Foundation
import SwiftUI

// 1. トレーニングの最小単位（スクワットなど）
struct Exercise: Identifiable, Codable {
    var id = UUID()
    let name: String
    let workSeconds: Int
    let restSeconds: Int
    let sets: Int
}

// 2. 1日分のパッケージ
struct DailySession: Identifiable {
    let id = UUID()
    let dayNumber: Int
    let mitchieQuote: String
    let exercises: [Exercise]
    var isCompleted: Bool = false
}

// 3. 目標の定義（enumにしておくと便利です）
enum WorkoutGoal: String, CaseIterable, Identifiable {
    case muscle = "筋肉をつける"
    case shapeUp = "シェイプアップ"
    case health = "健康増進"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .muscle: return "figure.strengthtraining.traditional"
        case .shapeUp: return "figure.run"
        case .health: return "figure.walk"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .muscle: return .orange
        case .shapeUp: return .blue
        case .health: return .green
        }
    }
}

// 4. モックデータ（実際のアプリではサーバーやデータベースから取得）
let mockPlan: [DailySession] = (1...30).map { day in
    DailySession(
        dayNumber: day,
        mitchieQuote: day == 1 ? "さあ、今日から新しい自分に挑戦だ！" :
                       day == 15 ? "半分達成！ここからが本番だぞ！" :
                       day == 30 ? "おめでとう！君はやり遂げた！" :
                       "今日も一歩前進だ！",
        exercises: [
            Exercise(name: "スクワット", workSeconds: 30, restSeconds: 15, sets: 3),
            Exercise(name: "腕立て伏せ", workSeconds: 20, restSeconds: 10, sets: 3),
            Exercise(name: "腹筋", workSeconds: 25, restSeconds: 15, sets: 3)
        ]
    )
}
