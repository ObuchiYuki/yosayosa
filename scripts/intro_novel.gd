extends NovelScreen

## 導入ストーリー用ノベル画面
## 「はじめから」を選ぶとこの画面が表示され、終わるとステージ1へ

const INTRO_TEXT := """<background_image id='bg_001'>むかしむかし、あるところに<space>
「ヨサリ」という少女がいました。<next_page><background_image id='bg_002'>ヨサリは光を操る不思議な力を持っていました。<space>
その力で人々を照らし、導いていたのです。<next_page><background_image id='bg_003'>ある日、ヨサリは古い鏡を見つけました。<space>
それは光を反射する魔法の鏡でした。<next_page><background_image id='yosari_001'>「この鏡を使えば、もっと遠くまで<space>
光を届けられるかもしれない…」<next_page><background_image id=''>さあ、ヨサリと一緒に<space>
光のパズルを解いていきましょう！"""


func _ready() -> void:
	super._ready()
	start(INTRO_TEXT, _on_intro_complete)


func _on_intro_complete() -> void:
	GameManager.current_stage = 1
	GameManager.change_scene("res://scenes/game_stage.tscn")
