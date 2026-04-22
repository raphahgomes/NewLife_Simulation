# Guia de Publicação para PC (Steam, Epic Games, Itch.io e GOG)

Como as lojas de PC funcionam de forma um pouco diferente do Google Play, aqui está o checklist completo e o que falta ser feito para transformarmos o formato do New Life (mobile) para a versão Desktop.

## 1. O Que Falta Alterar no Jogo (Adaptações para PC)

- [ ] **Exportação para Plataformas Desktop:** Precisamos configurar o `export_presets.cfg` no Godot para exportar os executáveis `.exe` (Windows), `.app` (macOS) e `.x86_64` (Linux).
- [ ] **Suporte a Mouse/Teclado:** O jogo atualmente pressupõe toques na tela (Touch). Ele funciona muito bem com o clique do mouse, mas a Steam gosta quando botões importantes (como barra de espaço, Esc) funcionam para avançar a idade ou nos menus.
- [ ] **Resolução e Aspect Ratio:** Como o game foi pensado em "Retrato" (em pé de celular), na tela do PC ele ficará com barras pretas dos lados. Será opcional desenhar bordas temáticas (ex: um quarto no fundo do celular onde a pessoa joga) para não deixar a tela vazia.
- [ ] **Substituição de Anúncios ("Watch Ad"):** Jogos de PC pagos (Steam) **não** usam integração nativa com propagandas de vídeo (AdMob). Teremos que converter as vidas extras/retornos para botões normais gratuitos, conquistas, ou custando dinheiro virtual de dentro do próprio jogo.

---

## 2. Checklist da Steam (Recomendado)

A Steam é o maior e principal mercado para simulações indies. O processo é o **Steam Direct**.

- [ ] **Conta Steamworks e Taxa:** Criar uma conta no painel de desenvolvedor (Steamworks) e preencher os dados de imposto e banco (isso requer identificação verdadeira e segura). Pagar a tarifa do "Steam Direct" que é de $100 dólares (restituíveis após as vendas ultrapassarem um limite).
- [ ] **Configuração da Página da Loja "Em Breve" (Coming Soon):** Subir os banners e Screenshots. A aprovação da página leva cerca de 2-4 dias. Você tem que obrigatóriamente deixar a página como "em breve" por 2 semanas acumulando Wishlists antes de poder clicar no botão "Lançar".
- [ ] **Upload via SteamPipe:** Baixar as ferramentas do SDK da Steam para subir a build.
- [ ] **Playtesting e Aprovação:** A Valve enviará humanos reais para jogar sua build e garantir que não quebra o PC nem rouba dados. Eles levarão de 3 a 5 dias, só depois disso você pode publicar.

## 3. Epic Games Store (Self-Publishing)

Recentemente a Epic Games abriu a loja para qualquer desenvolvedor de forma parecida com a Steam.

- [ ] **Registro e Taxa:** Existe a mesma taxa de registro das ferramentas (cerca de $100).
- [ ] **Uso do EOS (Epic Online Services):** Embora não tenha DRM obrigatório nem multiplayer, a Epic obriga a configurar as conquistas usando o painel próprio do desenvolvedor deles (se houver essa funcionalidade).
- [ ] **Etapas de Storefront:** Completar questionário do IARC (você já treinou isso para o Google Play) e mandar o design da loja para revisão da Epic.
- [ ] **Revisão de Build:** Eles fazem o checklist, e em sua grande maioria, é até mais frouxo que o da Steam.

## 4. Itch.io (Obrigatório para Portfólio)

Se você quer simplesmente adicionar o jogo em um portfólio **sem pagar nada**, o Itch.io é fantástico.

- [ ] **Plataforma 100% Grátis:** Sem taxa de $100.
- [ ] **Zero Burocracia de Revisão:** Você faz o upload do `.exe` num arquivo `.zip` e lança em 30 segundos, sem revisão humana.
- [ ] O visual da página é livre e completamente construído através do HTML. O link pode ser facilmente enviado na sua bio do LinkedIn ou GitHub. Se você quiser cobrar dinheiro por lá, eles têm sistemas simples que caem direto no PayPal ou Stripe (permitindo pagamento "Pay what you want").

## 5. GOG (Opcional - Curado)

O site GOG foca em jogos _DRM-Free_ mas requer curadoria.

- [ ] Diferente da Steam/Epic/Itch, você não paga imposto para acessar, mas você tem que **fazer o pit do jogo para a equipe deles**. Se curtir o projeto, lançarão. Sendo sincero, o GOG funciona melhor apenas quando o jogo já for um sucesso grande na Steam.

---

### Resumo dos Próximos Passos

Caso queira dar sequência rumo ao PC/Steam:

1. Precisamos remover os blocos de código nativo do Android/Anúncios.
2. Alterar o comportamento visual para focar numa janela vertical estilizada ou adaptar a responsividade para preencher a tela (_Landscape_).
3. Gerar a Build Windows no Godot.
