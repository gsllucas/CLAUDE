# Guia Base de Migração de Repositórios Node.js (→ Node LTS atual + TypeScript)

> Playbook reutilizável para modernizar serviços Node.js legados da organização.
> Use-o como ponto de partida: copie para o repositório-alvo, preencha os campos
> `<...>`, responda os **Pontos de decisão** e ajuste as fases ao stack local.
>
> Stack-alvo de referência: **Node LTS 24**, **TypeScript 6.0.3**, **ESM nativo**,
> **esbuild** (build), **tsx** (dev watch), **Apollo Server 5 + Fastify**, **pnpm**,
> **Vitest**, **oxlint**, **pino**, e **GraphQL Codegen** para tipagem de schema/resolvers.

---

## 0. Como usar este guia

1. **Levante o estado atual** do repositório (seção *Inventário*). Não planeje sem isso.
2. **Carregue as skills** do projeto (seção *Skills*) — elas definem padrões de código,
   commits e arquitetura que devem guiar toda a migração.
3. **Responda os Pontos de decisão** com o time — eles mudam a estratégia toda.
4. **Liste as substituições** de pacotes depreciados e peça aprovação antes de trocar.
5. **Execute em fases**, em PRs pequenos e revisáveis, validando build/lint/testes a cada fase.
6. **Não pule a validação ponta a ponta** ao final de cada fase.

> Princípio geral: **uma mudança estrutural por PR**. Misturar troca de gerenciador de
> pacotes + upgrade de framework + migração para TypeScript + reescrita de testes no mesmo
> PR torna a revisão e o rollback inviáveis.

---

## 0.1 Orquestração com sub-agents (OBRIGATÓRIO)

> **Regra de execução:** o agente principal (a janela de chat) **não executa as fases
> diretamente**. Ele atua como **orquestrador** e **delega cada fase a um sub-agent
> dedicado** (idealmente **uma fase = um sub-agent = um PR**). Isso preserva o contexto da
> janela principal: o trabalho pesado (ler dezenas de arquivos, rodar builds, iterar em
> testes) acontece no contexto isolado do sub-agent, e só o **resumo** retorna ao
> orquestrador.

**Por que delegar (não fazer inline):**
- Cada fase lê/edita muitos arquivos e roda ferramentas — o volume de saída **degrada e
  satura** a janela principal, levando a perda de contexto e a decisões piores nas fases
  seguintes.
- O orquestrador precisa manter a **visão de ponta a ponta** (sequência de PRs, pontos de
  decisão, gates) por toda a migração. Mantê-lo enxuto é o que viabiliza isso.

**Papel do agente ORQUESTRADOR (janela principal):**
1. Faz o **Inventário** (seção 1) e consolida os **Pontos de decisão** (seção 3) — esse é o
   único trabalho que pode rodar inline, pois define a estratégia.
2. Para cada fase, **spawna um sub-agent** com um *brief* autocontido (modelo abaixo).
3. Recebe de volta apenas um **resumo estruturado** (o que mudou, status dos gates, riscos,
   link/branch do PR) — **não** o despejo de arquivos.
4. **Valida o gate** da fase (build/lint/type-check/testes verdes) antes de liberar a
   próxima. Sub-agents rodam **em sequência** quando há dependência entre fases; fases
   independentes podem ser paralelizadas.
5. Mantém o quadro geral: ordem dos PRs, decisões pendentes e bloqueadores.

**Papel de cada SUB-AGENT (contexto isolado):**
- Executa **uma** fase do guia, do início ao gate de validação.
- Carrega as skills relevantes (`.agents/skills/*` do repo, ou o fallback global
  `~/.claude/skills/*` — ver seção 2) e segue as **Regras críticas** (seção 5).
- Abre **um PR** com commit seguindo a skill **Conventional Commits** (um escopo por fase).
- Retorna ao orquestrador um **resumo curto e estruturado**, não a transcrição do trabalho.

**Modelo de brief para o sub-agent (preencher e passar no spawn):**
```
Fase: <nº e nome, ex.: "Fase 1 — Gerenciador de pacotes + tooling base">
Objetivo: <o que entregar nesta fase>
Contexto do repo: <stack atual relevante + decisões já tomadas nos Pontos de decisão>
Seções do guia a seguir: <ex.: §1, §6 Fase 1, §7 configs>
Skills a carregar: <ex.: clean-code, conventional-commit>
Regras inegociáveis: zero `any` (§5); uma mudança estrutural por PR; commits Conventional.
Critério de pronto (gate): <comandos que devem passar verdes, ex.: pnpm install, pnpm lint>
Entrega: 1 PR + resumo estruturado (mudanças, gates, riscos, branch/PR).
```

**Formato do resumo que o sub-agent retorna ao orquestrador:**
```
Fase: <nº e nome>            Status: <ok | bloqueado>
Branch/PR: <ref>
Mudanças: <bullets curtos>
Gates: <pnpm lint ✓ | pnpm test ✓ | ...>
Riscos/observações: <bloqueadores, decisões necessárias, dívidas>
Próxima fase sugerida: <nº>
```

> Se uma fase ficar grande demais para um único PR, o sub-agent pode **subdividi-la em
> sub-PRs coesos** (ainda um escopo por PR), reportando cada um no resumo.

---

## 1. Inventário inicial do repositório (preencher)

