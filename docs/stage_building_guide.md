# ステージ構築ガイド

## 概要

ステージデータは `scripts/game_manager.gd` 内の Dictionary で定義する。  
本番ステージは `_init_stages()` の `stages` に、デバッグ専用は `_init_debug_stages()` の `debug_stages` に追加する。

---

## ステージデータの構造

```gdscript
stages[1] = {
    "name": "ステージ名",              # デバッグメニューのリスト表示用
    "title": "1 - 1  はじまりの間",     # ゲーム画面上部に表示（省略時 "1 - N"）
    "start": Vector2i(1, 4),           # プレイヤー開始位置 (col, row)
    "goal": Vector2i(11, 4),           # ゴール位置
    "mirror_count": 2,                 # インベントリに入る鏡の数
    "inv_capacity": 4,                 # インベントリ最大スロット数（省略時 = mirror_count）
    "gimmicks": [                      # ギミック配列
        {"type": "wall_block", "pos": Vector2i(6, 0), "size": Vector2i(1, 5)},
    ],
}
```

### 必須キー

| キー | 型 | 説明 |
|---|---|---|
| `name` | String | ステージ名（デバッグメニュー表示用） |
| `start` | Vector2i | 開始セル座標 (col, row) |
| `goal` | Vector2i | ゴールセル座標 |
| `mirror_count` | int | プレイヤーに配布される鏡の枚数 |
| `gimmicks` | Array[Dictionary] | ギミック定義の配列（空なら `[]`） |

### 任意キー

| キー | 型 | デフォルト | 説明 |
|---|---|---|---|
| `title` | String | `"1 - N"` | ゲーム画面上部のラベル |
| `inv_capacity` | int | = mirror_count | インベントリの最大スロット数（placed_mirror で初期配置するときに余裕を持たせる） |

---

## グリッド座標

ステージサイズ small（デフォルト）の場合:

- **col**: `0` 〜 `12`（13列）
- **row**: `0` 〜 `8`（9行）
- `(0, 0)` = 左上、`(12, 8)` = 右下

medium / large は `GameManager.GRID_COLS_*` / `GameManager.GRID_ROWS_*` を参照。

---

## ギミック一覧

### wall_block — 壁ブロック

光を止める障害物。

```gdscript
{"type": "wall_block", "pos": Vector2i(6, 0), "size": Vector2i(1, 5)}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| `pos` | Vector2i | 左上セル座標 |
| `size` | Vector2i | ブロックサイズ (cols, rows) |

### fixed_mirror — 固定鏡

プレイヤーが動かせない鏡。

```gdscript
{"type": "fixed_mirror", "pos": Vector2i(4, 7), "angle": 315}
{"type": "fixed_mirror", "pos": Vector2i(6, 4), "angle": 45, "mirror_kind": "two_sided"}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| `pos` | Vector2i | セル座標 |
| `angle` | int | 鏡の角度（0, 45, 90, 135, 180, 225, 270, 315） |
| `mirror_kind` | String | 省略可。`"two_sided"` = 両面鏡、`"one_way"` = マジックミラー |

### placed_mirror — 初期配置の可動鏡

ステージ開始時からグリッド上に配置されている鏡。プレイヤーが回転・移動できる。

```gdscript
{"type": "placed_mirror", "pos": Vector2i(3, 2), "angle": 45}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| `pos` | Vector2i | セル座標 |
| `angle` | int | 初期角度 |
| `mirror_kind` | String | 省略可。fixed_mirror と同じ |

> **注意**: placed_mirror を使う場合は `inv_capacity` を `mirror_count` + 配置済み鏡の枚数以上に設定して、回収時にインベントリが溢れないようにする。

### refire_mirror — 再発射ポイント

光がここに到達すると一度停止し、そこから再エイム・再発射できる。

```gdscript
{"type": "refire_mirror", "pos": Vector2i(6, 0)}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| `pos` | Vector2i | セル座標 |

### enemy_zone — 敵マス

光が当たるとゲームオーバー。背景色 `#753A2D`。  
`id` を指定すると対応するスプライトが表示され、さらに敗北時にはスチル（挿絵）が全画面で表示される。

