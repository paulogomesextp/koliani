# Como testar o Koliani (Paulo)

## O que há de novo para playtestar (v0.9.0 → v0.9.6, 1 set 2026)

Tudo o que entrou nesta leva está por afinar — os números são todos "a
olho", conferidos só em screenshots headless. Arranca já no nível certo com
o kit todo (FLYMODE na tecla F):

```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" . -- --devmode --nivel=N
```

| o quê | onde ver (`--nivel=`) | o que confirmar |
|-------|----------------------|-----------------|
| **rig novo da Koliani** (Knight_player) | qualquer | escala e pés nos declives; leitura da silhueta; se as animações novas (rolar, dash, dano, defesa, agarrar a borda, aterrar, morte) entram na altura certa |
| **sons** de espada / tiro / acerto | qualquer | já não irritam ao fim de dois minutos? volume face à música? |
| **som do checkpoint** + **fogueira** | qualquer (a jornada põe vários) | a fogueira lê-se como "ponto de regresso"? acende bem ao tocar? |
| **fundo da cidade** (pack novo) | 21, 22, 23, 25 | é o fundo que mais se parece com o key_art — confirmar que não puxa a atenção para longe da acção |
| **fundo de igreja** (pack novo) | 7, 9, 18, 24, 27, 28, **30** | escuro de mais? claro de mais? (o Trono é o melhor exemplo) |
| **pântano** na região I | 1, 3 | substituiu o pôr-do-sol laranja do parallax_forest |
| **desaturação/tinta dos packs** | 6, 10 | o Cold Corridors deixou de ser azul-néon e o Mountain Dusk deixou de ter falésias vermelhas |
| **pedra gótica na região I** | 1..5 | acabou a relva de banda desenhada |
| **líquido mortal mais escuro** | qualquer | ainda se lê como perigo? |
| **5 monstros novos** | 3 besouro · 9 mastim · 12 abutre · 18 gosma · 24 raptor | escala, velocidade, e se o abutre a mergulhar é justo |
| **um monstro "cara" por nível** | percorrer 2-3 níveis seguidos | dá mesmo a sensação de que cada nível tem o seu bicho? |

Screenshots sem jogar:

- `tools/shot_dev_nivel.gd` — vários PNG ao longo da jornada de UM nível
  (`--screen 1 --script ... -- <idx> <prefixo> <n_shots> <passo_x> <zoom>`;
  o zoom real do jogo é 1.4).
- `tools/folha_de_contacto.gd` — **um retrato de cada um dos 30 níveis numa
  grelha 6x5** (uma linha por região). É a maneira mais rápida de ver se uma
  região ficou escura de mais ou se um fundo destoa:

```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" --screen 1 --resolution 1280x720 --script res://tools/folha_de_contacto.gd -- folha.png 1.4 2400
```

  Leva ~2 min e precisa de janela (não corre em `--headless`).

## Atalho no Ambiente de Trabalho

**"Koliani (testar)"** &mdash; duplo-clique abre o jogo **com o código
atual** (não precisa de reexportar nada). Aponta para `jogar.bat`.
Se desaparecer, recria com:
```
powershell -ExecutionPolicy Bypass -File criar-atalho.ps1
```

Builds prontos (gerados por `godot --headless --export-release ...`):
- `build/windows/Koliani.exe` &mdash; jogo autónomo Windows (snapshot; não
  se atualiza sozinho).
- `build/web/` &mdash; versão browser (o preview do Claude Code serve-a).

## Correr o jogo no PC

**Editor (recomendado para desenvolver):**
```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" -e .
```
No editor: **F5** corre o jogo (a partir do mundo atual do save), **F6**
corre a *cena aberta* (útil para testar um nível isolado).

**Sem editor (correr como o jogador veria):**
```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" .
```

O jogo arranca no **menu inicial** (`scenes/ui/MenuInicial.tscn`):

- **NEW GAME** — campanha nova do mundo 1 (apaga o save; pede confirmação).
- **LOAD GAME** — retoma o save (só aparece se houver progresso guardado).
- **HARDCORE MODE** — campanha nova com **tempo limite por mundo**; se o
  relógio (topo do ecrã) chegar a zero é *Game Over* e recomeça do mundo 1.
  O relógio pára enquanto o jogo está em pausa / no diário.
- **OPTIONS** — volume da *Music* e dos *Effects*, e **LANGUAGE**
  (English/Português/Español/Français/Deutsch/中文; muda o jogo todo na
  hora). O jogo arranca **em inglês**. As definições ficam em
  `%APPDATA%\Godot\app_userdata\Koliani\opcoes.json`.
- **Quit**.

> O modo **hardcore**: o relógio **não** reinicia quando morres (só ao
> mudar de mundo). Fim do run = tempo a zero **ou** gastar as 3 vidas →
> cartão "GAME OVER" (com voz) → recomeça do mundo 1.

> **Áudio**: música de fundo mais alta; no **mundo 4 (Zeriko)** muda para
> uma faixa mais rápida e alta; por baixo há sempre ruídos de casa
> assombrada; os demónios rosnam ao acertar-te. Tudo sintetizado
> (`tools/gerar_audio.py`).

