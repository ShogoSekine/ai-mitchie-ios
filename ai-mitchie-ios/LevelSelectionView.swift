import SwiftUI
struct LevelSelectionView: View {
    @State private var selectedRank: MitchieRank = .lv1
    
    var body: some View {
        VStack(spacing: 30) {
            Text("今の君のエネルギーは？")
                .font(.title2)
                .fontWeight(.bold)
            
            // 10段階の選択肢
            Picker("Mitchieランク", selection: $selectedRank) {
                ForEach(MitchieRank.allCases) { rank in
                    Text("Lv.\(rank.rawValue): \(rank.name)").tag(rank)
                }
            }
            .pickerStyle(.wheel) // ドラムロール形式
            .frame(height: 150)
            
            Text("今日の目標：15分以内で最高に輝く")
                .font(.caption)
                .foregroundColor(.gray)
            
            // トレーニング開始ボタン
            NavigationLink(destination: WorkoutDashboardView(rank: selectedRank)) {
                Text("\(selectedRank.name)を開始！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .navigationTitle("レベル選択")
    }
}
