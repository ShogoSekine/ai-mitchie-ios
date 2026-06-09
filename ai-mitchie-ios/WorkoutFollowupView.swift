import SwiftUI

struct WorkoutFollowupView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile

    @State private var followupMessage: String = ""
    @State private var isLoading = true

    private var daysOff: Int {
        guard let last = profile.lastWorkoutDate else { return 3 }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 3
    }

    var body: some View {
        VStack(spacing: 28) {
            // みっちーキャラ
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
            }
            .padding(.top, 40)

            VStack(spacing: 6) {
                Text("\(daysOff)日ぶりだな！")
                    .font(.title2).bold()
                Text("みっちーは待ってたぜ")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // メッセージエリア
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.orange)
                    Text("みっちーがメッセージを考えてるぜ...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.opening").foregroundColor(.orange)
                        Spacer()
                    }
                    Text(followupMessage)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        Text("— みっちー 💪")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal)
            }

            Spacer()

            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("よし、今日からまた頑張る！")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            Task { await loadFollowup() }
        }
    }

    private func loadFollowup() async {
        do {
            let message = try await MitchieAPIClient.shared.fetchFollowupMessage(
                daysOff: daysOff,
                goal: profile.goal
            )
            await MainActor.run {
                followupMessage = message
                isLoading = false
            }
        } catch {
            await MainActor.run {
                followupMessage = "久しぶりだな！でも戻ってきてくれて最高だぜ！一緒にまた走り出そう！🔥"
                isLoading = false
            }
        }
    }
}
