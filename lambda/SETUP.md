# Lambda + Amazon Bedrock セットアップガイド

## 構成概要

```
iOS App → API Gateway (POST) → Lambda (Python) → Amazon Bedrock (Nova Lite)
```

---

## 1. Lambdaファンクションのコード

`lambda_handler.py` として保存してデプロイしてください。

```python
import json
import boto3
import re
import os

bedrock = boto3.client(
    'bedrock-runtime',
    region_name=os.environ.get('BEDROCK_REGION', 'ap-northeast-1')
)

MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'amazon.nova-lite-v1:0')


def lambda_handler(event, context):
    try:
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event

        goal  = body.get('goal', '健康増進')
        level = int(body.get('level', 1))
        days  = int(body.get('days', 7))

        plan = generate_plan(goal, level, days)

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(plan, ensure_ascii=False)
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }


def generate_plan(goal: str, level: int, days: int) -> list:
    prompt = f"""あなたはMitchieという熱血パーソナルトレーナーです。
以下の条件で{days}日間のワークアウトプランをJSONで作成してください。

目標: {goal}
レベル: {level} (1=超初心者, 10=伝説の上級者)
日数: {days}日間

レベル別の目安:
- Lv.1-3: 種目1〜2個、workSeconds 15-25秒、restSeconds 15秒、sets 2-3
- Lv.4-6: 種目2〜3個、workSeconds 25-40秒、restSeconds 10秒、sets 3
- Lv.7-10: 種目3〜4個、workSeconds 40-60秒、restSeconds 10秒、sets 3-4

必ず以下のJSON配列のみを返してください。説明文・コードブロック記号は一切不要です：

[
  {{
    "dayNumber": 1,
    "mitchieQuote": "Mitchieらしい熱い一言（日本語・20文字程度）",
    "exercises": [
      {{
        "name": "エクササイズ名（日本語）",
        "workSeconds": 30,
        "restSeconds": 10,
        "sets": 3
      }}
    ]
  }}
]"""

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        body=json.dumps({
            "messages": [
                {
                    "role": "user",
                    "content": [{"text": prompt}]
                }
            ],
            "inferenceConfig": {
                "maxTokens": 4096
            }
        })
    )

    result = json.loads(response['body'].read())
    text = result['output']['message']['content'][0]['text'].strip()

    # ```json ... ``` や ``` ... ``` を除去
    text = re.sub(r'^```[a-z]*\n?', '', text).rstrip('`').strip()

    json_match = re.search(r'\[.*\]', text, re.DOTALL)
    if json_match:
        return json.loads(json_match.group())
    return json.loads(text)
```

---

## 2. Lambda 設定

| 項目 | 値 |
|------|----|
| ランタイム | Python 3.12 |
| タイムアウト | **60秒**（Bedrockのレスポンスが遅い場合があるため） |
| メモリ | 256 MB |

### 環境変数

| 変数名 | 値 | 説明 |
|--------|----|------|
| `BEDROCK_REGION` | `ap-northeast-1` | Bedrockを利用するリージョン |
| `BEDROCK_MODEL_ID` | `amazon.nova-lite-v1:0` | 使用するモデルID |

> **Amazon Nova モデルの選択肢（コスト順）**
> - 最安・最速: `amazon.nova-micro-v1:0`（テキストのみ）
> - バランス型: `amazon.nova-lite-v1:0` ← 推奨
> - 高精度: `amazon.nova-pro-v1:0`（コスト高）

---

## 3. IAM ロール（Lambda実行ロール）

