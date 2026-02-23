import Foundation
import SwiftData
import SwiftUI

// 1. トレーニング種目のモデル
@Model
class ExerciseModel {
    var name: String
    var workSeconds: Int
    var restSeconds: Int
    var sets: Int
    
    init(name: String, workSeconds: Int, restSeconds: Int, sets: Int) {
        self.name = name
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.sets = sets
    }
}

// 2. 1日分のセッションモデル
@Model
class DailySessionModel {
    var dayNumber: Int
    var mitchieQuote: String
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseModel]
    var isCompleted: Bool = false
    
    init(dayNumber: Int, mitchieQuote: String, exercises: [ExerciseModel], isCompleted: Bool = false) {
        self.dayNumber = dayNumber
        self.mitchieQuote = mitchieQuote
        self.exercises = exercises
        self.isCompleted = isCompleted
    }
}

// 3. UI用：目標の定義（これはSwiftDataではなく、選択肢として利用）
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
