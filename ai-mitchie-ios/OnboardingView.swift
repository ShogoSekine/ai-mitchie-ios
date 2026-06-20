import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentStep = 0

    // Step 2: ユーザー情報
    @State private var name: String = ""
    @State private var age: Int = 25
    @State private var height: Double = 165
    @State private var weight: Double = 60

    // Step 3: 目標
    @State private var selectedGoal: WorkoutGoal = .health
    @State private var selectedBodyType: TargetBodyType = .athlete

    // Step 4: レベル
    @State private var selectedRank: MitchieRank = .lv1

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.97, blue: 0.93).ignoresSafeArea()

            VStack(spacing: 0) {
                // ステップインジケーター
                if currentStep > 0 {
                    StepIndicatorView(currentStep: currentStep, totalSteps: 4)
                        .padding(.top, 16)
                        .padding(.horizontal, 30)
                }

                // コンテンツ
                Group {
                    switch currentStep {
                    case 0: Step1WelcomeView(onNext: { withAnimation { currentStep = 1 } })
                    case 1: Step2ProfileView(
                        name: $name, age: $age, height: $height, weight: $weight,
                        onNext: { withAnimation { currentStep = 2 } }
                    )
                    case 2: Step3GoalView(
                        selectedGoal: $selectedGoal, selectedBodyType: $selectedBodyType,
                        onNext: { withAnimation { currentStep = 3 } }
                    )
                    case 3: Step4LevelView(
                        selectedRank: $selectedRank,
                        onComplete: completeOnboarding
                    )
                    default: EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
    }

    private func completeOnboarding() {
        let profile = UserProfile(
            name: name.isEmpty ? "トレーニー" : name,
            age: age,
            height: height,
            weight: weight,
            goal: selectedGoal.rawValue,
            level: selectedRank.rawValue,
            targetBodyType: selectedBodyType.rawValue
        )
        modelContext.insert(profile)
        try? modelContext.save()
        hasCompletedOnboarding = true
    }
}

// MARK: - ステップインジケーター
private struct StepIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.orange : Color.orange.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}

// MARK: - Step 1: ウェルカム画面
private struct Step1WelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 150, height: 150)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 70))
                        .foregroundColor(.orange)
                }

                Text("💪 AIみっちーへようこそ！")
                    .font(.title).bold()
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "🎉", text: "どんなトレーニングでも全力で褒める！")
                    FeatureRow(icon: "🏠", text: "自宅でできる自重トレーニングのみ")
                    FeatureRow(icon: "🤖", text: "AIがあなた専用の7日間プランを作成")
                    FeatureRow(icon: "🔥", text: "サボっても責めない。また一緒に頑張ろう！")
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8)
                .padding(.horizontal)
            }

            Spacer()

            Button(action: onNext) {
                Text("みっちーと始める！")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon).font(.title3)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Step 2: プロフィール入力
private struct Step2ProfileView: View {
    @Binding var name: String
    @Binding var age: Int
    @Binding var height: Double
    @Binding var weight: Double
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("まず教えてくれ！")
                        .font(.title2).bold()
                    Text("プランを最適化するぜ")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top, 24)

                VStack(spacing: 0) {
                    // 名前
                    VStack(alignment: .leading, spacing: 6) {
                        Label("ニックネーム", systemImage: "person")
                            .font(.caption).foregroundColor(.secondary)
                        TextField("例: たろう", text: $name)
                            .textFieldStyle(.plain)
                            .font(.body)
                    }
                    .padding()

                    Divider().padding(.leading)

                    // 年齢
                    HStack {
                        Label("年齢", systemImage: "calendar")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Stepper("\(age) 歳", value: $age, in: 10...80)
                            .fixedSize()
                    }
                    .padding()

                    Divider().padding(.leading)

                    // 身長
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("身長", systemImage: "ruler")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.0f cm", height))
                                .font(.body).bold()
                        }
                        Slider(value: $height, in: 140...210, step: 1)
                            .accentColor(.orange)
                    }
                    .padding()

                    Divider().padding(.leading)

                    // 体重
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("体重", systemImage: "scalemass")
                                .font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f kg", weight))
                                .font(.body).bold()
                        }
                        Slider(value: $weight, in: 30...150, step: 0.5)
                            .accentColor(.orange)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8)
                .padding(.horizontal)

                Button(action: onNext) {
                    Text("次へ →")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Step 3: 目標・体型目標選択
private struct Step3GoalView: View {
    @Binding var selectedGoal: WorkoutGoal
    @Binding var selectedBodyType: TargetBodyType
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("目標を教えてくれ！")
                        .font(.title2).bold()
                    Text("みっちーが最適なメニューを作るぜ")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .padding(.top, 24)

                // トレーニング目標
                VStack(alignment: .leading, spacing: 12) {
                    Text("トレーニング目標").font(.headline).padding(.horizontal)

                    VStack(spacing: 10) {
                        ForEach(WorkoutGoal.allCases) { goal in
                            Button(action: { selectedGoal = goal }) {
                                HStack(spacing: 16) {
                                    Image(systemName: goal.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedGoal == goal ? .white : goal.themeColor)
                                        .frame(width: 36)
                                    Text(goal.rawValue)
                                        .font(.headline)
                                        .foregroundColor(selectedGoal == goal ? .white : .primary)
                                    Spacer()
                                    if selectedGoal == goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(selectedGoal == goal ? goal.themeColor : Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 体型目標
                VStack(alignment: .leading, spacing: 12) {
                    Text("目指す体型").font(.headline).padding(.horizontal)

                    VStack(spacing: 10) {
                        ForEach(TargetBodyType.allCases) { bodyType in
                            Button(action: { selectedBodyType = bodyType }) {
                                HStack(spacing: 16) {
                                    Image(systemName: bodyType.icon)
                                        .font(.title2)
                                        .foregroundColor(selectedBodyType == bodyType ? .white : .orange)
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bodyType.rawValue)
                                            .font(.headline)
                                            .foregroundColor(selectedBodyType == bodyType ? .white : .primary)
                                        Text(bodyType.description)
                                            .font(.caption)
                                            .foregroundColor(selectedBodyType == bodyType ? .white.opacity(0.8) : .secondary)
                                    }
                                    Spacer()
                                    if selectedBodyType == bodyType {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(selectedBodyType == bodyType ? Color.orange : Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Button(action: onNext) {
                    Text("次へ →")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Step 4: レベル選択
private struct Step4LevelView: View {
    @Binding var selectedRank: MitchieRank
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("今の実力は？")
                    .font(.title2).bold()
                Text("正直に選んでくれ！みっちーは責めないぜ😄")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal)

            VStack(spacing: 0) {
                Picker("レベル", selection: $selectedRank) {
                    ForEach(MitchieRank.allCases) { rank in
                        Text("Lv.\(rank.rawValue)  \(rank.name)").tag(rank)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8)
            .padding(.horizontal)

            // 選択中のレベル説明
            HStack(spacing: 12) {
                Image(systemName: "info.circle")
                    .foregroundColor(.orange)
                Text(selectedRank.difficultyDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            Button(action: onComplete) {
                HStack {
                    Image(systemName: "flame.fill")
                    Text("みっちーと一緒に始める！")
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
    }
}
