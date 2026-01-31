import SwiftUI

struct WorkoutTimerView: View {
    let session: DailySession
    
    // タイマーの状態管理
    @State private var currentExerciseIndex = 0
    @State private var currentSet = 1
    @State private var isResting = false
    @State private var timeLeft: Double = 0
    @State private var totalDuration: Double = 0
    @State private var timerRunning = false
    
    // Mitchieのモチベーションメッセージ
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
    
    // 1秒ごとに実行されるタイマー
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color(white: 0.97).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 現在の状態ヘッダー
                VStack {
                    Text("Day \(session.dayNumber)")
                        .font(.subheadline).bold().foregroundColor(.gray)
                    Text(isResting ? "リラックス・タイム" : session.exercises[currentExerciseIndex].name)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(isResting ? .blue : .orange)
                }
                .padding(.top)

                // 円形タイマー部分
                ZStack {
                    // 背景の円（薄い色）
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.2)
                        .foregroundColor(isResting ? .blue : .orange)
                    
                    // カウントダウンに合わせて削れる円
                    Circle()
                        .trim(from: 0, to: CGFloat(timeLeft / totalDuration))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(isResting ? .blue : .orange)
                        .rotationEffect(Angle(degrees: -90)) // 真上から始まるように回転
                        .animation(.linear(duration: 1.0), value: timeLeft) // 滑らかな動き
                    
                    // 中央の残り秒数
                    VStack {
                        Text("\(Int(ceil(timeLeft)))")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                        Text("SECONDS")
                            .font(.caption).bold()
                    }
                }
                .frame(width: 260, height: 260)
                .padding()

                // セット数とモチベーションメッセージ
                VStack(spacing: 20) {
                    Text("SET \(currentSet) / \(session.exercises[currentExerciseIndex].sets)")
                        .font(.title2).bold()
                    
                    // Mitchieのメッセージ
                    Text(mitchieMotivation)
                        .font(.headline)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .frame(height: 80)
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                }

                Spacer()

                // コントロールボタン
                Button(action: { timerRunning.toggle() }) {
                    HStack {
                        Image(systemName: timerRunning ? "pause.fill" : "play.fill")
                        Text(timerRunning ? "一時停止" : "スタート！")
                    }
                    .font(.title2).bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(timerRunning ? Color.gray : Color.orange)
                    .cornerRadius(20)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            setupNextStep()
            mitchieMotivation = session.mitchieQuote // 最初は初期メッセージ
        }
        .onReceive(timer) { _ in
            guard timerRunning else { return }
            
            if timeLeft > 0 {
                timeLeft -= 1
                // 5秒ごとにメッセージを更新して飽きさせない
                if Int(timeLeft) % 5 == 0 && !isResting {
                    updateMotivation()
                }
            } else {
                handleStepCompletion()
            }
        }
    }
    
    // 次のステップ（トレーニングか休憩か）をセットアップ
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
    
    // タイマー終了時の処理
    func handleStepCompletion() {
        let currentExercise = session.exercises[currentExerciseIndex]
        
        if !isResting {
            // トレーニング終了 -> 休憩へ
            isResting = true
            setupNextStep()
        } else {
            // 休憩終了
            isResting = false
            if currentSet < currentExercise.sets {
                // 次のセットへ
                currentSet += 1
                setupNextStep()
            } else {
                // 次の種目へ
                if currentExerciseIndex + 1 < session.exercises.count {
                    currentExerciseIndex += 1
                    currentSet = 1
                    setupNextStep()
                } else {
                    // 全種目終了！
                    timerRunning = false
                    mitchieMotivation = "完全燃焼だな！最高のトレーニングだったぜ！🏆"
                }
            }
        }
    }
    
    func updateMotivation() {
        mitchieMotivation = motivations.randomElement() ?? ""
    }
}