Lambda に付与する IAM ポリシーに以下を追加してください。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel"
      ],
      "Resource": [
        "arn:aws:bedrock:ap-northeast-1::foundation-model/amazon.nova-lite-v1:0",
        "arn:aws:bedrock:ap-northeast-1::foundation-model/amazon.nova-micro-v1:0",
        "arn:aws:bedrock:ap-northeast-1::foundation-model/amazon.nova-pro-v1:0"
      ]
    }
  ]
}
```

> `Resource` の ARN は `BEDROCK_REGION` と `BEDROCK_MODEL_ID` に合わせて変更してください。

---

## 4. Bedrock モデルアクセスの有効化

Bedrockは**モデルごとにアクセス申請が必要**です。

1. AWSコンソール → **Amazon Bedrock** → **モデルアクセス**
2. `Amazon` の `Nova Lite` にチェック（Nova Micro / Nova Pro も使う場合は合わせて追加）
3. **アクセスをリクエスト** をクリック（通常即時承認）

---

## 5. API Gateway 設定

### 5-1. REST API の作成

1. AWSコンソール → **API Gateway** を開く
2. **REST API** の「構築」をクリック
3. 設定:
   - プロトコル: `REST`
   - 作成方法: `新しい API`
   - API 名: `mitchie-api`（任意）
   - エンドポイントタイプ: `リージョン`
4. **API の作成** をクリック

### 5-2. リソースとメソッドの作成

1. 左メニュー **リソース** → **アクション** → **リソースの作成**
   - リソース名: `plan`
   - リソースパス: `/plan`
   - **リソースの作成** をクリック
2. `/plan` を選択した状態で **アクション** → **メソッドの作成**
   - ドロップダウンで `POST` を選択 → チェックマークをクリック
3. メソッドの設定:
   - 統合タイプ: `Lambda 関数`
   - **Lambda プロキシ統合の使用**: ✅ チェックを入れる
   - Lambda リージョン: `ap-northeast-1`
   - Lambda 関数: 作成済みの関数名を入力
   - **保存** → 「Lambda 関数に権限を追加します」ダイアログが出たら **OK**

### 5-3. デプロイ

1. **アクション** → **API のデプロイ**
2. デプロイステージ: `[新しいステージ]`
   - ステージ名: `prod`
3. **デプロイ** をクリック
4. **ステージ** → `prod` → 表示される **URL の呼び出し** をコピー
   - 例: `https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/prod`
5. iOSアプリの `Info.plist` → `ApiGatewayUrl` にベースURLを設定（末尾スラッシュなし）
   - 例: `https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/prod`
   - ※ パス（`/plan` `/praise` `/followup`）はアプリ側で自動付与します

### 5-4. Lambda のタイムアウト対応（重要）

API Gateway のデフォルトタイムアウトは **29秒** です。Bedrock の応答が遅い場合に備え、Lambda 側のタイムアウトを 29秒以下に設定してください（API Gateway の上限を超えると 504 エラーになります）。

| 設定箇所 | 推奨値 |
|---------|--------|
| API Gateway 統合タイムアウト | 29,000 ms（変更不可・上限） |
| Lambda タイムアウト | **25秒**（余裕をもたせる） |

### 5-5. CORS 設定（curlやWebでテストする場合のみ）

iOSアプリからの通信には不要です。ブラウザや curl 以外のクライアントから叩く場合は以下を設定してください。

1. `/plan` リソースを選択 → **アクション** → **CORS の有効化**
2. `Access-Control-Allow-Origin`: `*`
3. **CORS を有効にして既存の CORS ヘッダーを置き換える** をクリック
4. 再度 **API のデプロイ** を実施

---

## 6. iOS側の設定（Info.plist）

```xml
<key>ApiGatewayUrl</key>
<string>https://xxxxxxxxxx.execute-api.ap-northeast-1.amazonaws.com/prod</string>
<key>ApiGatewayKey</key>
<string>$(API_GATEWAY_KEY)</string>
```

`ApiGatewayKey` は Xcode の **Build Settings → User-Defined** に `API_GATEWAY_KEY` を追加し、API Gateway で発行した APIキーを設定してください。

---

## 7. API Gatewayリソースの追加（/praise, /followup）

`/plan` に加えて `/praise`・`/followup` の2リソースを作成します。

1. API Gateway コンソールを開き、既存のAPIを選択
2. 左メニュー **リソース** → 「リソースの作成」
   - リソース名: `praise`、リソースパス: `/praise`
   - 同様に `followup`（`/followup`）を作成
3. 各リソースに **POST** メソッドを追加
   - 統合タイプ: Lambda 関数
   - Lambda 関数: 既存の `mitchie-lambda`（同一関数を再利用）
   - Lambda プロキシ統合: **有効**
4. APIをデプロイ（ステージ: `prod`）

---

## 8. テスト用リクエスト例

### /plan（ワークアウトプラン生成）
```bash
curl -X POST https://your-api-gateway-url/prod/plan \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"goal": "健康増進", "level": 1, "days": 7}'
```

期待されるレスポンス:
```json
[
  {
    "dayNumber": 1,
    "mitchieQuote": "今日から始めよう、俺が全力で支えるぜ！",
    "exercises": [
      {
        "name": "スクワット",
        "workSeconds": 20,
        "restSeconds": 15,
        "sets": 2,
        "howTo": "足を肩幅に開き、膝がつま先より前に出ないように腰を落とす。"
      }
    ]
  }
]
```

### /praise（ワークアウト完了後の褒めメッセージ）
```bash
curl -X POST https://your-api-gateway-url/prod/praise \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"exercises": ["スクワット", "プランク"], "totalSets": 9, "goal": "健康増進"}'
```

期待されるレスポンス:
```json
{ "message": "スクワット9セット完走とは最高だぜ！君の足腰は確実に強くなってる！🔥" }
```

### /followup（サボり日フォローメッセージ）
```bash
curl -X POST https://your-api-gateway-url/prod/followup \
  -H "Content-Type: application/json" \
  -H "x-api-key: YOUR_API_KEY" \
  -d '{"daysOff": 4, "goal": "シェイプアップ"}'
```

期待されるレスポンス:
```json
{ "message": "4日ぶりだな！でも戻ってきてくれた、それだけで最高だぜ！一緒に再スタートしよう！💪" }
```
