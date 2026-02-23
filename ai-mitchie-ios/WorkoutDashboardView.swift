import SwiftUI
import SwiftData

struct WorkoutDashboardView: View {
    @Query(sort: \DailySessionModel.dayNumber) var sessions: [DailySessionModel]
    @Environment(\.modelContext) private var modelContext
    @State private var isGenerating = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("君だけの7日間メニューを作ろうぜ！")
                            .font(.headline)
                        
                        if isGenerating {
                            ProgressView("Mitchieがプランを練ってるぜ...")
                        } else {
                            Button("7日プランを生成する") {
                                generate7DayPlan()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    .padding(.top, 100)
                } else {
                    // 7日間用のリスト表示（見やすくカード形式に）
                    VStack(spacing: 15) {
                        ForEach(sessions) { session in
                            NavigationLink(destination: WorkoutTimerView(session: session)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("DAY \(session.dayNumber)")
                                            .font(.caption).bold()
                                            .foregroundColor(.gray)
                                        Text(session.mitchieQuote)
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                    }
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
                    }
                    .padding()
                }
            }
            .navigationTitle("7 Days Challenge")
            .background(Color(white: 0.98))
            .toolbar {
                if !sessions.isEmpty {
                    Button("作り直す") {
                        // 既存のデータを消して再生成
                        try? modelContext.delete(model: DailySessionModel.self)
                        // ここで再度生成
                    }
                }
            }
            .alert("通信エラーだぜ！", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    func generate7DayPlan(goal: WorkoutGoal, level: Int) {
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
                    // エラー内容をセットしてアラートを表示
                    errorMessage = "Mitchieがプランを練るのに失敗したみたいだぜ...\n通信環境を確認するか、少し時間を置いてからもう一度試してくれ！"
                    showingErrorAlert = true
                    isGenerating = false
                }
            }
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
}
