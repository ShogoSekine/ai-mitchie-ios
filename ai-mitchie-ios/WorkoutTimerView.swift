import SwiftUI
import Combine

struct WorkoutTimerView: View {
    @Environment(\.dismiss) var dismiss
    let session: DailySession
    
    @State private var currentExerciseIndex = 0
    @State private var currentSet = 1
    @State private var isResting = false
    @State private var timeLeft: Double = 0
    @State private var totalDuration: Double = 0
    @State private var timerRunning = false
    @State private var isFinished = false
    
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
    
    var body: some View {
        ZStack {
            Color(white: 0.97).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // --- 進捗インジケーターエリア ---
                HStack(spacing: 30) {
                    VStack {
                        Text("この種目")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !isResting {
                            Text("あと \(session.exercises[currentExerciseIndex].sets - currentSet + 1) セット")
                                .font(.headline)
                                .foregroundColor(.orange)
                        } else {
                            Text("-") // 休憩中はハイフン表示
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

                VStack {
                    Text("Day \(session.dayNumber)")
                        .font(.subheadline).bold().foregroundColor(.gray)
                    Text(isResting ? "リラックス・タイム" : session.exercises[currentExerciseIndex].name)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(isResting ? .blue : .orange)
                        .multilineTextAlignment(.center)
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
                VStack {
                    Text(mitchieMotivation)
                        .font(.headline)
                        .italic()
                        .multilineTextAlignment(.center)
                        .frame(height: 100)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)

                Spacer()

                Button(action: { timerRunning.toggle() }) {
                    Label(timerRunning ? "一時停止" : "スタート！", systemImage: timerRunning ? "pause.fill" : "play.fill")
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
            
            // 完了画面オーバーレイ（変更なし）
            if isFinished {
                Color.orange.ignoresSafeArea()
                    .transition(.opacity)
                
                VStack(spacing: 30) {
                    Text("🏆 MISSION COMPLETE 🏆")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Image(systemName: "figure.strengthtraining.functional")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)
                    
                    Text("よくやった！\n今日の君は昨日の君を超えたぜ！\nこの一歩が未来を変えるんだ！")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding()

                    Button(action: { dismiss() }) {
                        Text("ダッシュボードに戻る")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 15)
                            .background(Color.white)
                            .cornerRadius(30)
                    }
                }
                .padding()
                .transition(.scale)
            }
        }
        .navigationBarBackButtonHidden(timerRunning)
        .onAppear { setupNextStep() }
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
    }
    
    // ロジック部分は変更なし
    func setupNextStep() {
        let currentExercise = session.exercises[currentExerciseIndex]
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
            let currentExercise = session.exercises[currentExerciseIndex]
            
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
