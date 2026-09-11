# Execution 9F — UI / Menu / HUD da Região I + causa-raiz do áudio mudo no Web/PWA

Data: 11 de setembro de 2026. Versão **v0.16.0**. Commits: `72bdc2a` (áudio),
`00399d0` (UI + versão), documentação a seguir.

## 1. Estado de partida (Git)

- branch `master`, HEAD = `origin/master` = `5742825` (9E.2 docs).
- Trabalho não relacionado preservado: o `project.godot` tinha o reordenamento
  `ui_accept`/`ui_cancel` do Paulo (editor) — **nunca foi posto em stage**; só a
  linha `config/version` entrou (via `git update-index --cacheinfo`). Os
  ficheiros não rastreados do Master Package, worktrees e ferramentas antigas
  ficaram intactos.

## 2. Web/PWA sem som — CAUSA-RAIZ

**Não era o gesto nem o autoplay.** As quatro correcções anteriores
(`423fde7`, `a1f19d8`, `556fc0e`, `415d535`) só trataram o desbloqueio do
`AudioContext`. Medido num build instrumentado (hook de `AudioNode.connect` +
analisador no destino, desde o arranque):

- `AudioContext`: `running` (no pane interno, que permite autoplay);
- 2 `AudioBufferSourceNode` a tocar (menu 121 s + assombração 12 s);
- **pico no `AudioDestination` = 0.**

O grafo explicou porquê. No Web o Godot 4.7.2 toca em modo **Sample** e
espelha os buses do `AudioServer` em JS (`GodotAudio.Bus`). Os buses `Music` e
`SFX` eram criados **em runtime** por `Opcoes._criar_buses()`
(`AudioServer.add_bus`). O `GodotAudio.Bus.move()` do motor faz
`buses.splice(toIndex-1, 0, bus)` — com o índice de "acrescentar no fim" o bus
novo cai na posição **0**; o Master antigo passa a índice 1 e o
`set_bus_send(i, "Master")` seguinte liga o **Master antigo ao bus novo**:

```
arestas medidas:  [2,3] Master->destino ... [2,X] [2,4] Master->Music ... [2,X] [2,7] Master->SFX
resultado:        Master -> SFX -> Music -> Master   (ciclo; nada chega ao destino)
```

Silêncio total de TODO o áudio em modo Sample, em qualquer browser e
dispositivo — exatamente o que o Game Master viu em vários browsers. O
Windows não passa pelo espelho JS, por isso sempre teve som.

### Correção (`72bdc2a`)

- `default_bus_layout.tres` com `Master`/`Music`/`SFX` (sends para o Master):
  o motor cria-os no arranque, por ordem, sem `move`. Medido depois: Master →
  destino, Music/SFX → Master, **pico 0,036–0,062 no menu**.
- `Opcoes._criar_buses()` fica rede de segurança com `push_warning` e a flag
  `_criou_buses` (no Web criar buses em runtime cala o jogo).
- `web/head_pwa.html`: `window.kolianiAudioDiag()` (estado de cada contexto,
  canal iOS) e, só com `?audio-debug=1`, um medidor de pico no destino. O
  desbloqueio por gesto existente fica (é necessário noutro plano: o contexto
  nasce `suspended` em browsers reais — ver §6).
- Sem transcodificação, sem forçar volumes, sem atrasos, sem desligar a PWA.
- Teste `teste_9f_buses_de_audio_estaticos` — **provado a morder** (3 falhas
  com o layout retirado).

## 3. Autoridade de UI

`Koliani_1.0_Master_Package_v2/references/approved/09_PRODUCTION_PACK_v7_UI_HUD_MAPS_MENUS.png`
— 1536×1024, **RGB** (sem alfa), SHA
`264d6def7c961ea04635754ae91f33f81c891a6eae6eddaf0b1420f094a7aba9` = manifesto
aprovado. Prancha de apresentação (texto PT pintado nos botões), não atlas. As
Koliani incidentais da prancha não foram usadas.

## 4. Inventário da UI (runtime como verdade)

