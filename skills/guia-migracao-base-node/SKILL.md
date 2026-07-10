---
name: guia-migracao-base-node
description: >
  Playbook de migração/modernização de serviços Node.js legados para Node LTS + TypeScript +
  ESM nativo + esbuild + Fastify/Apollo Server 5 + pnpm + Vitest + oxlint + pino + GraphQL
  Codegen. Use esta skill quando o usuário pedir para migrar, modernizar, atualizar o stack ou
  "subir versão" de um repositório Node.js. A execução é feita inline, na própria sessão de chat,
  fase a fase (uma fase = um PR), sob controle e validação humana a cada passo.
metadata:
  author: curia
  version: "1.1.0"
allowed-tools: Bash Read Write Edit Glob Grep
---

# Migração de Repositórios Node.js → Node LTS + TypeScript

Skill reutilizável para modernizar serviços Node.js legados. Stack-alvo de referência:
**Node LTS 24**, **TypeScript 6.0.3**, **ESM nativo**, **esbuild** (build), **tsx** (dev
watch), **Apollo Server 5 + Fastify**, **pnpm**, **Vitest**, **oxlint**, **pino** e
**GraphQL Codegen**.

> **Guia base completo (embarcado):** [`references/guia-migracao-base.md`](references/guia-migracao-base.md)
> — leia-o para os detalhes de cada fase, os blocos de config prontos e os modelos de
> `CLAUDE.md`/`README.md`. Esta SKILL é a versão acionável e resumida desse guia.

## Quando usar
- O usuário pede para **migrar/modernizar/atualizar** o stack de um serviço Node.js.
- Subir versão de Node, trocar gerenciador de pacotes, migrar para TypeScript/ESM, trocar
  framework HTTP/GraphQL, runner de testes, lint ou logging.

---

## Governança: validação humana e commits (OBRIGATÓRIO — precede tudo)

Estas regras são **inegociáveis** e têm prioridade sobre qualquer outra etapa do playbook:

1. **Migração 100% por PRs.** Toda mudança da migração entra exclusivamente via Pull Request —
   **uma fase = um PR**. Nada vai direto para branches protegidas (`master`/`develop`/`stage`).
2. **Aprovação humana por implementação.** Cada fase/PR só avança após **validação humana
   explícita**. O agente apresenta o resumo da fase (diff, gates, riscos) e **aguarda o "ok" do
   humano** antes de seguir para a próxima fase.
3. **Nunca commitar nem dar push sem validação humana.** O agente **não executa** `git commit`
   nem `git push` por conta própria. Ele prepara as mudanças, mostra o que será commitado/enviado
   e só roda `commit`/`push` **após o humano autorizar**. Sem autorização, pare e pergunte.
4. **Sem rodapé de co-autoria de LLM.** As mensagens de commit **não devem conter** rodapés do
   tipo `Co-Authored-By: Claude ...` nem `🤖 Generated with Claude Code` ou equivalentes. Use
   apenas a mensagem Conventional Commit limpa, sem assinatura de agente.

---

## Modelo de execução: INLINE, na sessão de chat (sob controle humano)

**A migração é executada inline, na própria sessão de chat — NÃO delegue fases a sub-agents.**
Toda a implementação acontece na conversa corrente, com o humano acompanhando e validando cada
passo. Não use a ferramenta `Agent`/sub-agents para conduzir as fases.

**Fluxo por fase (uma fase = um PR):**
1. Faz o **Inventário** (§Inventário) e consolida os **Pontos de decisão** — definem a estratégia.
2. **Cria/atualiza o `migrate-checklist.md` na raiz do projeto-alvo** (ver §Checklist de
   migração) listando todas as fases como tarefas `[ ]` antes de começar a implementar.
3. Executa **uma fase de cada vez**, do início ao gate, diretamente na sessão: ler arquivos,
   aplicar mudanças, rodar build/lint/type-check/testes.
4. **Valida o gate** da fase (build/lint/type-check/testes verdes) e **apresenta o resumo
   (diff, gates, riscos) ao humano**.
5. **Marca a tarefa correspondente como concluída (`[x]`) no `migrate-checklist.md`** assim que a
   implementação estiver pronta **com os gates passando**.