Atalhos para saltar o menu (capturas, testes):
```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" . -- --jogar
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" . -- --nivel=3
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" . -- --hardcore
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" . -- --hardcore --hc-tempo=15
```
`--hc-tempo=N` força N segundos em todos os mundos (afinar / ver o Game
Over depressa). `--nivel=4` cai já no chefe final (para ouvir a música do
boss).

## Regerar o áudio sintetizado

```
python tools/gerar_audio.py
```
Gera `game_over.wav`, `boss.wav`, `assombracao.wav`, `demonio_ataque.wav`
em `assets/audio/`. A seguir, no editor (ou `--import`) o Godot reimporta;
`boss.wav` e `assombracao.wav` têm `loop_mode=1` no `.import`.

## Controlos

| Ação | Teclado | Toque (telemóvel) |
|------|---------|-------------------|
| Andar | setas ← → ou A / D | d-pad esquerdo |
| Saltar (duplo depois de apanhar a gema do mundo 1) | Espaço ou ↑ | botão baixo-direito |
| Atacar | J | botão de ação (cima) |
| Dash | K | botão de ação (baixo) |
| Rolar | ↓ | botão de ação (esquerda) |
| Defender (escudo, depois de o apanhar) — hold | L ou botão direito do rato | botão de ação (meio-esq.) |
| Projétil mágico (depois de o apanhar) | U ou clique esquerdo; mira com A/D + W/S (8 direções) | botão de ação |
| Diário de pistas | I ou Tab | botão canto sup. direito |
| Fechar diário | Esc | (toca fora / botão) |
| Pausa | P | botão abaixo do diário |
| Fechar pausa | P ou Esc | botão "Continuar" |

Menu de pausa: *Continuar*, *Recomeçar no checkpoint*, *Menu principal*
(volta ao ecrã inicial) e *Sair do jogo*.

## Atalhos de depuração (só no editor / build de debug)

| Tecla | Efeito |
|-------|--------|
| F1 / F2 / F3 / F4 | saltar para o mundo 1 / 2 / 3 / 4 |
| F5 | desbloquear todas as habilidades (salto duplo, dash aéreo, partir paredes, escudo) |
| F6 | +3 vidas |
| F9 | apagar o save e recomeçar a campanha |

O save fica em
`%APPDATA%\Godot\app_userdata\Koliani\progresso.json` — apagar esse ficheiro
também recomeça do zero.

## Estado visual/áudio (2.º passe, "look Dead Cells")

Personagens são sprites SVG rim-lit com shader (flash de dano) e animação
procedural (squash/stretch, wind-up dos chefes, rastro da lâmina, frame de
impacto). Ambiente: parallax de 4 camadas com silhuetas recortadas, feixes
de luz, poeira, e passe de ecrã (contraste/saturação/**bloom** — baixa em
`Atmosfera.tscn > Grade > Passe` se estiver forte para o teu gosto).
Plataformas com shader de pedra/tijolo. SFX sintetizados + cama de
ambiente em loop. **Falta:** frames de animação a sério, música, tiles
decorados, mixagem de áudio.

## O que olhar (a jogabilidade ainda é *greybox* — layout por afinar)

- **Feel do movimento**: salto/duplo salto, corte de salto, dash, rolar.
  Os números estão em `scripts/movimento.gd` e `scripts/koliani.gd`.
- **Distâncias de salto** entre plataformas (montei sem jogar).
- **Ritmo** dos inimigos e do chefe (telegrafo → investida).
- **Fossos**: cair no vazio reaparece no checkpoint.

Anota o que estiver mal (muito curto / muito longo / injusto) que eu afino.

---

# Instalar o que falta

## 1. Modelos de export -- JÁ INSTALADOS ✔

O build Web local já funciona:
```
& "C:\Users\paulo\Desktop\Godot_v4.7.2-stable_win64.exe" --headless --export-release "Web" build/web/index.html
```
Para ver no browser: o Claude Code arranca o preview `koliani-web`
(`.claude/launch.json`) e abre a página. Ou à mão:
```
python -m http.server 8060 --directory build/web
```
(APK local ainda precisa de JDK 17 + Android SDK + keystore; o CI trata disso.)

## 2. Ligar o repositório ao GitHub + CI

O agente não mexe em `git config`/`remote` — estes passos são teus:

1. Cria um repositório **vazio** no GitHub (sem README/licença).
2. No `C:\Projetos\koliani`:
   ```
   git remote add origin https://github.com/<o-teu-user>/koliani.git
   git push -u origin master
   ```
3. O workflow `.github/workflows/ci.yml` corre sozinho a cada push:
   testes → build Web → build APK (artifacts `koliani-web`, `koliani-android`).
4. A **1.ª execução** pode falhar por detalhes (versão da imagem
   `barichello/godot-ci`, nome dos presets). Manda-me o log do Actions que
   eu ajusto o YAML.

Com o CI a verde tens sempre um **APK** para instalar no telemóvel a partir
da página do Actions, sem precisar do PC ligado.