| Ecrã / componente | Antes | Arte antes | Agora | Autoridade |
|---|---|---|---|---|
| Menu inicial | botões `StyleBoxFlat` roxos | código | botões da prancha (normal / selecionado a ouro no foco), título a ouro | 09 §4, §9 |
| Novo / Continuar | idem | código | idem (principal destacado pelo foco de ouro) | 09 §9 |
| Seletor de níveis | carrossel de 100, 20 pastilhas "1..20", "0/100" | pedra anokolisa | **20 regiões × 5**: pastilhas I–XX, cabeçalho "I · REGIÃO · n/5", faixa 1-1..1-5, carrossel só da região, ↑/↓ muda de região; moldura de ouro nos cartões, chevrons soltos | 09 §5, §6 |
| HUD vida | calha pedra anokolisa | pixel kit | calha com gema vermelha + enchimento da prancha | 09 §2 |
| HUD energia (Shadowblade) | idem, só com `projetil` | pixel kit | calha com gema azul + enchimento | 09 §2 |
| HUD chefe | placa `painel_chefe` | pixel kit | moldura de ouro + calha vermelha escura | 09 §2, §9 |
| Vidas / Essência | coração / losango anokolisa | pixel kit | coração e cristal da prancha | 09 §1 |
| Cabeçalho do nível | placa tingida + selo "01" | pixel kit | placa escura + selo de ouro "1-5", texto ciano | 09 §9 |
| Equipamento / upgrade / disco da arma | pedra + `StyleBoxFlat` | misto | botões pequenos do kit, moldura ornamentada | 09 §9 |
| Pausa | `StyleBoxFlat` | código | painel de ouro + botões do kit | 09 §9 |
| Opções | `StyleBoxFlat` + cursores roxos | código | painel de ouro, cursores na calha de energia, idioma ativo "premido" a ouro | 09 §2, §9 |
| Diálogo (balão) | caixa roxa arredondada | código | **caixa de diálogo** da prancha | 09 §9 |
| Tutorial de mecânica | placa anokolisa | pixel kit | caixa de diálogo | 09 §9 |
| Toasts (habilidade / equipamento / pista) | placa anokolisa | pixel kit | toasts da prancha (azul / violeta) com ícone | 09 §8 |
| Checkpoint | só fogueira + som | — | + toast "Checkpoint activated!" com ícone (chave nova ×6) | 09 §8 |
| Morte / retry | não há ecrã (GAME OVER retirado, recomeço direto) | — | não inventado | — |
| Transição / loading | fade (`Transicao`) | código | inalterado (é só um fade) | — |
| Idioma | botões nas Opções | — | idem, no kit | — |

Não usado/inventado: estrelas, objetivos, poções, chaves, moedas e XP da
prancha — **não existem no jogo** (sem sistemas falsos).

## 5. Kit de produção

`tools/produzir_ui_9f.py` → `assets/ui/producao_9f/` (19 peças, ampliadas 2×
LANCZOS; `--validar` 19/19 PASS; manifesto com a caixa exata na prancha,
método, zonas de inpaint e SHA de cada peça):

- **A — recorte direto:** `moldura_painel`, `moldura_ornamentada`, 4 ícones de
  habilidade em ladrilho (dash, salto duplo, escudo, ataque especial).
- **B — reconstrução técnica:** botões normal/selecionado/desativado,
  `caixa_dialogo`, `toast_info`, `toast_habilidade` (texto pintado removido por
  interpolação linear por linha entre as colunas fora dele); glifos
  `ico_coracao`, `ico_cristal`, `ico_checkpoint` (fundo liso retirado por
  flood-fill a partir das bordas).
- **C — derivação:** `barra_{vida,energia}_calha` (as colunas vazias da
  própria barra repetidas por cima do enchimento pintado) e
  `barra_{vida,energia}_enchimento` (fatia do enchimento).
- **Descartado:** as linhas de região do mapa-mundo (§6 da prancha) — a arte
  do mapa atrás delas não é fundo liso; o estado "região aberta" usa o botão.

Nenhum texto fica nas imagens; todos os rótulos são `Textos.t`. Tipografia: a
fonte do projeto (não há outra livre no repo). `scripts/ui_producao.gd` monta o
tema e as peças (barras em 3 pedaços com escala uniforme — a nine-patch
esmagava a gema numa barra de 26 px).

## 6. Prova de áudio no browser real (Chrome, Windows) — build `00399d0`

`http://localhost:8075/?audio-debug=1` (servidor do export limpo):

