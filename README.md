# yosayosa - ひかりのパズル

Godot 4.x で作成された2D反射パズルゲームです。

## ゲーム概要

プレイヤー（光の粒子）を発射し、鏡で反射させながらゴールを目指すパズルゲームです。

### 操作方法

- **ドラッグ**: 発射方向の指定 / 鏡の移動
- **スペースキー**: 発射
- **右クリック**: 鏡を回転（15度刻み）
- **インベントリクリック**: 鏡を取り出す

### ゲームの流れ

1. 右側のインベントリから鏡をドラッグして配置
2. 鏡の角度を右クリックで調整
3. 画面をドラッグして発射方向を決定
4. スペースキーで発射
5. ゴール（星形）に到達すればクリア

## 動作環境

- Godot 4.3+
- GDScript

## セットアップ

### 1. Godotのインストール

#### macOS (Homebrew)
```bash
brew install --cask godot
```

#### 手動インストール
[Godot公式サイト](https://godotengine.org/download)からダウンロード

### 2. プロジェクトを開く

1. Godotを起動
2. 「インポート」をクリック
3. このフォルダの `project.godot` を選択
4. 「インポートして編集」をクリック

## ディレクトリ構造

```
yosayosa/
├── project.godot        # プロジェクト設定
├── scenes/
│   ├── title_screen.tscn   # タイトル画面
│   ├── debug_menu.tscn     # デバッグメニュー
│   ├── game_stage.tscn     # ゲームステージ
│   ├── blank_screen.tscn   # 空白画面（準備中）
│   ├── player.tscn         # プレイヤー
│   ├── mirror.tscn         # 鏡
│   ├── goal.tscn           # ゴール
│   └── ui/
│       ├── inventory.tscn      # インベントリ
│       └── result_overlay.tscn # 結果表示
├── scripts/
│   ├── game_manager.gd     # ゲーム全体管理（Autoload）
│   ├── game_stage.gd       # ステージロジック
│   └── ...
└── assets/
    ├── sprites/       # 画像/スプライト
    ├── audio/         # 音声ファイル
    └── fonts/         # フォントファイル
```

## デバッグステージ

1. **Stage 1: 基本操作** - 直線でゴールへ
2. **Stage 2: 鏡の反射** - 1枚の鏡で反射
3. **Stage 3: 複数の鏡** - 複数の鏡を使用
4. **Stage 4: 固定鏡** - 動かせない鏡が配置
5. **Stage 5: 複雑な迷路** - 複数の壁と鏡

## 今後の拡張予定

- [ ] 素材画像への置き換え
- [ ] 回転刻み設定画面
- [ ] 動く障害物
- [ ] ギャラリー機能
- [ ] オプション画面

## ライセンス

MIT License