6. **Aguarda a validação humana explícita** antes de commitar/abrir o PR e antes de iniciar a
   próxima fase (ver §Governança). Sem o "ok", pare e pergunte.
7. Mantém a visão de ponta a ponta: ordem dos PRs, decisões pendentes, bloqueadores.

> **Princípio geral:** uma mudança estrutural por PR. Não misturar gerenciador de pacotes +
> framework + TypeScript + testes no mesmo PR.

---

## Inventário inicial (preencher antes de planejar)

| Item | Atual | Alvo |
|---|---|---|
| Node | `<ex: 12.x>` | `<LTS, ex: 24>` |
| Gerenciador de pacotes | `<npm/yarn>` | `pnpm` |
| Linguagem | `<JS/TS>` | **TypeScript** (`6.0.3`) |
| Módulos | `<CJS/ESM-Babel>` | **ESM nativo** |
| Build | `<Babel/tsc/nenhum>` | **esbuild** (+ `tsc --noEmit`) |
| Dev watch | `<nodemon>` | **`tsx watch`** / `node --watch` |
| Framework HTTP/API | `<Express/Apollo/...>` | **Fastify + Apollo Server 5** |
| ORM | `<Sequelize/Prisma/...>` | `<versão estável madura>` |
| Tipagem GraphQL | `<manual/nenhuma>` | **GraphQL Codegen** (server-preset) |
| Logging | `<console/winston>` | **`pino`** |
| Testes | `<Mocha/Jest>` | **Vitest** |
| Lint/format | `<ESLint/Prettier>` | **oxlint** |
| Git hooks | `<Husky>` | remover (gates → CI) |
| Libs internas/privadas | `<@org/*>` | verificar compat. com Node alvo |

**Descoberta read-only:** `pnpm dlx knip` (deps/arquivos/exports não usados),
`pnpm outdated`, `npm ls <pkg>`, grep por padrões legados (`sequelize.import`, `node-fetch`,
`SchemaDirectiveVisitor`, `require(`, `console.log`).

---

## Skills do projeto (carregar e seguir)

Fonte de verdade de estilo/commits/arquitetura. **Ordem de resolução:** primeiro o
`.agents/skills/` do repo-alvo (versionado e fixado em `skills-lock.json` — manter coerente);
se não existir no repo, usar a cópia **global** em `~/.claude/skills/` como fallback. As skills
globais já ficam disponíveis ao agente; o `.agents/skills/` local existe para versionar a fonte
junto ao código migrado.

| Skill | Caminho no repo | Fallback global | Uso |
|---|---|---|---|
| Clean Code | `.agents/skills/clean-code` | `~/.claude/skills/clean-code` | nomes, funções pequenas, sem código morto |
| Apollo Server | `.agents/skills/apollo-server` | `~/.claude/skills/apollo-server` | bootstrap, context/auth, data sources, plugins |
| NodeJS Backend Patterns | `.agents/skills/nodejs-backend-patterns` | `~/.claude/skills/nodejs-backend-patterns` | erros, async, padrões backend |
| Conventional Commits | `.agents/skills/conventional-commit` | `~/.claude/skills/conventional-commit` | commits (uma fase = um escopo) |

---

## Pontos de decisão (resolver ANTES de codar)

1. **TypeScript** total vs. incremental (`allowJs`). Em ambos: **proibido `any`**.
2. **ESM nativo** (`"type":"module"`): ajustar `__dirname`, loaders de `.graphql`, paths de start/test.
3. **Builder**: esbuild (bundle ESM, `target: node<alvo>`, `packages: "external"`); `tsc` só type-check.
4. **Framework HTTP**: Fastify + Apollo 5 via `@as-integrations/fastify`.
5. **ORM**: última estável madura (ex.: Sequelize 6.x), não alpha/beta.
6. **Serviços acoplados/federados**: migração isolada vs. upgrade coordenado com gateway.
7. **Sequenciamento**: faseado em PRs.
8. **Libs internas/privadas**: compatibilidade com Node alvo — **pode ser bloqueador**.
9. **Path aliases (`@/`)**: substituir imports relativos profundos (`../../../`) por um alias
   de pathing. Decidir o mecanismo conforme o build (ver §Path aliases na Fase 8): com
   `bundle:false`, o `@/` exige reescrita no pós-build do esbuild.

