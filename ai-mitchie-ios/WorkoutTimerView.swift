import SwiftUI
import Combine

struct WorkoutTimerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    let session: DailySessionModel

    @State private var currentExerciseIndex = 0
    @State private var currentSet = 1
    @State private var isResting = false
    @State private var timeLeft: Double = 0
    @State private var totalDuration: Double = 0
    @State private var timerRunning = false
    @State private var isFinished = false
    @State private var startTime: Date = Date()

    // howTo シート
    @State private var showHowTo = false

    // 全体進捗管理
    @State private var currentStepCount = 1
    private var totalSteps: Int {
        session.exercises.map { $0.sets }.reduce(0, +)
    }

    // モチベーションメッセージ
    @State private var mitchieMotivation: String = ""
    let motivations = [
        "あと少し！君の筋肉が輝いてるぜ！✨",
        "呼吸を止めるな！酸素を細胞に送り込め！🔥",
        "限界の先にある景色、一緒に見ようぜ！🌅",
        "その汗、ダイヤモンドより美しいぜ！💎",
        "いいぞ！君の努力は裏切らない、俺が保証する！👊",
        "キツい時こそ笑え！筋肉が喜んでる証拠だ！😆",
        "今の君、世界で一番カッコいいぜ！🚀"
    ]

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentExercise: ExerciseModel? {
        guard currentExerciseIndex < session.exercises.count else { return nil }
        return session.exercises[currentExerciseIndex]
    }

    var body: some View {
        if session.isRestDay {
            VStack(spacing: 16) {
                Image(systemName: "bed.double")
                    .font(.system(size: 56))
                    .foregroundColor(.gray)
                Text("本日はお休みです")
                    .font(.title2).bold()
                Text("今日のトレーニングは完了扱いです。体をしっかり休めて、次の一歩に備えようぜ！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("戻る") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(white: 0.97).ignoresSafeArea())
            .onAppear {
                session.markAsCompletedIfRestDay(in: modelContext)
            }
        } else if !session.canStartWorkout {
            VStack(spacing: 16) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 56))
                    .foregroundColor(.gray)
                Text(session.isMissed ? "この日のトレーニングをやり忘れたため、以降は開放されません" : "まだこの日のトレーニングは開始できません")
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)
                Text("予定日を迎えるまで、他の日のトレーニングは選べません。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("戻る") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color(white: 0.97).ignoresSafeArea())
            .onAppear {
                session.updateAvailability(in: [session], context: modelContext)
            }
        } else {
            ZStack {
                Color(white: 0.97).ignoresSafeArea()

                VStack(spacing: 20) {
                // --- 進捗インジケーターエリア ---
                HStack(spacing: 30) {
                    VStack {
                        Text("この種目")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let ex = currentExercise, !isResting {
                            Text("あと \(ex.sets - currentSet + 1) セット")
                                .font(.headline)
                                .foregroundColor(.orange)
                        } else {
                            Text("-")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                    }

                    Divider().frame(height: 30)

                    VStack {
                        Text("ミッション完了まで")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("あと \(totalSteps - currentStepCount + 1) セット")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding(.top)

                // 種目名 + ℹ️ ボタン
                VStack(spacing: 4) {
                    Text("Day \(session.dayNumber)")
                        .font(.subheadline).bold().foregroundColor(.gray)
                    HStack(spacing: 8) {
                        Text(isResting ? "リラックス・タイム" : (currentExercise?.name ?? ""))
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(isResting ? .blue : .orange)
                            .multilineTextAlignment(.center)

                        // ℹ️ ボタン（運動中・howTo がある場合のみ表示）
                        if !isResting, let ex = currentExercise, !ex.howTo.isEmpty {
                            Button(action: { showHowTo = true }) {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                    .foregroundColor(.orange.opacity(0.7))
                            }
                        }
                    }
                }

                // 円形タイマー
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.1)
                        .foregroundColor(isResting ? .blue : .orange)

                    Circle()
                        .trim(from: 0, to: CGFloat(timeLeft / max(totalDuration, 1)))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .foregroundColor(isResting ? .blue : .orange)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 1.0), value: timeLeft)

                    VStack {
                        Text("\(Int(ceil(timeLeft)))")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                        Text("SECONDS")
                            .font(.caption).bold()
                    }
                }
                .frame(width: 240, height: 240)

                // Mitchieのメッセージエリア
                Text(mitchieMotivation)
                    .font(.headline)
                    .italic()
                    .multilineTextAlignment(.center)
                    .frame(height: 100)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                    .padding(.horizontal)

                Spacer()

                Button(action: { timerRunning.toggle() }) {
                    Label(timerRunning ? "一時停止" : "スタート！",
                          systemImage: timerRunning ? "pause.fill" : "play.fill")
                        .font(.title3).bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(timerRunning ? Color.secondary : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }

            // 完了画面オーバーレイ → WorkoutCompleteView に遷移
            if isFinished {
                NavigationLink(
                    destination: WorkoutCompleteView(
                        session: session,
                        duration: Date().timeIntervalSince(startTime)
                    ),
                    isActive: .constant(true)
                ) { EmptyView() }
                .hidden()
            }
            }
            .navigationBarBackButtonHidden(timerRunning)
            .onAppear {
                startTime = Date()
                setupNextStep()
            }
            .onReceive(timer) { _ in
                guard timerRunning && !isFinished else { return }
                if timeLeft > 0 {
                    timeLeft -= 1
                    if Int(timeLeft) % 10 == 0 && !isResting {
                        updateMotivation()
                    }
                } else {
                    handleStepCompletion()
                }
            }
            .sheet(isPresented: $showHowTo) {
                if let ex = currentExercise {
                    ExerciseHowToSheet(exercise: ex)
                }
            }
        }
    }

    // MARK: - ロジック
    func setupNextStep() {
        guard let currentExercise else { return }
        if isResting {
            timeLeft = Double(currentExercise.restSeconds)
            totalDuration = Double(currentExercise.restSeconds)
            mitchieMotivation = "しっかり休んで、次の爆発に備えようぜ！🍵"
        } else {
            timeLeft = Double(currentExercise.workSeconds)
            totalDuration = Double(currentExercise.workSeconds)
            updateMotivation()
        }
    }

    func handleStepCompletion() {
        if !isResting {
            isResting = true
            setupNextStep()
        } else {
            isResting = false
            guard let currentExercise else { return }

            if currentSet < currentExercise.sets {
                currentSet += 1
                currentStepCount += 1
                setupNextStep()
            } else if currentExerciseIndex + 1 < session.exercises.count {
                currentExerciseIndex += 1
                currentSet = 1
                currentStepCount += 1
                setupNextStep()
            } else {
                timerRunning = false
                withAnimation(.spring()) {
                    isFinished = true
                }
            }
        }
    }

    func updateMotivation() {
        mitchieMotivation = motivations.randomElement() ?? ""
    }
}