```gdscript
{"type": "enemy_zone", "pos": Vector2i(9, 3), "size": Vector2i(1, 3), "id": "slime"}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| `pos` | Vector2i | 左上セル座標 |
| `size` | Vector2i | 省略可。マス数 (cols, rows)。デフォルト `(1, 1)` |
| `id` | String | 省略可。スプライトID（後述）。省略時は背景色のみ |

#### 使用可能な敵スプライト ID

| id | ドット絵 | 挿絵（スチル） | 説明 |
|---|---|---|---|
| `jellyfish` | クラゲ透過.png | クラゲ.png | クラゲ |
| `gorilla` | ゴリラ透過.png | ゴリラ.png | ゴリラ |
| `succubus` | サキュバス透過.png | サキュバス.png | サキュバス |
| `slime` | スライム透過.png | スライム.png | スライム |
| `mimic` | ミミック透過.png | ミミック.png | ミミック |
| `worm` | ワーム透過.png | ワーム.png | ワーム |
| `pitfall` | 感覚遮断落とし穴.png | 感覚遮断.png | 感覚遮断落とし穴 |
| `tentacle` | 触手透過.png | 触手.png | 触手 |

- ドット絵: ステージ上のマスに aspect fit で表示
- 挿絵: 敵に当たって失敗したとき、全画面で表示（Failed テキストとボタンの下レイヤー）

### moving_platform — 移動する壁

一定範囲を往復する壁。発射中は停止する。

```gdscript
{"type": "moving_platform", "pos": Vector2i(5, 3), "size": Vector2i(1, 3),
 "axis": "x", "range": [3, 7], "speed": 1.5}
```

| パラメータ | 型 | 説明 |
|---|---|---|
| `pos` | Vector2i | 初期位置 |
| `size` | Vector2i | ブロックサイズ |
| `axis` | String | 移動軸。`"x"` = 横、`"y"` = 縦 |
| `range` | Array[int] | 移動範囲 `[min, max]`（グリッド座標） |
| `speed` | float | 移動速度（セル/秒） |

---

## 鏡の角度リファレンス

| 入射方向 → 反射方向 | angle |
|---|---|
| → ↑ (右→上) | 315 |
| → ↓ (右→下) | 225 |
| ↑ → → (上→右) | 135 |
| ↓ → → (下→右) | 45 |
| ← ↑ (左→上) | 45 |
| ← ↓ (左→下) | 135 |
| ↑ → ← (上→左) | 225 |
| ↓ → ← (下→左) | 315 |

角度 0° の鏡は法線が上向き。45° 刻みで反時計回り。

---

## ステージ追加の手順

1. `game_manager.gd` の `_init_stages()` に新しいエントリを追加
2. キーは連番 (`stages[1]`, `stages[2]`, ...)
3. デバッグメニューに自動で反映される（動的生成）
4. 「はじめから」→ ノベル完了後、`stages[1]` から順にプレイ
5. 最終ステージクリア後はタイトル画面に戻る

### デバッグ専用ステージ

テスト用のステージは `_init_debug_stages()` の `debug_stages` に追加する。  
デバッグメニューに `D1: ...` のように表示され、本番フローには影響しない。

---

## ファイル構成

| ファイル | 役割 |
|---|---|
| `scripts/game_manager.gd` | ステージデータ定義、座標変換、グローバル状態 |
| `scripts/game_stage.gd` | メインゲーム画面のオーケストレーター |
| `scripts/stage/stage_builder.gd` | ステージデータ → StageObject 群を生成するファクトリ |
| `scripts/stage/stage_object.gd` | 全ギミックの基底クラス |
| `scripts/stage/wall_block_object.gd` | 壁ブロック |
| `scripts/stage/mirror_object.gd` | 鏡（固定/可動/両面/マジックミラー） |
| `scripts/stage/goal_object.gd` | ゴール |
| `scripts/stage/refire_mirror_object.gd` | 再発射ポイント |
| `scripts/stage/enemy_zone_object.gd` | 敵マス |
| `scripts/stage/moving_platform_object.gd` | 移動する壁 |
| `scripts/stage/light_calculator.gd` | 光路計算 |
