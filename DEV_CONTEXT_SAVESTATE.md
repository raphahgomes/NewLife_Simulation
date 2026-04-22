# SAVESTATE CONTEXTO: FASE 1 (0 a 3 ANOS) - MOTOR BASE

Este documento serve como memória de longo prazo para as IAs e desenvolvedores. 
A arquitetura do Simulador foi alterada de "Eventos Matemáticos Isolados" para "Efeito Borboleta Orgânico e Oculto".

## 1. Variáveis Injetadas (Character.gd)
- `family_hidden_wealth` (Economia Oculta da Família).
- `family_stress_level` e `family_sanity`.
- `mother_age`, `father_age` (Envelhecem a cada ano).
- `mother_fertility`, `father_fertility` (Caem de acordo com a idade).
- `mother_health`, `father_health`, `mother_happiness`, `father_happiness`.
- `parents_depressed` (Booleano) e `siblings_count` / `dead_siblings`.
- `pets`: Array contendo dicionários dos gatos/cachorros (Controla afinidade e tags de depressão).

## 2. Mecânicas Biológicas Ocultas (0 a 3 Anos) 
- **Gravidez e Aborto Oculto:** O Motor checa fertilidade e saúde para a mãe tentar engravidar. Idade e stress turbinam o risco de Aborto (Gera trauma na mãe e depressão familiar).
- **Risco Doméstico (O Efeito Borboleta do Stress):** 
  - Stress > 80: Risco de Agressão Doméstica 
  - Se a mãe tem `luck` alta, o divórcio resolve. Se não, o pai é preso e a economia familiar despenca a zero (se a mãe não trabalhar, n existe familia assim mais. Mãe pode ter emprego e pai não, e vice-versa e podem ser mafiosos, herdeiros, ter investimentos... Pode ser mt coisa. Podem ganhar na loteria tbm...) (`family_hidden_wealth * 0.3`).
- **Pet Autônomo:** 
  - O Pet sofre negligência natural (15% chance).
  - Pode apenas aprontar (Destruir coisas e gerar stress para os pais).
  - Pode ATACAR o jogador se for retido em casa sob 80+ de stress. Risco de adoção pós-ataque VARIA DE ACORDO COM A AFINIDADE COM OUTROS MEMBROS DA FAMILIA de 50%.
- **Acidentes de Bebê e Saúde:** 
  - Maior Azar (`luck < 30`) = 15% de chance de cair do berço ou engasgar.
  - Pais Ricos pagam curas. Pais pobres podem rezar pra curar ou usar medicos baratos e medicina alternatvia e geram trauma futuro oculto à criança.
- **Micro-Terapias:** 
  - Casamentos falidos (>60 stress) podem ser salvos por Terapia de Casal ($800 ocultos).
  - Crianças traumatizadas com grana em casa ativam Terapia Infantil para limpeza de trauma (caso a familia tenha como pagar) ou então podem tentar ignorar ou ir diminuindo a felicidade até fazerem amigos/etc.
  - Adestradores podem curar a afinidade de cães agressivos (Pais Ricos ou tentativa de adestramento (1x por ano com chance de falha))).

## 3. Estratégia de Desenvolvimento e Teste (O Pedido do Jogador)
- **Modularização de Arquivos:** As regras não devem ficar presas em um só mega-arquivo `GameManager.gd`. Usaremos arquitetura por estágios (Scripts específicos para Bebês, Crianças, etc.). O JSON `baby_events.json` será alimentado para rodar a HUD.
- **Teste Progressivo de AAB:** Limitaremos as builds para travar em marcos (ex: Morrer/Encerrar teste ao bater 3 anos). Isso nos permite testar na prática a engine de 0 a 3 anos sem precisar codificar até os 100 anos de idade para checar cada erro.

-- FIM DO SAVESTATE --