# Execução — Skins da Koliani: conjuntos de armadura + arma (29 set 2026)

Pedidos do Paulo, pela ordem:
1. "novos assets para skins da Koliani";
2. "skins a sério, não trocas de cor ou de brilho";
3. "novos assets de armaduras e armas que possam ser aplicados ao modelo da
   Koliani, usando o Golden Model dela";
4. "pode ter algumas com palete trocada" / "esses exemplos eu gostei" /
   "mas simples ficam só essas, depois quero mais elaborado" -- as 3 de
   paleta do 1.º passe VOLTAM com os ids e nomes originais (Brasa da
   Fornalha, Abadia Afogada, Planícies Celestiais) e são as únicas simples;
   os conjuntos ganham ids próprios.

## Como estava
- Skins da Loja = só tinta (`CosmeticosVisuais.TINTA_SKIN`), placeholder.
- O corpo em todos os 100 níveis é o Golden Set (84 PNG 128×128, pés y=104,
  `koliani.gd::_montar_golden_set`). A arte não é indexada (~1200 cores/frame).
- A lâmina da Koliani está pintada DENTRO dos frames, magenta, e só aparece
  nos golpes (25 frames: `attack_*`, `defesa`).
- **Descartado**: usar os rigs antigos (`koliani_nova`, `shadowblade`,
  `cavaleiro`) como skins -- têm 64-72 px de célula, outro estilo, ficam
  pequenos ao lado do Golden Set.
- **1.ª tentativa (commit `85ef70e`)**: só troca de paleta. Não chegava
  como skin elaborada, mas o Paulo gostou e ficaram como as 3 simples.

## O que foi feito
Uma skin = Golden Set + paleta + CONJUNTO de peças desenhadas:

| Skin | Cabeça | Ombro | Costas | Arma |
|---|---|---|---|---|
| Guardiã da Forja (`skin_guardia_forja`) | cornos com fendas de brasa | ferro com espigão | -- | montante de brasa |
| Abadessa Afogada (`skin_abadessa_afogada`) | capuz fundo, orla verde-água | -- | -- | tridente |
| Serafim Celestial (`skin_serafim_celestial`) | auréola | ouro em asa | asas de penas (batem) | espada solar |
| Arauta do Vazio (`skin_vazio`, Região XIX) | coroa de espinhos | -- | capa rasgada (esvoaça) | foice |

Só paleta (sem peças, silhueta do Golden Set), aprovadas pelo Paulo e as
únicas simples: `skin_fornalha` (Brasa da Fornalha), `skin_abadia_afogada`
(Abadia Afogada), `skin_celestial` (Planícies Celestiais) -- frames iguais
byte a byte aos do 1.º passe (`85ef70e`). O teste exige que
sejam a minoria (`CosmeticosVisuais.SKIN_SO_PALETA`).

- `tools/trajes_koliani.py` -- as peças (grelhas de texto e desenho
  procedural) e as âncoras por frame:
  - **cara**: média da pele nas 8 linhas abaixo da pele mais alta (validado
    à vista nos 84 frames);
  - **ombro**: pele do braço logo abaixo da cara, o ponto mais para trás;
  - **lâmina**: maior aglomerado magenta (vizinhança de 2 px; brilhos soltos
    no cabelo desviavam a reta), PCA -> reta; o punho é a ponta mais perto do
    corpo. Apaga-se (+ halo rosa) e desenha-se a arma nova na mesma reta,
    maior ou igual, para tapar o que se apagou.
- **Rolamento**: `roll_003/004/005` são o `jump_loop_003` rodado 270/180/90°
  (confirmado pixel a pixel). Veste-se o original e roda-se o resultado,
  alinhado pelo corpo -- cornos, asas e arma rodam com ela.
- `tools/gerar_skins_koliani.py` -- compõe as 3 skins (84 frames cada),
  `preview.png` (um golpe, para mostrar a arma) e `pecas/` (as peças soltas).
- Runtime sem mudanças desde o 1.º passe: `CosmeticosVisuais.DIR_SKIN` ->
  `koliani.gd::_caminho_skin`. Hitbox/colisão intactas.
- i18n: nomes/descrições novos nos 6 idiomas.
- Teste `teste_skins_arte_real`: 84/84 frames, a silhueta CRESCE (>40 px
  novos no idle) sem perder corpo (<10 px), sem magenta onde estava a lâmina (a paleta do Vazio é magenta, por isso só se olham esses pixéis); as só-paleta têm a silhueta exatamente igual, a
  Koliani equipada lê os frames da skin, sem skin volta ao Golden Set.
- Provador: `res://tools/ProvadorSkins.tscn`.

## Testes
- Suite completa (Linux headless, Godot 4.7.2, sandbox `user://` limpo):
  **0 falhas**.
- **Armadilha de método**: com um sandbox REUTILIZADO entre corridas, o
  `teste_golem_piloto_ttk` falhou 3/3 (TTK do cleave 2,8-9,3 s em vez de
  0,93 s). A causa é o `progresso.json` que a própria suite deixa no
  `user://`: com sandbox limpo passa sempre, e o commit anterior às skins
  passa igual. Correr sempre com sandbox novo (`tools/correr_testes.ps1` já
  o faz).

## Limites conhecidos
- A arma só se vê nos golpes -- é assim no Golden Set (fora dos golpes não
  há lâmina desenhada).
- Algumas pontas de arma tocam a borda do canvas (x=127), como já acontecia
  com a lâmina original; no rolamento os cornos/asas passam por baixo dos pés
  durante 1 frame.
- O VFX do golpe (arco magenta) não muda.
- As peças de corpo são só ombreiras: pernas e tronco continuam o fato do
  Golden Set com a paleta da skin.

## Decisões para o Paulo
- Aprovar o visual. Preços/raridades provisórios.
- Ligar estas peças ao `Equipamento` (armas/armaduras de gameplay, hoje
  invisíveis no Golden Set)? A biblioteca de peças serve para isso.