| Momento | AudioContext | Pico no destino |
|---|---|---|
| Carregado, sem gesto | `suspended`, t=0 | 0 (política de autoplay normal) |
| Após 1 clique no canvas | `running` | 0,077–0,252 (música do menu) |
| Música a 0 nas Opções | `running` | **0** (50 amostras; o mute do bus Music é respeitado) |
| SFX de UI `apanhar` (cursor dos Efeitos), música a 0 | `running` | 0 → **0,296** entre 5141–5660 ms (≈ duração do sample) |
| SFX de UI `carrossel` (→ no seletor) | `running` | buffer 0,446 s arrancou, pico 0,29 |
| Música de jogo (L1, Música reposta a 100 %) | `running` | **0,038–0,113**, 50/50 amostras em 5 s (faixa `nivel_01.ogg`, buffer 60,47 s) |
| SFX de jogo (L1, música a 0): `salto` 0,126 s, golpe 0,377 s, 0,223 s | `running` | 0 → **0,28–0,33** (20 amostras com som) |

Consola: só `RUNTIME TRACE | build=0.16.0`; sem avisos de autoplay,
AudioContext, descodificação, CSP ou service worker.

## 7. Matriz de áudio

- MENU MUSIC: **PASS**
- GAMEPLAY MUSIC: **PASS**

Nota honesta: logo a seguir a retomar a pausa houve uma leitura a 0 (a pausa
suspende os players; ao retomar o motor recria a fonte com `_restart`). Em
seguida, 50/50 amostras com som. Preferências repostas no fim do teste
(Música 100 %, Efeitos ≈0,45, English).
- UI SFX: **PASS**
- GAMEPLAY SFX: **PASS**

## 8. Builds (mesmo commit `00399d0`, worktree limpo `.worktrees/export-9f`)

- Windows: `Koliani.exe` 166,0 MB, SHA `0143624f8941ef0b16f2c02567b7f3becacd06c501ae0c87ec4b3c84b6f86e5d`.
- Web: `index.pck` 56,8 MB, SHA `52349f3a6a5a046bef1c3aabeb25a165349a909b626c16c8e6c9f17063606af6`;
  **SHA medido no browser = export**; service worker `activated`, cache
  `Koliani-sw-cache-1789150815|5733576` (a única).
- Prova no EXE (`--nivel=5 --foto-estado=ui9f`, userdata com cópia e reposição
  verificada por `diff`): 6 fotos — HUD, toast de checkpoint, toast de
  habilidade, HUD do chefe (Coração Putrefacto), diálogo, pausa. Registo JSON:
  7–13 texturas do kit por foto; **única textura legada visível:
  `ico_caveira.png`** (16 px, cabeçalho e placa do chefe).

## 9. Testes

- Suite headless **OK — todos os testes passaram**.
- Novos: `teste_9f_buses_de_audio_estaticos`, `teste_9f_ui_producao` (kit =
  manifesto por SHA, tema, seletor 20×5 com desbloqueio intacto, pausa/opções
  sem estilo legado, HUD com a calha do kit) — ambos **provados a morder**.
- i18n: `hud.checkpoint` nos 6 idiomas; teste de chaves iguais passa.

## 10. Desempenho

UI sem blur, sem shaders de ecrã inteiro, sem sobreposições gigantes: só
`StyleBoxTexture`/`TextureRect` estáticos. O áudio não ganhou polling por frame
nem recriação de AudioContext (o layout de buses é estático; o medidor de pico
só existe em `?audio-debug=1`). Não houve medição A/B de frame-time: o
`requestAnimationFrame` pára com o pane de browser escondido e a rota de
foto do EXE não mede tempos. Por construção (poucos nós estáticos, texturas
de 2–60 KB, nenhum redesenho por frame), regressão: **NÃO esperada / não
medida**.

## 11. Armadilhas e hipóteses descartadas

- **Descartado:** autoplay/gesto como causa do silêncio total (contexto
  `running` e pico 0 ao mesmo tempo); ficheiros de áudio fora do PCK;
  formatos incompatíveis (nada foi transcodificado).
- O pane de browser interno do Claude permite autoplay: o contexto nasce
  `running` lá. A prova do gesto tem de ser num Chrome real.
- Com o pane escondido o `requestAnimationFrame` pára — medir frame-time lá dá
  timeout.
- `AudioBufferSourceNode.prototype.start` é próprio (não o de
  `AudioScheduledSourceNode`): um hook no pai não apanha as fontes do Godot.
- A fonte do Web não tem emoji: 🔒/✦ saíam em tofu (tirados do seletor; o ✦ do
  "Santuário" é do i18n e ficou — backlog).
- **Chinês em tofu no Web** (botão 中文): a fonte exportada não tem CJK. É
  anterior à 9F; precisa de uma fonte CJK livre (decisão de asset).
- Python no Windows escreve CRLF (`open(..., 'w')`); o Git normaliza para LF.
