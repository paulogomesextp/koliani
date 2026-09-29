# 9H.19 — auditoria de fontes e bloqueio de produção

13 setembro 2026. Estado: INCOMPLETE / paragem no gate de fontes.

## Objetivo, âmbito e conclusão

Áudio apenas: 12 candidatos, substituição musical candidata, laboratório A/B,
integração candidata e export Windows após validação. Não propagar ao catálogo
sem aprovação humana. Este lote documental conclui a auditoria local e o brief;
não conclui a produção nem as fases B–F.

HEAD START: `1d1fd7c19413cd63d221fea7a32045a720c6cf24`.
Branch: `codex/9h16-l1-perfection`, worktree `C:\Projetos\koliani-9h16`.
HEAD inicial igual à referência remota da branch. Fetch origin master realizado;
log dessa referência nas últimas 24 horas sem commits. Auxiliares não versionados
preservados; árvore principal com alterações alheias não editada.

Hipóteses verificadas: fontes brutas nos packs locais; fontes alternativas nos
worktrees/histórico; instrumentos ou stems para nova composição. Inventário por
extensões de áudio em C:\Projetos, incluindo pastas incoming ignoradas e demos
dos packs de arte. Histórico de áudio consultado em todas as referências Git;
isto não equivale a escutar cada versão histórica nem a auditar todo o computador.
Inventário inicial: `C:\Temp\koliani_9h19_audio_inventory.txt`.

## Fontes encontradas

