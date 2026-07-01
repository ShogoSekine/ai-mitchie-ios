# AIみっちー iOSアプリ — 実装プラン

## 概要

事業計画書に基づき、既存のSwiftコードを全面再設計してiOSアプリ「AIみっちー」を構築する。  
バックエンドは **Amazon Bedrock（Nova Lite）+ AWS Lambda + API Gateway** の既存構成を継続・拡張する。

**今回のスコープ: Phase 1〜3**（データ設計・iOS画面・API強化）  
**次フェーズ (Phase 4)**: 音声応援（AVSpeechSynthesizer）・プッシュ通知（UNUserNotificationCenter）

**トレーニング方針**: 全メニューは **器具不要の自重トレーニングのみ**。自宅の床さえあれば実施可能な種目に限定する。ベンチプレス・懸垂・バーベル・ダンベル・マシン等、特別な器具を要する種目は一切含めない。

---

## アーキテクチャ全体図

```
┌─────────────────────────────────────────────────────────────┐
│                        iOSアプリ                             │
│                                                             │
│  OnboardingView → HomeView → WorkoutDashboardView           │
│                       │                                     │
│                       ├─→ WorkoutFollowupView（サボり日）    │
│                       └─→ ProfileView                      │
│                                                             │
│  WorkoutDashboardView → WorkoutTimerView → WorkoutCompleteView │
│                                                             │
│  [SwiftData]: UserProfile / WorkoutPlan / DailySessionModel │
│               ExerciseModel / WorkoutLog                    │
│                                                             │
│  [MitchieAPIClient]: fetch7DayPlan / fetchPraiseMessage     │
│                      fetchFollowupMessage                   │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS POST + x-api-key
                    ┌────────▼────────┐
                    │  API Gateway    │
                    │  /plan          │
                    │  /praise        │
                    │  /followup      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  AWS Lambda     │
                    │  lambda_handler │
                    └────────┬────────┘
                             │
                    ┌────────▼────────────────┐
                    │  Amazon Bedrock          │
                    │  amazon.nova-lite-v1:0   │
                    └─────────────────────────┘
```

---

## Phase 1: データ基盤

### 対象ファイル
- `ai-mitchie-ios/WorkoutModels.swift`（全面改訂）
- `ai-mitchie-ios/ai_mitchie_iosApp.swift`（改訂）

### 1-1. WorkoutModels.swift — 追加モデル

#### 既存モデル（一部拡張）
- `ExerciseModel @Model` — name, workSeconds, restSeconds, sets, **howTo**（初心者向けフォーム説明文・AI生成）
- `DailySessionModel @Model` — dayNumber, mitchieQuote, exercises[], isCompleted
- `WorkoutGoal` enum — 筋肉をつける / シェイプアップ / 健康増進
- `MitchieRank` enum — Lv.1〜10

#### 新規追加モデル

```swift
// ユーザープロフィール
@Model
class UserProfile {
    var name: String
    var age: Int
    var height: Double          // cm
    var weight: Double          // kg
    var goal: String            // WorkoutGoal.rawValue
    var level: Int              // MitchieRank.rawValue
    var targetBodyType: String  // "スリム" / "アスリート" / "筋肉質"
    var streakCount: Int        // 連続トレーニング日数
    var totalWorkouts: Int      // 累計ワークアウト完了数
    var lastWorkoutDate: Date?  // 最後にワークアウトを完了した日
    var createdAt: Date
}

// 生成済みワークアウトプラン
@Model
class WorkoutPlan {
    var generatedAt: Date
    var goal: String
    var level: Int
    var isActive: Bool
    @Relationship(deleteRule: .cascade) var sessions: [DailySessionModel]
}

// ワークアウト完了ログ
@Model
class WorkoutLog {
    var completedAt: Date
    var duration: TimeInterval  // 秒数
    var completedSets: Int
    var dayNumber: Int
    var praiseMessage: String   // AI生成済みキャッシュ（再表示用）
    var goal: String
}
```

### 1-2. ai_mitchie_iosApp.swift — 変更点

- `modelContainer` に `UserProfile`, `WorkoutPlan`, `WorkoutLog` を追加
- 起点 `GoalSelectionView` → `RootView`（初回判定ロジック）に変更
- `RootView` の判定ロジック：
  - `UserDefaults["hasCompletedOnboarding"] == false` → `OnboardingView` を表示
  - `true` → `HomeView` を表示

---

## Phase 2: iOS 画面実装

### 画面遷移図

