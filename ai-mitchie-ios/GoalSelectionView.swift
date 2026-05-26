import SwiftUI

struct GoalSelectionView: View {
    @State private var selectedGoal: WorkoutGoal = .health
    @State private var selectedRank: MitchieRank = .lv1

    var body: some View {
        VStack(spacing: 30) {
            Text("プランを設定するぜ！")
                .font(.title2).bold()
                .padding(.top, 20)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("目標").font(.headline)
                    Picker("目標", selection: $selectedGoal) {
                        ForEach(WorkoutGoal.allCases) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("レベル").font(.headline)
                    Picker("レベル", selection: $selectedRank) {
                        ForEach(MitchieRank.allCases) { rank in
                            Text("Lv.\(rank.rawValue)  \(rank.name)").tag(rank)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(radius: 2)
            .padding(.horizontal)

            NavigationLink(destination: WorkoutDashboardView(initialGoal: selectedGoal, initialLevel: selectedRank.rawValue)) {
                Text("この条件でプランを作る！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedGoal.themeColor)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .navigationTitle("プラン設定")
    }
}
