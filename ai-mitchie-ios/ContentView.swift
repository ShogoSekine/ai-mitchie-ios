import SwiftUI

struct ContentView: View {
    @State private var mitchieMessage: String = "準備はいいかい？\n君の今日の頑張りを教えてくれ！"
    @State private var isThinking: Bool = false
    @State private var userInput: String = "" // ← 入力されたテキストを保持する変数
    
    let apiClient = MitchieAPIClient()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("AI Trainer Mitchie")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.top)
                
                // メッセージ表示エリア
                VStack {
                    if isThinking {
                        ProgressView("Mitchieが言葉を選んでいます...")
                            .scaleEffect(1.2)
                            .padding()
                    } else {
                        Text(mitchieMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 150)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
                .padding(.horizontal)

                // --- ここからテキスト入力フォーム ---
                HStack {
                    TextField("例：腹筋10回やったよ！", text: $userInput)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onSubmit { // キーボードのReturnキーが押されたとき
                            handleCustomReport()
                        }
                    
                    Button(action: handleCustomReport) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(userInput.isEmpty ? Color.gray : Color.orange)
                            .clipShape(Circle())
                    }
                    .disabled(userInput.isEmpty || isThinking) // 空文字や通信中は無効化
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .padding(.horizontal)
                // --- ここまでテキスト入力フォーム ---

                Text("または、クイック報告！")
                    .font(.caption)
                    .foregroundColor(.gray)

                // 既存のクイックボタン
                ScrollView {
                    VStack(spacing: 12) {
                        ReportButton(title: "スクワット1回やった！", color: .orange) {
                            sendReport("スクワット1回やったよ！最高でしょ？")
                        }
                        
                        ReportButton(title: "少しだけ歩いた", color: .blue) {
                            sendReport("今日は少しだけ歩いて、自分をいたわったよ。")
                        }
                        
                        ReportButton(title: "今日は休んだ（エライ！）", color: .green) {
                            sendReport("今日は体を休めるという勇気ある選択をしたよ！")
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .preferredColorScheme(.light)
        .animation(.default, value: mitchieMessage)
        .animation(.default, value: isThinking)
    }
    
    // テキストフォーム用の送信処理
    func handleCustomReport() {
        guard !userInput.isEmpty else { return }
        let message = userInput
        userInput = "" // 送信後に入力欄を空にする
        sendReport(message)
        
        // キーボードを閉じる
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func sendReport(_ message: String) {
        isThinking = true
        Task {
            do {
                let reply = try await apiClient.askMitchie(userMessage: message)
                await MainActor.run {
                    self.mitchieMessage = reply
                    self.isThinking = false
                }
            } catch {
                await MainActor.run {
                    self.mitchieMessage = "通信トラブルも進化への休息さ！\nもう一度話しかけてくれ！"
                    self.isThinking = false
                }
            }
        }
    }
}

struct ReportButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(12)
        }
        .padding(.horizontal, 40)
    }
}