```
起動
 │
 ├─[初回]─→ OnboardingView (Step 1〜4)
 │               └─→ HomeView（完了後）
 │
 └─[2回目以降]─→ RootView
                     │
                     ├─[3日以上未アクセス]─→ WorkoutFollowupView
                     │                           └─→ HomeView
                     │
                     └─→ HomeView
                             │
                             ├─→ WorkoutDashboardView
                             │       └─→ WorkoutTimerView
                             │               └─→ WorkoutCompleteView
                             │                       └─→ HomeView
                             │
                             └─→ ProfileView
```

---

### 2-1. OnboardingView（新規）

**ファイル**: `ai-mitchie-ios/OnboardingView.swift`

| Step | 内容 |
|------|------|
| Step 1 | みっちー紹介画面。SFSymbols `figure.strengthtraining.traditional` + 絵文字 💪 でキャラ表現。アプリコンセプト説明 |
| Step 2 | ユーザー情報入力（名前・年齢・身長・体重）。`TextField` + `Stepper` / `Slider` |
| Step 3 | 目標選択（`WorkoutGoal` 流用）+ 体型目標選択（スリム / アスリート / 筋肉質の3択カード） |
| Step 4 | レベル選択（`MitchieRank` Picker）+ 完了ボタン → `UserProfile` をSwiftDataに保存 |

**完了時の処理**:
```swift
UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
// UserProfile をモデルコンテキストに insert & save
```

---

### 2-2. HomeView（新規）

**ファイル**: `ai-mitchie-ios/HomeView.swift`  
**置き換え対象**: `GoalSelectionView.swift`（削除 or 統合）

**表示要素**:
- みっちーキャラクターエリア: `💪🔥` + 今日の定型激励メッセージ（ローカル定型文をランダム表示。APIコールなし）
- ストリーク表示: 「🔥 N日連続！」バッジ
- 今日のセッションカード: `WorkoutPlan` から当日分の `DailySessionModel` を取得して表示
  - 未完了: オレンジのCTAボタン「今日のトレーニングを始める！」
  - 完了済み: グリーンの✅バッジ + 「今日の分は完了だぜ！」
- プラン未生成時: 「みっちーに7日間プランを作ってもらう！」ボタン → `WorkoutDashboardView` へ
- 右上: プロフィールアイコンボタン → `ProfileView` へ

---

### 2-3. WorkoutDashboardView（改修）

**ファイル**: `ai-mitchie-ios/WorkoutDashboardView.swift`

**変更点**:
- `initialGoal` / `initialLevel` をコンストラクタで受け取る代わりに `UserProfile` から `@Query` または環境オブジェクトで取得
- 今日分（当日に対応する `dayNumber`）の行をハイライト表示（オレンジ背景・太字）
- 完了済み行は薄いグレー + ✅アイコン
- 既存の7日プラン生成ロジック（`fetch7DayPlan`）はそのまま流用
- 各セッション行をタップすると種目一覧を表示し、種目ごとに `ℹ️` ボタンを配置 → タップで `howTo` をシート（`.sheet`）表示

---

### 2-4. WorkoutTimerView（改修）

**ファイル**: `ai-mitchie-ios/WorkoutTimerView.swift`

**変更点**:
- ワークアウト開始時刻を記録（`startTime = Date()`）
- 全セッション完了判定時:
  ```swift
  // duration を計算して WorkoutCompleteView に渡す
  let duration = Date().timeIntervalSince(startTime)
  // NavigationLink または sheet で WorkoutCompleteView を表示
  ```
- `session.isCompleted = true` の設定タイミングを `WorkoutCompleteView` に移動
- 現在の種目名の横に `ℹ️` ボタンを配置 → タップで `exercise.howTo` をシート表示（タイマーは一時停止しない）

**ExerciseHowToSheet（インラインコンポーネント）**:
```swift
// WorkoutTimerView 内に定義
struct ExerciseHowToSheet: View {
    let exercise: ExerciseModel
    var body: some View {
        VStack(spacing: 20) {
            Text(exercise.name).font(.title2).bold()
            Text(exercise.howTo)
                .font(.body)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
}
```

---

### 2-5. WorkoutCompleteView（新規）

**ファイル**: `ai-mitchie-ios/WorkoutCompleteView.swift`

**表示フロー**:
1. 表示と同時に `MitchieAPIClient.shared.fetchPraiseMessage(...)` を非同期呼び出し
2. 読み込み中: ローディングスピナー + 「みっちーが褒め言葉を考えてるぜ...」
3. 完了: 
   - 大きな絵文字（🎉💪🔥）アニメーション
   - AI生成の全肯定メッセージを白い吹き出し形式で表示
   - 完了サマリー（セット数・所要時間）