---

## Regras críticas de tipagem e estilo (inegociáveis a partir da fase de TS)

- **SEMPRE tipar** retornos, args, `context`, models, resolvers, payloads (criar `interface`/`type`).
- **NUNCA usar `any`.** Use `unknown` + narrowing, generics ou uniões. Crie wrappers tipados
  para libs sem tipos. Proibido inclusive em assinaturas de bibliotecas.
- **Evitar `unknown` sempre que possível.** Use `unknown` apenas quando não há como derivar o
  tipo do contexto. Em módulos de proxy, **inspecione os campos da query GraphQL que é montada
  e crie uma interface que espelhe exatamente os campos de retorno** — nunca tipar o resultado
  de uma query como `unknown` se os campos são conhecidos pela própria string da query.
- **Sem comentários no código.** Nomes bem escolhidos dispensam explicação. Não adicionar linhas
  de comentário em implementações — a skill clean-code já cobre esse princípio.
- **DX em primeiro lugar:** schema GraphQL como fonte de verdade (tipos por codegen, não à mão);
  `tsx` para feedback rápido; erros de tipo pegos no build/CI.
- `strict: true`, `noImplicitAny`, `strictNullChecks`, `noUncheckedIndexedAccess`.

---

## Fases (cada uma = 1+ PR, gate verde + validação humana antes do merge)

- **Fase 0 — Preparação/bloqueadores/skills:** carregar skills + validar `skills-lock.json`;
  verificar compat. de libs internas com Node alvo (parar e alinhar se incompatível);
  atualizar `.nvmrc` e `engines.node`; rodar `knip`.
- **Fase 1 — Pacotes + tooling base:** migrar para **pnpm** (gerar `pnpm-lock.yaml`, remover
  `package-lock`/`yarn.lock`, preservar `.npmrc`/registries); remover husky/nodemon; adotar
  **oxlint**; criar **`.editorconfig`** na raiz. Gate: `pnpm install`, `pnpm lint`.
  - **oxlint e knip são gates permanentes** (não só desta fase): `pnpm lint` **sem erros** (incl.
    `typescript/no-explicit-any`) e **knip** sem deps/exports/arquivos não usados são condição de
    cada fase/PR, rodam no **CI sem `allow_failure`** (oxlint também no **pre-commit hook**).
    Nenhuma fase fecha com lint vermelho nem com dead code/deps órfãs.
- **Fase 2 — ESM nativo:** `"type":"module"`, remover `babel*`; `__dirname` → `import.meta.url`;
  loaders runtime (`@graphql-tools/load-files`, `fs`); `require` → `import`; introduzir
  **esbuild** (`esbuild.config.mjs`), script `build`, `start` → `node dist/server.js`.
  Gate: `pnpm build` + `pnpm start` sobem do `dist/`.
- **Fase 3 — ORM/dados:** subir ORM/driver à versão alvo; refatorar carregamento de models
  (remover `sequelize.import`); revisar operadores, paginação, hooks, transações, ENUMs.
  Gate: DB de teste + migrations + sync/seed.
- **Fase 4 — Fastify + Apollo Server 5 (maior risco):** bootstrap Fastify + Apollo via
  `@as-integrations/fastify` (`fastifyApolloHandler`/`fastifyApolloDrainPlugin`); montar
  `context`, plugins, `formatError`; migrar diretivas (`mapSchema`+`getDirective`), data
  sources e middlewares **preservando comportamento** (auth, roles, mascaramento de erro).
  Se GraphQL, integrar Fastify corretamente ao fluxo. Coordenar gateway se federado.
  Gate: introspecção/contrato + smoke autenticado.
- **Fase 5 — Demais deps + logging:** `fetch` nativo (`agent` → `undici.Agent`); **pino**
  (pretty só em dev), remover `console.*`/`winston`/`morgan`; subir libs utilitárias;
  remover deps mortas (knip).
