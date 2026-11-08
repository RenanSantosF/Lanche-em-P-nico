# Publicar o Lanche em Pânico na Google Play

## Ficha resumo (copie e cole na Play Console)

| Campo | Valor |
|---|---|
| **Nome do pacote (ID do app)** | `com.ferreiratecnologia.lancheempanico` — permanente, não muda depois de publicar |
| **Nome do app** | Lanche em Pânico (EN: Burger Panic · ES: Pánico Burger) |
| **Desenvolvedor** | Ferreira Tecnologia (FT) |
| **Versão atual** | 3.3.0 (o `versionCode` sobe sozinho a cada build: 100 + número do build) |
| **Tipo / preço** | Jogo · Gratuito · Contém anúncios |
| **Categoria** | Jogos → Casual |
| **Classificação indicativa** | Livre / Everyone (questionário IARC: sem violência, sem compras, com anúncios) |
| **Público-alvo recomendado** | 13 anos ou mais (evita as regras extras do programa Família) |
| **Idiomas** | Português (Brasil), Inglês, Espanhol |
| **Android mínimo / alvo** | Android 7.0 (API 24) / Android 16 (API 36) |
| **Arquivo para a loja** | `lanche-em-panico.aab` (Release no GitHub, gerado quando os secrets da chave existem) |
| **Assinatura** | Chave de upload `lanche-upload.jks`, alias `lanche` + Assinatura de apps do Google Play |
| **Política de privacidade** | `https://github.com/RenanSantosF/Lanche-em-P-nico/blob/main-7787344074917853781/PRIVACY.md` |
| **AdMob – ID do app** | `ca-app-pub-4311255826061303~4157782489` |
| **AdMob – Intersticial "A cada fase"** | `ca-app-pub-4311255826061303/7993085719` |
| **AdMob – Premiado "Recompensa"** | `ca-app-pub-4311255826061303/7320353635` |
| **ID de publicidade** | Sim, usado para anúncios |
| **Permissões** | Internet, estado da rede, vibrar (+ AD_ID adicionada pelo SDK de anúncios) |
| **Ícone** | `store/play_icon_512.png` |
| **Gráfico de destaque** | `store/feature_graphic_1024x500.png` |
| **Capturas** | `store/screenshots/` (pt_, en_, es_) |
| **Textos da ficha** | No fim deste arquivo (PT, EN, ES) |


Tudo o que dá para automatizar já está pronto no repositório. Este guia mostra o que **só você** pode fazer (conta, pagamento, formulários da Play Console) e onde está cada material.

## O que já está pronto

| Item | Onde |
|---|---|
| AAB assinado para enviar à Play Store (anúncios reais) | Gerado pelo GitHub Actions em toda atualização da branch principal, anexado à **Release** |
| APK de teste para o celular (anúncios de TESTE do Google) | Mesma Release: `lanche-em-panico.apk` |
| Alvo Android 16 (API 36), exigido pela Play Store | Godot 4.7.2 |
| AdMob: intersticial "A cada fase" + premiado "Recompensa" + consentimento GDPR | `autoload/Ads.gd` |
| Política de privacidade (PT/EN/ES) | `PRIVACY.md` (o próprio link do GitHub) |
| Ícone 512×512 | `store/play_icon_512.png` |
| Gráfico de destaque 1024×500 | `store/feature_graphic_1024x500.png` |
| Capturas de tela 1080×1920 (PT, EN e ES) | `store/screenshots/` |
| Textos da ficha da loja (PT, EN, ES) | Mais abaixo neste arquivo |

ID do pacote (permanente na Play Store): **`com.ferreiratecnologia.lancheempanico`**

---

## Passo 1 — Guardar a chave de upload no GitHub (uma vez só)

A Play Store exige que o AAB seja assinado sempre com a **mesma chave de upload**. Você recebeu a chave em arquivos separados (`lanche-upload.jks` e três `.txt`). **Guarde uma cópia em lugar seguro** (Google Drive, pendrive). Se perder, dá para pedir a troca ao suporte da Google, mas é demorado.

No GitHub: **Settings → Secrets and variables → Actions → New repository secret**, crie 3 secrets com o conteúdo de cada arquivo:

| Nome do secret | Conteúdo |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | todo o texto de `ANDROID_KEYSTORE_BASE64.txt` |
| `ANDROID_KEYSTORE_PASSWORD` | o texto de `ANDROID_KEYSTORE_PASSWORD.txt` |
| `ANDROID_KEY_ALIAS` | `lanche` |

Depois vá em **Actions → Build Android → Run workflow**. A Release nova vai trazer o `lanche-em-panico.aab`.

