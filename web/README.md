
## intro_koliani.mp4 (Execution 9H)

Cópia do vídeo de abertura aprovado pelo Game Master
(`work/production_art_gate/10_menu_rebrand/05_intro_video_approved/koliani_intro_video.mp4`,
SHA `dab200cef9db9...`). Vive aqui porque **no Web o vídeo não passa pelo
Godot**: o export Web é single-threaded e descodificar Theora em wasm
bloqueia a thread principal (visto a sério -- a página deixou de responder a
`screenshot` e a `eval`). No browser toca-se um `<video>` do DOM, que é
descodificado pelo browser por hardware; e um `<video>` só toca a partir de
um URL, não de dentro do `.pck`.

O `.github/workflows/ci.yml` copia-o para `build/web/` depois do export.
O desktop continua a usar `assets/video/intro_koliani.ogv` (Theora, dentro
do pacote), que lá corre sem problema.

9H.6: o iOS prepara o motor/pack, toca o mesmo MP4 antes de iniciar o main
loop Godot e segue ao menu no fim/Skip. Restantes browsers mantêm o startup
existente. Shell base Godot 4.7.2 (MIT):
https://github.com/godotengine/godot/blob/4.7.2-stable/misc/dist/html/full-size.html
`web/shell_intro.html.in` conserva splash/startup/PWA oficiais. Gerar com
`python tools/gerar_shell_intro_web.py` e verificar com `--verificar`.
O JS vem de `JS_INTRO` e os textos dos seis catálogos; não editar o shell gerado.
Idioma inicial inglês, como Textos; depois usa espelho do idioma escolhido
em Opções, sem substituir o save. Sem painel temporário visível.