| Item | Valor atual | Alvo |
|---|---|---|
| Versão do Node | `<ex: 12.x>` | `<LTS atual, ex: 24>` |
| Gerenciador(es) de pacote | `<npm / yarn / ambos>` | `pnpm` |
| Linguagem / tipagem | `<JavaScript / TypeScript?>` | **TypeScript** (alvo `6.0.3`, compatível com Node LTS) |
| Sistema de módulos no código | `<CommonJS / ESM via Babel / ESM nativo>` | **ESM nativo** |
| Transpilação/build | `<Babel? tsc? nenhum>` | **esbuild** (bundle p/ `dist/`) |
| Runtime de dev (watch) | `<nodemon...>` | **`tsx watch`** (TS) / `node --watch` (JS) |
| Framework HTTP/API | `<Express, Apollo, Fastify, Nest...>` | **Fastify + Apollo Server 5** (`@as-integrations/fastify`) |
| ORM/camada de dados | `<Sequelize, Prisma, TypeORM, knex...>` | `<versão alvo>` |
| Tipagem de GraphQL | `<manual / nenhuma>` | **GraphQL Codegen** (`@graphql-codegen/cli` + server-preset) |
| Logging | `<console / winston / bunyan...>` | **`pino`** (+ `pino-pretty` em dev) |
| Runner de testes | `<Mocha, Jest...>` | **Vitest** |
| Lint/format | `<ESLint, Prettier...>` | **oxlint** |
| Hooks de git | `<Husky, pre-push...>` | remover (gates → CI) |
| Infra | `<Dockerfile base, docker-compose, CI, nginx>` | `<imagem/ajustes>` |
| Libs internas/privadas | `<@org/* + registry>` | `<verificar compat.>` |

**Ferramentas de descoberta (read-only):**
- `knip` (`pnpm dlx knip`) → dependências, exports e arquivos **não utilizados**.
- `npm outdated` / `pnpm outdated` → defasagem de versões.
- `npm ls <pacote>` → quem depende de quê (deps transitivas).
- `grep`/busca por padrões depreciados (ex.: `sequelize.import`, `node-fetch`,
  `SchemaDirectiveVisitor`, `require(`, `console.log`).

---

## 2. Skills do projeto

Carregue e siga as skills versionadas em `.agents/skills/`. Elas são a fonte de verdade
para estilo de código, mensagens de commit e padrões de backend durante a migração.
**Ordem de resolução:** use o `.agents/skills/` do repo-alvo quando presente; caso o repo
ainda não tenha as skills versionadas, recorra à cópia **global** em `~/.claude/skills/`.

| Skill | Caminho no repo | Fallback global | Uso |
|---|---|---|---|
| Clean Code | `.agents/skills/clean-code` | `~/.claude/skills/clean-code` | nomes, funções pequenas, baixo acoplamento, sem código morto |
| Apollo Server | `.agents/skills/apollo-server` | `~/.claude/skills/apollo-server` | bootstrap, context/auth, data sources, plugins, error handling |
| NodeJS Backend Patterns | `.agents/skills/nodejs-backend-patterns` | `~/.claude/skills/nodejs-backend-patterns` | padrões de backend Node (erros, async) |
| Conventional Commits | `.agents/skills/conventional-commit` | `~/.claude/skills/conventional-commit` | mensagens de commit padronizadas (uma fase = um escopo) |

> **`skills-lock.json` (obrigatório):** mantenha na raiz do repositório um lockfile que
> fixa origem e hash de cada skill, garantindo reprodutibilidade entre máquinas/CI.
> O arquivo já existe neste repositório; ao iniciar uma nova migração, copie-o e ajuste
> as entradas conforme as skills realmente usadas. Formato:
>
> ```jsonc
> {
>   "version": 1,
>   "skills": {
>     "apollo-server":       { "source": "apollographql/skills",                "sourceType": "github", "skillPath": "skills/apollo-server/SKILL.md",       "computedHash": "<sha256>" },
>     "clean-code":          { "source": "sickn33/antigravity-awesome-skills",  "sourceType": "github", "skillPath": "skills/clean-code/SKILL.md",          "computedHash": "<sha256>" },
>     "conventional-commit": { "source": "github/awesome-copilot",              "sourceType": "github", "skillPath": "skills/conventional-commit/SKILL.md", "computedHash": "<sha256>" },
>     "nodejs-backend-patterns": { "source": "wshobson/agents",                 "sourceType": "github", "skillPath": "plugins/javascript-typescript/skills/nodejs-backend-patterns/SKILL.md", "computedHash": "<sha256>" }
>   }
> }
> ```

---

## 3. Pontos de decisão (resolver ANTES de codar)

Cada decisão muda profundamente o escopo. Documente a escolha e o porquê.

1. **TypeScript: migração total vs. incremental**
   - Alvo: **TypeScript `6.0.3`** (ou a versão estável mais nova compatível com o Node LTS).
   - *Incremental* (`allowJs`, renomear módulo a módulo): menor risco, convive com `.js`.
   - *Total* (renomear tudo para `.ts` numa fase): mais limpo, exige suíte de testes verde
     antes para detectar regressões. Em ambos: **proibido `any`** (ver Regras críticas).
2. **ESM nativo** — `"type":"module"`; ajustar `__dirname`, carregamento de assets não-JS
   (ex.: `.graphql`) e repontar testes/`start` para `src/`/`dist/`.
3. **Builder: esbuild vs. tsc**
   - Alvo: **esbuild** (bundle rápido para `dist/`, `format: "esm"`, `target: "node24"`,
     `packages: "external"`). `tsc` fica responsável apenas por **type-check** (`--noEmit`).
4. **Framework HTTP: Fastify vs. Express**
   - Alvo: **Fastify** + Apollo Server 5 via `@as-integrations/fastify` (`@3.1.0` ou a
     latest compatível com o Node LTS). Melhor performance e tipagem que Express.