- **Fase 6 — Testes:** **Vitest** (+ coverage v8), `vitest.config`; migrar arquivos
  (`require`→`import`, assertions, hooks); corrigir até a suíte ficar verde.
  - **Arquivos de teste em TypeScript:** renomear `*.test.js`→`*.test.ts` (e helpers para
    `.ts`), converter imports para o alias **`@/`** (src) / **`@test/`** (test), tipar o helper
    de app/contexto e as respostas (`zero any`; dublês de infra — redis/publisher/eventBroker/
    logger — podem usar `as unknown as T`). Ajustar `vitest.config` `include` para `*.test.ts` e
    os globs de override do `.oxlintrc.json`. Se os testes não entrarem no `tsc --noEmit`
    estrito (ex.: precisariam de `@types/*` extra ou config relaxada), registrar a decisão.
  - **Rodar 100% sem skip:** a meta é a suíte inteira verde, **sem `skip`/`skipIf`** silencioso.
    Testes que dependem de infra (Postgres/Redis/fila) ficam atrás de uma flag (ex.: `RUN_DB_TESTS`).
    Provisionar a infra descartável (Docker isolado em porta livre, **nunca** apontar para um
    banco real — `sync({force:true})`/migrations são destrutivos) e rodar com a flag ligada.
    Se ainda assim falharem, **reportar ao humano exatamente o que falta** (container, seeds,
    fixtures, URLs) em vez de deixar skipado. Verificar se o seeding/fixtures (ex.: `before`
    hooks que sincronizavam dados) foi de fato migrado — runners legados (mocha) costumavam
    semear dados por arquivo, e isso se perde na troca de runner.
- **Fase 7 — Infra:** Dockerfile `node:<alvo>-alpine` + corepack/pnpm + build esbuild,
  servir de `dist/` (manter `node_modules` no runtime); compose/start com pnpm; CI com stage
  de lint + type-check + testes.
- **Fase 8 — TypeScript:** `typescript@6.0.3` + `@types/*`; `tsconfig.json` `strict`; `.js`→`.ts`;
  criar `interface`/`type` (zero `any`); `tsx watch` no dev; `tsc --noEmit` no CI.
  Gate: `pnpm type-check` limpo.
  - **Path aliases (`@/`):** trocar imports que sobem diretório (`../…`) por um alias, mantendo
    `./` de mesmo diretório. Três pontos de resolução precisam concordar:
    1. **`tsconfig.json` `paths`** (`"@/*": ["./src/*"]`, `"@test/*": ["./test/*"]`) — resolve
       `tsc` e `tsx` (dev). No **TS 6.0+ não usar `baseUrl`** (deprecado; `paths` resolve relativo
       ao tsconfig).
    2. **Vitest `resolve.alias`** (regex `^@test/` antes de `^@/` para não colidir) — resolve os testes.
    3. **esbuild pós-build** (quando `bundle:false`): o Node em produção (`node dist/…`) **não** lê
       `tsconfig paths`; como `dist/` espelha `src/`, reescrever cada `@/x` para o caminho relativo
       `.js` correto do arquivo emitido até o irmão em `dist/` — no mesmo passo que já reescreve
       `.ts`→`.js`. (Subpath imports do Node `#` **não** encaixam bem no split `src/`↔`dist/`.)
    - Alinhar o **codegen** (`contextType`/`mappers`) ao `@/` para o arquivo gerado não dar drift.
    - Se houver enums/valores no arquivo gerado importados pelos resolvers, o `__generated__`
      **precisa ir para o build** (não é só type-only) — senão `node dist/…` quebra com
      `ERR_MODULE_NOT_FOUND`.
    - Codemod seguro: só reescrever specifiers em posição de `import/from`; **não** tocar strings
      de runtime (`pathToFileURL`/`path.join('…/x.js')`).
