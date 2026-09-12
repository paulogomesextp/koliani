# Execution 9H.QA — revisão visual e de game feel

Base: `948109bc`. **Revisão apenas. Zero alterações a código, cenas, arte ou
gameplay.** Capturas em `work/qa/` (pasta ignorada pelo git).

## Método — e os seus limites

**Isto foi avaliado por CAPTURAS E LEITURA DE CÓDIGO, não por jogar.**
Não houve sessão de input real: não premi botões, não lutei com a Morvanna,
não atravessei um nível de ponta a ponta. Tudo o que depende de *sentir* —
peso do salto, hitstop, timing de combo, resposta do toque — está marcado
**NOT ASSESSABLE** e não deve ser lido como aprovado.

- **Capturado agora:** seletor de níveis, folha do rig da Koliani (13 estados),
  L2 e L4 em runtime.
- **Capturado nesta máquina na sessão 9H.11 (mesmo código):** Pausa, Santuário,
  HUD com barra de chefe, L1, L3, L5.
- **Reutilizado:** `work/integration_9h10_9h11/exe_menu.png` (menu do EXE v0.18.2).
- **Não testado:** Web/PWA, intro em vídeo, SFX, música, qualquer input.

---

## 1. OVERALL SCORE — **6,0 / 10**

Um frontend de qualidade comercial colado a um jogo que parece outro produto.

## 2. VISUAL SCORE — **6,0 / 10**

Menu principal **9/10**. Seletor **5/10**. Gameplay da Região I **5/10**.
A média esconde o problema real, que é a **distância entre os três**.

## 3. GAME FEEL SCORE — **NOT ASSESSABLE**

Não joguei. O que se pode dizer por leitura de código: a estrutura existe
(hitstop, i-frames de rolamento, críticos por costas e pós-rolamento,
telégrafos e janela de castigo nos chefes). Se isso *sente* bem, não sei.
**Não dar por validado.**

## 4. COMMERCIAL READINESS — **4,5 / 10**

O menu vende o jogo. A primeira captura de gameplay desvende-o. Hoje, uma
página de loja com estas duas imagens lado a lado prejudica mais do que ajuda.

---

## 5. TOP 10 PROBLEMS

| # | problema | estado | impacto |
|---|---|---|---|
| 1 | **Três identidades visuais no mesmo jogo.** Menu = ilustração pintada, carmesim sobre carvão, heroína de key-art. Seletor = crómio verde-esmeralda sobre panorama azul-magenta. Gameplay = mosaico pixel azul-magenta. Nada disto parece o mesmo produto. | **PROVEN** (3 capturas) | crítico / comercial |
| 2 | **A faixa verde-oliva chapada no fundo do ecrã.** Massa lisa, sem textura, com um recorte ondulado duro. No L4 ocupa **um terço do ecrã**. Aparece em L1, L2, L3, L4 e L5. Lê-se como placeholder. | **PROVEN** (5 níveis) | crítico / visual |
| 3 | **L1 e L2 são visualmente o mesmo nível.** Mesmo panorama (mesma Heart Tree, mesma estrela), mesmo tileset, mesmo verde de musgo. Só muda a densidade de props. | **PROVEN** (capturas na mesma posição de câmara) | alto |
| 4 | **O seletor é verde e o menu é carmesim.** Anéis, placas, linha do percurso, abas e o botão JOGAR: tudo esmeralda. Contradiz a direcção aprovada na 9H.10/9H.11. *Ressalva: capturado com `tudo_desbloqueado=1`, ou seja com todos os níveis no estado "concluído", o que inflaciona o verde. Confirmar com save fresco.* | **LIKELY** | alto / coerência |
| 5 | **Desfoque do fundo.** Fonte de 952×247 ampliada 4,2× = 0,24 px de fonte por px de ecrã. Causa já medida e documentada na 9H.12B. | **PROVEN** (medido) | alto |
| 6 | **O chão é um carimbo de 30×75 repetido ~35× por plataforma, sem variantes.** O passe de valor da 9H.11 atenuou, não resolveu. | **PROVEN** (medido) | alto |
| 7 | **Promessa vs entrega da personagem.** O menu mostra uma heroína ilustrada em grande plano; em jogo é um sprite de ~50 px. É a distância mais cara de fechar e a que mais desilude. | **PROVEN** | alto / comercial |
| 8 | **Painel do seletor duplica informação.** A coluna direita repete "Guardião Ghorak / Região I 1/5 / Estado Concluído" que já está à esquerda. | **PROVEN** | médio / UX |
| 9 | **Morvanna: a janela de dano é a única.** Voa a 210 px e só fica ao alcance durante `dur_exposta = 2,1 s`; telégrafos de 0,62–0,72 s. Se o jogador falhar a janela, o combate arrasta sem nada acontecer. Risco de leitura de "unfair" por *tédio*, não por dificuldade. | **LIKELY** (lido no código, não jogado) | médio |
| 10 | **Contraste da Koliani sobre a corrupção.** A personagem é escura com vermelho; os fundos do L1/L5 são magenta saturado. Nas capturas ainda se lê, mas a margem é pequena e no L5 (cristal em toda a parte) encolhe. | **LIKELY** | médio |