Fontes abaixo já estavam locais em
`C:\Projetos\koliani\assets\audio\incoming\sfx\`. Nenhuma foi importada,
descarregada, modificada ou redistribuída nesta execução.

| SOURCE / ORIGINAL LOCATION | AUTHOR | LICENSE | REDISTRIBUTION ALLOWED | Local / quantidade |
| --- | --- | --- | --- | --- |
| https://opengameart.org/content/different-steps-on-wood-stone-leaves-gravel-and-mud | TinyWorlds | CC0 declarada nos créditos e ferramenta existentes | Sim sob CC0; página não reverificada nesta execução | passos / 8 |
| https://opengameart.org/content/monster-sound-effects-pack | Ogrebane | CC0 declarada nos créditos e ferramenta existentes | Sim sob CC0; página não reverificada nesta execução | monstros / 20 |
| https://opengameart.org/content/80-cc0-creture-sfx-2 | rubberduck | CC0 declarada nos créditos e ferramenta existentes | Sim sob CC0; página não reverificada nesta execução | criaturas2 / 80 |
| https://opengameart.org/content/100-cc0-sfx-2 | rubberduck | CC0 declarada nos créditos e ferramenta existentes | Sim sob CC0; página não reverificada nesta execução | sfx100_2 / 100 |
| https://opengameart.org/content/50-rpg-sound-effects | Kenney Vleugels | CC0, confirmada no license.txt local | Sim sob licença local | kenney / 51 |

Total: 259 amostras. `sfx100_2` inclui passos, madeira, metal, vidro, ar,
impactos e ambientes. São potenciais fontes de matéria física; não foram
classificadas como fracas nem profissionais por métricas ou nomes de ficheiro.
As amostras misc não foram classificadas auditivamente. Não se identificaram
gravações explicitamente documentadas de roupa/couro nem sessões de foley.

O catálogo tem também OGG legados creditados como CC0 e WAV das execuções
9H.13/13B/18, sintetizados por geradores locais. Reutilizar esses WAV como corpo
principal repetiria o método rejeitado. `preparar_sfx.py` referencia os packs
acima; não foi executado por cima do catálogo.

Música: incoming contém masters/misturas de Ehlers, Of Far Different Nature,
Junkala, Marcelo e faixas rock/metal. Créditos existentes registam CC0/CC-BY.
Não são stems de piano/cello disponíveis para compor um motivo novo. Os MP3
OneCinematicStudio fornecidos pelo Paulo não têm aqui prova documental de
redistribuição: não utilizados. Demos Ansimuz/GothicVania contêm áudio, mas não
foi estabelecida a licença específica de cada som; não utilizados.

`compor_trilha_9h1.py` e `motor_musical.py` produzem música por síntese própria,
sem samples instrumentais. O tema atual é D menor, 60 BPM, motivo de sete notas.
Não foi retocado. Nenhum SF2/SFZ, FLAC/AIFF instrumental ou stem identificado
na pesquisa dirigida. Não houve avaliação auditiva válida nesta execução.

## Paragem

PROFESSIONAL PRODUCTION ASSET REQUIRED

Existem fontes locais potenciais, mas a sua adequação ao gate profissional não
foi estabelecida. Isto é insuficiência de evidência e de seleção auditiva, não
prova de que os packs sejam inadequados. Faltam seleção humana das fontes e
material de produção para roupa/corpo/arma que sustente a direção congelada.
Não fabricar outro catálogo predominantemente procedural para preencher o gate.

MAIN MENU MUSIC — PROFESSIONAL PRODUCTION ASSET REQUIRED

## Brief de produção musical (proposta para produção, não áudio aprovado)

- Tempo: 56–64 BPM; referência de trabalho 60 BPM, 4/4 com fraseado livre.
- Modo: Ré menor natural; Mi bemol pontual em textura de perigo, sem ostinato.
- Motivo proposto de quatro notas: D4–F4–E4–A3, valores 1,5 / 1 / 1,5 / 4
  tempos. Pausa após a frase; não transformar em jingle. É proposta, não novo
  cânone musical aprovado. Guardar MIDI/partitura e stems para callbacks.
- Instrumentos: piano felt gravado, cello/viola em dinâmica baixa, drone de
  cordas grave, floresta/vento distante e metal friccionado muito discreto.
  Textura humana etérea opcional, sem letra. Sem rock ou percussão épica.
- Introdução: 8 compassos / 32 s, ambiente e entrada esparsa do piano.
- Loop: 32 compassos / 128 s a 60 BPM; A de 8 compassos, resposta de cello
  de 8, tensão contida de 8, dissolução de 8. Sem resolução triunfal.
- Duração de entrega: cerca de 160 s, intro mais loop; export separado de ambos.
- Ponto de loop: início da secção recorrente aos 32 s, retorno após 160 s;
  reverb da última frase impresso sobre o início do loop, sem fade global.
- Arco emocional: floresta silenciosa → ausência/melancolia de Elara → vestígio
  perigoso de Shadowblade → mistério suspenso. Espaço entre frases para UI.
- Entrega: WAV estéreo 48 kHz/24-bit, stems alinhados e licença escrita que
  permita publicar fontes e derivados no repositório público. Reverificar
  licença de cada material externo antes de utilização.

## Estado dos critérios pedidos

UI NAV / CONFIRM / BACK / JUMP / LAND / DASH / ATTACK LIGHT / ATTACK FINISHER /
ENEMY HIT / ESSENCE / CHECKPOINT / PORTAL: nenhum NEW produzido ou integrado.
VARIATIONS: nenhuma nova. NEW TRACK CREATED: NO.
PROFESSIONAL PRODUCTION ASSET REQUIRED: YES.

A/B AUDIO LAB: NOT IMPLEMENTED (gate bloqueado).
OLD/NEW COMPARISON AVAILABLE: NO; teclado S existente preservado.
Clipping / duplicate triggers / missing files / stale mappings: não verificados
para NEW, porque não existem candidatos. Não atribuir PASS a esses critérios.
Mixer GM e todo runtime intactos. Swing/hit não alterados.

Baseline e final: `tools/correr_testes.ps1`, EXIT 0; log final indicado na retoma.
Baseline: `C:\Temp\koliani_9h19_baseline.log`. Suite diz todos os testes passaram;
retenção de 84 ObjectDB e 2 recursos à saída existente no baseline, sem correção
fora do âmbito. Save real intacto, SHA256
`08522C2225734AE8005F6B66314C5CC83E9166F93427EC8B5662544CE0411FF6`.

WINDOWS VERSION: 0.18.13 existente, não incrementada nem exportada; smoke novo
não realizado. WINDOWS SIZE: 205736040 bytes. WINDOWS SHA256:
`E6E801E25F7CBF9304D110643E50A0B9B7DF6811F09E7BD46FC592F65869124E`.
Não apresentar esta build como entrega 9H.19.

HUMAN LISTEN REQUIRED: YES. HUMAN PLAYTEST REQUIRED para aceitação em jogo.
OTHER GAME SYSTEMS MODIFIED: NO. PAID API USED: NO.

Próximo passo: obter seleção auditiva das fontes locais e gravações/stems com
direitos claros, depois retomar B; D–F continuam pendentes. Apenas o lote
documental de auditoria/brief é elegível para commit; execução não aprovada.
