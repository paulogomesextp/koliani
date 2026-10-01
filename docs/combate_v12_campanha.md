# Combate 1.2 no jogo principal — 1 outubro 2026

Pedido: levar o combate 1.2 testado para a campanha. Fonte: C:\Projetos\koliani-master, master, base 34e3def6.

Main agora chama a ativação idempotente do CoreCombate em cada nível. Reutiliza os valores aprovados de BalanceCombate: básicos 0,30/0,35/0,43/0,60; aéreos 1,40/1,60; Launcher/Dash 1,30; Cleave 2,30; Counter 2,70. Preservados os inputs, timings, clamp, contrato PD por origem de ataque e Counter manual existentes. Feedback textual PD passa por Textos.t nos seis idiomas.

Não foram alterados HP/IA/guarda/peso/perfis dos inimigos, progressão, controlos móveis, poses ou skins. Os pilotos existentes continuam pilotos; inimigos comuns conservam o contrato de dano legado. O TTK e anti-spam dos alvos de laboratório não são garantia para todos os inimigos da campanha. A arte final do feedback PD/Cleave continua a dívida já documentada. Combat Lab permanece separado, sem Core simultâneo; V2.1 permanece pendente.

## Evidência

- Importação final sem SCRIPT ERROR/ERROR: work/import_combate_final.log.
- 100 níveis carregados pelo Main: núcleo único, valores 1.2, sem Lab e sem HybridShadowbladeSignature. work/qa_combate_campanha_v12_corrigido.log. Nenhum erro em execução; ao encerrar esse arnés de 100 cenas há RIDs/5 recursos por libertar. Não equivale a validação humana dos percursos.
- Renderer real Vulkan/RTX 5070, ações por input nos N1 e N6: Launcher/Cleave/Dash/Air x2, PD por origem, Counter e texto traduzido. work/qa_combate_acoes_n1_n6.log, sem SCRIPT ERROR/ERROR; aviso ObjectDB ao encerrar.
- 20 contratos existentes reutilizados pelo arnés tools/qa_combate_regressao_v12.tscn: 0 falhas. Inclui dano, núcleo, inimigos piloto, energia, Lab, clamp e balance. work/combat_regressao_harness.log. Simulação com --fixed-fps 60, sem sincronização de relógio real, passo 1/60; 2 recursos ativos ao encerrar. Execução normal de referência em work/combat_regressao.log também concluiu 20 testes/0 falhas, com 8 recursos por libertar ao encerrar.
- Suite geral completa com --fixed-fps 60: 5 falhas, portanto NÃO PASS global. work/suite_combate_v12_fixed.log. Quatro verificações reprovam id duplicado skin_shadowblade; duplicação já presente no HEAD anterior em scripts/loja_catalogo.gd:101/105. Outra é câmara/offscreen: teste não carrega Main/Core; corrida isolada normal também reprova visibilidade, work/qa_offscreen_normal_combate.log. Fontes destes testes/câmara/catálogo não foram modificadas neste lote. RIDs/recursos de shutdown também registados. Nenhuma destas falhas foi ocultada ou corrigida fora do âmbito.
- Corridas gerais normais/trace interrompidas durante simulações longas, sem conclusão; não contam como PASS. Diagnóstico inicial de bloqueio no menu foi corrigido.
- Windows/Web locais exportados, versão 0.18.20. Logs work/export_windows_combate_v12.log e work/export_web_combate_v12.log sem erros; smoke Windows exit 0 sem ERROR. Manifesto SHA em work/shadowblade_fidelity/builds_manifesto.json. Três saves reais intactos em todas as verificações.
- Backup anterior: build/windows/backups/antes_combate_12_20261001/Koliani.exe e work/web_antes_combate_12_20261001.

HUMAN PLAYTEST REQUIRED: sensação e leitura do combate com os inimigos reais. DEVICE VALIDATION REQUIRED: controlo móvel e Web no dispositivo. Sem push/publicação online. Próximo: Paulo testar a campanha Windows; catálogo/câmara devem ser tratados num lote próprio antes de uma publicação.
