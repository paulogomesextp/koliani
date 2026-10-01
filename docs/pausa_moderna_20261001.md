# Menu de pausa — 1 outubro 2026

Objetivo: usar a apresentação do menu inicial no menu aberto dentro do nível
e remover a música de fundo da pausa. Sem mudar as ações, níveis, combate,
skins, saves ou controlos.

Reutiliza `Frontend9H`: prancha `fundo_menu`, véu, vinheta, rótulos sem caixas,
separadores e realce único que acompanha o foco. Mantém Continuar, Opções,
Mapa e Menu principal. Reiniciar continua oculto como antes.

`Musica.pausa()` suspende a reprodução das camas e não inicia a faixa de
ambiência da pausa. Continuar retoma a faixa na posição anterior; saídas do
menu libertam a suspensão. Os efeitos curtos de interface mantêm-se.

QA: composição, quatro botões/foco/realce, abrir/fechar Opções, suspensão
musical, posição conservada e retoma; capturas com renderer real a 1280×720
e 1920×1080. Teste de Esc/P no nível real. Logs em `work/qa_pausa_*`.
Avisos ObjectDB de encerramento permanecem; não há declaração de PASS global.
HUMAN PLAYTEST REQUIRED para apreciação visual; DEVICE VALIDATION REQUIRED.

Builds feitas de árvore limpa derivada do commit deste lote para não incluir
o polimento de skins ainda não concluído de outro trabalho. O EXE anterior
tem SHA256 `b69b80d3c1f85568aa57e59c5592ba4e5cb5b7dbfad0452e8e3b015499ed0dd0`,
igual ao manifesto de `84c3031` (CoreCombate 1.2). V2.1 não está integrada.
As alterações locais de skins foram preservadas, não commitadas neste lote.
Windows principal e Web local atualizados juntos, sem push/publicação online.