## Passo 2 — Política de privacidade

Já está publicada no próprio GitHub (o repositório é público):
https://github.com/RenanSantosF/Lanche-em-P-nico/blob/main-7787344074917853781/PRIVACY.md

## Passo 3 — Conta de desenvolvedor

1. Crie a conta em <https://play.google.com/console> (taxa única de US$ 25 e verificação de identidade).
2. **Contas pessoais novas** precisam fazer um **teste fechado com pelo menos 12 testadores por 14 dias** antes de liberar a produção. Use a faixa **Teste fechado** e convide amigos e família pelo e-mail deles.

## Passo 4 — Criar o app na Play Console

- Nome: **Lanche em Pânico** · Idioma padrão: Português (Brasil) · Tipo: **Jogo** · **Gratuito**
- Em **Configurar o app**, responda:
  - **Política de privacidade:** o link da política de privacidade (Passo 2).
  - **Anúncios:** **Sim, o app contém anúncios.**
  - **Acesso ao app:** todo o conteúdo está disponível sem login.
  - **Classificação do conteúdo:** questionário IARC → categoria *Jogo*. Sem violência, sem compras, **com anúncios**. Deve sair "Livre" / "Everyone".
  - **Público-alvo:** recomendo **13 anos ou mais**. Se marcar faixas abaixo de 13, o app entra no programa *Família* e os anúncios precisam seguir regras extras. O código já limita os anúncios à classificação livre, mas a Google revisa com mais rigor.
  - **Segurança dos dados** (por causa do SDK do AdMob):
    - Coleta dados? **Sim**. Compartilha? **Sim** (com a Google, para anúncios).
    - **Identificadores do dispositivo ou outros IDs** (ID de publicidade): coletado e compartilhado, para *Publicidade ou marketing* e *Prevenção de fraudes*.
    - **Local aproximado** (pelo IP): coletado e compartilhado, para *Publicidade*.
    - **Atividade no app / interações** e **Diagnósticos**: coletados, para *Publicidade* e *Análise*.
    - Dados criptografados em trânsito: **Sim**. O usuário pode pedir exclusão: os dados do jogo ficam só no aparelho.
  - **ID de publicidade:** **Sim, o app usa o ID de publicidade** (para anúncios).
  - Categoria: **Jogos → Casual** (ou Simulação).

## Passo 5 — Ficha da loja

Envie o ícone, o gráfico de destaque e as capturas de `store/screenshots/` (`pt_*` para Português, `en_*` para English, `es_*` para Español). Copie os textos abaixo.

## Passo 6 — Enviar o AAB

**Teste fechado → Criar versão →** envie o `lanche-em-panico.aab` da Release mais recente. Aceite a **Assinatura de apps do Google Play** (recomendado). Cada build novo já sai com um `versionCode` maior, então as atualizações sobem sem conflito.

## Passo 7 — Conectar o AdMob à Play Store

Depois que o app estiver publicado (mesmo em teste), no AdMob vá em **Apps → Lanche em Pânico → Configurações do app → Adicionar loja de apps** e vincule ao app da Play Store. Recomendado: publique um `app-ads.txt` no site de desenvolvedor informado na Play Store (o AdMob mostra o conteúdo exato).

> **Importante:** nunca clique nos seus próprios anúncios reais. O APK de teste usa anúncios de teste do Google justamente para você poder testar à vontade.

---

## Textos da ficha da loja

### Português (pt-BR)
**Título (até 30):** Lanche em Pânico

**Descrição curta (até 80):** Monte lanches do jeito certo, ganhe estrelas e faça sua lanchonete crescer!

**Descrição completa:**
```
A fila não para e os clientes estão com fome! Em Lanche em Pânico você comanda a chapa, monta cada lanche exatamente como o pedido e transforma uma lanchonete simples num sucesso.

🍔 MONTE DO JEITO CERTO
Siga a comanda de baixo para cima: pão, carne, cheddar, alface, tomate, bacon, ovo, cebola, picles... Lanche perfeito vale 3 estrelas. Errou? Ganha menos!

🔥 A CHAPA NÃO PERDOA
Você começa com uma chapa só! A carne leva tempo para assar e queima se você esquecer. O cheddar derrete em cima da carne, na chapa. Planeje, faça várias coisas ao mesmo tempo e não deixe queimar!

😰 CLIENTE GRITANDO, CHEF NERVOSO
Demorou? O cliente grita "Anda logo!" e você fica nervoso: a tela treme, o coração acelera e as mãos tremem. Capriche num lanche perfeito para se acalmar!

⭐ METAS, COMBOS E HORA DO RUSH
Bata a meta de cada dia para avançar. Encadeie lanches perfeitos para fazer combos e ganhar mais. Cuidado com a Hora do Rush, os clientes VIP apressados e o crítico exigente!

🏪 EXPANDA SUA LANCHONETE
Suba de nível de Aprendiz até Lenda do Lanche. Compre ingredientes novos, mais chapas, chapa turbo, exaustor, ajudante de chapa, fritadeira, máquina de refri, mais bancos, TV, panfletos, chá de camomila, decoração e letreiro neon. A lanchonete muda de visual conforme evolui.

✨ PARA TODA A FAMÍLIA
Visual colorido, controles simples, tutorial no primeiro dia e partidas rápidas. Leve, roda bem até em celulares simples. Em português, inglês e espanhol.

Jogo gratuito com anúncios.
```

