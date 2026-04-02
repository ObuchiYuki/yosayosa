extends NovelScreen

## サンプルノベルシーン - 各種機能のデバッグ用デモ（rect 拡張含む）

const SAMPLE_TEXT := """<bgm id='mystery'>【1/15】BGM再生テスト<space>
BGM: mystery を再生中です。<next_page><bgm id='cute'>【2/15】BGM切替テスト<space>
BGM: cute に切り替えました。<next_page><background_image id='bg_001'>【3/15】背景画像テスト<space>
background_image: bg_001 を表示中。<next_page><background_image id='bg_002'><image id="yosari_001" rect='80 80 320 480'><image id="yosari_003" rect='480 100 320 480'><image id="yosari_005" rect='880 80 320 480'>【4/15】rect 数値4つ（aspect fit）<space>
固定の w×h 箱に収めます。<next_page><hide_image id='yosari_001'><hide_image id='yosari_003'><hide_image id='yosari_005'><image id="light_001" rect='120 120 - 100'><image id="light_002" rect='360 120 - 100'><image id="light_003" rect='600 120 - 100'>【5/15】rect「- 高さ」幅はアスペクト自動<space>
例: 100 120 - 100 の形です。<next_page><hide_image id='light_001'><hide_image id='light_002'><hide_image id='light_003'><image id="yosari_004" rect='520 140 380 -'>【6/15】rect「幅 -」高さはアスペクト自動<space>
幅固定で高さが自動です。<next_page><hide_image id='yosari_004'><image id="focus_lines" rect='0 30 screen -'>【7/15】rect「screen -」横幅フル<space>
幅は画面幅・高さは比で自動。<next_page><hide_image id='focus_lines'><image id="yosari_002" rect='1680 0 - screen'>【8/15】rect「- screen」縦幅フル<space>
高さは画面高・幅は比で自動。<next_page><hide_image id='yosari_002'><image id="komodo_dragon" rect='200 250 520 380'>【9/15】SE: sparkle1<space>
komodo は数値 rect のまま。<next_page><hide_image id='komodo_dragon'><play id="sparkle1">【10/15】SE 再生のみ<space>
SE: sparkle1 を鳴らしました。<next_page><play id="rumble"><screen_effect type="shake">【11/15】SE + シェイク<space>
SE: rumble + shake です。<next_page><play id="magic_reflect"><screen_effect type="flash">【12/15】SE + フラッシュ<space>
SE: magic_reflect + flash です。<next_page><play id="jidaigeki1"><screen_effect type="shake,flash">【13/15】シェイク＋フラッシュ同時<space>
SE: jidaigeki1 + 両方。<next_page><background_image id='bg_003'><image id="credit_001" rect='0 0 screen screen'><bgm id='comical'>【14/15】rect「screen screen」<space>
画面全体の箱に aspect fit。<next_page><hide_image id='credit_001'><background_image id=''><bgm id=''><play id="applause">【15/15】終了<space>
クリックでタイトルに戻ります。"""


func _ready() -> void:
	super._ready()
	start(SAMPLE_TEXT, _on_sample_complete)


func _on_sample_complete() -> void:
	GameManager.change_scene("res://scenes/title_screen.tscn")