5. **Versão do ORM: estável vs. major mais nova**
   - Prefira a **última estável madura** (ex.: Sequelize 6.x) a versões alpha/beta
     (ex.: Sequelize 7 / `@sequelize/core`) com breaking changes não estabilizadas.
6. **Estratégia para serviços acoplados/distribuídos** (subgraphs federados, libs
   compartilhadas): migração isolada (mantendo contrato/versão) vs. upgrade coordenado
   (janela de deploy conjunta).
7. **Sequenciamento**: faseado em PRs.
8. **Compatibilidade das libs internas/privadas** com o Node alvo — **pode ser bloqueador**.

---

## 4. Substituições de pacotes depreciados (catálogo)

Padrões comuns observados em serviços legados. **Confirme cada troca com o time** antes de
aplicar — especialmente as que mudam comportamento de runtime (validar por testes).

| Categoria | Padrão legado (depreciado/removido) | Substituto recomendado |
|---|---|---|
| Gerenciador de pacotes | npm + yarn em paralelo | **pnpm** (lockfile único, supply-chain) |
| Linguagem | JavaScript sem tipos | **TypeScript** (`6.0.3`) + tipagem explícita |
| Build | Babel (ESM→CJS), targets antigos | **esbuild** (bundle ESM) + `tsc --noEmit` (type-check) |
| Hot reload | `nodemon` / `babel-node` | **`tsx watch`** (TS) / `node --watch` (JS) |
| Git hooks | `husky`, `pre-push` | remover (mover gates para CI) |
| Lint | `eslint` + `babel-eslint` + plugins | **oxlint** |
| Testes | `mocha` + `nyc` + `should`/`chai` | **vitest** + `@vitest/coverage-v8` |
| Logging | `console.*`, `winston`, `bunyan`, `morgan` | **`pino`** (+ `pino-pretty` em dev) |
| HTTP client | `node-fetch`/`request`/`axios`(se desnecessário) | **`fetch` nativo** (Node 18+); `undici` Agent p/ TLS custom |
| Datas | `moment` (legado) | `luxon` / `date-fns` / `Temporal` |
| Servidor GraphQL | Apollo Server 2/3 (`apollo-server-*`) | `@apollo/server` 5 + **`@as-integrations/fastify`** |
| Framework HTTP | Express puro / `apollo-server-express` | **Fastify** |
| Federation | `@apollo/federation` (`buildFederatedSchema`) | `@apollo/subgraph` (`buildSubgraphSchema`) |
| Schema GraphQL | `merge-graphql-schemas`, `graphql-tools` v4 | `@graphql-tools/*` escopados (`load-files`, `merge`, `utils`) |
| Diretivas GraphQL | `SchemaDirectiveVisitor` | `mapSchema` + `getDirective` (`@graphql-tools/utils`) |
| Tipagem GraphQL | tipos manuais / ausentes | **`@graphql-codegen/cli`** + **`@eddeee888/gcg-typescript-resolver-files`** |
| Data sources GraphQL | `apollo-datasource` (`DataSource`) | classe simples injetada no `context` (tipada) |
| ORM | `sequelize@5` (`sequelize.import`) | `sequelize@6.x` (carregamento por factory) |
| Driver Postgres | `pg@7` | `pg@8` |
| Auth/JWT | `jsonwebtoken@8` | `jsonwebtoken@9` |
| Deps mortas | qualquer lib não importada (confirmar com `knip`) | remover |

> **Regra de ouro para depreciados sem sucessor compatível:** se um pacote não tem versão
> compatível com o Node alvo **e** a funcionalidade é simples, avalie uma implementação
> própria enxuta (sem dependência) em vez de adotar outra lib — reduz superfície de
> breaking changes futuras. Para funcionalidade complexa, escolha um substituto mantido e
> peça aprovação.

---

## 5. Regras críticas de tipagem (TypeScript)

> Aplicam-se a **toda** mudança a partir da fase de TypeScript. São inegociáveis.

- **SEMPRE mantenha o código tipado** com base nas interfaces e tipos criados. Identifique
  pontos sem tipagem (retornos de funções, args, `context`, models, resolvers, payloads de
  rede) e **crie `interface`/`type` explícitos**.
- **NUNCA use o tipo `any`.** Prefira tipos concretos; quando o tipo for genuinamente
  desconhecido, use `unknown` + narrowing, generics ou tipos de união. `any` proibido
  inclusive em assinaturas de bibliotecas — crie wrappers tipados.
- **SEMPRE pense na Developer Experience (DX):** tipos que dão autocomplete e erros úteis,
  schema GraphQL como fonte de verdade (tipos gerados por codegen, não duplicados à mão),
  `tsx` para feedback rápido em dev, e erros de tipo pegos no build/CI antes do deploy.
- Habilite `strict: true` no `tsconfig`. Trate `noImplicitAny`, `strictNullChecks` e
  `noUncheckedIndexedAccess` como aliados, não obstáculos.

---

## 6. Fases de execução (template)

> Ordene da menor para a maior superfície de risco. Cada fase = 1+ PR, com build/lint/testes
> verdes antes do merge (commits seguindo a skill **Conventional Commits**). Ajuste/remova
> fases conforme o stack do repositório.

### Fase 0 — Preparação, bloqueadores e skills
- Carregar skills (`.agents/skills/*`) e validar/copiar **`skills-lock.json`**.
- Verificar compatibilidade das **libs internas/privadas** com o Node alvo no registry. Se
  não houver versão compatível, **parar e alinhar** com os times donos.