- **Fase 9 — GraphQL Codegen (schema = fonte de verdade):** gerar tipos do SDL e **tipar os
  resolvers com eles** (sem duplicar à mão). Duas variantes:
  - **A (padrão):** `@graphql-codegen/cli` + `@eddeee888/gcg-typescript-resolver-files`
    (server-preset) — arquivos de resolver tipados por módulo.
  - **B (resolvers carregados por glob em runtime):** o server-preset é **incompatível** (dona os
    arquivos por módulo) → use `typescript` + `typescript-resolvers` em **arquivo único** +
    **`mappers`** (tipo do SDL → classe do model; `parent`/retorno = instância do model),
    `contextType` e `defaultMapper: 'Partial<{T}>'`. Gerado **fora** do glob de resolvers.
  - **Padrões (Variante B):** tipar o mapa com `Resolvers`; **`satisfies Resolvers`** quando o
    módulo é **consumido por outro resolver/helper** (preserva o tipo chamável — `: Resolvers`
    alarga p/ `Resolver<>` não-chamável e quebra a chamada); **auto-referência** → extrair a
    lógica p/ `*-helper.ts` (TS7022); remover interfaces derivadas do schema, **manter** respostas
    externas (proxy), descartar sombras de infra; coerções `ID`→`string` (`Number()`/`String()`);
    `__resolveReference` resolve pela chave de federação; mudanças de apoio (FK `ForeignKey<>`,
    alargar helpers, campos no `context`) no mesmo PR; **um resolver por PR**.
  - Script `codegen`(+`--watch`) no CI. Gate: `pnpm codegen` sem drift; `tsc --noEmit` verde.
    Detalhes e exemplos em `guia-migracao-base.md` §Fase 9.
- **Fase 10 — Documentação (`CLAUDE.md` + `README.md`):** documentar o stack pós-migração
  para dois públicos.
  - **10.a `CLAUDE.md` (agentes):** **criar/atualizar na raiz** com o stack pós-migração.
    Se já existir, remover stack legado. Conteúdo mínimo: visão do stack, comandos (`pnpm
    dev/build/start/type-check/lint/test/codegen`), regras inegociáveis (zero `any`, schema =
    fonte de verdade, commits Conventional, uma mudança por PR, gates verdes), estrutura,
    skills (`.agents/skills/*` + `skills-lock.json`) e pegadinhas (`packages: external`,
    `.graphql` em runtime). Enxuto e factual — não duplicar o guia.
  - **10.b `README.md` (pessoas):** **criar/atualizar na raiz** refletindo o novo escopo. Se
    já existir, remover instruções do stack legado. Deixar **explícito o fluxo de setup**
    (clone → `nvm use` → `corepack enable` → `pnpm install` → `.env` → subir deps/migrations
    → `pnpm dev`, cada passo com comando exato) e uma **introdução/resumo** do repositório
    (o que faz, tipo de API, papel na arquitetura). Incluir stack, pré-requisitos, scripts,
    Docker, testes/qualidade, estrutura e contribuição.
  - **10.c Auditoria de variáveis de ambiente:** mapear **todo** uso de `process.env.*` no código
    **e nos testes** (`grep -rohE "process\.env\.[A-Z_0-9]+"`) e reconciliar com o `.env_example`
    e o README:
    - **Usadas no código mas não documentadas** → adicionar ao `.env_example`/README.
    - **Documentadas mas não usadas** (legadas) → antes de remover, conferir que **nenhuma lib
      interna** as consome (`grep` no `node_modules/@org/*`); só então remover.
    - **Variáveis só de teste** (ex.: `RUN_DB_TESTS`) → documentar na seção de testes.
    - Gate: `.env_example`/README batem exatamente com o que o código lê.
  - Modelos de ambos na seção Configs do `guia-migracao-base.md`.
  - Gate: `CLAUDE.md` e `README.md` na raiz, sem menção ao stack legado, comandos batendo
    com o `package.json`; um dev novo consegue subir o projeto só seguindo o README.

---

## Configs de referência

Ver os blocos prontos em `guia-migracao-base.md` (seção 7): `.oxlintrc.json`,
`.editorconfig`, `tsconfig.json` (ESM, `noEmit`), `esbuild.config.mjs` (`format:"esm"`, `target:"node24"`,
`packages:"external"`), `codegen.ts` (server-preset), scripts do `package.json`, logger
`pino`, e o **modelo de `CLAUDE.md`**. Reutilize-os ajustando ao stack do repositório.

---

## Checklist de migração (`migrate-checklist.md` na raiz — OBRIGATÓRIO)

