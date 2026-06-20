import json
import boto3
import re
import os

bedrock = boto3.client(
    "bedrock-runtime",
    region_name=os.environ.get("BEDROCK_REGION", "ap-northeast-1"),
)

MODEL_ID = os.environ.get("BEDROCK_MODEL_ID", "amazon.nova-lite-v1:0")


# ──────────────────────────────────────────────
# エントリーポイント
# ──────────────────────────────────────────────
def lambda_handler(event, context):
    try:
        # パス取得（API Gateway v2 は rawPath, v1 は path）
        path = event.get("rawPath") or event.get("path", "/plan")

        # ボディのパース
        if isinstance(event.get("body"), str):
            body = json.loads(event["body"])
        elif isinstance(event.get("body"), dict):
            body = event["body"]
        else:
            body = event

        if path.endswith("/plan"):
            return handle_plan(body)
        elif path.endswith("/praise"):
            return handle_praise(body)
        elif path.endswith("/followup"):
            return handle_followup(body)
        else:
            return _error(404, f"Not Found: {path}")

    except json.JSONDecodeError as e:
        return _error(400, f"JSONパースエラー: {str(e)}")
    except ValueError as e:
        return _error(400, f"入力値エラー: {str(e)}")
    except Exception as e:
        return _error(500, f"サーバーエラー: {str(e)}")


# ──────────────────────────────────────────────
# /plan: 7日間ワークアウトプラン生成
# ──────────────────────────────────────────────
def handle_plan(body: dict) -> dict:
    goal = body.get("goal", "健康増進")
    level = int(body.get("level", 1))
    days = int(body.get("days", 7))
    plan = generate_plan(goal, level, days)
    return _success(plan)


def generate_plan(goal: str, level: int, days: int) -> list:
    if not 1 <= level <= 10:
        raise ValueError(f"レベルは1〜10の範囲で指定してください: {level}")
    if not 1 <= days <= 14:
        raise ValueError(f"日数は1〜14の範囲で指定してください: {days}")

    prompt = f"""あなたはMitchieという熱血パーソナルトレーナーです。
以下の条件で{days}日間のワークアウトプランをJSONで作成してください。

目標: {goal}
レベル: {level} (1=超初心者, 10=伝説の上級者)
日数: {days}日間

【重要な制約】
- 必ず器具不要の自重トレーニングのみを使用してください
- ベンチプレス、懸垂（チンニング）、バーベル、ダンベル、マシンなど器具を使う種目は絶対に選ばないでください
- 使用可能な種目の例：スクワット、ランジ、プッシュアップ（腕立て伏せ）、バーピー、マウンテンクライマー、プランク、クランチ、レッグレイズ、グルートブリッジ、ジャンピングジャック、ハイニーなど、自宅の床さえあればできる種目

レベル別の目安（workSecondsとsetsはレベルに応じて必ず調整すること）:
- Lv.1-3: 種目1〜2個、workSeconds 15-25秒、restSeconds 15秒、sets 2-3
- Lv.4-6: 種目2〜3個、workSeconds 25-40秒、restSeconds 10秒、sets 3
- Lv.7-10: 種目3〜4個、workSeconds 40-60秒、restSeconds 10秒、sets 3-4

休息日について:
- {days}日間のうち、適切なタイミングで休息日を設けてください
- 休息日はexercisesを空配列 [] にし、mitchieQuoteに休養を促す一言を入れてください

howToフィールドについて:
- 各エクササイズに "howTo" フィールドを追加してください
- 初心者が読んでもすぐ実践できるよう、フォームのポイントを1〜2文（40文字以内）の日本語で簡潔に説明してください

出力形式:
- dayNumber 1 から {days} まで、必ず{days}個の要素を持つJSON配列を返してください
- 説明文・コードブロック記号は一切不要です

[
  {{
    "dayNumber": 1,
    "mitchieQuote": "Mitchieらしい熱い一言（日本語・20文字程度）",
    "exercises": [
      {{
        "name": "エクササイズ名（日本語）",
        "workSeconds": レベルに応じた秒数,
        "restSeconds": レベルに応じた秒数,
        "sets": レベルに応じたセット数,
        "howTo": "初心者向けフォーム説明（40文字以内）"
      }}
    ]
  }},
  ... (dayNumber {days} まで続く)
]"""

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        body=json.dumps({
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}],
                }
            ],
            "inferenceConfig": {
                "maxTokens": 4096,
            },
        }),
    )

    result = json.loads(response["body"].read())
    text = result["output"]["message"]["content"][0]["text"].strip()
    text = re.sub(r"^```[a-z]*\n?", "", text).rstrip("`").strip()

    json_match = re.search(r"\[.*\]", text, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())
    return json.loads(text)


# ──────────────────────────────────────────────
# /praise: ワークアウト完了後の全肯定褒めメッセージ
# ──────────────────────────────────────────────
def handle_praise(body: dict) -> dict:
    exercises = body.get("exercises", [])
    total_sets = int(body.get("totalSets", 0))
    goal = body.get("goal", "健康増進")
    message = generate_praise(exercises, total_sets, goal)
    return _success({"message": message})


def generate_praise(exercises: list, total_sets: int, goal: str) -> str:
    exercise_str = "、".join(exercises) if exercises else "トレーニング"
    prompt = f"""あなたはMitchieという熱血パーソナルトレーナーです。
ユーザーが以下のワークアウトを完了しました。

目標: {goal}
実施した種目: {exercise_str}
完了セット数: {total_sets}セット

【重要な前提】
- このワークアウトは器具不要の自重トレーニングです
- メッセージに器具（ベンチプレス・ダンベル等）への言及は含めないでください

以下の条件でMitchieらしい全肯定の褒めメッセージを1つ生成してください：
- 日本語・100文字程度
- 熱血で前向き、ユーザーを全力で称える口調
- 具体的な種目名を1つ以上含める
- 決して否定的な表現を使わない
- メッセージのみを返してください（説明文不要）"""

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        body=json.dumps({
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {"maxTokens": 256},
        }),
    )
    result = json.loads(response["body"].read())
    return result["output"]["message"]["content"][0]["text"].strip()


# ──────────────────────────────────────────────
# /followup: サボり日フォローメッセージ
# ──────────────────────────────────────────────
def handle_followup(body: dict) -> dict:
    days_off = int(body.get("daysOff", 3))
    goal = body.get("goal", "健康増進")
    message = generate_followup(days_off, goal)
    return _success({"message": message})


def generate_followup(days_off: int, goal: str) -> str:
    prompt = f"""あなたはMitchieという熱血パーソナルトレーナーです。
ユーザーが{days_off}日間トレーニングできていませんでした。

目標: {goal}

以下の条件でMitchieらしいフォローメッセージを1つ生成してください：
- 日本語・80文字程度
- 絶対に責めない・否定しない
- 「また一緒に頑張ろう」という前向きなトーン
- ユーザーが戻ってきやすくなる優しい励まし
- メッセージのみを返してください（説明文不要）"""

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        body=json.dumps({
            "messages": [{"role": "user", "content": [{"text": prompt}]}],
            "inferenceConfig": {"maxTokens": 256},
        }),
    )
    result = json.loads(response["body"].read())
    return result["output"]["message"]["content"][0]["text"].strip()


# ──────────────────────────────────────────────
# ユーティリティ
# ──────────────────────────────────────────────
def _success(data) -> dict:
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(data, ensure_ascii=False),
    }


def _error(status_code: int, message: str) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"error": message}, ensure_ascii=False),
    }
    try:
        if isinstance(event.get("body"), str):