- Atualizar `.nvmrc` e adicionar `"engines": { "node": ">=<alvo>" }` ao `package.json`.
- Rodar `knip` para inventário de itens não usados (deps, arquivos órfãos, exports).

### Fase 1 — Gerenciador de pacotes + tooling base (não muda runtime)
- Migrar para **pnpm**: gerar `pnpm-lock.yaml`; remover `package-lock.json`/`yarn.lock`.
  Preservar registries escopados e auth (ex.: token de CI) no `.npmrc`.
- Remover **husky**/`pre-push`/`nodemon`.
- Adotar **oxlint** (config base na seção 7); ajustar script `lint`.
- Criar **`.editorconfig`** na raiz (seção 7) para padronizar indentação/EOL/charset.
- **Validação:** `pnpm install`, `pnpm lint`.

### Fase 2 — ESM nativo
- `"type": "module"`; remover `.babelrc` e deps `babel*`.
- Trocar `__dirname`/`__filename` por `import.meta.url` + `fileURLToPath`.
- Substituir carregadores que dependiam de plugins de build (ex.: import de `.graphql`,
  globs de arquivos) por equivalentes em runtime (`@graphql-tools/load-files`, `fs`).
- Converter `require(...)` remanescentes para `import`.
- Introduzir o **esbuild** como builder (`esbuild.config.mjs`, seção 7: `format: "esm"`,
  `target: "node<alvo>"`, `packages: "external"`) e adicionar o script `build`; é nesta
  fase que ele entra, pois o bundle ESM depende do `"type": "module"` recém-ativado. O
  `start` passa a apontar para o artefato (`node dist/server.js`).
- **Validação:** o serviço sobe a partir do artefato em `dist/`: `pnpm build` gera o
  bundle ESM e `pnpm start` (`node dist/server.js`) inicializa sem erros. Em dev, o watch
  roda direto do fonte (`node --watch src/server.js`, ou `tsx watch` após a fase de
  TypeScript). Garanta que assets não-JS (ex.: `.graphql`) sejam resolvidos em runtime
  (loader/`fs`), já que `packages: "external"` não os empacota.

### Fase 3 — ORM / camada de dados
- Subir o ORM para a versão alvo estável e o driver correspondente.
- Refatorar carregamento de models/migrations conforme a nova API (remover `sequelize.import`).
- Revisar operadores, paginação, hooks, transações e tipos (ex.: ENUMs).
- **Validação:** subir DB de teste, rodar migrations e um sync/seed.

### Fase 4 — Framework principal: Apollo Server 5 + Fastify (maior risco)
- Reescrever o bootstrap para **Fastify** + Apollo Server 5 via `@as-integrations/fastify`
  (`fastifyApolloHandler`/`fastifyApolloDrainPlugin`); montar `context`, plugins e
  `formatError` na nova assinatura.
- Migrar extensões/customizações (diretivas, data sources, middlewares) para os novos
  mecanismos, **preservando exatamente o comportamento** (auth, roles, mascaramento de erro).
- <critical>**SE A API FOR GRAPHQL, SEMPRE INTEGRE O FASTIFY CORRETAMENTE COM O FLUXO DA API GRAPHQL**</critical>.
- Em serviços distribuídos/federados, ajustar contrato/schema e **coordenar com o gateway**.
- **Validação:** introspecção/contrato; smoke de rotas autenticadas e operações críticas.

### Fase 5 — Demais dependências e logging
- Migrar HTTP client para `fetch` nativo (atenção: `agent` do node-fetch →
  `dispatcher`/`undici.Agent` no nativo).
- Adotar **`pino`** como logger; usar **`pino-pretty`** apenas em dev (transport). Remover
  `console.*`/`winston`/`morgan`. Logar em JSON estruturado em produção.
- Subir libs utilitárias (datas, JWT, validadores, cache/redis, mensageria) para majors
  compatíveis, validando breaking changes pontuais.
- Remover deps mortas confirmadas pelo `knip`.

### Fase 6 — Testes
- Adotar **Vitest** (+ coverage v8); criar `vitest.config`.
- Migrar arquivos de teste: repontar imports, converter `require/var` → `import`, ajustar
  `describe/it/hooks`, substituir a lib de assertion. Manter o compatível (ex.: `nock`).
- **Corrigir** testes quebrados até a suíte passar verde (necessário antes da Fase 8).

### Fase 7 — Infra (Docker, CI, proxy)
- **Dockerfile**: imagem base `node:<alvo>-alpine`; usar pnpm (`corepack` +
  `pnpm i --frozen-lockfile`); rodar o build **esbuild** já configurado na Fase 2 e servir
  de `dist/` (lembre que `packages: "external"` exige `node_modules` no estágio de runtime).
- **docker-compose / comandos de start**: usar pnpm; sem yarn/npm.
- **CI**: ajustar imagens/cache para pnpm e **adicionar stage de lint + type-check + testes**
  como quality gate antes do deploy.
- Proxy/observabilidade (nginx/sonar): revisar só se portas/artefatos mudarem.

### Fase 8 — Migração para TypeScript
- Instalar `typescript@6.0.3` (+ `@types/node` do Node LTS e `@types/*` das libs sem tipos).
- Criar `tsconfig.json` (seção 7) com `strict: true`; renomear `.js` → `.ts` (total ou
  incremental via `allowJs`).
- **Criar `interface`/`type`** para models, `context`, data sources, payloads e retornos —
  seguindo as **Regras críticas (seção 5): zero `any`**.
