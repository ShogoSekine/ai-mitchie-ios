struct WorkoutTimerView: View {
    let session: DailySession
    @State private var currentExerciseIndex = 0
    @State private var timeLeft = 10
    @State private var isResting = false
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Day \(session.dayNumber)")
                .font(.subheadline).foregroundColor(.gray)
            
            Text(session.mitchieQuote)
                .font(.headline).italic()
                .multilineTextAlignment(.center)
                .padding()

            VStack {
                Text(isResting ? "休憩中" : session.exercises[currentExerciseIndex].name)
                    .font(.largeTitle).bold()
                
                Text("\(timeLeft)")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(isResting ? .blue : .orange)
            }
            
            HStack {
                VStack {
                    Text("セット")
                    Text("1/\(session.exercises[currentExerciseIndex].sets)")
                }
                Divider().frame(height: 40)
                VStack {
                    Text("次")
                    Text(currentExerciseIndex + 1 < session.exercises.count ? session.exercises[currentExerciseIndex+1].name : "終了！")
                }
            }
            
            Button("スタート / 一時停止") {
                // ここにタイマーのロジックを実装
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}