4. `WorkoutLog` をSwiftDataに保存（praiseMessage をキャッシュ）
5. `UserProfile.streakCount` と `totalWorkouts` と `lastWorkoutDate` を更新
6. 「ホームに戻る」ボタン

---

### 2-6. WorkoutFollowupView（新規）

**ファイル**: `ai-mitchie-ios/WorkoutFollowupView.swift`

**表示条件**: `HomeView` 起動時に `UserProfile.lastWorkoutDate` を確認し、3日以上経過している場合にシート表示

**表示フロー**:
1. `MitchieAPIClient.shared.fetchFollowupMessage(daysOff: N, goal: userProfile.goal)` を呼び出し
2. 読み込み中: スピナー
3. 完了: みっちーキャラ + AI生成の優しいフォローメッセージ
4. 「よし、今日からまた頑張る！」ボタン → シートを閉じて `HomeView` へ戻る

---

### 2-7. ProfileView（新規）

**ファイル**: `ai-mitchie-ios/ProfileView.swift`

**表示要素**:
- ユーザー情報表示・編集（名前・年齢・身長・体重・目標・レベル・体型目標）
- 統計セクション: 連続日数ストリーク / 累計ワークアウト数
- 「プランをリセットして再生成」ボタン: `WorkoutPlan` を削除 → `WorkoutDashboardView` へ遷移

---

## Phase 3: API強化

### 3-1. MitchieAPIClient.swift（改修）

**追加内容**:

```swift
// 共通エラー型
enum APIError: Error {
    case invalidURL
    case serverError(Int)
    case decodingError
    case networkError(Error)
}

// 褒めメッセージ取得（ワークアウト完了後）
func fetchPraiseMessage(
    exercises: [String],
    totalSets: Int,
    goal: String
) async throws -> String

// フォローアップメッセージ取得（サボり日）
func fetchFollowupMessage(
    daysOff: Int,
    goal: String
) async throws -> String
```

**APIエンドポイント**:
- `/praise`: `POST {"exercises": [...], "totalSets": N, "goal": "..."}`  
  → `{"message": "全肯定メッセージ"}`
- `/followup`: `POST {"daysOff": N, "goal": "..."}`  
  → `{"message": "フォローメッセージ"}`

**Info.plist 追加キー**:
```xml
<key>ApiGatewayKey</key>
<string>$(API_GATEWAY_KEY)</string>
```
（既存の `ApiGatewayUrl` に加えて `ApiGatewayKey` も追加）

---

### 3-2. lambda_handler.py（拡張）

**ルーティング追加**:

```python
def lambda_handler(event, context):
    # API Gatewayのパスを取得
    path = event.get("rawPath") or event.get("path", "/plan")
    
    if path.endswith("/plan"):
        # 既存ロジック
        return handle_plan(body)
    elif path.endswith("/praise"):
        return handle_praise(body)
    elif path.endswith("/followup"):
        return handle_followup(body)
    else:
        return _error(404, "Not Found")
```

**新規関数**:

```python
def generate_praise(exercises: list, total_sets: int, goal: str) -> str:
    """
    ワークアウト完了後の全肯定褒めメッセージを生成する。
    みっちーらしい熱血口調（日本語・100文字程度）。
    """

def generate_followup(days_off: int, goal: str) -> str:
    """
    N日間サボった後の優しいフォローメッセージを生成する。
    責めず・励ます・また始めたくなる口調（日本語・80文字程度）。
    """
```

**プラン生成（`/plan`）のプロンプト制約**（既存 `lambda_handler.py` に実装済み）:

| 区分 | 内容 |
|------|------|
| ✅ 使用可能な種目 | スクワット・ランジ・プッシュアップ（腕立て伏せ）・バーピー・マウンテンクライマー・プランク・クランチ・レッグレイズ・グルートブリッジ・ジャンピングジャック・ハイニーなど |
| ❌ 禁止種目 | ベンチプレス・懸垂（チンニング）・バーベル・ダンベル・マシン系など器具を必要とする種目すべて |
| 基準 | **自宅の床さえあれば実施可能**であること |

`/praise` および `/followup` の生成プロンプトにも同じ前提（自重トレーニングのみ）を明記し、メッセージ内容が器具前提にならないよう制御する。

**`howTo` フィールドの追加**（初心者向けフォーム説明）:

Lambdaのプロンプトに `howTo` 生成を追加し、`ExerciseDTO` のJSONレスポンスに含める。

```json
// 拡張後のレスポンス例
{
  "name": "スクワット",
  "workSeconds": 30,
  "restSeconds": 15,
  "sets": 3,
  "howTo": "足を肩幅に開き、膝がつま先より前に出ないように腰をゆっくり落とす。背筋は伸ばしたまま。"
}
```

