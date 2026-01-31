import SwiftUI

struct GoalSelectionView: View {
    let goals = [
        ("筋肉をつける", "figure.strengthtraining.traditional", Color.orange),
        ("シェイプアップ", "figure.run", Color.blue),
        ("健康増進", "figure.walk", Color.green)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("君の目指す姿を教えてくれ！")
                .font(.title2).bold()
            
            ForEach(goals, id: \.0) { goal in
                NavigationLink(destination: LevelSelectionView()) {
                    HStack {
                        Image(systemName: goal.1)
                            .font(.largeTitle)
                        Text(goal.0)
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(goal.2.opacity(0.1))
                    .foregroundColor(goal.2)
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(goal.2, lineWidth: 2))
                }
            }
            .padding(.horizontal)
        }
    }
}
