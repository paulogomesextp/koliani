# Execution R3D — Koliani 3D, Região I (N01–N05) — vertical slice jogável

Data: 9 outubro 2026 (sessão autónoma noturna). Branch `claude/koliani-3d-region01`
(worktree `C:\Projetos\koliani-3d`), base `origin/master` 7e3f5d11.

## O que é

O **gameplay** da Região I (N01–N05) passa a ser 3D. Todo o resto do jogo fica
exatamente como estava (decisão LOCKED do Paulo nesta sessão): Menu principal,
Seletor de níveis/carrossel de regiões, submenu, HUD, Pausa, Opções, save,
transições, áudio aprovado, i18n. Loja fora do âmbito (intocada).

Fluxo real (provado por teste automático no EXE e no editor):
`MenuInicial → SELECT LEVEL → Região I → N01 → Main.tscn → nível 3D`.
O `main.gd` só ganhou um desvio: `Nivel3D.caminho_para(indice, caminho_2d)`
devolve a cena 3D para os índices 0–4; N06+ continuam 2D. `-- --2d` ou o
setting `koliani/r3d/regiao1_3d=false` repõem o 2D.

## Arquitetura (tudo em `scripts/r3d/`, `scenes/r3d/`, `assets/r3d/`)

| Ficheiro | Papel |
|---|---|
| `kit3d.gd` | Fábrica de malhas (tubos com transporte paralelo, tornos, lajes de contorno, rochas facetadas, fetos/erva, cones de luz) e materiais (paleta LOCKED da Região I). Auto-verifica a orientação das faces. |
| `assets/r3d/shaders/*` | `estilo` (triplanar + musgo + luz em degraus + rim + veios de corrupção), `gradiente` (cabelo/tecido), `folhagem` (forma no UV + vento), `veneno`, `ceu`, `raio_luz`, `aditivo`. |
| `deco3d.gd` | Kit da Região I: árvores antigas c/ contrafortes, árvore-mãe, troncos caídos, pilares/arcos/menires sagrados, corrupção, cogumelos, cristais, torre afundada, teias/casulos, salgueiro chorão, folhagem MultiMesh, floresta de fundo (afastada da rota). |
| `ambiente3d.gd` | Céu/lua/nevoeiro/glow/grading — 5 perfis (um por nível). |
| `koliani_modelo3d.gd` | Modelo 3D da Koliani (Golden Set): ~120 peças, rig por juntas, animação procedural (idle, run, jump, fall, landing, 4 golpes distintos, hurt, death, dash) + mola no cabelo/cachecol/saia. |
| `koliani3d.gd` | Controlador (CharacterBody3D). Feel traduzido do 2D (não os números em px): corrida 6,6 m/s, salto ~2 m, ápice ~0,40 s, queda ×1,22, ápice suave, coyote 0,10, buffer 0,12, corte 0,45; combo 4 golpes (×0,85/1/1,25/1,9, janela 0,42 s), i-frames 0,6 s, vida 100. Contrato da HUD (grupo `koliani`, `vida_mudou`, `energia_mudou`, `morreu`, retrato do Golden Set). `salto_duplo`/`dash` só se a habilidade estiver desbloqueada (cânone). |
| `camara_r3d.gd` | 3.ª pessoa orientada pela rota desenhada do nível (3/4), vertical preguiçosa, *sphere-cast* contra terreno e troncos, órbita manual (RMB/analógico dir.) que regressa, modo chefe. |
| `inimigo3d.gd` | goblin corrompido, gosma, bruto (elite). Patrulha → deteta → persegue → ataque com aviso → recupera; não cai das plataformas; vozes `mob_<família>_*` aprovadas. |
| `pecas3d.gd` | Fogueira (checkpoint), portal de saída, espinhos de corrupção, raiz que irrompe, plataforma móvel. |
| `chefe_coracao3d.gd` | O Coração Putrefacto 3D — ciclo canónico do 2D (ver abaixo). |
| `nivel3d.gd` + `niveis/n0X_3d.gd` | Base + API de construção; conclusão = exatamente a `Porta` 2D. Funde malhas estáticas por material/célula (draw calls). |
| `qa_bot_r3d.gd` | Bot de QA (rota, saltos, combate, modo-chefe), FPS, capturas; e prova do front-end real (`--qa-r3d-ui`). |
| `tests/r3d/` | Suite 3D (79 asserções). |

## Níveis

