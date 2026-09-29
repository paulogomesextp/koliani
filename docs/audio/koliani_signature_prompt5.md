# Koliani Signature — SFX Overhaul Prompt 5 (21 set 2026)

**Estado:** PASS técnico do candidato de escuta; **HUMAN LISTEN REQUIRED**.
Branch `codex/sfx-overhaul`, HEAD inicial `6dda2834`. Não integrado em
`master`, sem PWA nova. O texto do pedido dizia 10 anos; o cânone do projeto
mantém **16 anos**. A direção sonora ágil/precisa/sobrenatural foi seguida sem
alterar a idade da personagem.

## Redesign

27 WAV originais, sem samples terceiros, em
`assets/audio/koliani_signature/`. A fonte é
`tools/gerar_sfx_koliani_signature.py` (determinístico). Cada peça combina no
máximo dois gestos dominantes: transiente físico ou corte de ar filtrado, mais
uma ressonância curta de duas parciais (554→370 e 835→565 Hz) quando há
Shadowblade/energia. A família partilha essa assinatura, mas os quatro golpes
têm envelopes e varrimentos diferentes; o quarto tem antecipação, corpo mais
baixo e cauda própria. O dash tem chirp descendente + ar em aceleração, em vez
do sopro contínuo do vento da Região II. Não se criaram mecânicas.

| Evento | Assets novos |
|---|---|
| movimento | `koliani_jump`, `koliani_double_jump`, `koliani_land_soft/medium/hard`, `koliani_dash`, `koliani_roll`, `koliani_wall`, `koliani_grab`, `koliani_step_1/2/3` |
| Shadowblade | `shadowblade_swing_1/2/3`, `shadowblade_finisher`, `shadowblade_hit` + `_v2/_v3`, `shadowblade_critical`, `shadowblade_energy_cast` |
| defesa/dano | `shadow_shield_on`, `shadow_shield_hit`, `koliani_hurt`, `koliani_hurt_heavy`, `koliani_death`, `koliani_stomp` |

O pisão ganhou um som corporal próprio porque, ao trocar `acerto` para metal
Shadowblade, os dois callsites de pisão ficariam a soar como espada. O hurt
pesado é seleção **só sonora** para dano não fatal >=25 % da vida máxima; não
muda dano, i-frames, recuo nem prioridades. O fatal continua a disparar apenas
`koliani_death`.

Os sons genéricos `salto` e `bloqueio` usados também por inimigos/chefes
ficaram intactos; a Koliani usa chaves próprias. Anti-repetição de `acerto`
continua com três assets, sem repetição imediata; há um só jitter de pitch
na reprodução e o RNG de áudio continua separado do de gameplay.

## QA objetiva

`tools/verificar_audio_koliani.py` usa FFprobe/FFmpeg, verifica os 27 streams
e simula em PCM a cadência de quatro golpes mais quatro impactos. Resultado:

- 27/27 PCM 16-bit, **mono 44,1 kHz**, 0,120–0,770 s;
- picos de **−10,0 a −3,0 dBFS**, zero clipping por asset;
- morte **−18,0 LUFS**; LUFS integrado não é válido para os one-shots abaixo
  dos 400 ms, por isso não foram normalizados para um alvo uniforme;
- o gerador mede e molda a janela mais forte de **50 ms** por evento, em vez
  de normalizar apenas por pico: passos −16 dBFS, golpes 1–4 de −12 a
  −8,5 dBFS, impactos ~−9 dBFS antes do volume do callsite;
- sequência de combo + impactos: **−6,40 dBFS** de pico na mistura simulada.

Isto não substitui ouvir a mistura real com música/inimigos nem um altifalante
de telemóvel. **DEVICE VALIDATION REQUIRED** para a legibilidade em hardware
mobile. A build de QA Windows serve primeiro a escuta humana do Paulo.

`tools/verificar_sfx_koliani.gd`, renderer Vulkan real: **0 falhas**.
Input real confirma um trigger de jump e um de double jump. Confirma quatro
streams de combo, crítico real dedicado, três impactos com anti-repetição,
dash, escudo com activation/impact diferentes e cooldown, hurt leve/pesado e
fatal sem hurt+death. Catálogo: 27 novos carregados, nenhum stream missing.

Regressões: `verificar_sfx_criticos`, `verificar_sfx_combate`,
`verificar_sfx_chefes`, `verificar_sfx_mundo`: **4/4 exit 0, falhas=0**.
Chefes emitiram duas ocorrências de `Balao._avancar` e mundo três erros de
runtime; comparei-os com uma worktree limpa do HEAD `6dda2834`: **mesma
quantidade e mesmas mensagens**. Não são regressões deste lote. Suite geral
exit 0, testes `OK`, save real intacto; mantém o teardown conhecido da Região
III. Import/export Godot 4.7.2 sem erros de script.

Numa repetição final isolada de chefes surgiu adicionalmente uma vez o erro
do motor `slot >= slot_max` em `ObjectDB::get_instance`; a repetição seguinte
voltou exactamente às duas mensagens `Balao._avancar` da baseline, com
`falhas=0` nas duas. É intermitência de teardown, não foi ocultada nem usada
como prova de áudio limpo.

O diff funcional em `koliani.gd` é exclusivamente seleção de stream/volume
por evento sonoro; física, dano e progressão não mudaram.

## Build QA e paragem

`C:\Projetos\koliani-sfx\build\qa\Koliani-KolianiSFX-QA.exe` — export
Windows release com PCK embutido, **207 984 336 bytes**, SHA-256
`0C05E2453CFC3482178AF5C38A13FAE77A603BFEB4DD6DA1A652D7F45E897CD0`.
Smoke headless: exit 0; apenas warnings conhecidos de limpeza ao sair.
O SHA-256 da build oficial
`C:\Projetos\koliani\build\windows\Koliani.exe` ficou **inalterado**:
`C23080F32C64B4BB91F5626E95AFCCD3326F06788FDD34491AA50FCBB4EDB521`.

Próximo passo: **Paulo testar rapidamente os sons da Koliani** e dizer o que
soa bom, fraco, excessivo ou irritante. Não integrar em `master` nem publicar
PWA antes desse feedback. Não começar o Global Music Audit nesta execução.
