import SwiftUI

struct WorkoutView: View {
    let rank: MitchieRank
    
    var body: some View {
        VStack {
            Text("モード：\(rank.name)")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Text("Mitchieがメニューを作成中...")
                .font(.title3)
            
            ProgressView()
                .padding()
            
            Spacer()
        }
        .navigationTitle("トレーニング")
    }
}
