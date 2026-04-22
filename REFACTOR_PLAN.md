# NewLife Simulation - Master Refactor Plan

Este documento detalha a refatora��o completa do jogo para transformar as mec�nicas matem�ticas isoladas em um Verdadeiro Simulador de Vida, englobando Efeito Borboleta, economias ocultas e extrema interatividade em TODAS as idades.

## Fase 1: Efeito Borboleta, Economia Oculta e Vida Din�mica (Aplicado a TODAS as Idades)
**O que muda:** O jogo deixa de ter eventos onde "A��o X = Resultado Y e fim". Toda a��o, desde beb� (chorar, morder) at� adulto, enche "baldes" de estresse e muda a sanidade dos familiares.
**Economia Familiar Din�mica (Novo):** A fam�lia ter� um or�amento oculto. Suas a��es podem fazer seus pais perderem o emprego. Uma fam�lia pobre for�ar� voc� a mudar de escola, negar� cursos, ou obrigar� a crian�a a vender balas no sinal. Um div�rcio dividir� a renda da casa, mudando seu estilo de vida na inf�ncia.
**Arquivos que ser�o modificados/criados nesta fase:**
- scripts/data_models/Character.gd: Adicionar status ocultos (\stress\, sanity, hidden_wealth, 	ags emocionais).
- scripts/autoloads/GameManager.gd: Criar o "Motor de Economia Familiar" que roda a cada ano e injeta eventos for�ados (ex: "Sua fam�lia faliu e voc� teve que sair da escola particular").
- scripts/autoloads/EventManager.gd: Refatorar o processador de eventos para checar o estresse. (Ex: Beb� chora -> EventManager avalia Stress da m�e -> Roda chance de agress�o/div�rcio).
- scripts/data_models/EventData.gd: Adicionar pr�-requisitos financeiros e de tag para disparar eventos.

## Fase 2: Sistema de Combate e Ataques (Consequ�ncias F�sicas)
**O que muda:** Brigou com o pai na Fase 1? Ou tentou assaltar na Fase 4? Isso aciona o Modo Combate. Voc� escolhe onde bater (Rosto, Corpo, Extremidades) e o dano pode quebrar ossos ou matar, resultando em pris�o, hospital ou morte.
**Arquivos que ser�o modificados/criados nesta fase:**
- scripts/systems/CombatSystem.gd (NOVO): Gerenciar� a matem�tica de turnos, chance de acerto por for�a/agilidade e os danos.
- scripts/ui/CombatHUD.tscn / .gd (NOVO): Interface dedicada que sobrep�e a tela para voc� escolher os alvos e ver a barra de vida.
- scripts/ui/GameHUD.gd: Linkar a��es agressivas de di�logo (Fase 1) para chamar o CombatSystem.

## Fase 3: Autoescola, Avia��o e Aprendizado Pr�tico
**O que muda:** Clicar em "Tirar Carteira" n�o te d� mais o item se voc� tiver dinheiro. Voc� precisa responder perguntas sobre placas ou situa��es, ou passar em minigames textuais (Brev� de Piloto, Barco).
**Arquivos que ser�o modificados/criados nesta fase:**
- data/events/adult_events.json: Inserir arrays de "perguntas te�ricas" com respostas certas/erradas.
- scripts/ui/GameHUD.gd: Adicionar a renderiza��o desse "Quiz" visual quando a atividade for selecionada.
- scripts/autoloads/AttributeSystem.gd: Vincular a falha nos testes � perda de dinheiro sem receber a licen�a.

## Fase 4: Mundo do Crime Expandido
**O que muda:** Abordagens complexas. Voc� quer roubar uma casa? O jogo pergunta "Como?" (Entrar pela janela, Arrombar porta). Cada escolha requer um item. Armas e ferramentas (Faca t�tica, P� de Cabra, Masterkey) podem ser compradas num mercado paralelo para aumentar sucesso (sem apologia, itens com fun��o mec�nica).
**Arquivos que ser�o modificados/criados nesta fase:**
- scripts/systems/CrimeSystem.gd (NOVO): Gerencia os steps de um assalto e a chance de ser pego pela pol�cia (levando a julgamento/pris�o).
- data/items/black_market.json (NOVO): Banco de dados de itens ilegais que podem ser comprados ou vendidos.
- scripts/ui/GameHUD.gd: Menus de invent�rio para o mercado clandestino.

## Fase 5: Carreira M�dica e Medicina Avan�ada
**O que muda:** Como m�dico, chegam pacientes gerados aleatoriamente (doen�as, gravidade). Voc� precisa escolher se os atende com equipamento barato (mais falha) ou de ponta. Falhas podem gerar sequelas, perda de CRM ou processo por erro m�dico.
**Arquivos que ser�o modificados/criados nesta fase:**
- scripts/systems/MedicalCareerSystem.gd (NOVO): Gera os NPCs pacientes e calcula as chances de cura.
- data/careers/careers.json: Adicionar as especializa��es m�dicas.
- scripts/ui/GameHUD.gd: Interface interativa "Diagnosticar / Tratar / Dispensar".

## Fase 6: Profiss�es Interativas Globais
**O que muda:** Toda profiss�o ter� eventos di�rios de dilemas. O chefe assediou um colega, voc� denuncia (ganha moral, corre risco de demiss�o) ou fica quieto? Promo��es v�m por boas escolhas, n�o s� clicando em "Trabalhar Mais".
**Arquivos que ser�o modificados/criados nesta fase:**
- data/careers/careers.json: Adicionar uma chave event_prompts para cada n�vel de carreira.
- scripts/autoloads/EventManager.gd: Toda vez que avan�a de idade, roda 1 evento espec�fico do emprego atual do jogador.

---
