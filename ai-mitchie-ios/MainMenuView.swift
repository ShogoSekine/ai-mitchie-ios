struct MainMenuView: View {
    var body: some View {
        NavigationStack { // 画面遷移を管理するスタック
            ZStack {
                Color(white: 0.97).ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("AI Mitchie トレーニング")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Image(systemName: "figure.run.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 20) {
                        // トレーニング開始へのリンク
                        NavigationLink(destination: LevelSelectionView()) {
                            MenuButton(title: "トレーニングを始める", icon: "bolt.fill", color: .orange)
                        }
                        
                        // おしゃべり画面へのリンク
                        NavigationLink(destination: ChatView()) {
                            MenuButton(title: "Mitchieとおしゃべり", icon: "message.fill", color: .blue)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
        .preferredColorScheme(.light) // ダークモードでも色を固定
    }
}

// 共通ボタンパーツ
struct MenuButton: View {
  let title: String
  let icon: String
  let color: Color
  var body: some View {
      HStack {
          Image(systemName: icon)
          Text(title)
      }
      .font(.headline)
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding()
      .background(color)
      .cornerRadius(15)
      .shadow(radius: 5)
  }
}
