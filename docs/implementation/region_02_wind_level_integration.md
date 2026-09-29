# Região II — integração de vento em N06, N07 e N09

## Estado

Integração técnica e aceitação humana concluídas em 16 de setembro de 2026.
As cenas carregam, as invariantes estruturais e a suite passam, e o playtest
humano confirmou N06/N07/N09 do início ao fim sem problemas nem cheats.
Checkpoint/morte/respawn passaram nos três níveis; combate/knockback e o ponto
perto de `x≈954` em N09 também passaram. Estado final: **PASS**.

## N06 — Portão dos Condenados

- `VentoEntrada`: zona horizontal pulsada para a direita, intensidade
  `420 px/s²`, limite `300 px/s`, área `760 × 250`. Introduz a leitura a favor
  da marcha sem cobrir o checkpoint inicial.
- `VentoBifurcacao`: zona horizontal pulsada para a esquerda, intensidade
  `520 px/s²`, limite `320 px/s`, área `820 × 300`. Abrange as duas rotas da
  bifurcação e termina antes do checkpoint de reencontro e da arena.
- Intenção: ensinar rajada a favor e depois oposição controlável, mantendo
  pausas seguras entre zonas.

## N07 — Fornalha dos Pecadores

- `UpdraftEntrada`: para cima, `1050 px/s²`, limite `340 px/s`, área
  `190 × 300`.
- `UpdraftMeio`: para cima, `1180 px/s²`, limite `380 px/s`, área
  `210 × 320`.
- `UpdraftSaida`: para cima, `980 px/s²`, limite `330 px/s`, área
  `190 × 300`.
- Intenção: três colunas contínuas apoiam a rota alta existente. As áreas
  começam acima do passadiço inferior, preservando a alternativa baixa e os
  checkpoints. Glide não foi implementado.

## N09 — Ala dos Mortos

- `VentoVariavelEntrada`: pulso para a direita, `360 px/s²`, limite
  `280 px/s`, ciclo `1,45 s / 1,0 s`.
- `VentoVariavelCombate`: pulso para a esquerda, `440 px/s²`, limite
  `300 px/s`, ciclo `1,1 s / 0,85 s`, fase `0,35 s`.
- `VentoVariavelSaida`: pulso para a direita, `520 px/s²`, limite
  `320 px/s`, ciclo `0,9 s / 0,75 s`, fase `0,2 s`.
- Intenção: alternar direção, intensidade e cadência ao longo das plataformas
  existentes. Inimigos, plataformas espectrais, checkpoints, boss e arena
  foram preservados; nenhuma zona cobre um checkpoint ou o boss.

## Leitura espacial

`WindZone` ganhou um guia mecânico procedural opcional (`mostrar_guia` e
`cor_guia`): linhas com setas alinhadas à direção da força. Em zonas pulsadas,
o guia acompanha o multiplicador ativo. Isto é feedback funcional provisório,
não art pass, partícula ou SFX final.

## Ficheiros alterados

- `scenes/levels/Prisao_dos_Condenados.tscn`;
- `scenes/levels/Fornalha_dos_Pecadores.tscn`;
- `scenes/levels/Ala_dos_Mortos.tscn`;
- `scripts/wind_zone.gd`;
- `tests/test_region02_wind_levels.gd` e respetivo UID;
- `tests/run_tests.gd`;
- `docs/plano_atual.md` e `docs/retomar_aqui.md`;
- este documento.

N08 e N10 não foram alterados. Não houve mudança de glide, bosses, UI, SFX,
inimigos, saves, progressão global ou geradores.

## Validação executada

Godot oficial 4.7.2, userdata isolada:

- importação headless: `EXIT 0`;
- WindZone A–L: `OK -- Region II reusable WindZone (A-L)`, `EXIT 0`;
- Movement + Camera 4A: `PASS`, `EXIT 0`;
- suite completa, incluindo o contrato novo de N06/N07/N09:
  `OK -- todos os testes passaram`, `EXIT 0`;
- smoke individual das três cenas: `EXIT 0`;
- alcance estático final:
  - N06: porta `#14`, `porta_alcancavel=true`;
  - N07: porta `#14`, `porta_alcancavel=true`;
  - N09: porta `#15`, `porta_alcancavel=true`;
- bot anti-softlock com a Koliani real, mas em `modo_dev`:
  - N06: chegou à porta em 14 s; maior paragem 0,8 s;
  - N07: chegou à porta em 14 s; maior paragem 0,7 s;
  - N09: chegou à porta em 39 s; paragem de 26,1 s perto de `x=954`,
    resolvida sem morte.

Os avisos de objetos/recursos retidos no encerramento imediato do runner já
eram observados nos baselines e não produziram falhas novas.

## Fecho do playtest humano

- N06, N07 e N09: PASS sem problemas, em progressão normal e sem cheats.
- Checkpoint/morte/respawn: PASS nos três níveis, sem força residual reportada.
- N09: combate e knockback PASS; a paragem perto de `x≈954` não é softlock.
- Browser/telemóvel não foram testados: **DEVICE VALIDATION REQUIRED** para
  aceitação nessas plataformas.

## Próximo passo

Fechar o commit/push do Process 10 e parar. Não iniciar o Process 11 nesta
execução.