**Bugs já confirmados na 9H.12B e ainda por corrigir:** a legenda do HUD promete
"Jump ×2" com `HABILIDADES_INICIAIS` vazio; o crash na saída do L1 está na
transição (`porta.gd:69`) — o L2 carrega limpo em headless.

---

## 6. TOP 10 WINS

1. **O menu principal é material de loja.** Composição, tipografia, paleta e
   ornamento ao nível do que se vende. **Não tocar.**
2. **A Pausa e o Santuário passaram a falar a língua do menu** (9H.11) — carvão,
   carmesim, ornamento controlado, sem o verniz azul/dourado de template.
3. **A barra do chefe deixou de se confundir com a vida do jogador** — lâmina
   carmesim contra a calha com gema. Leitura de combate resolvida.
4. **O rig da Koliani está são:** 13 estados, todos distintos, pés na mesma
   linha, todos virados para o mesmo lado. Sem dobras nem inversões.
5. **Os quatro ataques têm poses diferentes** — a base de um combo legível existe.
6. **O L5 já não é "o L1 com outro céu"** (9H.11): cristal a dominar, zero
   lanternas quentes, rocha tingida de violeta.
7. **A estrutura dos chefes é sólida:** telégrafo → golpe → janela de castigo,
   fases a 50 %, presos à arena.
8. **O carrossel do seletor é bom desenho de UX** — caminho, fichas 1-1…1-5,
   miniatura, retrato do guardião, abas de região. É só a cor que está errada.
9. **A infra para o remaster já existe:** `Kit.topo(rng)` sorteia variantes,
   `_source/imagegen_v1/` tem as fontes em 1254–2172 px.
10. **Nenhum erro de script** nos smoke-tests de cena feitos nesta revisão.

---

## 7. P0 FIX NOW

1. **Matar a faixa verde-oliva chapada.** É o defeito mais barato de corrigir
   com maior retorno visual. (#2)
2. **Corrigir o crash na saída do L1.** Um crash na primeira transição do jogo
   é o pior bug possível para um playtester.
3. **Alinhar o tutorial do salto duplo com a realidade.** Prometer um botão que
   não funciona destrói confiança no minuto um.
4. **Pôr o seletor em carmesim** (ou confirmar que o verde é só do estado
   "concluído" e corrigir a distribuição de cor). (#4)

## 8. P1 NEXT

5. Tiles grandes com variantes — o plano 9H.12D.
6. Fundo nativo por camadas — o plano 9H.12E.
7. Diferenciar L1 de L2 (panorama ou landmark próprio, não só densidade).
8. Tirar a duplicação de informação do painel do seletor.
9. Playtest real da Morvanna com cronómetro na janela exposta.
10. Subir a presença da Koliani em ecrã (escala ou contorno) e medir o
    contraste contra o L5.

## 9. DO NOT TOUCH

- **Menu principal** — aprovado e congelado.
- **Pausa, Santuário, barra de chefe** — acabados de unificar na 9H.11.
- **Rig e estados da Koliani** — o alinhamento está são; mexer arrisca partir.
- **Chefes e mobs** — o Game Master diz que estão bons; a leitura de código
  confirma estrutura sã.
- **Colisões, geometria, checkpoints, progressão** — fora de qualquer passe
  de arte.
- **UI kit da 9H.10/9H.11** — não é o gargalo; não gastar lá.

## 10. READY TO CLOSE REGION I: **NO**

Três razões, todas provadas: a faixa verde chapada aparece nos cinco níveis;
L1 e L2 são o mesmo quadro; e o fundo não tem resolução para 720p. Nenhuma
delas se resolve com afinação — precisam dos passes 9H.12C/D/E já planeados.

O que **está** pronto a fechar: o frontend (menu, pausa, santuário) e a
leitura de combate na HUD.
