import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData Models

// 1. トレーニング種目のモデル
@Model
class ExerciseModel {
    var name: String
    var workSeconds: Int
    var restSeconds: Int
    var sets: Int
    var howTo: String   // 初心者向けフォーム説明文（AI生成）

    init(name: String, workSeconds: Int, restSeconds: Int, sets: Int, howTo: String = "") {
        self.name = name
        self.workSeconds = workSeconds
        self.restSeconds = restSeconds
        self.sets = sets
        self.howTo = howTo
    }
}

// 2. 1日分のセッションモデル
@Model
class DailySessionModel {
    var dayNumber: Int
    var mitchieQuote: String
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseModel]
    var isCompleted: Bool = false
    var scheduledDate: Date?
    var isMissed: Bool = false
    var isBlockedByPreviousMiss: Bool = false

    var isRestDay: Bool {
        exercises.isEmpty
    }

    var canStartWorkout: Bool {
        guard let scheduledDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let sessionDay = Calendar.current.startOfDay(for: scheduledDate)
        return !isCompleted && !isRestDay && !isMissed && !isBlockedByPreviousMiss && sessionDay == today
    }

    init(dayNumber: Int, mitchieQuote: String, exercises: [ExerciseModel], isCompleted: Bool = false, scheduledDate: Date? = nil) {
        self.dayNumber = dayNumber
        self.mitchieQuote = mitchieQuote
        self.exercises = exercises
        self.isCompleted = isCompleted
        self.scheduledDate = scheduledDate
    }

    func markAsCompletedIfRestDay(in context: ModelContext) {
        guard isRestDay && !isCompleted else { return }
        isCompleted = true
        try? context.save()
    }

    func updateAvailability(in sessions: [DailySessionModel], now: Date = Date(), context: ModelContext? = nil) {
        let todayStart = Calendar.current.startOfDay(for: now)
        let sortedSessions = sessions.sorted { $0.dayNumber < $1.dayNumber }
        var shouldBlock = false

        for session in sortedSessions {
            if session.isRestDay || session.isCompleted || session.scheduledDate == nil {
                session.isMissed = false
                session.isBlockedByPreviousMiss = false
                continue
            }

            let sessionDay = Calendar.current.startOfDay(for: session.scheduledDate!)
            if shouldBlock || sessionDay > todayStart {
                session.isBlockedByPreviousMiss = shouldBlock
                session.isMissed = false
                continue
            }

            if sessionDay < todayStart {
                session.isMissed = true
                session.isBlockedByPreviousMiss = false
                shouldBlock = true
            } else {
                session.isMissed = false
                session.isBlockedByPreviousMiss = false
            }
        }

        try? context?.save()
    }
}

// 3. ユーザープロフィール
@Model
class UserProfile {
    var name: String
    var age: Int
    var height: Double          // cm
    var weight: Double          // kg
    var goal: String            // WorkoutGoal.rawValue
    var level: Int              // MitchieRank.rawValue
    var targetBodyType: String  // "スリム" / "アスリート" / "筋肉質"
    var streakCount: Int        // 連続トレーニング日数
    var totalWorkouts: Int      // 累計ワークアウト完了数
    var lastWorkoutDate: Date?  // 最後にワークアウトを完了した日
    var createdAt: Date

    init(
        name: String,
        age: Int,
        height: Double,
        weight: Double,
        goal: String,
        level: Int,
        targetBodyType: String
    ) {
        self.name = name
        self.age = age
        self.height = height
        self.weight = weight
        self.goal = goal
        self.level = level
        self.targetBodyType = targetBodyType
        self.streakCount = 0
        self.totalWorkouts = 0
        self.lastWorkoutDate = nil
        self.createdAt = Date()
    }
}

// 4. 生成済みワークアウトプラン
@Model
class WorkoutPlan {
    var generatedAt: Date
    var goal: String
    var level: Int
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var sessions: [DailySessionModel]

    init(goal: String, level: Int) {
        self.generatedAt = Date()
        self.goal = goal
        self.level = level
        self.isActive = true
        self.sessions = []
    }
}

// 5. ワークアウト完了ログ
@Model
class WorkoutLog {
    var completedAt: Date
    var duration: TimeInterval  // 秒数
    var completedSets: Int
    var dayNumber: Int
    var praiseMessage: String   // AI生成済みキャッシュ（再表示用）
    var goal: String

    init(duration: TimeInterval, completedSets: Int, dayNumber: Int, praiseMessage: String, goal: String) {
        self.completedAt = Date()
        self.duration = duration
        self.completedSets = completedSets
        self.dayNumber = dayNumber
        self.praiseMessage = praiseMessage
        self.goal = goal
    }
}

// MARK: - Enums

// 目標の定義
enum WorkoutGoal: String, CaseIterable, Identifiable {
    case muscle  = "筋肉をつける"
    case shapeUp = "シェイプアップ"
    case health  = "健康増進"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .muscle:  return "figure.strengthtraining.traditional"
        case .shapeUp: return "figure.run"
        case .health:  return "figure.walk"
        }
    }

    var themeColor: Color {
        switch self {
        case .muscle:  return .orange
        case .shapeUp: return .blue
        case .health:  return .green
        }
    }
}

// 体型目標
enum TargetBodyType: String, CaseIterable, Identifiable {
    case slim    = "スリム"
    case athlete = "アスリート"
    case muscle  = "筋肉質"

    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .slim:    return "figure.stand"
        case .athlete: return "figure.run"
        case .muscle:  return "figure.strengthtraining.traditional"
        }
    }

    var description: String {
        switch self {
        case .slim:    return "引き締まった細身の体型"
        case .athlete: return "バランスよく引き締まった体型"
        case .muscle:  return "たくましく筋肉のある体型"
        }
    }
}
