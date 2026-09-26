# N4 -- A Arvore que Chora (nivel AUTORAL, CHALLENGE: o Especial com custo de Energia)

Estado: **PRONTO PARA PLAYTEST DO GM -- NAO LOCKED** (26 set 2026, sem push). Cena `scenes/levels/A_Arvore_que_Chora.tscn`
(gerada uma vez por script; agora edita-se a cena). Padrao N1-N3: `corredor = false`, `checkpoints_autorais`,
`estreia_x_autoral = 1500`, `mecanica_anunciada = "especial"` (chaves `mec.especial.*`, `hud.ability.especial` nos 6 idiomas).
Guardiao (Entrevane) e Porta inalterados. Nome legacy mantido. Fora do N4: Raiz Elevatoria, camara da seiva (alavanca+grades)
e gotas de acido (mecanicas nao ensinadas) -- `tools/verifica_raiz_elevatoria.gd` e `verifica_camara_seiva.gd` ficaram sem alvo (nao estao no CI).

## Energia / Especial: antes e depois (localizado em `koliani.gd`)
ANTES: barra de Energia (99, +12/s) so' visivel com a habilidade `projetil`; **nada gastava Energia** (o tiro e' ilimitado, 1/3 do dano)
-- a barra era decorativa (auditoria: "UI que mente"). Nao havia Especial no motor (o Kamehameha das notas antigas ja' nao existe).
DEPOIS: nova habilidade `especial` (`HABILIDADES_TODAS`), accao `especial` (**Q** / ombro direito do comando / botao tactil novo,
icone do projetil). Onda espectral (`ProjetilKoliani` com `perfura`, escala 1,8x) que **atravessa** todos os inimigos, dano
`_dano_golpe * 2,6` (130 com a espada base), cooldown 0,45 s.
- **Custo 33** (1/3 da barra = 3 usos). Sem Energia suficiente: nao dispara, Energia nunca negativa, a barra pisca.
- **Recuperacao**: passiva +12/s (melhoria "foco" escala) depois de 0,6 s de pausa (1.o uso outra vez em ~3,4 s medidos);
  **+5 por golpe de espada** que acerta e **+8 por acerto de pogo**. Nunca ha' softlock: nada exige o Especial.
- HUD: marcas a 1/3 e 2/3 na barra (cada segmento = um uso); barra visivel tambem com `especial`.

## Mapa (x do mundo; chao y 665; 8 000 px)
| # | Seccao | x | Papel |
|---|---|---|---|
| 1 | Abertura | 0-1230 | tufo (pogo) + gate de Dash com poco de retry: recordar sem exigir precisao |
| 2 | Altar do Especial | 1500 | `Coletavel` `especial` no caminho; placa quando entra em ecra |
| 3 | Teste seguro | 2150 | 1 gosma (vida 100) isolada, sem pressao, Energia cheia; `CheckTeste` 2400 depois do descanso |
| 4 | Recuperacao | 2450-2900 | zona vazia: a barra volta a encher a olhos vistos; nada a fazer senao ver |
| 5 | Dash + combate | 2900-3750 | elite goblin de CARGA (140) + 1 goblin: reposicionar com Dash |
| 6 | Pogo + combate | 3788-4376 | cama 224 - ilha com gosma (70) - cama 224; matar a gosma, ressaltar nela ou nos espinhos; `CheckMeio` 4500 |
| 7 | Dash + Pogo + hazard | 4700-5426 | gate, cama 272, ilha com raiz, gate; `CheckEnergia` 5480 |
| 8 | Gestao de Energia | 5426-6862 | 2 goblins alinhados (1 Especial mata os dois) + elite gosma saltadora (170: 2 Especiais); 3 cargas = tudo: se gastar ja' nas goblins e disparar as 3 antes do elite, fica so' com espada (4 golpes) |
| 9 | Desafio final | 6380-6992 | `CheckFinal` 6380; cama 272, ilha com gosma, gate de Dash |
| 10 | Fecho | 6992-8000 | cache 32, Guardiao, Porta |
5 checkpoints (300, 2400, 4500, 5480, 6380); o maior troco e' 2 100 px so' no inicio (so' movimento). 4 gates de Dash, todos pos-N2.
Inimigos: so' goblin e gosma (aprovados), 7 no total (nao compensei a falta de F3 com mais goblins).

## Medido (`teste_n4_autoral`)
Gasto 33/33/33 e Energia 0 (nunca < 0), 4.o disparo recusado; sem a habilidade nada muda; regen -> 33 em 202 frames;
golpe +5; onda atravessa e fere 2 goblins alinhados; geometria = 4 gates, vaos comuns no salto simples. Suite completa PASS, save real
intacto; N1/N2/N3 e pogo sem regressao; `verifica_alcance_todos` (0 portas inalcancaveis), `verifica_mecanicas`, `verifica_jornada` OK.
Capturas: `docs/qa/n4_autoral/`. Duracao **estimada** 4-5 min (nao medida com humano).

## Falta / por validar
Arte propria do Especial (usa o laser roxo do tiro, escalado; pose `lancar`) e icone do botao (reusa o do tiro); posicao do botao
tactil novo (dx -330, dy -226) por testar num telemovel; sem QA de mobile do Especial; balanceamento (custo 33, +5/+8, dano 2,6x) a olho;
elite gosma saltadora e arte legacy; se F3 (inimigos novos) entrar, o encontro 8 pede reavaliacao.