| Nível | Papel | Landmark | Conteúdo |
|---|---|---|---|
| N01 Floresta Putrefata | ensinar | Árvore-Mãe corrompida (34 m) + raiz-ponte | arco de entrada, trilho, 1.º salto sobre o pântano, tronco caído, fogueira, ruínas a subir, raiz que irrompe, guardião (bruto) antes do portal |
| N02 Pântano dos Sussurros | desenvolver | Torre sagrada afundada (26 m, luz esmeralda) | pedras sagradas sobre veneno, espinhos, ponte de raiz a subir, degraus de ruína, platô com raízes alternadas, rampa |
| N03 Ninho da Viúva Negra | combinar | Teia gigante com casulo-coração | porta de teias, arena de emboscada (4), abismo (tronco→lajes→ponte), trilho estreito com raízes e espinhos |
| N04 A Árvore que Chora | desafio | Salgueiro chorão gigante | subida em espiral, bruto no patamar, tronco suspenso, raízes duplas, varanda com o **Coração ao longe** (prenúncio) |
| N05 Coração da Floresta | chefe | A arena no oco das raízes da árvore-mãe | aproximação corrompida, fogueira pré-chefe, arena selada por espinhos, chefe, cartão de região, portal |

## Chefe N05 — O Coração Putrefacto (fiel ao `chefe_coracao_putrefacto.gd`)

PROTEGIDO → MECÂNICA (sempre com aviso) → EXPOSTO → RECOVER.
RAÍZES (marcas 1,5 s → irrompem), PULSO (incha → onda em anel, salta-se),
BROTOS (rebentá-los abre o núcleo já e alonga 50 %; ignorados, abre mais tarde/curto).
Casca: 5 % do dano. Fase 2 (<50 %): combos (raízes+pulso, pulso duplo, raízes+brotos),
avisos −15 %, janela −20 %, 2.ª zona de raízes, rugido. Vida 1500.
Vitória = o 2D: `marcar_chefe_derrotado_por_nivel`, concede `salto_duplo`,
cartão `region.1.complete`, portal abre depois do cartão; música de chefe/ambiente
pela `Musica` aprovada; `chefe_cai` + `conquista`.

## Áudio (sem redesenho)

Só `Som.toca`/`Musica` existentes com as mesmas chaves e volumes do 2D
(passos, salto, aterragens por tier, ataque×4, acerto/crítico, dano/dano_pesado,
morte, respawn, vozes mob_*, raiz_aviso/irrompe, selo, portal, transicao,
chefe_entrada/cai, conquista, bloqueio). Sem AudioStreamPlayer3D novos: o `Som`
aprovado é 2D/não posicional e mudá-lo seria redesenho da mistura.

## Verificação (medida)

- Suite 3D `tests/r3d/TestesR3D.tscn`: **79/79** (jogador, 5 níveis carregam/entrada/saída/
  inimigos/**gate anti-greybox automático**/arte, progressão N01→N06, save, chefe).
- Bot isolado, fluxo real, **cadeia N01→N05 sem invencibilidade, 0 mortes**,
  chefe derrotado; ~59 FPS médios (vsync), mín. 51 (RTX 5070, Vulkan Mobile, 1280×720).
- **EXE exportado**: a mesma cadeia passa dentro do build (`--qa-r3d`).
- Front-end real (`--qa-r3d-ui`): Menu → SELECT LEVEL → Região I → N01 → 3D.
- Save real intacto (SHA256, `godot_isolado.py`) em todas as execuções.

## Armadilhas encontradas (custaram tempo)

- `main.gd` trata qualquer argumento `--foto*` como "tirar foto e sair" — o QA usa `--capturas=`.
- Builds release não aceitam caminho de cena na linha de comando (`disable_path_overrides`):
  o bot instala-se pelo `Nivel3D` com `--qa-r3d` e `-- --nivel=N`.
- Rampas: a ponta alta prolongada fazia um degrau onde a cápsula encalhava → patamar plano.
- Lajes de terreno: a orientação do triangulado depende do contorno → auto-verificação da normal.
- O anel de floresta de fundo à volta do centro cortava níveis compridos → filtro pela rota.
- `set_physics_process(false)` antes de entrar na árvore é ignorado (o Godot volta a ligar).

## Por fazer / limites reais

- Playtest humano (feel do salto 3D, câmara, dificuldade). Os números são tradução do feel 2D, não afinados por mão humana.
- Modelos são composição procedural estilizada (sem esqueleto skinned): lê-se como a Koliani, mas não é um modelo esculpido.
- Mini-chefes 2D da região (Morvanna N02, Entrevane N04) não foram portados; o bruto faz de elite.
- Setas do teclado: ↑ é saltar (binding aprovado) e ↓ não tem ação → em 3D usar **WASD + Espaço + J** (ou comando).
- Mobile/Web não testados (plataforma ativa = Windows).
