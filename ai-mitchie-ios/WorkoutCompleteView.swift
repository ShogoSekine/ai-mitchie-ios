import SwiftUI
import SwiftData

struct WorkoutCompleteView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Environment(NavigationCoordinator.self) private var coordinator

    let session: DailySessionModel
    let duration: TimeInterval

    @State private var praiseMessage: String = ""
    @State private var isLoading = true
    @State private var showEmoji = false

    private var profile: UserProfile? { profiles.first }

    private var completedSets: Int {
        session.exercises.map { $0.sets }.reduce(0, +)
    }

    private var durationText: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return minutes > 0 ? "\(minutes)分\(seconds)秒" : "\(seconds)秒"
    }

    var body: some View {
        ZStack {
            Color.orange.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // みっちーキャラ
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    .scaleEffect(showEmoji ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showEmoji)

                    // 絵文字アニメーション
                    Text("🎉 💪 🔥")
                        .font(.system(size: 44))
                        .opacity(showEmoji ? 1 : 0)
                        .scaleEffect(showEmoji ? 1.0 : 0.3)
                        .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.1), value: showEmoji)

                    Text("MISSION COMPLETE！")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showEmoji ? 1 : 0)
                        .animation(.easeIn.delay(0.2), value: showEmoji)

                    // 完了サマリー
                    HStack(spacing: 20) {
                        SummaryBadge(icon: "repeat.circle.fill", value: "\(completedSets)セット", label: "完了セット")
                        SummaryBadge(icon: "clock.fill", value: durationText, label: "所要時間")
                        SummaryBadge(icon: "calendar", value: "Day \(session.dayNumber)", label: "今日のデイ")
                    }
                    .padding(.horizontal)
                    .opacity(showEmoji ? 1 : 0)
                    .animation(.easeIn.delay(0.3), value: showEmoji)

                    // AI褒めメッセージ
                    VStack(spacing: 12) {
                        if isLoading {
                            VStack(spacing: 12) {
                                ProgressView().tint(.orange)
                                Text("みっちーが褒め言葉を考えてるぜ...✨")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(16)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "quote.opening")
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                Text(praiseMessage)
                                    .font(.body).bold()
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                HStack {
                                    Spacer()
                                    Image(systemName: "quote.closing")
                                        .foregroundColor(.orange)
                                }
                                HStack {
                                    Spacer()
                                    Text("— みっちー 💪")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .opacity(showEmoji ? 1 : 0)
                    .animation(.easeIn.delay(0.4), value: showEmoji)

                    // ホームに戻るボタン
                    Button(action: goHome) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("ホームに戻る")
                                .font(.headline)
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    .opacity(showEmoji ? 1 : 0)
                    .animation(.easeIn.delay(0.5), value: showEmoji)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation { showEmoji = true }
            Task { await loadPraise() }
        }
    }

    // MARK: - AI褒めメッセージ取得
    private func loadPraise() async {
        let exerciseNames = session.exercises.map { $0.name }
        let goal = profile?.goal ?? WorkoutGoal.health.rawValue
        do {
            let message = try await MitchieAPIClient.shared.fetchPraiseMessage(
                exercises: exerciseNames,
                totalSets: completedSets,
                goal: goal
            )
            await MainActor.run {
                praiseMessage = message
                isLoading = false
                savePraiseAndUpdateProfile(praise: message)
            }
        } catch {
            await MainActor.run {
                praiseMessage = "よくやった！今日の君の努力は最高だぜ！その一歩が未来を変える！💪"
                isLoading = false
                savePraiseAndUpdateProfile(praise: praiseMessage)
            }
        }
    }

    // MARK: - 保存 & プロフィール更新
    private func savePraiseAndUpdateProfile(praise: String) {
        // セッション完了フラグ
        session.isCompleted = true
        session.isMissed = false
        session.isBlockedByPreviousMiss = false

        // WorkoutLog保存
        let log = WorkoutLog(
            duration: duration,
            completedSets: completedSets,
            dayNumber: session.dayNumber,
            praiseMessage: praise,
            goal: profile?.goal ?? WorkoutGoal.health.rawValue
        )
        modelContext.insert(log)

        // UserProfile更新
        if let profile {
            let today = Calendar.current.startOfDay(for: Date())
            if let last = profile.lastWorkoutDate {
                let lastDay = Calendar.current.startOfDay(for: last)
                let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
                profile.streakCount = diff == 1 ? profile.streakCount + 1 : 1
            } else {
                profile.streakCount = 1
            }
            profile.totalWorkouts += 1
            profile.lastWorkoutDate = Date()
        }

        try? modelContext.save()
    }

    private func goHome() {
        // NavigationStackをルートからリセットしてHomeViewに確実に戻る
        coordinator.resetToRoot()
    }
}

// MARK: - 完了サマリーバッジ
private struct SummaryBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
            Text(value)
                .font(.headline).bold()
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
    }
}