- Adotar **`tsx watch`** como runtime de dev; apontar o `entryPoints` do esbuild de
  `.js` → `.ts` (build já existente desde a Fase 2); `tsc --noEmit` para type-check no CI.
- **Validação:** `pnpm type-check` sem erros; serviço sobe via `tsx` e build via esbuild.

### Fase 9 — Tipagem de GraphQL com Codegen (schema = fonte de verdade)

Objetivo: gerar tipos a partir do SDL e **tipar os resolvers com os tipos gerados**, sem
duplicar tipos à mão. Escolha a variante conforme **como os resolvers são carregados**:

**Variante A (padrão) — server-preset.** `@graphql-codegen/cli` +
`@eddeee888/gcg-typescript-resolver-files`; o preset gera tipos + **arquivos de resolver
tipados por módulo** (referência:
https://the-guild.dev/graphql/codegen/docs/guides/graphql-server-apollo-yoga-with-server-preset).
Use quando o projeto pode adotar a estrutura de arquivos do preset.

**Variante B — single-file + `mappers` (ORM).** Quando os resolvers são carregados por **glob
em runtime** (ex.: `@graphql-tools/load-files` casando `**/*.{js,ts}`), o server-preset é
**incompatível** — ele *é dono* dos arquivos de resolver por módulo e reescreveria a estrutura
de `src/`. Use então `@graphql-codegen/cli` + plugins `typescript` + `typescript-resolvers`
emitindo **um único** `types.generated.ts` (fora do glob de resolvers), com:
- `mappers`: liga cada tipo de objeto do SDL à classe do model (ex.: Sequelize) → o
  `parent`/retorno do resolver passa a ser a **instância do model**;
- `contextType`: aponta para o tipo de `context` da app;
- `defaultMapper: 'Partial<{T}>'` p/ tipos sem model (paginations, edges, responses,
  Query/Mutation); `scalars` p/ escalares custom; `federation: true` se subgraph;
- `useTypeImports: true` se `verbatimModuleSyntax`.

**Padrão de tipagem dos resolvers (sobretudo na Variante B):**
- Tipar o mapa do módulo com `Resolvers` (o agregado **já compõe** `QueryResolvers`/
  `MutationResolvers`/`<Tipo>Resolvers`; o codegen **não** gera um tipo "por módulo" — não o
  monte à mão com `Pick`, é duplicar o SDL).
- `const x: Resolvers = {…}` no caso normal; **`… satisfies Resolvers`** quando o módulo é
  **consumido por outro resolver/helper** (chamada resolver→resolver). `satisfies` preserva o
  tipo literal **chamável** (métodos seguem funções, grupos presentes); `: Resolvers` os alarga
  para `Resolver<>` (união **não-chamável**) e quebra a chamada direta.
- **Auto-referência** (um resolver chamando métodos irmãos no próprio objeto) quebra a inferência
  do `satisfies` (TS7022) → **extraia** a lógica compartilhada para um `*-helper.ts` e chame-a
  dos dois lados (resolver e chamador).
- Interfaces manuais, **3 baldes**: (1) **derivadas do schema** (args/parent/input/shape de
  model/DB) → **remover** e usar codegen + models; (2) **respostas externas (proxy HTTP)** →
  **manter**, tipadas (espelhar os campos da query); (3) **sombras de infra** (logger/redis/
  publisher/`Context & { transaction }`) → **remover** e usar o `context` tipado.
- Ajustes dirigidos pelo tipo: `ID`→`string` (coagir `Number()` p/ FK numérica em where/create,
  `String()` em cursor); args opcionais → `?? default` + guardas; `__resolveReference` resolve
  pela **chave de federação** (`findByPk(parent.id)`); `model.build({…})` p/ instâncias
  sintéticas; `!!(await x.update())` (aguardar a Promise, não `!!promise`).
- **Mudanças de apoio** no mesmo PR quando o tipo exigir: declarar FKs com o brand `ForeignKey<>`
  no model; alargar assinaturas de helpers; adicionar campos ao tipo de `context` (ex.:
  `transaction`, cliente Redis/infra real em vez de uma interface "mínima").
- A tipagem **expõe bugs latentes** (chave de registry errada, resolver de tipo/campo
  inexistente no SDL, arg fantasma fora do SDL, `!!promise` sem `await`) — corrija os exigidos
  pelo tipo e **sinalize os demais** ao humano; não corrija bugs fora de escopo sem combinar.

**Granularidade:** **um resolver por PR** (não tipar todos de uma vez). Adicionar script
`codegen` (+`--watch` em dev); rodar no CI p/ detectar drift entre schema e resolvers.

- **Validação:** `pnpm codegen` sem drift; `tsc --noEmit` verde; `grep "as unknown"` zerado no
  arquivo (salvo borda justificada, ex.: projeção de SQL cru via `literal`).

### Fase 10 — Documentação do projeto: `CLAUDE.md` + `README.md` (OBRIGATÓRIO)

> Ao final da migração, o repositório precisa **documentar o novo stack** em dois públicos
> distintos: **agentes** (`CLAUDE.md` — escopo/regras) e **pessoas** (`README.md` — setup e
> visão geral). Os dois são complementares: o `CLAUDE.md` é contexto enxuto e factual para o
> Claude Code; o `README.md` é a porta de entrada humana do repositório.

#### 10.a `CLAUDE.md` — escopo e regras (para agentes)

> Crie (ou atualize) o arquivo **`CLAUDE.md` na raiz** refletindo o estado **pós-migração** —
> ele passa a ser a fonte de verdade de escopo/regras consumida automaticamente pelo Claude
> Code em sessões futuras.

- **Se o `CLAUDE.md` não existir:** crie-o na raiz.
- **Se já existir:** **atualize-o** removendo referências ao stack legado (Node antigo,
  Babel, Mocha, npm/yarn, Apollo 2/3, `console.*` etc.) e descrevendo a stack-alvo real.
- Mantenha-o **enxuto e factual** — é contexto para o agente, não documentação extensa.
  Não duplique o conteúdo deste guia; aponte para ele e para as skills.

**Conteúdo mínimo do `CLAUDE.md`:**
1. **Visão geral do stack** (pós-migração): Node LTS (alvo), TypeScript + ESM nativo,
   esbuild (build) + `tsc --noEmit` (type-check), `tsx watch` (dev), Fastify + Apollo
   Server 5, ORM/versão, pnpm, Vitest, oxlint, pino, GraphQL Codegen.
2. **Comandos do dia a dia** (a partir dos scripts do `package.json`): `pnpm dev`,
   `pnpm build`, `pnpm start`, `pnpm type-check`, `pnpm lint`, `pnpm test`, `pnpm codegen`.
3. **Regras inegociáveis:** zero `any` (§5); schema GraphQL como fonte de verdade (tipos via
   codegen, nunca duplicados à mão); commits **Conventional**; **uma mudança estrutural por
   PR**; gates de lint + type-check + testes verdes antes de merge.
4. **Estrutura do projeto:** onde ficam `src/`, schema `.graphql`, models, resolvers,
   tipos gerados (`*.generated.ts`), testes e configs.
5. **Skills do projeto:** apontar para `.agents/skills/*` e o `skills-lock.json` como
   padrões a seguir (clean-code, apollo-server, nodejs-backend-patterns,
   conventional-commit).
6. **Pegadinhas/observações** relevantes (ex.: `packages: "external"` exige `node_modules`
   no runtime; assets `.graphql` resolvidos por loader/`fs`).

- **Validação:** `CLAUDE.md` presente na raiz, sem menção ao stack legado, com comandos que
  batem com o `package.json` atual. Ver modelo na seção 7.

#### 10.b `README.md` — porta de entrada do projeto (para pessoas)

> Crie (ou atualize) o **`README.md` na raiz** refletindo o novo escopo do repositório.
> **Se já existir:** atualize-o removendo instruções do stack legado (npm/yarn, `nvm use 12`,
> `npm test` com Mocha, build via Babel etc.) e descrevendo o fluxo atual. O foco é deixar
> **explícito e bem explicado o fluxo de setup** e dar uma **introdução/resumo** do projeto.

**Estrutura mínima do `README.md` (padrão):**
1. **Título + introdução/resumo:** o que o serviço faz, em uma a três frases (domínio, tipo
   de API — REST/GraphQL —, papel na arquitetura/quais serviços consome/expõe).
2. **Stack:** lista enxuta da tecnologia (Node LTS, TypeScript/ESM, Fastify + Apollo 5, ORM,
   pnpm, Vitest, oxlint, pino, Codegen).
3. **Pré-requisitos:** versão do Node (referenciando o `.nvmrc`), `pnpm` (via `corepack`),
   serviços externos (Postgres/Redis), e variáveis de ambiente (apontar para `.env_example`).
4. **Setup passo a passo (explícito):** clonar → selecionar Node (`nvm use`) → habilitar pnpm
   (`corepack enable`) → `pnpm install` → copiar `.env_example` → `.env` e preencher → subir
   dependências (ex.: `docker-compose up -d db`) → rodar migrations/seeds → `pnpm dev`.
   Cada passo com o **comando exato** e o resultado esperado.
5. **Scripts disponíveis:** tabela mapeando os scripts do `package.json` (`dev`, `build`,
   `start`, `type-check`, `lint`, `test`, `codegen`) ao que cada um faz.
6. **Rodando com Docker:** build da imagem `node:<alvo>` e `docker-compose up`, se aplicável.
7. **Testes e qualidade:** como rodar `pnpm test`, `pnpm lint`, `pnpm type-check` localmente
   (os mesmos gates do CI).
8. **Estrutura de pastas** (resumo) e **como contribuir** (commits Conventional, um escopo
   por PR, gates verdes antes do merge).

- **Validação:** o `README.md` permite a um dev **novo** subir o projeto do zero seguindo só
  o passo a passo, sem instruções do stack legado; comandos batem com o `package.json`. Ver
  modelo na seção 7.

---

## 7. Configs de referência

**`.oxlintrc.json` (base sugerida):**
```json
{
  "$schema": "./node_modules/oxlint/configuration_schema.json",
  "plugins": ["typescript"],
  "categories": {},
  "rules": {
    "eqeqeq": "warn",
    "no-console": "warn",
    "no-unused-vars": ["warn", { "argsIgnorePattern": "^_" }],
    "typescript/no-explicit-any": "error"
  },
  "overrides": [
    {
      "files": ["test/**/*.ts", "**/*.test.ts", "**/migrations/**", "**/seeders/**"],
      "rules": { "no-console": "off", "no-unused-vars": "off" }
    }
  ],
  "env": { "builtin": true, "node": true, "es2024": true },
  "globals": {},
  "ignorePatterns": ["dist/**", "coverage/**", ".scannerwork/**", "src/schema/**/*.generated.ts"]
}
```

**`.editorconfig` (padroniza indentação/EOL entre editores):**
```ini
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
```

**`tsconfig.json` (ESM nativo, type-check via tsc; emit via esbuild):**
```jsonc
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ESNext"],
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "noEmit": true,            // esbuild faz o emit; tsc só checa tipos
    "verbatimModuleSyntax": true,
    "allowImportingTsExtensions": true  // permite imports com extensão .ts (válido com noEmit)
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
```

**`esbuild.config.mjs` (builder do projeto):**
```js
import { build } from "esbuild";
import fs from "fs";

// Clean dist folder before building
if (fs.existsSync("dist")) {
  fs.rmSync("dist", { recursive: true });
}

await build({
  entryPoints: ["src/server.ts"],
  outdir: "dist",
  bundle: true,
  packages: "external",
  platform: "node",
  format: "esm",
  target: "node24",
  sourcemap: false,
  logLevel: "info",
});
```

**`codegen.ts` (server-preset com resolver files tipados):**
```ts
import type { CodegenConfig } from "@graphql-codegen/cli";
import { defineConfig } from "@eddeee888/gcg-typescript-resolver-files";

const config: CodegenConfig = {
  schema: "src/**/*.graphql",
  generates: {
    "src/schema": defineConfig({
      // gera tipos + arquivos de resolver tipados a partir do SDL
      resolverGeneration: "minimal",
    }),
  },
};

export default config;
```

**`codegen.ts` (Variante B — single-file + `mappers`, p/ resolvers carregados por glob):**
```ts
import type { CodegenConfig } from "@graphql-codegen/cli";

const config: CodegenConfig = {
  schema: "src/resources/**/*.graphql",
  generates: {
    "src/__generated__/types.generated.ts": {
      plugins: ["typescript", "typescript-resolvers"],
      config: {
        federation: true,
        useTypeImports: true, // verbatimModuleSyntax
        contextType: "../types/graphql-context.ts#GraphQLContext",
        mappers: {
          // cada tipo de objeto do SDL → classe do model (parent/retorno = instância do model)
          Cooperative: "../db/models/cooperative.ts#SequelizeCooperative",
          // ...demais entidades com model
        },
        scalars: { EmailType: "string" },
        defaultMapper: "Partial<{T}>", // tipos sem model (paginations, edges, responses, Query/Mutation)
      },
    },
  },
};

export default config;
```
> O `types.generated.ts` fica **fora** do glob de resolvers (ex.: em `src/__generated__/`),
> senão o `loadFiles` o interpretaria como typeDefs/resolvers em runtime.

**Scripts `package.json` (alvo típico: TypeScript + ESM + esbuild):**
```jsonc
{
  "type": "module",
  "engines": { "node": ">=<alvo>" },
  "scripts": {
    "start": "node dist/server.js",
    "dev": "tsx watch src/server.ts",
    "build": "node esbuild.config.mjs",
    "type-check": "tsc --noEmit",
    "codegen": "graphql-codegen --config codegen.ts",
    "codegen:watch": "graphql-codegen --config codegen.ts --watch",
    "lint": "oxlint",
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

**Logger `pino` (JSON em prod, pretty em dev):**
```ts
import pino from "pino";

const isDev = process.env.NODE_ENV !== "production";

export const logger = pino(
  isDev
    ? { level: "debug", transport: { target: "pino-pretty", options: { colorize: true } } }
    : { level: process.env.LOG_LEVEL ?? "info" },
);
```

**`CLAUDE.md` (modelo de escopo/regras na raiz — preencher com o estado real):**
```md
# <nome-do-serviço>

Serviço <REST/GraphQL> em Node.js. Este arquivo é o contexto de escopo e regras para
agentes e devs. Para o passo a passo da migração, ver `guia-migracao-base.md`.

## Stack
- Runtime: Node <LTS alvo> (ESM nativo, `"type": "module"`)
- Linguagem: TypeScript <versão> — `strict: true`, **zero `any`**
- Build: esbuild (`dist/`, ESM) · Type-check: `tsc --noEmit`
- Dev: `tsx watch`
- API: Fastify + Apollo Server 5 (`@as-integrations/fastify`)  <!-- se GraphQL -->
- Dados: <ORM + versão> · Driver: <ex.: pg 8>
- Pacotes: pnpm · Testes: Vitest · Lint: oxlint · Log: pino · GraphQL: codegen

## Comandos
- `pnpm dev` — dev com watch
- `pnpm build` — bundle esbuild em `dist/`
- `pnpm start` — sobe de `dist/`
- `pnpm type-check` — `tsc --noEmit`
- `pnpm lint` — oxlint
- `pnpm test` — Vitest
- `pnpm codegen` — gera tipos de GraphQL a partir do SDL

## Regras
- **Nunca** usar `any`; tipar tudo (models, context, resolvers, payloads).
- Schema GraphQL é a fonte de verdade — tipos via codegen, **não** duplicados à mão.
- Commits no padrão **Conventional Commits**.
- **Uma mudança estrutural por PR**; gates (lint + type-check + testes) verdes antes do merge.

## Estrutura
- `src/` — código · `src/**/*.graphql` — SDL · `src/schema/**/*.generated.ts` — tipos gerados
- models / resolvers / data sources: <caminhos>
- `test/` — testes (Vitest)

## Skills do projeto
Seguir as skills em `.agents/skills/*` (fixadas em `skills-lock.json`):
clean-code · apollo-server · nodejs-backend-patterns · conventional-commit.

## Observações
- esbuild usa `packages: "external"` → `node_modules` precisa existir no runtime.
- Assets `.graphql` são resolvidos em runtime (loader/`fs`), não empacotados.
```

**`README.md` (modelo de porta de entrada na raiz — preencher com o estado real):**
```md
# <nome-do-serviço>

<Uma a três frases: o que o serviço faz, tipo de API (REST/GraphQL), papel na
arquitetura — o que expõe/consome.>

## Stack
- Node <LTS alvo> · TypeScript <versão> (ESM nativo)
- Fastify + Apollo Server 5 (GraphQL)  ·  <ORM + versão> + <driver>
- pnpm · esbuild · Vitest · oxlint · pino · GraphQL Codegen

## Pré-requisitos
- Node <alvo> (use `nvm use` — versão fixada no `.nvmrc`)
- pnpm (via `corepack enable`)
- <Postgres / Redis / outros serviços> — ou via Docker Compose
- Variáveis de ambiente: copie `.env_example` para `.env`

## Setup
\`\`\`bash
git clone <repo> && cd <repo>
nvm use                      # Node da versão do .nvmrc
corepack enable              # habilita o pnpm
pnpm install                 # instala dependências
cp .env_example .env         # configure as variáveis
docker-compose up -d db      # sobe o banco (se aplicável)
pnpm <migrate>               # roda migrations/seeds
pnpm dev                     # sobe em modo watch (tsx)
\`\`\`
Serviço disponível em <http://localhost:PORT> (GraphQL em `/graphql`).

## Scripts
| Script | O que faz |
|---|---|
| `pnpm dev` | dev com watch (`tsx`) |
| `pnpm build` | bundle de produção (esbuild → `dist/`) |
| `pnpm start` | sobe a partir de `dist/` |
| `pnpm type-check` | checagem de tipos (`tsc --noEmit`) |
| `pnpm lint` | oxlint |
| `pnpm test` | testes (Vitest) |
| `pnpm codegen` | gera tipos de GraphQL a partir do SDL |

## Docker
\`\`\`bash
docker-compose up --build
\`\`\`

## Qualidade
Antes de abrir PR: `pnpm lint`, `pnpm type-check` e `pnpm test` verdes (mesmos gates do CI).

## Estrutura
- `src/` — código · `src/**/*.graphql` — SDL · `test/` — testes
- <models / resolvers / data sources: caminhos>

## Contribuição
Commits no padrão **Conventional Commits**; **uma mudança estrutural por PR**; gates verdes
antes do merge.
```

---

## 8. Checklist de verificação ponta a ponta (por fase e no fim)

- [ ] `pnpm install --frozen-lockfile` sem erros.
- [ ] `pnpm lint` (oxlint) sem erros — **incluindo `no-explicit-any`**.
- [ ] `pnpm type-check` (`tsc --noEmit`) sem erros.
- [ ] `pnpm codegen` gera tipos de GraphQL sem drift.
- [ ] `pnpm build` (esbuild) gera `dist/` e `pnpm start` sobe a partir dele.
- [ ] `pnpm test` (Vitest) verde, cobrindo os fluxos críticos.
- [ ] Serviço sobe e `/healthcheck` (ou equivalente) responde 200.
- [ ] Contrato externo validado (REST/SDL GraphQL/contrato de fila) — **sem quebra de assinatura**.
- [ ] Smoke manual de auth + operação crítica (incl. transações de banco).
- [ ] Imagem Docker `node:<alvo>` builda e migrations rodam no ambiente de teste.
- [ ] Pipeline de CI verde com o novo stage de lint + type-check + testes.
- [ ] `skills-lock.json` presente e coerente com `.agents/skills/`.
- [ ] `CLAUDE.md` na raiz criado/atualizado com o stack pós-migração e regras (Fase 10.a).
- [ ] `README.md` na raiz criado/atualizado com intro + fluxo de setup explícito (Fase 10.b).
- [ ] Cada fase executada por um **sub-agent** dedicado, com resumo reportado ao orquestrador (§0.1).

---

## 9. Riscos recorrentes a vigiar

- **Libs internas/privadas** sem versão compatível com o Node alvo → bloqueador; alinhar cedo.
- **Serviços acoplados** (federation, contratos de fila, libs compartilhadas) → exigem
  coordenação de deploy; nunca migrar isoladamente sem validar o contrato.
- **`any` vazando** ao migrar para TypeScript (especialmente em libs sem tipos e no
  `context`) → proíba via lint; use `unknown` + narrowing e wrappers tipados.
- **Drift entre schema GraphQL e resolvers** → mantenha o codegen no CI; schema é a fonte
  de verdade, tipos não devem ser duplicados à mão.
- **Tipagem de resolvers (Variante B/mappers)**: server-preset incompatível com carregamento por
  glob; `: Resolvers` quebra chamadas resolver→resolver (use `satisfies` nos consumidos);
  auto-referência + `satisfies` = TS7022 (extrair p/ helper); a tipagem expõe bugs latentes
  (chave de registry errada, resolver de tipo/campo fora do SDL, arg fantasma, `!!promise` sem
  `await`) — corrigir os exigidos pelo tipo e sinalizar o resto.
- **Diferenças sutis de API** ao trocar libs (`agent` → `dispatcher` no fetch nativo;
  assinatura de `formatError`; integração Apollo Express → **Fastify**; remoção de
  `sequelize.import`).
- **ESM + esbuild**: `packages: "external"` não empacota deps — garanta `node_modules` no
  runtime; cuidado com imports de assets não-JS (`.graphql`) que precisam de loader/`fs`.
- **ENUMs e tipos de banco** em upgrades de ORM.
- **Testes acoplados a `dist/`** quebram ao migrar para ESM/`src/`/TypeScript.
- **Perda de cobertura silenciosa** ao migrar runner de testes — conferir o relatório.
