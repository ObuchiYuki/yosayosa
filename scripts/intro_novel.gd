extends NovelScreen

## 導入ストーリー用ノベル画面
## 「はじめから」を選ぶとこの画面が表示され、終わるとステージ1へ

const INTRO_TEXT := """
<bgm id="cute">
<background_image id='bg_001'>
<image id='yosari_001' rect='0 0 1700 -'>
<image id='bronze_mirror' rect='100 0 1700 -'>
カキョウヨサリ…とある青銅鏡の付喪神の写しである。<next_line>
だが、その気質や人格は写し身ごとに異なっている。
<next_page><clear_image>


<image id='yosari_001' rect='0 -400 3000 -'>
そしてこの写し身は、実にものぐさな性格だったようだ…
<next_page><clear_image>


<image id='floor_plan' rect='60 0 - 800'>
<image id='yosari_002' rect='170 0 1600 -'>
<play id='decide'>
「あちきが鏡であることを活かせばさ…<next_line>
鏡の反射を活かして移動が楽になるじゃん？」
<next_page>


<image id='imagination_mirror' rect='0 -50 - 1050'>
「例えば鏡をこうやって置いて、ここから<next_line><space>
<image id='motion_lines' rect='0 -50 - 1050'>
鏡から鏡へと移動してけば…」
<next_page>

<play id='sparkle1'>
「光の速さで家の中どこでも行き放題になるんじゃ？<next_line>
天才か？」
<next_page><clear_image>

<background_image id='bg_bedroom'>
<image id='yosari_004' rect='-500 0 - -'>
<image id='full_mirror' rect='1200 170 450 -' z="-1">
写し身ちゃんは、家じゅうに買ってきた鏡を配置して<next_line>
実験を行った。

<next_page>
<play id='magic_reflect'>
<image id='light_001' rect='100 0 1500 -' z="-1">
(この角度で姿見に入れば、一瞬でお風呂場に<next_line>いけるはず…！)
<hide_image id='yosari_004'>
<hide_image id='light_001'>
<play id='shoot'>
<image id='light_002' rect='140 120 1500 -' z="-1">
<space>

<next_page><clear_image>

<background_image id='bg_washroom'>
こうして洗面台を通って
<image id='light_004' rect='0 0 screen screen'>
<play id='reflect'>

<next_page><clear_image>

<background_image id='bg_bathroom'>
<space><space><space>
<image id='light_005' rect='0 -100 screen screen'>
<play id='reflect'>
<space><space><space>
<clear_image>

<image id='light_006' rect='100 0 - -'>
<image id='yosari_003' rect='100 0 - -'>
<play id='sparkle1'>
<space><space><space>
<hide_image id='light_006'>
<image id='yosari_004' rect='100 0 - -'>
<play id='sparkle2'>
<space><space><space>
<hide_image id='yosari_003'>
「実験大成功 <space> 一瞬でお風呂場まで<next_line>
移動できたね！」
<next_page>

<image id='light_006' rect='100 0 - -' z='-1'>
<play id='magic_reflect'>
<space><space><space>
<hide_image id='yosari_004'>
<hide_image id='light_006'>

<image id='light_005' rect='0 -100 screen screen'>
<play id='shoot'>
<space><space><space>
「へへ、これなら
<clear_image>
<background_image id='bg_washroom'>
<image id='light_004' rect='0 0 screen screen'>
<play id='reflect'>
友達の家とかの<next_line>
進路にも鏡を置いて、瞬間移動を実現できるんじゃ…」

<space>
<next_page><clear_image>


<background_image id='bg_bedroom'>
<bgm id='comical'>
<image id='full_mirror_rotate' rect='0 420 1500 -'>
<image id='komodo_dragon' rect='500 100 2000 -'>
<play id='scene_change'>
<space><space>
<image id='focus_lines' rect='0 0 screen -'>
なんと、浴室に移動している間に、ペットの<next_line>
コモドドラゴンが姿見を倒してしまっていた！

<next_page>
<image id='light_003' rect='-100 -100 screen -'>
<play id='shoot'>
「ちょっと待って！ <space> そこの鏡に入れなかったら…！」

<next_page><clear_image>
<background_image id='bg_city_aerial'>
<image id='light_007' rect='0 0 screen -'>
<play id='shoot'>
「うわああああああああ！！！」

<next_page><clear_image>
<background_image id='bg_japan_map'>
<image id='light_008' rect='0 -200 2200 -'>
<play id='shoot'>
「う　あ　あ　あ　あ　あ　あ　あ　あ　！　！　！　」

<next_page><clear_image>
<background_image id='bg_earth_space'>
<space><space><space>
<image id='light_009' rect='0 -130 screen -'>
<play id='shoot'>
<text_speed v="0.7">
「あ　あ　あ　あ　あ　あ…」
<text_speed v="1.0">

<next_page><clear_image>
<background_image id='bg_002'>
<image id='yosari_005' rect='0 0 screen -'>
<screen_effect type="shake">
到着する場所を失った光とかした写し身は<next_line>
どこまでもどこまでも飛び続けていた。

<next_page>
<screen_effect type="shake">
（ヤバい…いつまでたっても止まらない…<next_line>
誰か助けてー！）

<next_page transition='black' transition_duration='1.0'><clear_image>
<bgm transition id=''>
<background_image id=''>
<image id='magic_mirror' rect='0 0 screen -'>
<image id='yosari_006' rect='0 0 screen -'>

「う〜ん…」<space><space><space>

<next_page>


<hide_image id='yosari_006'>
<image id='yosari_007' rect='0 0 screen -'>
<play id='blink'>
「こ…ここは…？」<space><space><space>

<next_page><clear_image>
<background_image id='bg_stone_wall'>
<play id='find_out'>
<bgm id='mystery'>
気が遠くなるほどの距離を飛んだ写し身は、<next_line>
見慣れないダンジョンの中で目を覚ました。

<next_page><clear_image>

<background_image id='bg_001'>
<play id='bell_ring'>
<image id='honka_001' rect='0 0 screen -'>
<image id='magic_mirror' rect='520 400 1700 -'>
<image id='yosari_009' rect='0 0 screen -'>
「あー、目が覚めた？」

<next_page>

「あー、あなたは確か…」

<next_page>
<hide_image id='honka_001'>
<image id='honka_002' rect='0 0 screen -' z='-1'>
「念話で魂に直接話しかけているけど、<next_line>
そこは行き場を失った光が辿り着く鏡の牢獄」

<next_page>
<hide_image id='honka_002'>
<image id='honka_001' rect='0 0 screen -' z='-1'>
「元の世界に帰りたければ脱出しなさい。<next_line>
助力はしてあげるから、横着した罰と思ってがんばって」

<next_page><clear_image>
<background_image id=''>
<image id='magic_mirror' rect='0 0 screen -'>
<image id='yosari_008' rect='0 0 screen -'>
<screen_effect type="shake">
<play id='jidaigeki1'>
「こうなったらやってやる！<next_line>
このダンジョンを攻略して元の世界に帰るんだ！」
"""


func _ready() -> void:
	super._ready()
	start(INTRO_TEXT, _on_intro_complete)


func _on_intro_complete() -> void:
	GameManager.mark_op_watched()
	GameManager.is_debug_mode = false
	GameManager.current_stage = 1
	if GameManager.get_max_stage() > 0:
		GameManager.change_scene("res://scenes/game_stage.tscn")
	else:
		GameManager.change_scene("res://scenes/title_screen.tscn")
