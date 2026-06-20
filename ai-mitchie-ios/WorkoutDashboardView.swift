import SwiftUI
import SwiftData

struct WorkoutDashboardView: View {
    @Query(sort: \DailySessionModel.dayNumber) var sessions: [DailySessionModel]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    @State private var isGenerating = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var selectedExercise: ExerciseModel? = nil

    private var profile: UserProfile? { profiles.first }

    private var goal: WorkoutGoal {
        WorkoutGoal(rawValue: profile?.goal ?? WorkoutGoal.health.rawValue) ?? .health
    }
    private var level: Int { profile?.level ?? 1 }

    // 今日のdayNumber（プランなしの場合は未完了の先頭）
    private var todayDayNumber: Int {
        sessions.first(where: { !$0.isCompleted })?.dayNumber ?? -1
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if sessions.isEmpty {
                    emptyPlanView
                } else {
                    sessionListView
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("Mitchie 7Days")
        .alert("エラーだぜ！", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $selectedExercise) { exercise in
            ExerciseHowToSheet(exercise: exercise)
        }
    }

    // MARK: - プラン未生成時
    private var emptyPlanView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.strengthtraining.functional")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .padding(.top, 30)

            VStack(spacing: 12) {
                HStack {
                    Text("目標").foregroundColor(.secondary)
                    Spacer()
                    Text(goal.rawValue).bold().foregroundColor(goal.themeColor)
                }
                Divider()
                HStack {
                    Text("レベル").foregroundColor(.secondary)
                    Spacer()
                    Text("Lv.\(level)").bold().foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.05), radius: 5)
            .padding(.horizontal)

            if isGenerating {
                VStack(spacing: 15) {
                    ProgressView().scaleEffect(1.5)
                    Text("Mitchieがプランを練ってるぜ...\n（7日分生成中）")
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 10)
            } else {
                Button(action: { generate7DayPlan(goal: goal, level: level) }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("7日分のプランを作る！")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(goal.themeColor)
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - セッションリスト
    private var sessionListView: some View {
        VStack(spacing: 12) {
            ForEach(sessions, id: \.dayNumber) { session in
                SessionRowView(
                    session: session,
                    isToday: session.dayNumber == todayDayNumber,
                    onInfoTap: { exercise in selectedExercise = exercise }
                )
            }

            Button(action: resetPlan) {
                Label("プランをリセット", systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .padding(.horizontal)
    }

    // MARK: - ロジック
    private func generate7DayPlan(goal: WorkoutGoal, level: Int) {
        isGenerating = true
        Task {
            do {
                let dtos = try await MitchieAPIClient.shared.fetch7DayPlan(
                    goal: goal.rawValue,
                    level: level
                )
                await MainActor.run {
                    for dto in dtos {
                        let exercises = dto.exercises.map {
                            ExerciseModel(
                                name: $0.name,
                                workSeconds: $0.workSeconds,
                                restSeconds: $0.restSeconds,
                                sets: $0.sets,
                                howTo: $0.howTo
                            )
                        }
                        let newSession = DailySessionModel(
                            dayNumber: dto.dayNumber,
                            mitchieQuote: dto.mitchieQuote,
                            exercises: exercises
                        )
                        modelContext.insert(newSession)
                    }
                    try? modelContext.save()
                    isGenerating = false
                }
            } catch {
                print("❌ エラー詳細: \(error)")
                await MainActor.run {
                    errorMessage = "通信エラーだぜ！少し時間を置いてから試してくれ！\n\nエラー: \(error.localizedDescription)"
                    showingErrorAlert = true
                    isGenerating = false
                }
            }
        }
    }

    private func resetPlan() {
        try? modelContext.delete(model: DailySessionModel.self)
    }
}

// MARK: - セッション行
private struct SessionRowView: View {
    let session: DailySessionModel
    let isToday: Bool
    let onInfoTap: (ExerciseModel) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー行（タップで種目展開）
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    // Day番号
                    Text("Day\n\(session.dayNumber)")
                        .font(.caption).bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(isToday ? .white : .orange)
                        .frame(width: 44, height: 44)
                        .background(isToday ? Color.orange : Color.orange.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if isToday {
                                Text("今日 🔥").font(.caption2).foregroundColor(.orange)
                            }
                            if session.exercises.isEmpty {
                                Text("休息日")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.gray)
                                    .cornerRadius(4)
                            }
                        }
                        Text(session.mitchieQuote)
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundColor(session.isCompleted ? .secondary : .primary)
                    }
                    Spacer()
                    Image(systemName: session.isCompleted
                          ? "checkmark.circle.fill"
                          : (isExpanded ? "chevron.up" : "chevron.down"))
                        .foregroundColor(session.isCompleted ? .green : .orange)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // 種目リスト（展開時）
            if isExpanded {
                Divider()
                if session.exercises.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bed.double")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("本日はお休みです")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("体を休めて、次のセッションに備えましょう！")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    VStack(spacing: 0) {
                        ForEach(session.exercises) { exercise in
                            ExerciseRowInDashboard(exercise: exercise, onInfoTap: { onInfoTap(exercise) })
                            if exercise.id != session.exercises.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }

                    // タイマーへのリンク
                    if !session.isCompleted {
                        NavigationLink(destination: WorkoutTimerView(session: session)) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("このセッションを始める！")
                                    .font(.subheadline).bold()
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding([.horizontal, .bottom], 12)
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
        .background(session.isCompleted ? Color.gray.opacity(0.06) : Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(isToday ? 0.1 : 0.05), radius: isToday ? 8 : 5)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isToday ? Color.orange : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - ダッシュボード内の種目行
private struct ExerciseRowInDashboard: View {
    let exercise: ExerciseModel
    let onInfoTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run.circle")
                .foregroundColor(.orange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.subheadline).bold()
                Text("\(exercise.sets)セット × \(exercise.workSeconds)秒  休憩\(exercise.restSeconds)秒")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            // ℹ️ ボタン
            if !exercise.howTo.isEmpty {
                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - フォーム説明シート（共通コンポーネント）
struct ExerciseHowToSheet: View {
    let exercise: ExerciseModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "figure.run.circle.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                Text(exercise.name)
                    .font(.title2).bold()
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Label("フォームのポイント", systemImage: "checkmark.seal")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text(exercise.howTo.isEmpty ? "説明はありません。" : exercise.howTo)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack(spacing: 20) {
                InfoBadge(icon: "timer", value: "\(exercise.workSeconds)秒", label: "運動時間")
                InfoBadge(icon: "pause.circle", value: "\(exercise.restSeconds)秒", label: "休憩時間")
                InfoBadge(icon: "repeat", value: "\(exercise.sets)セット", label: "セット数")
            }

            Spacer()
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

private struct InfoBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundColor(.orange)
            Text(value).font(.headline).bold()
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(10)
    }
}
