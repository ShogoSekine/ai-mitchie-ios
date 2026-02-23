import SwiftUI
import SwiftData

struct WorkoutDashboardView: View {
    // データベースから保存されているセッションを自動取得
    @Query(sort: \DailySessionModel.dayNumber) var sessions: [DailySessionModel]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if sessions.isEmpty {
                    // データがない場合（初回のみ表示）
                    ContentUnavailableView {
                        Label("プランがありません", systemImage: "clipboard")
                    } description: {
                        Text("Mitchieにプランを作ってもらおうぜ！")
                    } actions: {
                        Button("30日プランを生成する") {
                            generateMock30DayPlan() // 本来はここでAIを呼び出す
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    // 30日分のグリッド表示
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 15) {
                        ForEach(sessions) { session in
                            NavigationLink(destination: WorkoutTimerView(session: session)) {
                                VStack {
                                    Text("\(session.dayNumber)")
                                        .font(.headline)
                                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "circle")
                                }
                                .frame(width: 60, height: 60)
                                .background(session.isCompleted ? Color.orange : Color.white)
                                .foregroundColor(session.isCompleted ? .white : .orange)
                                .cornerRadius(12)
                                .shadow(radius: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("30日チャレンジ")
        }
    }
    
    // 【重要】AI（Gemini）から30日分を受け取ったと仮定して保存する関数
    func generateMock30DayPlan() {
        // 本来はここで Gemini API を叩き、レスポンスをループで回す
        for day in 1...30 {
            let newSession = DailySessionModel(
                dayNumber: day,
                mitchieQuote: "Day \(day)！今日も最高に輝いてるぜ！",
                exercises: [
                    ExerciseModel(name: "スクワット", workSeconds: 2 * day, restSeconds: 10, sets: 2),
                    ExerciseModel(name: "プランク", workSeconds: 2 * day, restSeconds: 10, sets: 2)
                ]
            )
            modelContext.insert(newSession) // データベースに保存
        }
    }
}
