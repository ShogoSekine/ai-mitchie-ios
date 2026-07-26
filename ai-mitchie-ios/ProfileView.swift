import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var isEditing = false

    // 編集用バッファ
    @State private var editName: String = ""
    @State private var editAge: Int = 25
    @State private var editHeight: Double = 165
    @State private var editWeight: Double = 60
    @State private var editGoal: WorkoutGoal = .health
    @State private var editBodyType: TargetBodyType = .athlete
    @State private var editRank: MitchieRank = .lv1

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        List {
            // みっちーキャラ + 統計
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile?.name ?? "トレーニー")
                            .font(.title3).bold()
                        Text("レベル \(profile?.level ?? 1) / \(MitchieRank(rawValue: profile?.level ?? 1)?.name ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                HStack(spacing: 0) {
                    StatItem(icon: "🔥", value: "\(profile?.streakCount ?? 0)日", label: "連続")
                    Divider()
                    StatItem(icon: "💪", value: "\(profile?.totalWorkouts ?? 0)回", label: "累計")
                    Divider()
                    StatItem(icon: "🎯", value: profile?.targetBodyType ?? "-", label: "体型目標")
                }
                .frame(height: 60)
            }

            // 基本情報
            Section("基本情報") {
                if isEditing {
                    // 編集モード
                    HStack {
                        Text("ニックネーム")
                        Spacer()
                        TextField("名前", text: $editName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("年齢")
                        Spacer()
                        Stepper("\(editAge)歳", value: $editAge, in: 10...80)
                            .fixedSize()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("身長")
                            Spacer()
                            Text(String(format: "%.0f cm", editHeight)).bold()
                        }
                        Slider(value: $editHeight, in: 140...210, step: 1).accentColor(.orange)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("体重")
                            Spacer()
                            Text(String(format: "%.1f kg", editWeight)).bold()
                        }
                        Slider(value: $editWeight, in: 30...150, step: 0.5).accentColor(.orange)
                    }
                } else {
                    // 表示モード
                    InfoRow(label: "ニックネーム", value: profile?.name ?? "-")
                    InfoRow(label: "年齢", value: "\(profile?.age ?? 0)歳")
                    InfoRow(label: "身長", value: String(format: "%.0f cm", profile?.height ?? 0))
                    InfoRow(label: "体重", value: String(format: "%.1f kg", profile?.weight ?? 0))
                }
            }

            // トレーニング設定
            Section("トレーニング設定") {
                if isEditing {
                    Picker("目標", selection: $editGoal) {
                        ForEach(WorkoutGoal.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                    Picker("体型目標", selection: $editBodyType) {
                        ForEach(TargetBodyType.allCases) { b in
                            Text(b.rawValue).tag(b)
                        }
                    }
                    Picker("レベル", selection: $editRank) {
                        ForEach(MitchieRank.allCases) { r in
                            Text("Lv.\(r.rawValue) \(r.name)").tag(r)
                        }
                    }
                } else {
                    InfoRow(label: "目標", value: profile?.goal ?? "-")
                    InfoRow(label: "体型目標", value: profile?.targetBodyType ?? "-")
                    InfoRow(label: "レベル", value: "Lv.\(profile?.level ?? 1) \(MitchieRank(rawValue: profile?.level ?? 1)?.name ?? "")")
                }
            }

        }
        .navigationTitle("プロフィール")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "完了" : "編集") {
                    if isEditing { saveEdits() }
                    else { loadEdits() }
                    withAnimation { isEditing.toggle() }
                }
                .bold(isEditing)
            }
        }
    }

    // MARK: - 編集ロジック
    private func loadEdits() {
        guard let p = profile else { return }
        editName = p.name
        editAge = p.age
        editHeight = p.height
        editWeight = p.weight
        editGoal = WorkoutGoal(rawValue: p.goal) ?? .health
        editBodyType = TargetBodyType(rawValue: p.targetBodyType) ?? .athlete
        editRank = MitchieRank(rawValue: p.level) ?? .lv1
    }

    private func saveEdits() {
        guard let p = profile else { return }
        p.name = editName.isEmpty ? p.name : editName
        p.age = editAge
        p.height = editHeight
        p.weight = editWeight
        p.goal = editGoal.rawValue
        p.targetBodyType = editBodyType.rawValue
        p.level = editRank.rawValue
        try? modelContext.save()
    }

}

// MARK: - サブビュー
private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(icon)
            Text(value).font(.headline).bold()
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