- **Crie um `migrate-checklist.md` na raiz do projeto-alvo** no início da migração, listando
  todas as fases (incluindo sub-fases) como tarefas em formato `- [ ]`.
- **Após cada implementação de fase, com os gates passando**, marque a tarefa correspondente
  como concluída (`- [x]`). Não marque antes dos gates ficarem verdes.
- Mantenha o arquivo como fonte única de progresso da migração, atualizado em tempo real ao
  longo da sessão.
- Reaproveite a estrutura do checklist ponta a ponta abaixo (fases + gates) como base do arquivo.

---

## Checklist ponta a ponta (por fase e no fim)

- [ ] `pnpm install --frozen-lockfile` sem erros.
- [ ] `pnpm lint` (oxlint) sem erros — incluindo `no-explicit-any`. **Gate permanente** (CI sem
  `allow_failure` + pre-commit).
- [ ] **knip** (`pnpm dlx knip` ou script `knip`) sem deps/exports/arquivos não usados. **Gate
  permanente**: rodar a cada fase e no CI, não só na descoberta inicial — a migração não fecha
  com dead code/deps órfãs.
- [ ] `pnpm type-check` (`tsc --noEmit`) sem erros.
- [ ] `pnpm codegen` sem drift (idempotente).
- [ ] `pnpm build` gera `dist/` e `pnpm start` sobe dele (todos os imports de `dist/` resolvem;
  `@/` reescrito p/ relativo; `__generated__` no build se exporta valores).
- [ ] Path aliases (`@/` / `@test/`) resolvem em `tsc`, `tsx`, Vitest e no `dist/` (pós-build).
- [ ] Arquivos de teste em `*.test.ts` (zero `any`); `vitest.config` `include` e overrides do
  `.oxlintrc.json` ajustados.
- [ ] `pnpm test` (Vitest) verde **sem skip silencioso**; suítes de infra rodadas com a flag
  (ex.: `RUN_DB_TESTS=true`) contra infra descartável, ou bloqueadores reportados ao humano.
- [ ] Auditoria de env (Fase 10.c): `.env_example`/README batem com `process.env.*` do código e testes.
- [ ] `/healthcheck` (ou equivalente) responde 200.
- [ ] Contrato externo validado (REST/SDL/fila) — sem quebra de assinatura.
- [ ] Smoke de auth + operação crítica (incl. transações de banco).
- [ ] Imagem Docker `node:<alvo>` builda e migrations rodam.
- [ ] CI verde com stage de lint + type-check + testes.
- [ ] `skills-lock.json` coerente com `.agents/skills/`.
- [ ] `CLAUDE.md` na raiz criado/atualizado (Fase 10.a).
- [ ] `README.md` na raiz criado/atualizado com intro + setup explícito (Fase 10.b).
- [ ] `migrate-checklist.md` na raiz criado e com as tarefas concluídas marcadas (`[x]`) à medida que os gates passam.
- [ ] Cada fase executada **inline na sessão**, com resumo apresentado e validado pelo humano antes do commit/PR.

---

## Riscos recorrentes

Libs internas sem versão para o Node alvo (bloqueador, alinhar cedo) · serviços
acoplados/federados (coordenar deploy) · `any` vazando (proibir via lint) · drift
schema↔resolvers (codegen no CI) · diferenças sutis de API (`agent`→`dispatcher`,
`formatError`, Express→Fastify, `sequelize.import`) · `packages:"external"` exige
`node_modules` no runtime e loader p/ `.graphql` · ENUMs/tipos em upgrade de ORM ·
testes acoplados a `dist/` · perda silenciosa de cobertura ao trocar runner ·
**enums do codegen importados como valor** mas `__generated__` fora do build →
`ERR_MODULE_NOT_FOUND` em `node dist/` · **`sequelize-cli` não carrega config `.ts`/ESM**
(`Cannot find database.js`) → migrations não rodam sem config `.js`/compilada ·
**seeding/`before` hooks legados não migrados** → suítes de banco sem fixtures ·
`sync({force:true})` com **ordem de FK** quebrando em models novos · alias `@/` que não
encaixa no `dist/` (pós-build do esbuild) · `baseUrl` deprecado no TS 6.