### English (en-US)
**Title:** Burger Panic

**Short description:** Build burgers just right, earn stars and grow your diner!

**Full description:**
```
The line never stops and the customers are hungry! In Burger Panic you run the grill, build every burger exactly as ordered and turn a tiny diner into a hit.

🍔 BUILD IT RIGHT
Follow the ticket from the bottom up: bun, patty, cheddar, lettuce, tomato, bacon, egg, onion, pickles... A perfect burger earns 3 stars. Make a mistake and you earn less!

🔥 THE GRILL IS UNFORGIVING
You start with a single grill! Patties take time to cook and burn if you forget them. Cheddar melts on top of the patty, right on the grill. Plan ahead, multitask and don't let anything burn!

⭐ GOALS, COMBOS AND RUSH HOUR
Hit each day's goal to move on. Chain perfect burgers for combos and bigger payouts. Watch out for Rush Hour, hurried VIP customers and the picky critic!

😰 YELLING CUSTOMERS, NERVOUS CHEF
Too slow? Customers yell "Hurry up!" and you get nervous: the screen shakes, your heart races and your hands tremble. Nail a perfect burger to calm down!

🏪 EXPAND YOUR DINER
Level up from Apprentice to Burger Legend. Buy new ingredients, more grills, a turbo grill, an exhaust hood, a grill helper, a fryer, a soda machine, more stools, a TV, flyers, chamomile tea, decorations and a neon sign. Your diner's look changes as it grows.

✨ FUN FOR THE WHOLE FAMILY
Colorful art, simple controls, a first-day tutorial and quick sessions. Lightweight, runs well even on low-end phones. In English, Portuguese and Spanish.

Free game with ads.
```

### Español (es-419 / es-ES)
**Título:** Pánico Burger

**Descripción breve:** ¡Arma hamburguesas perfectas, gana estrellas y haz crecer tu local!

**Descripción completa:**
```
¡La fila no para y los clientes tienen hambre! En Pánico Burger manejas la plancha, armas cada hamburguesa tal como la piden y conviertes un local sencillo en un éxito.

🍔 ÁRMALA BIEN
Sigue la comanda de abajo hacia arriba: pan, carne, cheddar, lechuga, tomate, bacon, huevo, cebolla, pepinillos... Una hamburguesa perfecta vale 3 estrellas. ¿Te equivocaste? ¡Ganas menos!

🔥 LA PLANCHA NO PERDONA
¡Empiezas con una sola plancha! La carne tarda en hacerse y se quema si la olvidas. El cheddar se derrite sobre la carne, en la plancha. ¡Planifica, haz varias cosas a la vez y no dejes que se queme!

⭐ METAS, COMBOS Y HORA PUNTA
Cumple la meta de cada día para avanzar. Encadena hamburguesas perfectas para hacer combos y ganar más. ¡Cuidado con la Hora Punta, los clientes VIP con prisa y el crítico exigente!

😰 CLIENTES GRITANDO, CHEF NERVIOSO
¿Tardaste? El cliente grita "¡Apúrate!" y te pones nervioso: la pantalla tiembla, el corazón se acelera y las manos tiemblan. ¡Haz una hamburguesa perfecta para calmarte!

🏪 AMPLÍA TU LOCAL
Sube de nivel de Aprendiz a Leyenda Burger. Compra ingredientes nuevos, más planchas, plancha turbo, extractor, ayudante de plancha, freidora, máquina de refrescos, más taburetes, TV, volantes, té de manzanilla, decoración y un letrero de neón. Tu local cambia de aspecto mientras crece.

✨ PARA TODA LA FAMILIA
Gráficos coloridos, controles sencillos, tutorial el primer día y partidas rápidas. Ligero, funciona bien incluso en móviles sencillos. En español, portugués e inglés.

Juego gratuito con anuncios.
```
