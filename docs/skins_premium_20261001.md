# Quatro skins aprovadas — polimento integrado (1 outubro 2026)

Âmbito: Arcanjo, Arquidemónio, Abadia Afogada e Planícies Celestiais.
Arcanjo/Arquidemónio conservam acessórios/poses aprovados, mas o brilho
separa-se dos corpos; composição de alfa e faixa dos pés preservadas.
Abadia/Celestial mantêm todos os frames do corpo aprovado sem alteração.
As quatro têm aura e cinco slots de VFX próprios: penas, brasas, água e
estrelas, além do preview correspondente na loja. Splashes aprovadas,
Shadowblade, IDs, preços, progressão e gameplay não foram redesenhados.

Fontes: gerar_skins_koliani.py, trajes_premium.py e
gerar_vfx_skins_aprovadas.py. Arte procedural nativa do projeto, sem compra
ou novos assets externos. Novo runtime skins_premium_aura.gd e perfis em
VfxSkin. Remoção síncrona da aura ao desequipar corrigida durante o QA.

Provas concluídas:

- 336 frames: nitidez estrutural, ausência de halo baked novo e import
  lossless/sem mipmaps; zero falhas. Paridade de 84 frames Anjo/Demónio
  e passada run_final com a base: zero falhas.
- 3.758 hashes protegidos sem alteração inesperada, incluindo Golden,
  Shadowblade, corpos simples, cenas, dados e código de gameplay. Pausa/
  música excluídas explicitamente da comparação anterior por serem o
  lote independente já commitado em f04d82f5.
- qa_skins_premium: contagens/FPS/loops, escala/offset/colisão, perfis,
  cinco slots por skin, frame/espelho da aura, desequipar/regresso à base,
  compra/equipar/preview pela Loja e persistência JSON: PASS.
- qa_vfx_espada: 150 casos de skins/golpes/sentidos/gravidade: PASS.
- Testes existentes teste_skins_arte_real, teste_loja_cosmeticos_visuais e
  teste_shadowblade_paridade: zero falhas.
- Capturas Vulkan reais: comparacao_renderer e quatro poses por skin
  (idle/ataque/dash/salto duplo), inspecionadas. Corpos e motivos temáticos
  distinguíveis; efeitos de gameplay partilhados continuam visíveis.
- Runner confirmou três ficheiros do save real intactos; jogo principal
  fechado pelo utilizador para substituir a build sem escrita concorrente.

Logs/capturas em work/skins_premium_20261001. Avisos Camera2D/ObjectDB
no encerramento permanecem. Sem declaração de PASS da suite geral,
qualidade comercial ou performance móvel. HUMAN PLAYTEST REQUIRED para
avaliação visual em movimento; DEVICE VALIDATION REQUIRED para mobile/Web.

Prova adicional de export Windows: as quatro skins carregadas no EXE
release no nível 1, com saves de demonstração isolados. Quatro processos
terminaram em 0 e capturas exe_anjo/exe_demonio/exe_abadia_afogada/
exe_celestial foram inspecionadas; sem SCRIPT ERROR/ERROR nos logs desses
processos, mantendo avisos ObjectDB ao encerrar.

Entrega local: Windows principal e Web exportados do commit
deste lote, com backup anterior; resultado/hashes registados na retoma.
Sem push/publicação online. Combate V2.1 permanece fora deste lote.
