# Koliani -- bíblia de história

> Documento vivo. O agente `gaming` atualiza-o à medida que os mundos e as
> pistas são desenhados. É a fonte de verdade para o tom e a narrativa.

## Premissa

**Koliani** é uma menina de **10 anos**. A mãe foi levada por **Zeriko**,
um demónio que abre **portas** entre o mundo dela e vários reinos
fantasmagóricos. Koliani atravessa esses reinos, um a um, a enfrentar os
demónios de Zeriko e a juntar **pistas** sobre onde a mãe está a ser
mantida -- até chegar ao **Castelo de Zeriko**, o nível final, e a
libertar.

Tom: sombrio mas não gratuito -- uma criança corajosa num sítio que lhe é
grande demais. Gótico, luar, brilho magenta/roxo (ver `assets/branding/
key_art.png`). Slogan da key art: *"Uma menina. Um propósito. Uma lenda."*

## Personagens

- **Koliani** -- protagonista. Ágil, teimosa. Arma: uma lâmina que brilha
  (magenta). Evolui ao desbloquear habilidades permanentes ao longo da
  campanha (ex.: salto duplo, dash aéreo, quebrar certas paredes).
- **Zeriko** -- antagonista. Demónio guardião das portas. Aparece à
  distância nos primeiros mundos (a espreitar, a provocar) antes do
  confronto final. Segura uma lanterna-jaula onde se vê uma silhueta -- a
  mãe.
- **A mãe** -- objetivo. Nome por definir. Deixa sinais pelos mundos
  (cartas, objetos, sombras) que formam as **pistas**.
- **Demónios de mundo** -- um "chefe" temático por reino, além dos
  inimigos comuns (`DemonioBase` e derivados).

## Mundos (ordem da campanha)

A ordem é a lista `NIVEIS` em `scripts/estado_jogo.gd`. Nomes vindos da
key art; os detalhes são para o agente `gaming` desenhar.

| # | Mundo | Ideia de ambiente | Pista sobre a mãe |
|---|-------|-------------------|-------------------|
| 1 | **Floresta Putrefata** | floresta morta, névoa, raízes; verde-podre | primeiro sinal de que Zeriko a levou por uma porta |
| 2 | **Prisão dos Condenados** | masmorra, correntes, celas; azul-frio | uma carta da mãe escondida numa cela |
| 3 | **Torres Esquecidas** | torres partidas ao vento, vazio por baixo; roxo | vê-se a lanterna de Zeriko ao longe |
| 4 | **Castelo de Zeriko** | trono, vitrais partidos, lua; magenta intenso | confronto final -- libertar a mãe |

(`Level_Test.tscn` é só uma sala de teste, não conta como mundo.)

### Mundo 1 -- pistas e habilidade (implementado em `Floresta_Putrefata.tscn`)

| id da pista | tipo | onde | texto (rascunho) |
|-------------|------|------|------------------|
| `floresta_sinal_da_porta` | obrigatória (na `Porta`) | atravessar para o mundo 2 | "A porta ainda cheira ao enxofre dele. Ela passou por aqui." |
| `floresta_carta_rasgada` | segredo (`Coletavel`) | plataforma alta sobre o fosso -- **precisa do salto duplo** | "Metade de uma carta da mãe, rasgada: *...não me procures, Kol...*" |

Habilidade ganha no mundo 1: **`salto_duplo`** (`Coletavel` no caminho
principal, antes do fosso). É o gate do segredo e do resto da campanha.

### Mundo 2 -- pistas e habilidade (`Prisao_dos_Condenados.tscn`)

| id da pista | tipo | onde | texto (rascunho) |
|-------------|------|------|------------------|
| `prisao_carta_na_cela` | obrigatória (na `Porta`) | atravessar para o mundo 3 | nome dela riscado na pedra, data de há três dias |
| `prisao_grito_nas_correntes` | segredo (`Coletavel`) | cela alta, no topo da subida | correntes ainda a oscilar -- passou agora mesmo |

Habilidade ganha no mundo 2: **`dash_aereo`** (`Coletavel` no caminho
principal, em `ChaoMeio`). Permite fazer dash no ar.

### Mundo 3 -- pistas e habilidade (`Torres_Esquecidas.tscn`)

| id da pista | tipo | onde | texto (rascunho) |
|-------------|------|------|------------------|
| `torres_lanterna_de_zeriko` | obrigatória (na `Porta`) | atravessar para o mundo 4 | vê-se a lanterna-jaula de Zeriko ao longe, com uma silhueta |
| `torres_sussurro_da_mae` | segredo (`Coletavel`) | atrás de uma `ParedeFragil`, no topo da torre C | "Ele guarda-me para o fim, Kol. Chega antes disso." |

Habilidade ganha no mundo 3: **`partir_paredes`** (`Coletavel` no caminho
principal, em `TorreB`). Golpe + esta habilidade parte uma `ParedeFragil`.

## Estrutura de pista

Cada mundo tem **1 pista** obrigatória (avança a história) e pode ter
segredos opcionais. As pistas ficam guardadas em `EstadoJogo.pistas` e
mostram-se num ecrã de "diário" (por fazer). A porta de cada mundo pode
registar uma pista ao ser atravessada (`Porta.pista_ao_atravessar`).

## Final

Ao atravessar a última porta (`EstadoJogo.ha_proximo_nivel()` falso),
`main.gd` dispara `_ao_fim_da_campanha()` -- por agora um placeholder.
A cena de final a sério (Koliani liberta a mãe, Zeriko derrotado) é
trabalho do agente `gaming`.
