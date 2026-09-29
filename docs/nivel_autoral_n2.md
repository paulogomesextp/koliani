# N2 -- Pantano dos Sussurros (nivel AUTORAL, DEVELOP: o Dash)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (26 set 2026, sem push). Cena: `scenes/levels/Pantano_dos_Sussurros.tscn`.
Mesmo padrao do N1 (`docs/nivel_autoral_n1.md`): `corredor = false`, `alongar_plataformas = false`, `candeeiros = false`,
`checkpoints_autorais = true`, `estreia_x_autoral = 1640` (a placa "Dash" aparece quando o altar entra em ecra),
`mecanica_anunciada = "dash"` (chaves novas `mec.dash.nome/txt` e `hud.ability.dash` nos 6 idiomas).

## O que o Dash e' (medido na fisica F1, `tools/bench_movimento_f1.gd dash_teto`)
Dash de CHAO (o aereo e' outra habilidade, `dash_aereo`, que o N2 NAO da'): 10 ticks a 620 px/s, `velocity.y = 0`
(paira), invulneravel, recarga 0,55 s. **Envolvente medida**: vao maximo sob teto baixo: so' saltar 100 px (teto 64),
110 (teto 80), 130 (teto 100); com dash **160 px** em qualquer teto; sem teto o salto simples faz 230.
Por isso o Dash e' EXIGIDO onde o salto nao chega e o dash sim: **vao de 130 px sob teto de 64 px de folga**
(margem ~30 px para cada lado). Fora disso o dash e' so' esquiva/atalho.

## Mapa (x do mundo; topo do chao = y 665)
| # | Seccao | x | Papel |
|---|---|---|---|
| 1 | Entrada | 0-1270 | chao seguro + 2 degraus (continuidade do N1); fogueira 420 |
| 2 | Altar do Dash | 1370-2150 | o `Coletavel` `dash` esta NO caminho (impossivel falhar); fogueira `CheckAltar` (2000) so' depois |
| 3 | **Gate 1 (aprender)** | 2150-2280 | vao 130 sob `TetoGate1`; POCO DE RETRY por baixo (chao a 830 + 2 degraus do lado de ca); o outro lado nao se escala -> cair nao mata, nao se contorna |
| 4 | Dash e raizes | 2280-2920 | 3 `RaizPerigo` desfasadas (2500/2690/2880): salta-se, espera-se ou atravessa-se de dash (invulneravel) |
| 5 | Combate + segredo | 3030-3760 | goblin elite de CARGA (`comportamento = "carga"`, esquiva com dash/salto); segredo: 3 degraus de 60 px + vao 130 sob teto ate' a cache (3735,452), a 180 px do chao (inalcancavel so' a saltar) |
| 6 | **Gate 2 (exigido)** | 3880-4860 | 2 vaos de 130 px sob teto sobre AGUA MORTAL; raiz na plataforma de entrada (ha' 150 px livres para a saltar) |
| 7 | Descanso + Morvanna | 4980-6020 | fogueira `CheckDescanso` (5090); guardiao Morvanna inalterada (arena 660 px); Porta |
Agua do N2 desceu (`y` 950 -> 1070) para caber o poco de retry. 3 checkpoints autorais.

## Regras cumpridas
Sem Pogo, Especial/Energia, wall-jump, salto duplo, dash aereo; sem Serra/Fogo/Pendulo/Portal/Trampolim/Elevador/Ritmadas
(teste). Vaos comuns <= 125 px (plano) / <= 110 px (a subir); subidas <= 64 px.

## Validacao
`teste_n2_autoral`: geometria (todo o vao > 125 px so' existe com teto baixo a cobri-lo, >= 3 gates), coletaveis == [dash], sem
mecanicas futuras, altar no caminho, **piloto: so' a saltar o gate 1 NAO se passa (4 tentativas); com dash passa**.
Suite completa PASS; 8 verificadores CI exit 0; bot com habilidades vazias chega a porta em 55 s (modo dev, sem combate; pare
16 s no gate 2 porque o bot nao sabe fazer dash). Capturas: `docs/qa/n2_autoral/` (7). Save real intacto.

## Por validar por humano
Legibilidade do gate 1 (poco + degraus), ensino sem texto alem da placa, dificuldade do gate 2 sobre agua, densidade das raizes,
goblin de carga (esquiva), utilidade do segredo, Morvanna neste contexto, ritmo/duracao, continuidade visual com o N1.
Ha' um quadrado escuro na zona do poco nas capturas (a confirmar: degrau/sombra do kit).
Arte em falta: como no N1 (RaizPerigo por poligonos, goblin legado); teto de cave usa a `Plataforma` do kit (laje com relva por cima).
