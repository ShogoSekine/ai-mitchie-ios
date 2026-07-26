import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \DailySessionModel.dayNumber) private var sessions: [DailySessionModel]
    @Environment(\.modelContext) private var modelContext

    @State private var showFollowup = false
    @State private var showProfile = false

    private var profile: UserProfile? { profiles.first }

    // 今日のdayNumberを計算（プラン生成日からの経過日数）
    @Query private var plans: [WorkoutPlan]
    private var todaySession: DailySessionModel? {
        guard let plan = plans.first(where: { $0.isActive }) else {
            let today = Calendar.current.startOfDay(for: Date())
            return sessions.sorted { $0.dayNumber < $1.dayNumber }.first(where: { session in
                guard let scheduledDate = session.scheduledDate else { return false }
                return Calendar.current.isDate(scheduledDate, inSameDayAs: today)
            })
        }

        let today = Calendar.current.startOfDay(for: Date())
        let sortedSessions = plan.sessions.sorted { $0.dayNumber < $1.dayNumber }
        return sortedSessions.first(where: { session in
            guard let scheduledDate = session.scheduledDate else { return false }
            return Calendar.current.isDate(scheduledDate, inSameDayAs: today)
        }) ?? sortedSessions.first(where: { $0.canStartWorkout })
    }

    private let dailyMessages = [
        "今日も全力で行くぜ！💪",
        "昨日の自分を超える時だ！🔥",
        "どんな小さな一歩も、俺は見てるぜ！👊",
        "準備はいいか？一緒に燃え上がろう！🚀",
        "今日のトレーニングが未来の君を作るぜ！⚡",
        "さあ、始めよう！後悔は絶対させないぜ！😤",
        "君の努力は絶対に裏切らない！信じてくれ！🌟"
    ]

    private var todayMessage: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return dailyMessages[dayOfYear % dailyMessages.count]
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 1.0, green: 0.97, blue: 0.93).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    headerSection

                    // みっちーキャラクターエリア
                    mitchieSection

                    // ストリーク
                    if let profile {
                        streakSection(profile: profile)
                    }

                    // 今日のセッション
                    todaySessionSection

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
        checkFollowup()
        updateSessionAvailability()
    }
        .sheet(isPresented: $showFollowup) {
            if let profile {
                WorkoutFollowupView(profile: profile)
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView()
            }
        }
    }

    // MARK: - ヘッダー
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("AIみっちー")
                    .font(.title2).bold()
                if let name = profile?.name {
                    Text("よう、\(name)！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button(action: { showProfile = true }) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - みっちーキャラクターエリア
    private var mitchieSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 34))
                    .foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("みっちー")
                    .font(.caption).bold()
                    .foregroundColor(.orange)
                Text(todayMessage)
                    .font(.subheadline).bold()
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }

    // MARK: - ストリーク
    private func streakSection(profile: UserProfile) -> some View {
        HStack(spacing: 16) {
            StatCard(icon: "🔥", value: "\(profile.streakCount)日", label: "連続継続")
            StatCard(icon: "💪", value: "\(profile.totalWorkouts)回", label: "累計完了")
            StatCard(icon: "🎯", value: profile.goal, label: "目標")
        }
        .padding(.horizontal)
    }

    // MARK: - 今日のセッション
    private var todaySessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日のトレーニング")
                .font(.headline)
                .padding(.horizontal)

            if sessions.isEmpty {
                // プラン未生成
                noPlanCard
            } else if let session = todaySession {
                Group {
                    if session.canStartWorkout {
                        NavigationLink(destination: WorkoutTimerView(session: session)) {
                            TodaySessionCard(session: session)
                        }
                    } else {
                        TodaySessionCard(session: session)
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    session.markAsCompletedIfRestDay(in: modelContext)
                }

                // ダッシュボードへのリンク
                NavigationLink(destination: WorkoutDashboardView()) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("7日間プランを見る")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
            } else {
                // 全セッション完了
                allCompletedCard
            }
        }
    }

    private var noPlanCard: some View {
        NavigationLink(destination: WorkoutDashboardView()) {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("みっちーに7日間プランを\n作ってもらう！")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                Text("AIがあなた専用のプランを生成するぜ！")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8)
        }
        .padding(.horizontal)
    }

    private var allCompletedCard: some View {
        VStack(spacing: 12) {
            Text("🎉 今週のプランを完走したぜ！")
                .font(.headline)
            Text("新しいプランを作成しよう！")
                .font(.subheadline)
                .foregroundColor(.secondary)
            NavigationLink(destination: WorkoutDashboardView()) {
                Text("新しいプランを作る！")
                    .font(.subheadline).bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }

    // MARK: - サボり日チェック
    private func checkFollowup() {
        // 既にこの起動中に表示済みなら再表示しない
        guard !FollowupManager.shared.hasShownFollowupThisRun,
              let profile,
              let lastDate = profile.lastWorkoutDate else { return }
        let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        if days >= 3 {
            showFollowup = true
            FollowupManager.shared.hasShownFollowupThisRun = true
        }
    }

    private func updateSessionAvailability() {
        guard !sessions.isEmpty else { return }
        sessions.forEach { $0.updateAvailability(in: sessions, context: modelContext) }
    }
}

// MARK: - 今日のセッションカード
private struct TodaySessionCard: View {
    let session: DailySessionModel

    var body: some View {
        let isRestDay = session.isRestDay

        return HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isRestDay ? Color.gray.opacity(0.15) : (session.isCompleted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)))
                    .frame(width: 56, height: 56)
                Image(systemName: isRestDay ? "bed.double" : (session.isCompleted ? "checkmark.circle.fill" : "play.circle.fill"))
                    .font(.system(size: 28))
                    .foregroundColor(isRestDay ? .gray : (session.isCompleted ? .green : .orange))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(session.dayNumber)")
                    .font(.caption).bold()
                    .foregroundColor(session.isRestDay ? .gray : (session.isCompleted ? .green : .orange))
                Text(session.isRestDay ? "本日はお休みです" : (session.isCompleted ? "今日の分は完了だぜ！✅" : (session.isMissed ? "この日のトレーニングをやり忘れたぜ…" : "今日のトレーニングを始める！")))
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(session.mitchieQuote)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if session.canStartWorkout {
                Image(systemName: "chevron.right")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

// MARK: - 統計カード
private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.title3)
            Text(value)
                .font(.headline).bold()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
