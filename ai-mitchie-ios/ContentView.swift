import SwiftUI

struct ContentView: View {
    @State private var message = "やあ！AIみっちーだよ！\n今日はどんなトレーニングをしたかな？"
    
    var body: some View {
        VStack(spacing: 20) {
            // 仮のみっちービジュアル（後でイラストに変更）
            Text("💪")
                .font(.system(size: 100))
            
            // みっちーのセリフ
            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(15)
            
            // クイック報告ボタン
            HStack {
                Button("サボった...") { message = "報告してくれてありがとう！今は充電中だね。ナイス判断！" }
                Button("少しやった！") { message = "素晴らしい！その一歩が未来を変えるよ！最高だ！" }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
