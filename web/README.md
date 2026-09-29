# web/

- `shell.html` -- shell HTML do export Web (`html/custom_html_shell` no
  preset "Web"). Base: shell oficial do Godot 4.7.2 (MIT),
  https://github.com/godotengine/godot/blob/4.7.2-stable/misc/dist/html/full-size.html,
  com splash/startup/PWA oficiais.
- `head_pwa.html` -- vai para o `html/head_include` via
  `python tools/gerar_head_web.py` (som no telemóvel, horizontal sempre).

A abertura em vídeo (Execution 9H) foi retirada a pedido do Paulo (29 set
2026): o jogo, no Windows e na PWA, arranca direto no menu principal
(`run/main_scene = MenuInicial.tscn`). O vídeo e o código da intro ficam no
histórico do git, se um dia voltarem.
