import SwiftUI
import SwiftData

struct WorkoutDashboardView: View {
    @Query(sort: \DailySessionModel.dayNumber) var sessions: [DailySessionModel]
    @Environment(\.modelContext) private var modelContext

    let initialGoal: WorkoutGoal
    let initialLevel: Int

    @State private var isGenerating = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    init(initialGoal: WorkoutGoal = .health, initialLevel: Int = 1) {
        self.initialGoal = initialGoal
        self.initialLevel = initialLevel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    VStack(spacing: 30) {
                        Image(systemName: "figure.strengthtraining.functional")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)

                        VStack(spacing: 12) {
                            HStack {
                                Text("目標")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(initialGoal.rawValue)
                                    .bold()
                                    .foregroundColor(initialGoal.themeColor)
                            }
                            Divider()
                            HStack {
                                Text("レベル")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("Lv.\(initialLevel)")
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 2)
                        .padding(.horizontal)

                        if isGenerating {
                            VStack(spacing: 15) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Mitchieがプランを練ってるぜ...\n（7日分生成中）")
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            Button(action: {
                                generate7DayPlan(goal: initialGoal, level: initialLevel)
                            }) {
                                Text("この条件で7日分生成！")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(initialGoal.themeColor)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    // --- 以前のように、ここに直接表示ロジックを記述します ---
                    VStack(spacing: 15) {
                        ForEach(sessions) { session in
                            NavigationLink(destination: WorkoutTimerView(session: session)) {
                                HStack {
                                    Text("Day \(session.dayNumber)")
                                        .font(.headline)
                                        .frame(width: 60, alignment: .leading)
                                        .foregroundColor(.orange)
                                    
                                    Text(session.mitchieQuote)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "chevron.right")
                                        .foregroundColor(session.isCompleted ? .green : .orange)
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                        }
                        
                        Button("メニューを作り直す") {
                            resetPlan()
                        }
                        .padding()
                        .foregroundColor(.red)
                    }
                    .padding()
                }
            }
            .navigationTitle("Mitchie 7Days")
            .alert("エラーだぜ！", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    func generate7DayPlan(goal: WorkoutGoal, level: Int) {
        print("generate7DayPlan called with goal: \(goal.rawValue), level: \(level)")
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
                            ExerciseModel(name: $0.name, workSeconds: $0.workSeconds, restSeconds: $0.restSeconds, sets: $0.sets) 
                        }
                        let newSession = DailySessionModel(dayNumber: dto.dayNumber, mitchieQuote: dto.mitchieQuote, exercises: exercises)
                        modelContext.insert(newSession)
                    }
                    try? modelContext.save()
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "通信エラーだぜ！少し時間を置いてから試してくれ！"
                    showingErrorAlert = true
                    isGenerating = false
                }
            }
        }
    }
    
    func resetPlan() {
        try? modelContext.delete(model: DailySessionModel.self)
    }
}

    // // モックでの7日間生成（動作確認用）
    // func generate7DayPlan() {
    //     isGenerating = true
    //     DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
    //         for day in 1...7 {
    //             let newSession = DailySessionModel(
    //                 dayNumber: day,
    //                 mitchieQuote: "Day \(day)！君の努力は俺が一番知ってるぜ！",
    //                 exercises: [
    //                     ExerciseModel(name: "スクワット", workSeconds: 20, restSeconds: 10, sets: 3)
    //                 ]
    //             )
    //             modelContext.insert(newSession)
    //         }
    //         try? modelContext.save()
    //         isGenerating = false
    //     }
    // }
