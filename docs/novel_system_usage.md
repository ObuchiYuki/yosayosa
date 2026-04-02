# ノベルシステム 使い方

## 概要

`NovelScreen` は汎用的なノベルゲーム形式の画面を提供するクラスです。
テキストを入力として受け取り、上部に画像、下部にメッセージを自動で表示します。

## 基本的な使い方

### シーンとして使用

```gdscript
# 別シーンから遷移
GameManager.change_scene("res://scenes/novel_screen.tscn")
```

### コードから生成

```gdscript
var novel := NovelScreen.create()
add_child(novel)
novel.start("表示するテキスト", func(): print("完了"))
```

### 継承して使用（推奨）

`intro_novel.gd` のように継承して専用シーンを作成できます：

```gdscript
extends NovelScreen

const MY_TEXT := """<background_image id='bg_001'>ここにテキストを書きます。
<next_page>次のページの内容。"""

func _ready() -> void:
    super._ready()
    start(MY_TEXT, _on_complete)

func _on_complete() -> void:
    GameManager.change_scene("res://scenes/next_scene.tscn")
```

## メタタグ一覧

### `<space>`
文字送りに一瞬時間をあけます（約0.3秒）。文の区切りなどに使用。

```
むかしむかし、<space>あるところに…
```

### `<next_page>`
セリフのページ送り。クリックで次のページへ進みます。

```
最初のページの内容。<next_page>次のページの内容。
```

### `<play id="xxx">`
指定IDのSEを再生します。

```
<play id="sparkle1">キラーン！
```

### `<bgm id="xxx">`
指定IDのBGMを再生します。空のIDを指定すると停止。

```
<bgm id="mystery">不思議なBGMが流れる…
<bgm id="">BGMを停止
```

### `<background_image id='xxx'>`
上部にaspect_fillで画像を表示します。前の画像は自動的に消えます。
空のIDを指定すると画像を非表示にします。

```
<background_image id='yosari_001'>ヨサリが現れた！
<background_image id=''>（画像を消す）
```

### `<image id="xxx" rect='x y width height'>`
追加の画像を指定位置・サイズで表示します。
`rect` は `x y`（元画像サイズ）または `x y w h` で指定。

- **数値 + 数値**: その矩形に **aspect fit**（`KEEP_ASPECT_CENTERED`）で収める。
- **`-`**: もう一方の辺に合わせてアスペクト比から自動計算（例: `100 222 - 100` は高さ100固定で幅を自動）。
- **`screen`（幅）**: 幅を画面幅（1920）に（例: `100 200 screen -` は幅フル・高さはアスペクトで自動）。
- **`screen`（高さ）**: 高さを画面高（1080）に（例: `100 200 - screen`）。
- **`screen` と `screen` 両方**: 画面全体の箱に aspect fit。

```
<image id="magic_mirror" rect='100 200 300 400'>
<image id="light_001" rect='500 100'>
<image id="yosari_001" rect='100 200 - 320'>
```

### `<hide_image id='xxx'>`
`<image>` で表示した画像を隠します。

```
<hide_image id='magic_mirror'>
```

### `<clear_image>`
`<image>` で表示中のオーバーレイ画像をすべて消します。`background_image`（上部の背景）は変えません。

```
<clear_image>
```

### `<screen_effect type="shake"|"flash">`
画面を揺らす・光らせるエフェクト。カンマ区切りで両方指定可能。

```
<screen_effect type="shake">ガタガタ！
<screen_effect type="flash">ピカッ！
<screen_effect type="shake,flash">ドカーン！
```

## 利用可能な画像ID

### キャラクター
| ID | 説明 |
|---|---|
| `honka_001` | ひらがな「よさり」1 |
| `honka_002` | ひらがな「よさり」2 |
| `yosari_001` 〜 `yosari_010` | カタカナ「ヨサリ」1〜10 |

### 背景
| ID | 説明 |
|---|---|
| `bg_001` | 背景1 |
| `bg_002` | 背景2 |
| `bg_003` | 背景3 |

### アイテム・エフェクト
| ID | 説明 |
|---|---|
| `light_001` 〜 `light_009` | 光エフェクト |
| `magic_mirror` | 魔法の鏡 |
| `bronze_mirror` | 青銅鏡 |
| `imagination_mirror` | 想像の鏡 |
| `focus_lines` | 集中線 |
| `motion_lines` | 動線 |
| `komodo_dragon` | コモドドラゴン |
| `credit_001` | クレジット1 |
| `credit_002` | クレジット2 |

## 利用可能なBGM ID

| ID | 説明 |
|---|---|
| `title` | タイトルBGM |
| `stage` | ステージBGM |
| `comical` | コミカル |
| `mystery` | ミステリアス・アジアン |
| `cute` | かわいい系 |

## 利用可能なSE ID

| ID | 説明 |
|---|---|
| `shoot` | 発射音 |
| `reflect` | 反射音 |
| `applause` | 拍手 |
| `curse` | 失敗音 |
| `click` | UIクリック |
| `hover` | UIホバー |
| `scene_change` | 場面転換 |
| `find_out` | 発見 |
| `sparkle1` | キラッ1 |
| `sparkle2` | キラッ2 |
| `rumble` | ゴゴゴゴ |
| `message` | メッセージ表示音 |
| `goofy` | 間抜け |
| `decide` | 決定 |
| `jidaigeki1` | 時代劇演出1 |
| `jidaigeki2` | 時代劇演出2 |
| `jidaigeki3` | 時代劇演出3 |
| `bell` | 時計塔の鐘 |
| `magic_reflect` | 魔法反射 |
| `blink` | 目をパチパチ |
| `bell_ring` | 鈴を鳴らす |

## 操作方法

- **クリック** または **Space/Enter**: 
  - 文字送り中 → スキップして全文表示
  - 全文表示後 → 次のページへ
- 最後のページでクリック → `novel_finished` シグナル発火 / コールバック実行

## ファイル構成

```
scripts/
├── novel_screen.gd     # 基本クラス
└── intro_novel.gd      # 導入用（継承例）

scenes/
├── novel_screen.tscn   # 汎用シーン
└── intro_novel.tscn    # 導入シーン

assets/
├── sprites/novel/      # ノベル用画像
│   ├── game_bg.png
│   ├── dialog_frame.png
│   ├── honka_*.png
│   ├── yosari_*.png
│   ├── bg_*.png
│   └── ...
└── fonts/
    ├── BestTen-DOT.otf # メッセージ用フォント
    └── BestTen-CRT.otf
```

## 新しい画像・SEを追加する方法

### 画像を追加

1. `assets/sprites/novel/` に画像ファイルを配置
2. `scripts/novel_screen.gd` の `IMAGE_PATHS` に追加：

```gdscript
const IMAGE_PATHS: Dictionary = {
    # ...既存のエントリ...
    "my_new_image": "res://assets/sprites/novel/my_new_image.png",
}
```

### SEを追加

1. `assets/audio/` に音声ファイルを配置
2. `scripts/novel_screen.gd` の `SE_PATHS` に追加：

```gdscript
const SE_PATHS: Dictionary = {
    # ...既存のエントリ...
    "my_new_se": "res://assets/audio/my_new_se.mp3",
}
```