プロンプトへの追記内容:
```
各エクササイズに "howTo" フィールドを追加してください。
初心者が読んでもすぐ実践できるよう、フォームのポイントを1〜2文（40文字以内）の日本語で簡潔に説明すること。
```

Swift側の `ExerciseDTO` / `ExerciseModel` にも `howTo: String` を追加する（Phase 1と連動）。

**API Gatewayリソース追加**:
- `/praise` — POST メソッド
- `/followup` — POST メソッド

---

### 3-3. SETUP.md（追記）

- API Gatewayへ `/praise`, `/followup` リソースを追加する手順
- Lambda ルーティングの説明
- `curl` テスト例（`/praise`, `/followup`）

---

## ファイル変更サマリー

| ファイル | 状態 | 内容 |
|----------|------|------|
| `ai-mitchie-ios/WorkoutModels.swift` | **全面改訂** | UserProfile / WorkoutPlan / WorkoutLog 追加・ExerciseModelに `howTo` フィールド追加 |
| `ai-mitchie-ios/ai_mitchie_iosApp.swift` | **改訂** | modelContainer拡張・RootView起点に変更 |
| `ai-mitchie-ios/MitchieAPIClient.swift` | **改訂** | fetchPraiseMessage / fetchFollowupMessage 追加 |
| `ai-mitchie-ios/WorkoutDashboardView.swift` | **改修** | UserProfile連携・ハイライト強化・種目 `ℹ️` ボタン追加 |
| `ai-mitchie-ios/WorkoutTimerView.swift` | **改修** | 開始時刻記録・WorkoutCompleteView遷移・種目 `ℹ️` ボタン追加 |
| `ai-mitchie-ios/GoalSelectionView.swift` | **削除** | OnboardingViewに統合 |
| `ai-mitchie-ios/MitchieRank.swift` | **流用** | 変更なし |
| `lambda/lambda_handler.py` | **拡張** | /praise・/followupルーティング追加・`howTo` フィールドをプランJSONに含めるようプロンプト拡張 |
| `lambda/SETUP.md` | **追記** | 新エンドポイント手順 |
| `ai-mitchie-ios/HomeView.swift` | **新規** | ホーム画面 |
| `ai-mitchie-ios/OnboardingView.swift` | **新規** | 4ステップオンボーディング |
| `ai-mitchie-ios/WorkoutCompleteView.swift` | **新規** | 全肯定完了画面 |
| `ai-mitchie-ios/WorkoutFollowupView.swift` | **新規** | サボり日フォロー画面 |
| `ai-mitchie-ios/ProfileView.swift` | **新規** | プロフィール画面 |

---

## Verification（動作確認チェックリスト）

- [ ] Xcodeビルドエラーなし（SwiftData モデル整合確認・`howTo` フィールド含む）
- [ ] Lambda `/plan` レスポンスに `howTo` フィールドが含まれることを確認
- [ ] WorkoutTimerView: `ℹ️` タップで `howTo` シートが表示されること
- [ ] WorkoutDashboardView: 種目リスト展開 + `ℹ️` タップで `howTo` シートが表示されること
- [ ] オンボーディング: 初回のみ表示 → 2回目以降スキップ（UserDefaultsフラグ確認）
- [ ] Lambda `/plan` エンドポイント: `curl` でワークアウトプランJSON取得
- [ ] Lambda `/praise` エンドポイント: `curl` で褒めメッセージ取得
- [ ] Lambda `/followup` エンドポイント: `curl` でフォローメッセージ取得
- [ ] E2Eフロー: オンボーディング → プラン生成 → ワークアウト完了 → AI全肯定メッセージ表示
- [ ] WorkoutFollowupView: `lastWorkoutDate` を3日前に設定 → 起動時にシート表示確認
- [ ] ストリーク: 連続ワークアウト完了でカウントアップ確認

---

## Phase 4（スコープ外・次フェーズ）

- **AVSpeechSynthesizer** による音声応援（MitchieSpeechService）
  - カウントダウン音声・セット完了フレーズ・褒めメッセージ読み上げ
- **UNUserNotificationCenter** によるプッシュ通知（NotificationService）
  - 毎日リマインダー通知（指定時刻）
  - 3日間未アクセス時の優しいリマインド通知（ローカル通知）
- **ウェアラブル連携**（HealthKit / Watch）: 心拍数・消費カロリー取得
- **ブランド展開**: VTuber連携・LINEスタンプ等（事業計画書「将来的展望」）
