struct WorkoutDashboardView: View {
    let sessions: [DailySession] = mockPlan
    
    var body: some View {
        ScrollView {
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
        .navigationTitle("30日チャレンジ")
        .background(Color(white: 0.98))
    }
}
